package Im;

# ABSTRACT: Simple, Immutable Object Construction Toolkit

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

=head1 TERMINOLOGY

A C<Unit> is the basic unit of behaviour here. You can think of it as being like a role from Moo/Moose; You can also instantiate them as if they were classes. Think of them as roles on steroids.

=head1 SYNOPSIS

Here's a simple unit with a few types of accessors:

    package Foo;
    use Im;
    use Bar; # Assume it's a normal perl class package
    has foo => (required => 1);
    has bar => (predicate => 1);
    has baz => (builder => sub {Bar->new});
    1

Here are tests asserting what we've done to C<Foo>:

    use Test::More;
    use Foo;
    # We have all the expected attributes
    ok(Im->can('foo'));
    ok(Im->can('baz'));
    ok(Im->can('bar'));
    # We also generated a predicate for bar, default name has_bar
    ok(Im->can('has_bar'));
    # And we've installed the builder for baz into the symbol table
    # This means we can override it in subclasses easily!
    ok(Im->can('_build_baz'));
    done_testing;

Here we define an incomplete C<Unit> that requires the C<foo> and C<bar> methods to be present at object construction time:

    package Baz;
    use Im;
    requires qw(foo bar);
    1

These dependencies have to be solved at C<Unit> construction time.

We can compose such units into other C<Unit>s using C<with>

    package Quux;
    use Im;
    with 'Baz';
    1

There's even generic reification support, so you can provide a list of units that you wish to compose at the time you wish to construct a unit. Here's how we could reify a unit of all of C<Unit>s we've shown code for:

    use Foo;
    # Foo will automatically be added to the units list because
    # we're invoking through it.
    # Quux composes Baz, so it covers all three.
    Foo->new(foo => 1, units => ['Quux']);

There is an underlying C<reify> function in the L<Im::Util::Unit> module, but I urge you to avoid it where possible because the API underpinning this is highly unstable and while I'm averse to changing the public API, that isn't meant to be public :)

=head1 MOTIVATION

Also known as 'dear $deity, why?'. I've been yak shaving a lot recently. I wanted to build a HTML DOM library that was pure and immutable because statefulness is bad and my new templating library would be so complex to write if i permitted mutation that I had to find an alternative. Osfameron's C<MooX::Zippable> was fun for a while and I had good fun hacking on it, but ultimately the problem of state was still there and we were hiding away from it. Apparently immutable objects were still an unscratched itch.

Less than a week later, here we are.

=head1 METHODS

=head2 import

Yes, we do some import magic. It creates a metaobject for your class so everything just works. Suppress it by passing C<-noexport> as follows:

    use Im '-noexport';

Beware that this means that if you never call one of C<has>, C<requires> or C<with>, the metaobject will not be created.

=head1 EXPORTS

=head2 has

Signature: has ($name, %kwargs)

kwargs has the following valid keys as of current writing: C<predicate>, C<builder>, C<required>

If provided, C<required> makes providing an attribute mandatory to construct the C<Unit> instance. We default to optional.

If provided, C<predicate> is the name of a predicate method to generate that tests the existence of the attribute on the unit instance. Providing '1' defaults it to C<has_$attrname>.

If provided, C<builder> is a subref that will be used to create the initial value of the method. It will also be installed into the generated unit under C<_build_$attrname> so that if you wish to override it in another unit, this will be easy to do.

=head2 requires

Signature: requires (@names)

Takes a list of method names to require at unit instantiation time. Strings.

=head2 with

Takes a list of unit names to compose as unit instantiation time. Strings.

=head1 PLANS

=over 4

=item It would bee quite lovely to get C<Data::Lock> support going so we can be properly immutable (well, except to determined fiddlers). I suspect this would help catch a few logic bugs

=item I'd really like to come up with a compelling way of dealing with types. I don't like Moose's or Moo's.

=item Coercions would be nice as well

=item Build some better tests. Right now we don't test BUILD at all (hence it's undocumented), the special blocks stuff hasn't been tested properly and init_arg is broken (also: undocumented).

=back
