use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Test::Deep;
use Mojolicious::Lite;

use lib 't/lib';
use TestFor::MPDbicSchemaViewer::Schema;

my $schema = TestFor::MPDbicSchemaViewer::Schema->connect('dbi:SQLite:dbname=:memory:', '', '');

plugin 'DbicSchemaViewer' => { schema => $schema };

my $t = Test::Mojo->new;

$t->get_ok('/dbic-schema-viewer')->status_is(200)->content_like(qr/for TestFor::MPDbicSchemaViewer::Schema/);

done_testing;
