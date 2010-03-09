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

with 'Dist::Zilla::Role::AfterRelease';


# -- attributes

has tag_format => ( ro, isa=>Str, default => 'v%v' );
has tag_message=> ( ro, isa=>Str );


# -- role implementation

sub after_release {
    my $self = shift;
    my $git  = Git::Wrapper->new('.');

    # Make an annotated tag if tag_message, lightweight tag otherwise:
    my @opts;
    if (defined $self->tag_message) {
      push @opts, -m => _format_tag($self->tag_message, $self->zilla);
    }

    # create a tag with the new version
    my $tag = _format_tag($self->tag_format, $self->zilla);
    $git->tag( @opts, $tag );
    $self->log("Tagged $tag");
}

1;
__END__

=for Pod::Coverage::TrustPod
    after_release


=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::Tag]

=head1 DESCRIPTION

Once the release is done, this plugin will record this fact in git by
creating a tag.  If you set the C<tag_message> attribute, it makes an
annotated tag.  Otherwise, it makes a lightweight tag.

The plugin accepts the following options:

=over 4

=item * tag_format - format of the tag to apply. Defaults to C<v%v>.

=item * tag_message - format of the commit message.
Defaults to no message (creating a lightweight tag).

=back

You can use the following codes in both options:

=over 4

=item C<%{dd-MMM-yyyy}d>

The current date.  You can use any CLDR format supported by
L<DateTime>.  A bare C<%d> means C<%{dd-MMM-yyyy}d>.

=item C<%n>

a newline

=item C<%N>

the distribution name

=item C<%v>

the distribution version

=back
