use strict;
use warnings;

package Mojolicious::Plugin::DbicSchemaViewer;

# VERSION:
# ABSTRACT: Viewer for DBIx::Class schemas

use Mojo::Base 'Mojolicious::Plugin';
use File::ShareDir::Tarball 'dist_dir';
use Path::Tiny;
use Data::Dump::Streamer;
use experimental qw/signatures postderef/;

sub register($self, $app, $conf) {
    $conf->{'under'} ||= ['/admin/dbic'];
    my $schema = $conf->{'schema'};

    my $share_dir = path(dist_dir('Mojolicious-Plugin-DbicSchemaViewer'));
    $app->log->info('share_dir: ' . $share_dir);
    if($share_dir->is_dir) {
        $app->log->info('  exists');
        if($share_dir->child('static')->is_dir) {
            push $app->static->paths->@* => $share_dir->child('static')->realpath;
        }
        if($share_dir->child('templates')->is_dir) {
            $app->log->info('  adds templates dir: ' . $share_dir->child('templates'));
            push $app->renderer->paths->@* => $share_dir->child('templates')->realpath;
        }
        else {
            $app->log->info('  no template dir :(');
        }
    }

    $app->log->info("Serving from " . join ', ' => $app->renderer->paths->@*);

    my %layout = (layout => 'plugin-dbic-schema-viewer-default');

    my $router = $app->routes->under($conf->{'under'}->@*);
    $router->get('/')->to(cb => sub ($c) {
        $c->render(%layout, template => tmpl('viewer/schema'), db => $self->schema_info($schema), schema_name => ref $schema);
    });
}

sub tmpl($template) {
    return join '/' => ('plugin', 'dbicschemaviewer', $template);
}

sub schema_info($self, $schema) {

    my $db = { sources => [] };

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
         #   warn Dump $relation;

            my $class_name = $relation->{'class'} =~ s{^.*?::Result::}{}r;
            my $condition = Dump($relation->{'cond'})->Out;

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
  #  warn Dump $db;
    return $db;
}

1;
