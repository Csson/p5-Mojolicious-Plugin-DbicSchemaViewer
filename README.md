# NAME

Mojolicious::Plugin::DbicSchemaViewer - Viewer for DBIx::Class schema definitions

![Requires Perl 5.20+](https://img.shields.io/badge/perl-5.20+-brightgreen.svg) [![Travis status](https://api.travis-ci.org//.svg?branch=master)](https://travis-ci.org//)

# VERSION

Version 0.0001, released 2015-10-28.

# SYNOPSIS

    $self->plugin(DbicSchemaViewer => {
        schema => Your::Schema->connect(...),
    });

# DESCRIPTION

This plugin is a simple viewer for [DBIx::Class](https://metacpan.org/pod/DBIx::Class) schemas. It lists all `ResultSources` with column definitions and and their relationships.

## Configuration

The following settings are available. It is recommended to use either [router](https://metacpan.org/pod/router) or [condition](https://metacpan.org/pod/condition) to place the viewer behind some kind of authorization check.

### schema

Mandatory.

Should be an instance of an `DBIx::Class::Schema` class.

### url

Optional.

By default, the viewer is located at `/dbic-schema-viewer`.

### router

Optional. Can not be used together with [condition](https://metacpan.org/pod/condition).

Use this when you which to place the viewer behind an `under` route:

    my $secure = $app->routes->under('/secure' => sub {
        my $c = shift;
        return defined $c->session('logged_in') ? 1 : 0;
    });

    $self->plugin(DbicSchemaViewer => {
        router => $secure,
        schema => Your::Schema->connect(...),
    });

Now the viewer would be located, if the check is successful, at `/secure/dbic-schema-viewer`.

### condition

Optional. Can not be used together with [router](https://metacpan.org/pod/router).

Use this when you have a named condition you which to place the viewer behind:

    $self->routes->add_condition(random => sub { return !int rand 4 });

    $self->plugin(DbicSchemaViewer => {
        condition => 'random',
        schema => Your::Schema->connect(...),
    });

# HOMEPAGE

[https://metacpan.org/release/Mojolicious-Plugin-DbicSchemaViewer](https://metacpan.org/release/Mojolicious-Plugin-DbicSchemaViewer)

# AUTHOR

Erik Carlsson <info@code301.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson <info@code301.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
