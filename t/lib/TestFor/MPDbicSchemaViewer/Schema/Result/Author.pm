package TestFor::MPDbicSchemaViewer::Schema::Result::Author;

use base 'DBIx::Class::Core';

__PACKAGE__->table('Author');
__PACKAGE__->add_columns(
    author_id => { data_type => 'int' },
    name => { data_type => 'varchar' },
    birth_date => { data_type => 'datetime' },
);

__PACKAGE__->set_primary_key(qw/author_id/);

__PACKAGE__->has_many(books => 'TestFor::MPDbicSchemaViewer::Schema::Result::Book', 'author_id');

1;
