use Test::Most;
use lib 't/lib';

use strict;
use warnings;
use T1;
use T2;

eq_or_diff(
  {%{T1->meta}},
  {package => 'T1', requires => ['foo'], type => 'unit', units => [qw(T1 T2)], attrs => {foo => {required => 1}, bar => {builder => sub {}}, baz => {builder => sub{}, predicate => undef}}});

my $t1 = T1->new(  foo => 1, bar => 2);
# eq_or_diff({%$t1},{foo => 1, bar => 2});
done_testing;
