use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::Tag;
# ABSTRACT: tag the new version

use Git::Wrapper;
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Str };
use String::Formatter method_stringf => {
  -as => '_format_tag',
  codes => {
    d => sub { require DateTime;
               DateTime->now->format_cldr($_[1] || 'dd-MMM-yyyy') },
    n => sub { "\n" },
    N => sub { $_[0]->name },
    v => sub { $_[0]->version },
  },
};

with 'Dist::Zilla::Role::BeforeRelease';
with 'Dist::Zilla::Role::AfterRelease';


# -- attributes

has tag_format  => ( ro, isa=>Str, default => 'v%v' );
has tag_message => ( ro, isa=>Str, default => 'v%v' );
has branch => ( ro, isa=>Str );

# -- role implementation

sub before_release {
    my $self = shift;
    my $git  = Git::Wrapper->new('.');

    # Make sure a tag with the new version doesn't exist yet:
    my $tag = _format_tag($self->tag_format, $self->zilla);
    $self->log_fatal("tag $tag already exists")
        if $git->tag('-l', $tag );
}

sub after_release {
    my $self = shift;
    my $git  = Git::Wrapper->new('.');

    # Make an annotated tag if tag_message, lightweight tag otherwise:
    my @opts = $self->tag_message
        ? ( '-m' => _format_tag($self->tag_message, $self->zilla) )
        : ();

    # create a tag with the new version
    my $tag = _format_tag($self->tag_format, $self->zilla);
    $git->tag( @opts, $tag, ( $self->branch ) x !!$self->branch );
    $self->log("Tagged $tag");
}

1;
__END__

=for Pod::Coverage
    after_release
    before_release


=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::Tag]
    tag_format  = v%v       ; this is the default
    tag_message = v%v       ; this is the default

=head1 DESCRIPTION

Once the release is done, this plugin will record this fact in git by
creating a tag.  By default, it makes an annotated tag.  You can set
the C<tag_message> attribute to change the message.  If you set
C<tag_message> to the empty string, it makes a lightweight tag.

It also checks before the release to ensure the tag to be created
doesn't already exist.  (You would have to manually delete the
existing tag before you could release the same version again, but that
is almost never a good idea.)


=head2 Plugin options

The plugin accepts the following options:

=over 4

=item * tag_format - format of the tag to apply. Defaults to C<v%v>, see
C<Formatting options> below.

=item * tag_message - format of the commit message. Defaults to C<v%v>,
see C<Formatting options> below. Use C<tag_message = > to create a
lightweight tag.

=item * branch - which branch to tag. Defaults to current branch.

=back


=head2 Formatting options

Some plugin options allow you to customize the tag content. You can use
the following codes at your convenience:

=over 4

=item C<%{dd-MMM-yyyy}d>

The current date.  You can use any CLDR format supported by
L<DateTime>. A bare C<%d> means C<%{dd-MMM-yyyy}d>.

=item C<%n>

A newline

=item C<%N>

The distribution name

=item C<%v>

The distribution version

=back
