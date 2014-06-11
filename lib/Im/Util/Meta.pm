package Im::Util::Meta;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(install_attr);

use Im::Util qw(mutate);
use Package::Anonish::PP;
use Sub::Defer;

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
  my ($meta, $name, %spec) = 
  my $new = clone($meta);
  my %attrs = %{$meta->{'attrs'} || {}};
  $attrs{$name} = {%spec};
  $new = mutate($new, sub {
    $_->{'attrs'} = {%attrs};
  });
  set_meta($meta->{'package'},$new);
}

sub add_requires {
  my ($meta, $name, %spec) = 
  my $new = clone($meta);
  my @requires = @{$meta->{'requires'} || []};
  push @requires, $name
    unless grep $_ eq $name, @requires;
  $new = mutate($new, sub {
    $_->{'requires'} = [@requires];
  });
  set_meta($meta->{'package'},$new);
}

1
__END__
