package Im::Util::Unit;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
  create_meta
  declare_unit finalise_unit
  reify
  clone
  mutate
);

use Data::Lock qw(dlock);
use Im::Util::Meta qw( get_meta has_meta set_meta create_meta add_attribute add_requires add_with install_attr install_new install_does);
use Package::Anonish::PP;
use Safe::Isa;
use Set::Scalar;

sub _pa_for {
  return Package::Anonish::PP->new(@_);
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

sub _methodref_to_string {
  my ($methodref,$indent) = @_;
  $indent //= 4;
  my $key_len = pop (@{[sort {$a <=> $b} map length($_), keys $methodref]});
  my $val_len = pop (@{[sort {$a <=> $b} map length($_), values $methodref]});
  $key_len = 3 if $key_len < 3;
  $val_len = 3 if $val_len < 3;
  my $border = sprintf('+-%s-+-%s-+', '-' x $key_len, '-' x $val_len);
  my @ret = ($border);
  push @ret, sprintf("| key | val |");
  foreach my $k (sort keys %$methodref) {
    foreach my $v (sort {$a cmp $b} @{$methodref->{$k}}) {
      push @ret, sprintf("| %${key_len}s | %${val_len}s |", $k, $v);
    }
  }
  push @ret, $border;
  return join "\n", map (' ' x $indent) . $_, @ret;
}

sub _methods_to_merge {
	my @units = @_;
  my @requires = (map @{$_->{'requires'}||[]}, @units);
	# Keep two records:
	# - methods and package they were first found in. name => "packagename"
  my %methods;
  # - clashing methods only. name => ["packagename"]
  my %clashing;
  foreach my $u (@units) {
    my $pa = _pa_for($u);
    foreach my $m ($pa->methods) {
      $clashing{$m} = [(@{$clashing{$m}||[]}, $u)]
        if defined $methods{$m};
      $methods{$m} = $u;
    }
  }
  croak("Some units were unable to be merged. Here are the methods defined in multiple packages:\n" . _methodref_to_string({%clashing}))
    if (%clashing);
  return %methods;
}

sub _ensure_covered {
  my ($methods, $required, $defs) = @_;
  my @failing;
  foreach my $r (@$required) {
    unless (defined($methods->{$r}) || defined($defs->{$r})) {
      push @failing, $r;
    }
  }
  croak("The following required methods are not provided: " . join(", ", @failing))
    if @failing;
}

sub _sanitise_reify_args {
  my %args = @_;
  delete $args{defs};
  delete $args{units};
  %args;
}

# So much to do to this
# We could start with:
# - support some sort of logic for preferences. like optional reify in order, or here's an ordering, or these packages are deciders in the order provided, or these packagers are deciders but a clash is an error.
# Or maybe we just need some helpers to construct the list of defs?

sub _expand_units {
  my @units = @_;
	my @with = map @{get_meta($_)->{'with'}}, @units;
	foreach my $w (@with) {
		unless (grep $w eq $_, @units) {
			my %dedupe;
			@dedupe{@units,@with} = ();
			return _expand_units(sort keys %dedupe);
		}
	}
	return @units;
}

sub reify {
  my %args = @_;
  my @units = @{$args{units}||[]};
  croak("Cannot reify zero units")
    unless @units;
	my @expanded = _expand_units(@units);
  my %to_merge = _methods_to_merge(@expanded);
  my @requires = map @{$_->{'requires'}}, @expanded;
  _ensure_covered({%to_merge},[@requires],{%{$args{defs}||{}}});
  my $pa = _pa_for;
	my $new = create_meta(
    package => $pa->{'package'},
    requires => [@requires],
    units => [@expanded],
  );
  set_meta($pa->{'package'}, $new);
	# Potential optimisation: can we just precompile the class if it's a plain invocation with no extra roles? Watch out for compilation at reify time
  foreach my $k (keys %to_merge) {
    $pa->add_method($k, $to_merge{$k}->can($k));
  }
  return $pa->bless({_sanitise_reify_args($args{defs})});
}

sub clone {
  my ($ref) = @_;
  clone_a($ref);
}

sub mutate {
  my ($ref, $code) = @_;
  # Eventually, this will deal with locking and unlocking
  for ($ref) {
    $code->($ref);
    return $_;
  }
}

sub finalise_unit {
  my ($meta) = @_;
  install_attrs($meta);
  install_new($meta);
  install_does($meta);
}

1
__END__
