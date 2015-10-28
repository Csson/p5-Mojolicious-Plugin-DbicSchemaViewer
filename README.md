# NAME

Mojolicious::Plugin::DbicSchemaViewer - Viewer for DBIx::Class schema definitions

![Requires Perl 5.20+](https://img.shields.io/badge/perl-5.20+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Mojolicious-Plugin-DbicSchemaViewer.svg?branch=master)](https://travis-ci.org/Csson/p5-Mojolicious-Plugin-DbicSchemaViewer)

# VERSION

Version 0.0101, released 2015-10-28.

# SYNOPSIS

    $self->plugin(DbicSchemaViewer => {
        schema => Your::Schema->connect(...),
    });

# DESCRIPTION

This plugin is viewer for [DBIx::Class](https://metacpan.org/pod/DBIx::Class) schemas. It lists all `ResultSources` with column definitions and and their relationships. See `examples/example.html` for an example.

## Configuration

The following settings are available. It is recommended to use either ["router"](#router) or ["condition"](#condition) to place the viewer behind some kind of authorization check.

### schema

Mandatory.

Should be an instance of an `DBIx::Class::Schema` class.

### url

Optional.

By default, the viewer is located at `/dbic-schema-viewer`.

    $self->plugin(DbicSchemaViewer => {
        url => '/the-schema',
        schema => Your::Schema->connect(...),
    });

Now the viewer is located at `/the-schema`.

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

This software is copyright (c) 2015 by Erik Carlsson <info@code301.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
