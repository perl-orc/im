package Im::Util::Clone;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(clone_a);
use Scalar::Util qw(blessed);
use Safe::Isa;

sub arrayref {ref(shift) eq 'ARRAY' or undef;}
sub coderef {ref(shift) eq 'CODE' or undef};
sub hashref {ref(shift) eq 'HASH' or undef;}
sub simple {!ref(shift) or undef;}

sub clone_simple { shift; }

sub clone_arrayref {
  my $ar = shift;
  my @new = map clone_a($_), @$ar;
  return [@new];
}

sub clone_hashref {
  my $hr = shift;
  my %new = map {
    $_ => clone_a($hr->{$_})
  } (keys %$hr);
  return {%new};
}

sub clone_attr {
  my ($obj, $attr) = @_;
  croak("Undefined attr!") unless $attr;
  return ($attr => clone_a($obj->$attr));
}

sub clone_blessed {
  my $c = shift;
  my $new = clone_a({%$c});
  bless $new, blessed($c);
}

sub clone_a {
  my ($a) = @_;
  return clone_simple($a)   if simple($a);
  return clone_arrayref($a) if arrayref($a);
  return clone_hashref($a)  if hashref($a);
  return clone_blessed($a)  if blessed($a);
  croak("clone_a: don't know what to do with '$a'");
}

1
__END__
