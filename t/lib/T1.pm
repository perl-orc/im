package T1;

use Im;

requires 'foo';
with 'T2';

has foo => (required => 1);
has bar => (builder => sub { 42 });
has baz => (
  builder => sub { 43 },
  predicate => undef,
);

_finalise_unit;

1
__END__
