use Test::Most;

use Im::Util::Meta qw(
  get_meta has_meta set_meta create_meta
  add_attribute add_requires add_with
  install_attr install_attrs install_sub
  install_new install_does
);

{
  package T1;
}

subtest crud_meta => sub {
  eq_or_diff([get_meta('T1')],[undef]);
  eq_or_diff([has_meta('T1')],['']);
  set_meta('T1',{foo=>'bar'});
  eq_or_diff(get_meta('T1'),{foo =>'bar'});
  eq_or_diff(T1->meta,{foo =>'bar'});
};

subtest create_meta => sub {
  my $meta = create_meta(type => 'foo');
	eq_or_diff({%$meta}, {type => 'foo', units => []});
  $meta = create_meta(type => 'foo', package => 'bar');
	eq_or_diff({%$meta}, {type => 'foo', package => 'bar', units => ['bar']});
  $meta = create_meta(type => 'foo', units => [qw(a b c)]);
	eq_or_diff({%$meta}, {type => 'foo', units => [qw(a b c)]});
  $meta = create_meta(type => 'foo', units => [qw(a b c)], package => 'bar');
	eq_or_diff({%$meta}, {type => 'foo', package => 'bar', units => [qw(a b c)]});
  $meta = create_meta(type => 'foo');
};

done_testing;
