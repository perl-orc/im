package Im;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(has requires with);

use Im::Util::Meta qw(has_meta add_requires add_with add_attr);
use Im::Util::Unit qw(declare_unit);

sub import {
	if (grep /^-noexport$/, @_) {
		@_ = (grep /^-noexport$/, @_);
	} else {
    my $self = [caller]->[0];
    declare_unit($self)
      unless has_meta($self);
	}
  __PACKAGE__->export_to_level(1,@_);
}

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

1
__END__
