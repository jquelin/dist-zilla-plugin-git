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
    v => sub { $_[0]->version },
  },
};

with 'Dist::Zilla::Role::AfterRelease';


# -- attributes

has tag_format => ( ro, isa=>Str, default => 'v%v' );


# -- role implementation

sub after_release {
    my $self = shift;
    my $git  = Git::Wrapper->new('.');

    # create a tag with the new version
    my $tag = _format_tag($self->tag_format, $self->zilla);
    $git->tag( $tag );
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
creating a tag.

The plugin accepts the following options:

=over 4

=item * tag_format - format of the tag to apply. C<%v> will be
replaced by the dist version. Defaults to C<v%v>.


=back
