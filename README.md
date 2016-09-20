# NAME

Mojolicious::Plugin::DbicSchemaViewer - Viewer for DBIx::Class schema definitions

<div>
    <p>
    <img src="https://img.shields.io/badge/perl-5.20+-blue.svg" alt="Requires Perl 5.20+" />
    <a href="https://travis-ci.org/Csson/p5-Mojolicious-Plugin-DbicSchemaViewer"><img src="https://api.travis-ci.org/Csson/p5-Mojolicious-Plugin-DbicSchemaViewer.svg?branch=master" alt="Travis status" /></a>
    <a href="http://cpants.cpanauthors.org/release/CSSON/Mojolicious-Plugin-DbicSchemaViewer-0.0200"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Mojolicious-Plugin-DbicSchemaViewer/0.0200" alt="Distribution kwalitee" /></a>
    <a href="http://matrix.cpantesters.org/?dist=Mojolicious-Plugin-DbicSchemaViewer%200.0200"><img src="http://badgedepot.code301.com/badge/cpantesters/Mojolicious-Plugin-DbicSchemaViewer/0.0200" alt="CPAN Testers result" /></a>
    <img src="https://img.shields.io/badge/coverage-59.0%-red.svg" alt="coverage 59.0%" />
    </p>
</div>

# VERSION

Version 0.0200, released 2016-09-20.

# SYNOPSIS

    $self->plugin(DbicSchemaViewer => {
        schema => Your::Schema->connect(...),
    });

# DESCRIPTION

This plugin is a definition viewer for [DBIx::Class](https://metacpan.org/pod/DBIx::Class) schemas. It currently offers two different views on the schema:

- It lists all result sources with column definitions and and their relationships in table form.
- It uses  [DBIx::Class::Visualizer](https://metacpan.org/pod/DBIx::Class::Visualizer) to generate an entity-relationship model.

## Configuration

The following settings are available. It is recommended to use either ["router"](#router) or ["condition"](#condition) to place the viewer behind some kind of authorization check.

### allowed\_schemas

An optional array reference consisting of schema classes. If set, only these classes are available for viewing.

If not set, all findable schema classes can be viewed.

### url

Optional.

By default, the viewer is located at `/dbic-schema-viewer`.

    $self->plugin(DbicSchemaViewer => {
        url => '/the-schema',
        schema => Your::Schema->connect(...),
    });

The viewer is instead located at `/the-schema`.

Note that the CSS and Javascript files are served under `/dbic-schema-viewer` regardless of this setting.

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

# DEMO

There is a demo available at [http://dsv.code301.com/MadeUp::Book::Schema](http://dsv.code301.com/MadeUp::Book::Schema). Don't miss the help page for instructions.

# SEE ALSO

- `dbic-schema-viewer` - a small application (in `/bin`) for running this plugin standalone.
- [DBIx::Class::Visualizer](https://metacpan.org/pod/DBIx::Class::Visualizer)

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
