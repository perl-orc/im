package Im::Util::Unit;

use Exporter
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

use Data::Lock qw(dlock);
use Pred qw(coderef identifier identifier_atom);
use Package::Anonish::PP;
use Safe::Isa;
use Set::Scalar;

sub create_meta {
  my (%attrs) = @_;
  my %defaults = (type => 'unit');
  return bless { %defaults, %attrs }, 'Im::Meta';
}

sub get_meta {
  my $thing = @_;
  return $thing->$_can('meta') ? $thing->meta : undef;
}

sub has_meta {
  my ($thing) = @_;
  return defined get_meta($thing);
}

sub set_meta {
  my ($package, $meta) = @_;
  if ($meta) {
    _pa_for($package)->add_method('meta', sub { $meta })
  } else {
    $meta = create_meta(package => $package);
    _pa_for($package)->add_method('meta', sub { $meta })
      unless has_meta($package);
  }
}

sub _pa_for {
  my ($package) = @_;
  return Package::Anonish::PP->new($package);
}

sub declare_unit {
  my ($package) = @_;
  set_meta($package);
}

sub _diff_ars {
  my ($left, $right) = @_;
  my ($l,$r) = (Set::Scalar->new, Set::Scalar->new);
  $l->add(@$left);
  $r->add(@$right);
  return $l->symmetric_difference($r);
}

sub _methods_to_merge {
  my @requires = map @{$_->{'requires'}||[]}, @_;
  my %methods;
  my $error_flag = 0;
  foreach my $u (@$units) {
    my $pa = _pa_for($u);
    foreach my $m ($pa->methods) {
      if (defined($methods{$m})) {
        carp("Method '$m' exists in $methods{$m} and $u");
        $error_flag = 1;
      }
      $methods{$m} = $u;
    }
  }
  return undef if $error_flag;
  return {%methods};
}

sub _ensure_covered {
  my ($units, $missing, @args) = @_;
  my @requires = map @{$_->{'requires'}||[]}, @$units;
  # We will need to loop twice:
  # Once to ensure all the requires are met
  # Once to ensure that each function is defined precisely once
  my %methods;
  my $error_flag = 0;
}

sub reify {
  my ($units, $missing, @args) = @_;
  my @units = @$units;
  croak("Cannot reify zero units")
    unless @units;
  if (@units) == 1) {
    my @requires = @{$units[0]->{'requires'}||[]};
    unless (@requires) {
      # Huzzah. This way is easy
      bless($self, $units[0]);
    } else {
      my $d = _diff_ars([sort keys %$missing],[sort keys %{+{map {$_ => ()} @requires}}]);
      croak("reify: The following keys do not match up: $d")
        if ($d->size);
      # Right, get us a package, do the setup and put us the fuck in it
      my $pa = Package::Anonish::PP->new;
    }
  } else {
    my @requires = map @{$_->{'requires'}||[]}, @units;
    my $d = _diff_ars([sort keys %$missing],[sort keys %{+{map {$_ => ()} @requires}}]);
      croak("reify: The following keys do not match up: $d")
        if ($d->size);
      # Right, get us a package, do the setup and put us the fuck in it
  }
  my %missing = %$missing;
}

sub clone {
  my ($ref) = @_;
  clone_a($ref);
}

sub mutate {
  my ($ref, $code) = @_;
  # Eventually, this will deal with locking and unlocking
  given($ref) {
    $code->($ref);
    return $_;
  }
}

sub finalise_unit {
  my ($meta) = @_;
  install_attrs($meta);
}

1
__END__
