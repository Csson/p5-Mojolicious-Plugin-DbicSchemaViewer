package TestFor::MPDbicSchemaViewer::Schema::Result::One;

use base 'DBIx::Class::Core';

__PACKAGE__->table('One');
__PACKAGE__->add_columns(
    one_id => { data_type => 'int' },
    thedata => { data_type => 'varchar' },
);

__PACKAGE__->set_primary_key(qw/one_id/);

__PACKAGE__->has_many(many => 'TestFor::MPDbicSchemaViewer::Schema::Result::Many', 'one_id');

1;
