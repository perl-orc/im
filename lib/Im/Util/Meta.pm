package Im::Util::Meta;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
  get_meta has_meta set_meta create_meta
  add_attr add_requires add_with
  install_attr install_attrs install_sub mutate
  install_new install_does _attr_config _pa_for
);

use Carp qw(carp croak);
use Package::Anonish::PP;
use Safe::Isa;
use Scalar::Util qw(blessed);

sub _pa_for {
  return Package::Anonish::PP->new(@_);
}

sub get_meta {
  my $thing = shift;
  return $thing if $thing->$_isa('Im::Meta');
  return eval { $thing->meta } || undef;
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

sub create_meta {
  my (%attrs) = @_;
  my %defaults = (type => 'unit');
  $defaults{units} = [$attrs{package}||()];
  return bless { %defaults, %attrs }, 'Im::Meta';
}

sub install_sub {
  my ($meta, $name, $code) = @_;
  $meta = get_meta($meta);
  my $pa = Package::Anonish::PP->new($meta->{'package'});
  return $pa->add_method($name, $code);
}

sub _attr_config {
  my ($name, %conf) = @_;
  $conf{init_arg} = $name
    unless exists $conf{init_arg};
  if (exists $conf{required} && !$conf{required}) {
    $conf{predicate} = 1 unless exists $conf{predicate};
  }
  $conf{predicate} = "has_$name"
    if $conf{predicate}||'' eq '1';
  croak("Can't have a predicate and be required")
    if $conf{predicate} && $conf{required};
  croak("builder must be a CODE ref")
    if $conf{builder} && ref($conf{builder}) ne 'CODE';
  return %conf;
}

sub install_attr {
  my ($meta, $name, %conf) = @_;
  $meta = get_meta($meta);
  %conf = _attr_config($name, %conf);
  if ($conf{builder}) {
    # implies lazy
    install_sub($meta, "_build_$name", $conf{builder});
    install_sub($meta, $name, sub {
      my $self = shift;
      # Mutate before the next install_sub, or the tests won't pass
      # It's just easier, trust me.
      mutate($self, sub {
        $_->{$name} = $self->can("_build_$name")->($self);
      });
      install_sub($meta, $name, sub { shift->{$name} });
      $self->{$name};
    });
  } else {
    install_sub ($meta, $name, sub { shift->{$name} });
  }
  install_sub($meta, $conf{predicate}, sub { defined shift->$name })
    if $conf{predicate};
}

sub install_attrs {
  my ($meta) = @_;
  $meta = get_meta($meta);
  foreach my $k (keys %{$meta->{'attrs'}}) {
    install_attr($meta, $k, %{$meta->{'attrs'}->{$k}});
  }
}

sub add_attr {
  my ($meta, $name, %spec) = @_;
  $meta = get_meta($meta);
  my %attrs = %{$meta->{'attrs'} || {}};
  $attrs{$name} = {%spec};
  mutate($meta, sub {
    $_->{'attrs'} = {%attrs};
  });
  set_meta($meta->{'package'}, $meta);
}

sub _uniq {
  my %t;
	@t{@_} = ();
	return keys %t;
}

sub add_requires {
  my ($meta, @names) = @_;
  $meta = get_meta($meta);
  my @requires = _uniq(@{$meta->{'requires'} || []}, @names);
  mutate($meta, sub {
    $_->{'requires'} = [@requires];
  });
  set_meta($meta->{'package'}, $meta);
}

sub add_with {
  my ($meta, @units) = @_;
  $meta = get_meta($meta);
  my @with = @{ $meta->{'units'} || [] };
  foreach my $u (@units) {
    push @with, $u
      unless grep /^$u$/, @with;
  }
  mutate($meta, sub {
    $_->{'units'} = [@with];
  });
  set_meta($meta->{'package'}, $meta);
}

sub install_new {
  my ($meta) = @_;
  $meta = get_meta($meta);
  my %attrs = %{$meta->{'attrs'}||{}};
  my @required;
  foreach my $k (keys %attrs) {
    if ($attrs{$k}->{'required'}) {
      push @required, $k;
    }
  }
  my $new = sub {
    my ($class, %args) = @_;
    my @missing;
    foreach my $r (@required) {
      push @missing, $r
        unless defined $args{$r};
    }
    croak("The following required attributes are missing: " . join(", ", @missing))
      if @missing;
		$args{units} = [ $meta->{'package'} ]
			if !$args{units};
		unless (grep ($_ eq $meta->{'package'}), @{$args{units}}) {
			unshift @{$args{units}}, $meta->{'package'};
		}
    return Im::Util::Unit::reify(%args);
  };
  install_sub($meta->{'package'},'new', $new);
}

sub install_does {
  my $meta = shift;
  $meta = get_meta($meta);
  my $does = sub {
    my ($self, @does) = @_;
    my %lookup;
    @lookup{@{get_meta($self)->{'units'}}} = ();
    foreach my $d (@does) {
      return 0
        unless exists $lookup{$d};
    }
    1
  };
  install_sub($meta->{'package'},'does', $does);
}

sub mutate {
  my ($ref, $code) = @_;
  # Eventually, this will deal with locking and unlocking
  local $_ = $ref;
   $code->($ref);
	return $ref;
}

# Don't fucking ask.
require Im::Util::Unit;
Im::Util::Unit->import('reify');

1
__END__
