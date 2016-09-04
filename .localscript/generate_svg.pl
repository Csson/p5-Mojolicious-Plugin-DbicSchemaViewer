#!/usr/bin/env perl

use 5.10.1;
use strict;
use warnings;

use Dir::Self;
use Path::Tiny;
use DBIx::Class::Visualizer;
use lib __DIR__ . '/../t/lib';
use TestFor::MPDbicSchemaViewer::Schema;

main();

sub main {
    my $schema = TestFor::MPDbicSchemaViewer::Schema->connect;
    my $outdir = path(__DIR__.'/../../DBIx-Class-Visualizer/example/');

    $outdir->child('visualized.svg')->spew(DBIx::Class::Visualizer->new(schema => $schema)->svg);
    say $outdir->child('visualized.svg')->stringify;
}
