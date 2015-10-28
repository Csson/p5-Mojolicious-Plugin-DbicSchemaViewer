use strict;
use warnings;

package Mojolicious::Plugin::DbicSchemaViewer;

# VERSION:
# ABSTRACT: Viewer for DBIx::Class schema definitions

use Mojo::Base 'Mojolicious::Plugin';
use File::ShareDir::Tarball 'dist_dir';
use Path::Tiny;
use Data::Dump::Streamer;
use Safe::Isa;
use experimental qw/signatures postderef/;

sub register($self, $app, $conf) {

    # check configuration
    if(exists $conf->{'router'} && exists $conf->{'condition'}) {
        my $exception = "Can't use both 'router' and 'condition' in M::P::DbicSchemaViewer";
        $app->log->fatal($exception);
        $app->reply->exception($exception);
        return;
    }
    if(!exists $conf->{'schema'} || !$conf->{'schema'}->$_isa('DBIx::Class::Schema')) {
        my $exception = "'schema' must be an DBIx::Class::Schema instance in M::P::DbicSchemaViewer";
        $app->log->fatal($exception);
        $app->reply->exception($exception);
        return;
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
    my $schema = $conf->{'schema'};

    $router->get($url)->to(cb => sub ($c) {
        $self->render($c, 'viewer/schema', db => $self->schema_info($schema), schema_name => ref $schema);
    });
}

sub render($self, $c, $template, @args) {
    my %layout = (layout => 'plugin-dbic-schema-viewer-default');
    $c->render(%layout, template => join ('/' => ('plugin-dbic-schema-viewer', $template)), @args);
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

            my $condition = Dump($relation->{'cond'})->Out;

            # cleanup the dump
            $condition =~ s{^.*?\{}{\{};
            $condition =~ s{\n\s*?package .*?\n}{\n};
            $condition =~ s{\n\s*?BEGIN.*?\n}{\n};
            $condition =~ s{\n\s*?use strict.*\n}{\n}g;
            $condition =~ s{\n\s*?use feature.*\n}{\n}g;
            $condition =~ s{\n\s*?no feature.*\n}{\n}g;
            $condition =~ s{\n\s{3,}\}}{\n\}};
            $condition =~ s{\n\s{8,8}}{\n    }g;

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

1;


__END__

=pod

=encoding utf-8

=head1 SYNOPSIS

    $self->plugin(DbicSchemaViewer => {
        schema => Your::Schema->connect(...),
    });

=head1 DESCRIPTION

This plugin is a simple viewer for L<DBIx::Class> schemas. It lists all C<ResultSources> with column definitions and and their relationships.

=head2 Configuration

The following settings are available. It is recommended to use either L<router> or L<condition> to place the viewer behind some kind of authorization check.

=head3 schema

Mandatory.

Should be an instance of an C<DBIx::Class::Schema> class.

=head3 url

Optional.

By default, the viewer is located at C</dbic-schema-viewer>.

=head3 router

Optional. Can not be used together with L<condition>.

Use this when you which to place the viewer behind an C<under> route:

    my $secure = $app->routes->under('/secure' => sub {
        my $c = shift;
        return defined $c->session('logged_in') ? 1 : 0;
    });

    $self->plugin(DbicSchemaViewer => {
        router => $secure,
        schema => Your::Schema->connect(...),
    });
    
Now the viewer would be located, if the check is successful, at C</secure/dbic-schema-viewer>.

=head3 condition

Optional. Can not be used together with L<router>.

Use this when you have a named condition you which to place the viewer behind:

    $self->routes->add_condition(random => sub { return !int rand 4 });

    $self->plugin(DbicSchemaViewer => {
        condition => 'random',
        schema => Your::Schema->connect(...),
    });
