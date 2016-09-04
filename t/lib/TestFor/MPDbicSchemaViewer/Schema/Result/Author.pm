package TestFor::MPDbicSchemaViewer::Schema::Result::Author;

use base 'DBIx::Class::Core';

__PACKAGE__->table('Author');
__PACKAGE__->add_columns(
    author_id => {
        data_type => 'int',
        is_auto_increment => 1,
    },
    name => {
        data_type => 'varchar',
    },
    birth_date => {
        data_type => 'datetime',
    },
);

__PACKAGE__->set_primary_key(qw/author_id/);

__PACKAGE__->has_many(book_authors => 'TestFor::MPDbicSchemaViewer::Schema::Result::BookAuthor', 'author_id');
__PACKAGE__->many_to_many(books => 'book_authors', 'book_id');

1;
