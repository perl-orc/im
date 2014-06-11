package Im::Util::Meta;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
  get_meta has_meta set_meta create_meta
  add_attribute add_requires add_unit
  install_attr install_attrs install_sub
);

use Im::Util qw(mutate);
use Package::Anonish::PP;
use Safe::Isa;

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

sub create_meta {
  my (%attrs) = @_;
  my %defaults = (type => 'unit');
	$defaults{units} = [$defaults{package}||()];
  return bless { %defaults, %attrs }, 'Im::Meta';
}

sub install_sub {
  my ($meta, $name, $code) = @_;
  my $pa = Package::Anonish::PP->new($meta->{'package'});
  $pa->add_method($name, $code);
}

sub install_attr {
  my ($meta, $name, %conf) = @_;
  $conf{init_arg} = $name
    unless exists $conf{init_arg};
  if ($conf{init_arg}) {
    if ($conf{builder}) {
      if (exists $conf{lazy} && $conf{lazy}) {
        install_sub($meta, $name, sub {
          my $self = shift;
          install_sub($meta, $name, sub { shift->{$name} });
          mutate($self, sub {
            $_->{$name} = $conf{builder}->($self);
          });
          $self->{$name};
        });
      } else {
        install_sub($meta, $name, sub { $conf{builder}->($meta->{'package'}) });
      }
    } else {
      croak("lazy attributes must have a supplied 'builder' (CODE ref)")
        if ($conf{lazy});
      install_sub ($meta, $name, sub { shift->{$name} });
    }
  }
  if ($conf{predicate}) {
    $conf{predicate} = $name
      if $conf{predicate} eq '1';
    install_sub($meta, $conf{predicate}, sub { defined shift->$name });
  }
}

sub install_attrs {
  my ($meta) = @_;
  foreach my $k (keys %{$meta->{'attrs'}}) {
    install_attr($meta, $k, %{$meta->{'attrs'}->{$k}});
  }
}

sub add_attribute {
  my ($meta, $name, %spec) = @_;
  my $new = clone($meta);
  my %attrs = %{$meta->{'attrs'} || {}};
  $attrs{$name} = {%spec};
  $new = mutate($new, sub {
    $_->{'attrs'} = {%attrs};
  });
  set_meta($meta->{'package'},$new);
}

sub add_requires {
  my ($meta, $name, %spec) = @_;
  my $new = clone($meta);
  my @requires = @{$meta->{'requires'} || []};
  push @requires, $name
    unless grep $_ eq $name, @requires;
  $new = mutate($new, sub {
    $_->{'requires'} = [@requires];
  });
  set_meta($meta->{'package'},$new);
}

sub add_unit {
  my ($meta, @units) = @_;
  my $new = clone($meta);
  my @munits = @{$meta->{'units'} || []};
  foreach my $u (@units) {
    push @munits, $u
      unless (grep $_ eq $u, @munits);
  }
  $new = mutate($new, sub {
    $_->{'units'} = [@munits];
  });
  set_meta($meta->{'package'}, $new);
}

1
__END__
