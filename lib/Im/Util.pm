package Im::Util;

use strict;
use warnings;

use Carp qw(carp croak);
use Data::Lock qw(dlock);
use Im::Util::Clone;
use Im::Util::Meta qw(get_meta has_meta set_meta add_attribute add_requires add_unit install_attr);
use Im::Util::Unit qw(declare_unit finalise_unit);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(clone declare_unit finalise_unit has_meta install_attr);

sub clone { clone_a(shift); }

1
__END__
