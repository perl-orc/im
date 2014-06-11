package Im;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(has _finalise_class);

use Im::Util qw();

sub has {
  my ($name, %conf) = @_;
  my $self = [caller]->[0];
  declare_unit($self);
    unless has_meta($self);
  my $meta = get_meta($self);
  install_attr($meta, $name, %conf);
}

# Ick. How do we make this go away without XS?
sub _finalise_class {
  my $self = [caller]->[0];
  finalise_unit($self);
}

1
__END__
