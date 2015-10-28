package TestFor::MPDbicSchemaViewer::Schema::Result::Many;

use base 'DBIx::Class::Core';

__PACKAGE__->table('Many');
__PACKAGE__->add_columns(
	many_id => { data_type => 'int' },
	thedata => { data_type => 'varchar' },
);

__PACKAGE__->set_primary_key(qw/many_id/);

1;
