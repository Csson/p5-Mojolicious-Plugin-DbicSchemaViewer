use Mojolicious::Lite;
 
use lib 't/lib';
use TestFor::MPDbicSchemaViewer::Schema;

plugin 'DbicSchemaViewer', schema => TestFor::MPDbicSchemaViewer::Schema->connect;

app->start;
