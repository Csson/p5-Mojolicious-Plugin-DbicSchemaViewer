use strict;
use warnings;

package Mojolicious::Plugin::DbicSchemaViewer;

# ABSTRACT: Viewer for DBIx::Class schema definitions
# AUTHORITY
our $VERSION = '0.0103';

use Mojo::Base 'Mojolicious::Plugin';
use File::ShareDir::Tarball 'dist_dir';
use Path::Tiny;
use Data::Dump::Streamer;
use Safe::Isa;
use DateTime::Tiny;
use PerlX::Maybe;
use List::Util qw/none/;
use DBIx::Class::Visualizer;

use experimental qw/signatures postderef/;

has schemas => sub { +{} };
has allowed_schemas => sub { [] };

sub register($self, $app, $conf) {
    $app->plugin('BootstrapHelpers');

    # Check configuration
    if(exists $conf->{'router'} && exists $conf->{'condition'}) {
        my $exception = "Can't use both 'router' and 'condition' in M::P::DbicSchemaViewer";
        $app->log->fatal($exception);
        $app->reply->exception($exception);
        return;
    }
    # Preload all (if any) allowed schemas
    if(exists $conf->{'allowed_schemas'} && scalar $conf->{'allowed_schemas'}->@*) {
        $self->allowed_schemas->@* = $conf->{'allowed_schemas'}->@*;

        for my $allowed ($self->allowed_schemas->@*) {
            if(eval "require $allowed") {
                $self->schemas->{ $allowed } = $allowed->connect;
            }
        }
    }
    # add our template directory
    my $template_dir = path(dist_dir('Mojolicious-Plugin-DbicSchemaViewer'))->child('templates');

    if($template_dir->is_dir) {
        push $app->renderer->paths->@* => $template_dir->realpath;
    }

    my $router = exists $conf->{'router'}    ?  $conf->{'router'}
               : exists $conf->{'condition'} ?  $app->routes->over($conf->{'condition'})
               :                                $app->routes
               ;

    my $url = $conf->{'url'} || 'dbic-schema-viewer';

    push @{ $app->static->paths }, path(dist_dir('Mojolicious-Plugin-DbicSchemaViewer'))->child('public')->stringify;


    # Routes
    my $base = $router->get($url);

    # home / schema
    $base->get('/')->to(cb => sub ($c) {
        my $schema = $self->get_schema($app, $c);

        $c->redirect_to('error') && return if !defined $schema;

        $self->render($c, 'viewer/schema', db => $self->schema_info($schema), schema_name => ref $schema);
    })->name('schema');

    # visualizer
    $base->get('visualizer')->to(cb => sub ($c) {
        my $schema = $self->get_schema($app, $c);
        $c->redirect_to('error') && return if !defined $schema;

        my(%wanted_result_source_names, %skip_result_source_names);

        if($c->param('wanted_result_source_names')) {
            my $wanted_result_source_names = [split /,/ => $c->param('wanted_result_source_names')];
            %wanted_result_source_names = scalar $wanted_result_source_names->@* ? (wanted_result_source_names => $wanted_result_source_names) : ();
        }
        if($c->param('skip_result_source_names')) {
            my $skip_result_source_names = [split /,/ => $c->param('skip_result_source_names')];
            %skip_result_source_names = scalar $skip_result_source_names->@* ? (skip_result_source_names => $skip_result_source_names) : ();
        }

        my %args = (schema => $schema,
                      %wanted_result_source_names,
                      %skip_result_source_names,
                maybe degrees_of_separation => $c->param('degrees_of_separation'));

        $self->render($c, 'viewer/visualizer',
            schema_name => ref $schema,
            svg => DBIx::Class::Visualizer->new(
                      schema => $schema,
                      %wanted_result_source_names,
                      %skip_result_source_names,
                maybe degrees_of_separation => $c->param('degrees_of_separation'),
            )->svg
        );
    })->name('visualizer');

    # error
    $base->get('error')->to(cb => sub ($c) {
        $self->render($c, 'viewer/error', schema_name => 'Error');
    })->name('error');

}

sub render($self, $c, $template, @args) {
    my %layout = (layout => 'plugin-dbic-schema-viewer-default');
    $c->render(%layout, template => join ('/' => ('plugin-dbic-schema-viewer', $template)), @args);
}

sub get_schema {
    my $self = shift;
    my $app = shift;
    my $c = shift;

    my $schema;
    if($c->param('schema')) {
        if(scalar $self->allowed_schemas->@* && (none { $c->param('schema') eq $_ } $self->allowed_schemas->@*)) {
            $app->log->fatal($c->param('schema') . ' is not in the list of allowed schemas');
        }
        if(exists $self->schemas->{ $c->param('schema') }) {
            return $self->schemas->{ $c->param('schema') };
        }
        elsif(eval "require @{[ $c->param('schema') ]}") {
            $schema = ($c->param('schema'))->connect;
        }
        else {
            $app->log->fatal("Could not load @{[ $c->param('schema') ]}");
        }
    }
    else {
        $app->log->fatal(q{M::P::DbicSchemaViewer is missing mandatory 'schema' parameter.});
        return;
    }

    if($schema->$_isa('DBIx::Class::Schema')) {
        $self->schemas->{ $c->param('schema') } = $schema;
    }
    else {
        my $exception = "'schema' must be an DBIx::Class::Schema instance in M::P::DbicSchemaViewer, @{[ $c->param('schema') ]} is not";
        $app->log->fatal($exception);
        $app->reply->exception($exception);
        return;
    }
    return $schema;
}
sub schema_info($self, $schema) {

    my $db = { sources => [] };

    # put View:: result sources last
    my @sorted_sources = sort grep { !/^View::/ } $schema->sources;
    push @sorted_sources => sort grep { /^View::/ } $schema->sources;

    foreach my $source_name (@sorted_sources) {
        my $rs = $schema->resultset($source_name)->result_source;

        my $uniques = {};
        my %unique_constraints = $rs->unique_constraints;

        foreach my $unique_constraint (keys %unique_constraints) {
            foreach my $column ($unique_constraints{ $unique_constraint }->@*) {
                if(!exists $uniques->{ $column }) {
                    $uniques->{ $column } = [];
                }
                push $uniques->{ $column }->@* => $unique_constraint;
            }
        }
        my $clean_name = lc $source_name =~ s{::}{_}gr;

        my $source = {
            name => $source_name,
            clean_name => $clean_name,
            primary_columns => [$rs->primary_columns],
            unique_constraints => [$rs->unique_constraints],
            uniques => $uniques,
            columns_info => [],
            relationships => [],
        };

        foreach my $column_name ($rs->columns) {
            my $column_info = { $rs->column_info($column_name)->%* };
            my $data_type = delete $column_info->{'data_type'};
            $data_type = $column_info->{'is_enum'} && scalar $column_info->{'extra'}{'list'}->@* ? "enum/$data_type" : $data_type;

            push $source->{'columns'}->@* => {
                name => $column_name,
                $column_info->%*,
                data_type => $data_type,
            };
        }

        foreach my $relation_name (sort $rs->relationships) {
            my $relation = $rs->relationship_info($relation_name);
            my $class_name = $relation->{'class'} =~ s{^.*?::Result::}{}r;

            my $condition;
            # simple one column to one column relation: this_result_id => relation_name.that_result_id
            if(ref $relation->{'cond'} eq 'HASH' && scalar keys $relation->{'cond'}->%* == 1) {
                my @cleaned_condition = ((values $relation->{'cond'}->%*)[0] =~ s{^self\.}{}rx);
                push @cleaned_condition => (keys $relation->{'cond'}->%*)[0] =~ s{^foreign(?=\.)}{$relation_name}rx;
                $condition = join ' => ', @cleaned_condition;
            }
            # more complicated relation: dump relation to text and remove boilerplate
            else {
                $condition = Dump($relation->{'cond'})->Out;

                # cleanup the dump
                $condition =~ s{^.*?\{}{\{};
                $condition =~ s{\n\s*?package .*?\n}{\n};
                $condition =~ s{\n\s*?BEGIN.*?\n}{\n};
                $condition =~ s{\n\s*?use strict.*?\n}{\n}g;
                $condition =~ s{\n\s*?use feature.*?\n}{\n}g;
                $condition =~ s{\n\s*?no feature.*?\n}{\n}g;
                $condition =~ s{\n\s{3,}\}}{\n\}};
                $condition =~ s{\n\s{8,8}}{\n    }g;
            }

            my $on_cascade = [ sort map { $_ =~ s{^cascade_}{}rm } grep { m/^cascade/ && $relation->{'attrs'}{ $_ } } keys $relation->{'attrs'}->%* ];

            push $source->{'relationships'}->@* => {
                name => $relation_name,
                class_name => $class_name,
                clean_name => lc $class_name =~ s{::}{_}rg,
                condition => $condition,
                on_cascade => $on_cascade,
                $relation->%*,
                has_reverse_relation => keys $rs->reverse_relationship_info($relation_name)->%* ? 1 : 0,
            };
        }

        push $db->{'sources'}->@* => $source;
    }
    return $db;
}

sub visualizer($self, $schema) {
    ;
}

1;


__END__

=pod

=encoding utf-8

=head1 SYNOPSIS

    $self->plugin(DbicSchemaViewer => {
        schema => Your::Schema->connect(...),
    });

=head1 DESCRIPTION

This plugin is a viewer for L<DBIx::Class> schemata. It lists all C<ResultSources> with column definitions and and their relationships. See C<examples/example.html> for
an example (also available on L<Github|http://htmlpreview.github.io/?https://github.com/Csson/p5-Mojolicious-Plugin-DbicSchemaViewer/blob/master/examples/example.html>).

Optionally, if L<DBIx::Class::Visualizer> is installed, a graphical representation of the schema can be rendered using L<GraphViz2>.

=head2 Configuration

The following settings are available. It is recommended to use either L</router> or L</condition> to place the viewer behind some kind of authorization check.

=head3 schema

Mandatory.

An instance of a C<DBIx::Class::Schema> class.

=head3 url

Optional.

By default, the viewer is located at C</dbic-schema-viewer>.

    $self->plugin(DbicSchemaViewer => {
        url => '/the-schema',
        schema => Your::Schema->connect(...),
    });

The viewer is instead located at C</the-schema>.

=head3 router

Optional. Can not be used together with L</condition>.

Use this when you which to place the viewer behind an C<under> route:

    my $secure = $app->routes->under('/secure' => sub {
        my $c = shift;
        return defined $c->session('logged_in') ? 1 : 0;
    });

    $self->plugin(DbicSchemaViewer => {
        router => $secure,
        schema => Your::Schema->connect(...),
    });
    
Now the viewer is located at C</secure/dbic-schema-viewer> (if the check is successful).

=head3 condition

Optional. Can not be used together with L</router>.

Use this when you have a named condition you which to place the viewer behind:

    $self->routes->add_condition(random => sub { return !int rand 4 });

    $self->plugin(DbicSchemaViewer => {
        condition => 'random',
        schema => Your::Schema->connect(...),
    });
