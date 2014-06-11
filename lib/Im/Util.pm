package Im::Util;

use Carp qw(carp croak);
use Data::Lock qw(dlock);
use Im::Util::Clone;
use Im::Util::Meta;
use Im::Util::Unit;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(clone);

sub clone { clone_a(shift); }

1
__END__
