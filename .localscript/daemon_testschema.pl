use Mojolicious::Lite;

use Dir::Self;
use lib __DIR__ . '/../t/lib';
use TestFor::MPDbicSchemaViewer::Schema;

plugin 'DbicSchemaViewer', schema => TestFor::MPDbicSchemaViewer::Schema->connect;

app->start;
