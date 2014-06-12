use Test::Most;

use Im::Util::Meta qw(
  get_meta has_meta set_meta create_meta
  add_attribute add_requires add_with
  install_attr install_attrs install_sub mutate
  install_new install_does _attr_config _pa_for
);

# We'll need these for testing. We burn through a few

{
  package T1;
  package T2;
  package T3;
  package T4;
}

subtest mutate => sub {
	my $hr = {foo => 'bar'};
	my $ret = mutate($hr, sub {$_->{'bar'} = 'baz'});
  eq_or_diff($hr->{'bar'}, 'baz');
  eq_or_diff($ret->{'bar'}, 'baz');
  eq_or_diff($hr->{'foo'}, 'bar');
  eq_or_diff($ret->{'foo'}, 'bar');
};

subtest _pa_for => sub {
  eq_or_diff({%{_pa_for('foo')}}, {package => 'foo'});
  isa_ok(_pa_for, 'Package::Anonish::PP');
};

subtest crud_meta => sub {
  eq_or_diff([get_meta('T1')],[undef]);
  eq_or_diff([has_meta('T1')],['']);
  set_meta('T1',{foo=>'bar'});
  eq_or_diff(get_meta('T1'),{foo =>'bar'});
  eq_or_diff(T1->meta,{foo =>'bar'});
  set_meta('T1', create_meta(package => 'T1'));
  eq_or_diff(get_meta(T1->meta),T1->meta);
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

subtest install_sub => sub {
  set_meta('T1', create_meta(package => 'T1'));
  my $meta = T1->meta;
  eq_or_diff({%$meta}, {package => 'T1', units => ['T1'], type => 'unit' });
  install_sub($meta, 'foo', sub { 42 });
  eq_or_diff(T1->foo, 42);
};

subtest _attr_config => sub {
  eq_or_diff({_attr_config('foo')}, {init_arg => 'foo'});
  eq_or_diff({_attr_config('foo', required => 1)},
             {init_arg => 'foo', required =>1});
  eq_or_diff({_attr_config('foo', predicate => 1)},
             {init_arg => 'foo', predicate => 'has_foo'});
  throws_ok {
    _attr_config('foo', required => 1, predicate => 1);
  } qr/Can't have a predicate and be required/;
};


subtest install_attr => sub {
  set_meta('T2', create_meta(package=>'T2'));
  # The simplest case
  install_attr('T2', 'foo');
  ok('T2'->can('foo'));
  my $t2 = bless({qw(foo bar bar baz baz quux)}, 'T2');
  eq_or_diff($t2->foo,'bar');
  # Now we try a builder
  install_attr('T2', 'bar', builder => sub { 42 });
  ok($t2->can('_build_bar'));
  {
    local *T2::_build_bar = sub {die("DELIBERATE");};
    # We expect it to call the builder
    throws_ok {
      $t2->bar;
    } qr/DELIBERATE/;
  }
  # Now, having unhooked it, it should return the content of the builder
  eq_or_diff($t2->bar, 42);
  {
    local *T2::_build_bar = sub {die("DELIBERATE");};
    # The second time round, don't build. Success, the final attr is installed
    eq_or_diff($t2->bar, 42);
  }
  eq_or_diff($t2->_build_bar, 42);
  install_attr('T2', 'baz', builder => sub { 42 }, predicate => undef);
  ok($t2->can('baz'));
  ok(!$t2->can('has_baz'));
};

subtest "install_attrs, add_attribute" => sub {
  set_meta('T3', create_meta(package=>'T3'));
  add_attribute('T3', 'foo');
  add_attribute('T3', 'bar', builder => sub { 42 });
  add_attribute('T3', 'baz', builder => sub { 42 }, predicate => undef);
  install_attrs('T3');
  my $t3 = bless({qw(foo bar bar baz baz quux)}, 'T3');
  eq_or_diff($t3->foo,'bar');
  eq_or_diff($t3->bar, 42);
  eq_or_diff($t3->_build_bar, 42);
  ok($t3->can('baz'));
  ok(!$t3->can('has_baz'));
};

subtest add_requires => sub {
  set_meta('T4', create_meta(package => 'T4'));
  add_requires('T4', qw(a b c));
  add_requires('T4', qw(b c d));
  eq_or_diff('T4'->meta->{'requires'}, [qw(a b c d)]);
};

subtest add_with => sub {
  add_with('T4', qw(a b c));
  add_with('T4', qw(b c d));
  eq_or_diff('T4'->meta->{'units'}, [qw(T4 a b c d)]);
};

subtest install_does => sub {
  install_does(T1->meta);
  eq_or_diff(T1->meta->{'units'}, ['T1']);
  eq_or_diff(T1->does('T1'),1);
  eq_or_diff(T1->does('T2'),0);
};

subtest install_new => sub {
  install_new(T1->meta);
  # TODO: can't really test this until we've tested reify :(
  ok(1);
};


done_testing;
