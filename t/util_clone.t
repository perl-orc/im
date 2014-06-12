use Test::Most;

use Im::Util::Clone qw(clone_a);

my $a = 'a';
my $ret = clone_a($a);
eq_or_diff($a,$ret);
$ret = 'b';
eq_or_diff($a,'a');

$a = [qw(a b c d)];
$ret = clone_a($a);
eq_or_diff($a,$ret);
$ret->[0] = 'b';
eq_or_diff($a,[qw(a b c d)]);

$a = {qw(a b c d)};
$ret = clone_a($a);
eq_or_diff($a,$ret);
$ret->{'a'} = 'a';
eq_or_diff($a,{qw(a b c d)});

{
  package T2;
  sub new {
    my ($self, %kwargs) = @_;
    bless {%kwargs}, $self;
  }
  sub foo { shift->{'foo'} }
  sub bar { shift->{'bar'} }
}

my $t2 = T2->new(foo => 'foo', bar => 'foo');
eq_or_diff($t2->foo, 'foo');
eq_or_diff($t2->bar, 'foo');

my $t3 = clone_a($t2);
eq_or_diff($t3->foo,'foo');
eq_or_diff($t3->bar,'foo');
$t3->{'foo'} = 'baz';
eq_or_diff($t2->foo,'foo');

done_testing;
