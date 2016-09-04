package TestFor::MPDbicSchemaViewer::Schema::Result::Book;

use base 'DBIx::Class::Core';

__PACKAGE__->table('Book');
__PACKAGE__->add_columns(
    book_id => { data_type => 'int' },
    isbn => { data_type => 'varchar', size => 13 },
    title => { data_type => 'varchar' },
    author_id => { data_type => 'int', is_foreign_key => 1 },
);

__PACKAGE__->set_primary_key(qw/book_id/);

__PACKAGE__->belongs_to(author => 'TestFor::MPDbicSchemaViewer::Schema::Result::Author', 'author_id');

1;
