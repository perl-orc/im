use Test::Most;

use Im::Util::Unit qw(
  declare_unit finalise_unit
  reify
  clone
  _diff_ars _methodref_to_string _methods_to_merge
  _ensure_covered _sanitise_reify_args _expand_units
);
use Im::Util::Meta qw(add_requires);
# Packages are cheap, they burn well
{
  package T1;
  sub meta {
    return bless {units => [qw(T1 T2)], package => 'T1'}, 'Im::Meta';
  }
  sub foo {}
  package T2;
  sub meta {
    return bless {units => [qw(T1 T3 T4)], package => 'T2'}, 'Im::Meta';
  }
  sub bar {}
  package T3;
  sub meta {
    return bless {units => [qw(T1 T2 T4)], package => 'T3'}, 'Im::Meta';
  }
  sub foo {}
  sub bar {}
  package T4;
  sub meta {
    return bless {units => [qw(T4 T2)], package => 'T4'}, 'Im::Meta';
  }
  package T5;
  package T6;
}

subtest _diff_ars => sub {
	my @l = qw(a b c);
  my @r = qw(b c d);
	eq_or_diff(join(", ", (sort {$a cmp $b} _diff_ars(\@l, \@r)->elements)), "a, d");
};

subtest _methodref_to_string => sub {
	# You know, this would be the ideal place for a heredoc, if i could ever
	# remember the syntax for chaining a regexp replace onto it.
  my $exp = q(+-----+------+
| key | val  |
+-----+------+
| bar | baz  |
| bar | quux |
| foo | bar  |
| foo | baz  |
+-----+------+);
  eq_or_diff(_methodref_to_string({foo => ['bar','baz'],bar => ['baz','quux']}),$exp);
};

subtest _methods_to_merge => sub {
  my @exp = map quotemeta, (
    qq(Some units were unable to be merged. Here are the methods defined in multiple packages:\n+-----+-----+\n| key | val |\n+-----+-----+\n| foo | T1  |\n| foo | T3  |\n+-----+-----+),
    qq(Some units were unable to be merged. Here are the methods defined in multiple packages:\n+-----+-----+\n| key | val |\n+-----+-----+\n| bar | T2  |\n| bar | T3  |\n+-----+-----+),
    qq(Some units were unable to be merged. Here are the methods defined in multiple packages:\n+-----+-----+\n| key | val |\n+-----+-----+\n| bar | T2  |\n| bar | T3  |\n| foo | T1  |\n| foo | T3  |\n+-----+-----+),
  );
	throws_ok {
    _methods_to_merge(['T1','T3']);
  } qr/$exp[0]/;
	throws_ok {
    _methods_to_merge(['T2','T3']);
  } qr/$exp[1]/;
	throws_ok {
    _methods_to_merge(['T1','T2','T3']);
  } qr/$exp[2]/;
  eq_or_diff({_methods_to_merge(['T1','T2'])},{foo => 'T1', bar => 'T2'});
};

subtest _ensure_covered => sub {
  throws_ok {
    _ensure_covered({},[qw(a b c)],{});
  } qr/ provided: a, b, c/;
  # and this one shouldn't throw
  _ensure_covered({a => sub {}},[qw(a b)], {b => sub{}})
};

subtest _sanitise_reify_args => sub {
	eq_or_diff({_sanitise_reify_args(foo => 'bar', defs => {}, units => [])},{foo=>'bar'});
};
subtest _expand_units => sub {
  eq_or_diff([sort {$a cmp $b} _expand_units('T1')],[qw(T1 T2 T3 T4)]);
};

subtest declare_unit => sub {
	no warnings 'redefine';
  local *Im::Util::Meta::set_meta = sub {die(shift);};
  throws_ok {
    declare_unit('Bar');
  } qr/Bar/;
};

subtest finalise_unit => sub {
  {
		no warnings 'redefine';
		local *Im::Util::Meta::install_attrs = sub {die(shift);};
		local *Im::Util::Meta::install_new = sub {};
		local *Im::Util::Meta::install_does = sub {};
		throws_ok {
      finalise_unit('foo');
    } qr/foo/;
	}
  {
		no warnings 'redefine';
		local *Im::Util::Meta::install_attrs = sub {};
		local *Im::Util::Meta::install_new = sub {die(shift);};
		local *Im::Util::Meta::install_does = sub {};
		throws_ok {
      finalise_unit('foo');
    } qr/foo/;
	}
  {
		no warnings 'redefine';
		local *Im::Util::Meta::install_attrs = sub {};
		local *Im::Util::Meta::install_new = sub {};
		local *Im::Util::Meta::install_does = sub {die(shift);};
		throws_ok {
      finalise_unit('foo');
    } qr/foo/;
	}
  {
		no warnings 'redefine';
		local *Im::Util::Meta::install_attrs = sub {};
		local *Im::Util::Meta::install_new = sub {};
		local *Im::Util::Meta::install_does = sub {};
		finalise_unit('foo');
	}
};

use Data::Dumper 'Dumper';

subtest reify => sub {
	throws_ok {
    reify;
  } qr/Cannot reify zero units/;
	# warn Dumper(T1->meta);
	add_requires('T1','bar');
	# warn Dumper(T1->meta);
  finalise_unit('T1');
	eq_or_diff(T1->meta->{'requires'},['bar']);
	add_requires('T2','foo');
  finalise_unit('T2');
	eq_or_diff(T2->meta->{'requires'},['foo']);
  my $ret = reify(units => [qw(T1 T2)], defs => {foo => sub{}, bar => sub{}});
	eq_or_diff($ret->meta->{'units'},[qw(T1 T2 T3 T4)]);
	eq_or_diff($ret->meta->{'requires'},[qw(bar foo)]);
};

subtest clone => sub {
  no warnings qw(once redefine);
  local *Im::Util::Clone::clone_a = sub { die(@_); };
  throws_ok {
    clone("foo");
  } qr/foo/;
};

done_testing;
