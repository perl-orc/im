package Im;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(has _finalise_class);

use Im::Util qw(declare_unit has_meta add_requires add_with install_attr finalise_unit);

sub has {
  my ($name, %conf) = @_;
  my $self = [caller]->[0];
  declare_unit($self)
    unless has_meta($self);
  my $meta = get_meta($self);
  install_attr($meta, $name, %conf);
}

sub requires {
  my (@names) = @_;
	my $self = [caller]->[0];
	add_requires(get_meta($self), @names);
}

sub with {
  my (@names) = @_;
  my $self = [caller]->[0];
	add_with(get_meta($self), @names);
}

# Ick. How do we make this go away without XS?
sub _finalise_class {
  my $self = [caller]->[0];
  finalise_unit($self);
}

1
__END__
