#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::Tag;
{
  $Dist::Zilla::Plugin::Git::Tag::VERSION = '1.121770';
}
# ABSTRACT: tag the new version

use Git::Wrapper;
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Str };
use String::Formatter method_stringf => {
  -as => '_format_tag',
  codes => {
    d => sub { require DateTime;
               DateTime->now(time_zone => $_[0]->time_zone)
                       ->format_cldr($_[1] || 'dd-MMM-yyyy') },
    n => sub { "\n" },
    N => sub { $_[0]->zilla->name },
    t => sub { $_[0]->zilla->is_trial
                 ? (defined $_[1] ? $_[1] : '-TRIAL') : '' },
    v => sub { $_[0]->zilla->version },
  },
};

with 'Dist::Zilla::Role::BeforeRelease';
with 'Dist::Zilla::Role::AfterRelease';
with 'Dist::Zilla::Role::Git::Repo';


# -- attributes

has tag_format  => ( ro, isa=>Str, default => 'v%v' );
has tag_message => ( ro, isa=>Str, default => 'v%v' );
has time_zone   => ( ro, isa=>Str, default => 'local' );
has branch => ( ro, isa=>Str, predicate=>'has_branch' );
has signed => ( ro, isa=>'Bool', default=>0 );


has tag => ( ro, isa => Str, lazy_build => 1, );

sub _build_tag
{
    my $self = shift;
    return _format_tag($self->tag_format, $self);
}


# -- role implementation

sub before_release {
    my $self = shift;

    my $git  = Git::Wrapper->new( $self->repo_root );

    # Make sure a tag with the new version doesn't exist yet:
    my $tag = $self->tag;
    $self->log_fatal("tag $tag already exists")
        if $git->tag('-l', $tag );
}

sub after_release {
    my $self = shift;
    my $git  = Git::Wrapper->new( $self->repo_root );

    my @opts;
    push @opts, ( '-m' => _format_tag($self->tag_message, $self) )
        if $self->tag_message; # Make an annotated tag if tag_message, lightweight tag otherwise:
    push @opts, '-s'
        if $self->signed; # make a GPG-signed tag

    my @branch = $self->has_branch ? ( $self->branch ) : ();

    # create a tag with the new version
    my $tag = $self->tag;
    $git->tag( @opts, $tag, @branch );
    $self->log("Tagged $tag");
}

1;


=pod

=head1 NAME

Dist::Zilla::Plugin::Git::Tag - tag the new version

=head1 VERSION

version 1.121770

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

=item * tag_message - format of the tag annotation. Defaults to C<v%v>,
see C<Formatting options> below. Use C<tag_message = > to create a
lightweight tag.

=item * time_zone - the time zone to use with C<%d>.  Can be any
time zone name accepted by DateTime.  Defaults to C<local>.

=item * branch - which branch to tag. Defaults to current branch.

=item * signed - whether to make a GPG-signed tag, using the default
e-mail address' key. Consider setting C<user.signingkey> if C<gpg>
can't find the correct key:

    $ git config user.signingkey 450F89EC

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

=item C<%{-TRIAL}t>

Expands to -TRIAL (or any other supplied string) if this is a trial
release, or the empty string if not.  A bare C<%t> means C<%{-TRIAL}t>.

=item C<%v>

The distribution version

=back

=head1 METHODS

=head2 tag

    my $tag = $plugin->tag;

Return the tag that will be / has been applied by the plugin. That is,
returns C<tag_format> as completed with the real values.

=for Pod::Coverage after_release
    before_release

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

