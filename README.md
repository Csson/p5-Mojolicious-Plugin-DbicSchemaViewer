# NAME

Mojolicious::Plugin::DbicSchemaViewer - Viewer for DBIx::Class schema definitions

<div>
    <p>
    <img src="https://img.shields.io/badge/perl-5.20+-blue.svg" alt="Requires Perl 5.20+" />
    <a href="https://travis-ci.org/Csson/p5-Mojolicious-Plugin-DbicSchemaViewer"><img src="https://api.travis-ci.org/Csson/p5-Mojolicious-Plugin-DbicSchemaViewer.svg?branch=master" alt="Travis status" /></a>
    <a href="http://cpants.cpanauthors.org/release/CSSON/Mojolicious-Plugin-DbicSchemaViewer-0.0102"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Mojolicious-Plugin-DbicSchemaViewer/0.0102" alt="Distribution kwalitee" /></a>
    <a href="http://matrix.cpantesters.org/?dist=Mojolicious-Plugin-DbicSchemaViewer%200.0102"><img src="http://badgedepot.code301.com/badge/cpantesters/Mojolicious-Plugin-DbicSchemaViewer/0.0102" alt="CPAN Testers result" /></a>
    <img src="https://img.shields.io/badge/coverage-65.3%-red.svg" alt="coverage 65.3%" />
    </p>
</div>

# VERSION

Version 0.0102, released 2016-09-04.

# SYNOPSIS

    $self->plugin(DbicSchemaViewer => {
        schema => Your::Schema->connect(...),
    });

# DESCRIPTION

This plugin is a viewer for [DBIx::Class](https://metacpan.org/pod/DBIx::Class) schemata. It lists all `ResultSources` with column definitions and and their relationships. See `examples/example.html` for
an example (also available on [Github](http://htmlpreview.github.io/?https://github.com/Csson/p5-Mojolicious-Plugin-DbicSchemaViewer/blob/master/examples/example.html)).

Optionally, if [DBIx::Class::Visualizer](https://metacpan.org/pod/DBIx::Class::Visualizer) is installed, a graphical representation of the schema can be rendered using [GraphViz2](https://metacpan.org/pod/GraphViz2).

## Configuration

The following settings are available. It is recommended to use either ["router"](#router) or ["condition"](#condition) to place the viewer behind some kind of authorization check.

### schema

Mandatory.

An instance of a `DBIx::Class::Schema` class.

### url

Optional.

By default, the viewer is located at `/dbic-schema-viewer`.

    $self->plugin(DbicSchemaViewer => {
        url => '/the-schema',
        schema => Your::Schema->connect(...),
    });

The viewer is instead located at `/the-schema`.

### router

Optional. Can not be used together with ["condition"](#condition).

Use this when you which to place the viewer behind an `under` route:

    my $secure = $app->routes->under('/secure' => sub {
        my $c = shift;
        return defined $c->session('logged_in') ? 1 : 0;
    });

    $self->plugin(DbicSchemaViewer => {
        router => $secure,
        schema => Your::Schema->connect(...),
    });

Now the viewer is located at `/secure/dbic-schema-viewer` (if the check is successful).

### condition

Optional. Can not be used together with ["router"](#router).

Use this when you have a named condition you which to place the viewer behind:

    $self->routes->add_condition(random => sub { return !int rand 4 });

    $self->plugin(DbicSchemaViewer => {
        condition => 'random',
        schema => Your::Schema->connect(...),
    });

# SOURCE

[https://github.com/Csson/p5-Mojolicious-Plugin-DbicSchemaViewer](https://github.com/Csson/p5-Mojolicious-Plugin-DbicSchemaViewer)

# HOMEPAGE

[https://metacpan.org/release/Mojolicious-Plugin-DbicSchemaViewer](https://metacpan.org/release/Mojolicious-Plugin-DbicSchemaViewer)

# AUTHOR

Erik Carlsson <info@code301.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
