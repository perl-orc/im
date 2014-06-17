package Im::Util::Unit;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
  declare_unit
  reify
  clone
  _diff_ars _methodref_to_string _methods_to_merge
	_ensure_covered _sanitise_reify_args _expand_units
);

use Carp qw(carp croak);
use Data::Lock qw(dlock);
use Im::Util::Clone;
use Im::Util::Meta qw( get_meta has_meta set_meta create_meta add_requires add_with install_attr install_new install_does _pa_for mutate);
use Package::Anonish::PP;
use Safe::Isa;
use Set::Scalar;

sub declare_unit {
  my ($package) = @_;
  # Don't fucking ask.
  Im::Util::Meta::set_meta($package);
  install_new($package);
  install_does($package);
}

sub _diff_ars {
  my ($left, $right) = @_;
  my ($l,$r) = (Set::Scalar->new, Set::Scalar->new);
  $l->insert(@$left);
  $r->insert(@$right);
  return $l->symmetric_difference($r);
}

sub _methodref_to_string {
  my ($methodref) = @_;
  my $key_len = pop (@{[sort {$a <=> $b} map length($_), keys $methodref]});
  my $val_len = pop (@{[sort {$a <=> $b} map length($_), map @{$_}, values $methodref]});
  $key_len = 3 if $key_len < 3;
  $val_len = 3 if $val_len < 3;
  my $border = sprintf('+-%s-+-%s-+', '-' x $key_len, '-' x $val_len);
  my @ret = ($border);
  push @ret, sprintf("| %-${key_len}s | %-${val_len}s |", 'key', 'val');
  push @ret, $border;
  foreach my $k (sort keys %$methodref) {
    foreach my $v (sort {$a cmp $b} @{$methodref->{$k}}) {
      push @ret, sprintf("| %-${key_len}s | %-${val_len}s |", $k, $v);
    }
  }
  push @ret, $border;
  return join("\n", map ((' ' x 4) . $_), @ret)
}

sub _methods_to_merge {
	my ($units, $defs) = @_;
	my @units = _uniq(@$units);
  my @requires = _uniq(map @{get_meta($_)->{'requires'}||[]}, @units);
	# Keep two records:
	# - methods and package they were first found in. name => "packagename"
  my %methods;
  # - clashing methods only. name => ["packagename"]
  my %clashing;
  foreach my $u (@units) {
    my $pa = _pa_for($u);
    foreach my $m ($pa->methods) {
			# Taking the piss much?
			next if $m =~ /^(?:meta|new|does|requires|import|with|has|BEGIN|CHECK|INIT|END|UNITCHECK|AUTOLOAD|__ANON__)$/;
			$clashing{$m} = ($clashing{$m} ? [(@{$clashing{$m}||[]}, $u)] : [$methods{$m}, $u])
				if defined $methods{$m};
      $methods{$m} = $u;
    }
  }
	foreach my $c (keys %clashing) {
		if (defined $defs->{$c}) {
			$methods{$c} = $defs->{$c};
			delete $clashing{$c};
		}
	}
	if (%clashing) {
		croak("Some units were unable to be merged. Here are the methods defined in multiple packages:\n" . _methodref_to_string({%clashing}));
	}
	foreach my $d (keys %$defs) {
		if (!defined $methods{$d}) {
			$methods{$d} = $defs->{$d};
		}
	}
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

sub _expand_units {
  my @units = @_;
	my @with = map @{get_meta($_)->{'units'}}, @units;
	foreach my $w (@with) {
		unless (grep $w eq $_, @units) {
			my %dedupe;
			@dedupe{@units,@with} = ();
			return _expand_units(sort keys %dedupe);
		}
	}
	return @units;
}

sub _uniq {
  my %t; @t{@_} = (); return sort keys %t;
}

# So much to do to this
# We could start with:
# - support some sort of logic for preferences. like optional reify in order, or here's an ordering, or these packages are deciders in the order provided, or these packagers are deciders but a clash is an error.
# Or maybe we just need some helpers to construct the list of defs?

sub reify {
  my %args = @_;
  my @units = _uniq(@{$args{units}||[]});
  croak("Cannot reify zero units")
    unless @units;
	my @expanded = _expand_units(@units);
  my %to_merge = _methods_to_merge([@expanded],$args{defs}||{});
  my @requires = _uniq(map @{get_meta($_)->{'requires'}||[]}, @expanded);
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
		if($to_merge{$k} && !ref($to_merge{$k}) && $to_merge{$k}->can($k)) {
			$pa->add_method($k, $to_merge{$k}->can($k));
		} elsif (ref($to_merge{$k}) eq 'CODE') {
			$pa->add_method($k, $to_merge{$k});
		} else {
			croak("Don't know what to do with '$k'. This probably means you've forgotten to define or import a subroutine called '$k'.");
		}
  }
  my $blessed = $pa->bless({});
	my %sanitary = _sanitise_reify_args(%args);
	if ($blessed->can('BUILD')) {
		%sanitary = $blessed->BUILD(%sanitary);
	}
	mutate($blessed, sub {
		foreach my $k (keys %sanitary) {
      $_->{$k} = $sanitary{$k};
		}
  });
	$blessed;
}

sub clone {
  # Don't fucking ask.
	Im::Util::Clone::clone_a(shift);
}

1
__END__
