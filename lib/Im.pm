package Im;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(has requires with _finalise_unit);

use Im::Util::Meta qw(has_meta add_requires add_with add_attr);
use Im::Util::Unit qw(declare_unit finalise_unit);

sub has {
  my ($name, %conf) = @_;
  my $self = [caller]->[0];
  declare_unit($self)
    unless has_meta($self);
  add_attr($self, $name, %conf);
}

sub requires {
  my (@names) = @_;
  my $self = [caller]->[0];
  declare_unit($self)
    unless has_meta($self);
  add_requires($self, @names);
}

sub with {
  my (@names) = @_;
  my $self = [caller]->[0];
  declare_unit($self)
    unless has_meta($self);
  add_with($self, @names);
}

# Ick. How do we make this go away without XS?
sub _finalise_unit {
  my $self = [caller]->[0];
  declare_unit($self)
    unless has_meta($self);
  finalise_unit($self);
}

1
__END__
