#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::NextVersion;
{
  $Dist::Zilla::Plugin::Git::NextVersion::VERSION = '1.120970';
}
# ABSTRACT: provide a version number by bumping the last git release tag

use Dist::Zilla 4 ();
use Git::Wrapper;
use Version::Next ();
use version 0.80 ();

use Moose;
use namespace::autoclean 0.09;
use MooseX::AttributeShortcuts;

with 'Dist::Zilla::Role::VersionProvider';
with 'Dist::Zilla::Role::Git::Repo';

# -- attributes

has version_regexp  => ( is => 'ro', isa=>'Str', default => '^v(.+)$' );

has first_version  => ( is => 'ro', isa=>'Str', default => '0.001' );

has _previous_versions => (

    traits  => ['Array'],
    is      => 'lazy',
    isa     => 'ArrayRef[Str]',
    handles => {

        has_previous_versions => 'count',
        previous_versions     => 'elements',
        earliest_version      => [ get =>  0 ],
        last_version          => [ get => -1 ],
    },
);

sub _build__previous_versions {
  my ($self) = @_;

  local $/ = "\n"; # Force record separator to be single newline

  my $git  = Git::Wrapper->new( $self->repo_root );
  my $regexp = $self->version_regexp;

  my @tags = $git->tag;
  @tags = map { /$regexp/ ? $1 : () } @tags;

  # find tagged versions; sort least to greatest
  my @versions =
    sort { version->parse($a) <=> version->parse($b) }
    grep { eval { version->parse($_) }  }
    @tags;

  return [ @versions ];
}

# -- role implementation

sub provide_version {
  my ($self) = @_;

  # override (or maybe needed to initialize)
  return $ENV{V} if exists $ENV{V};

  return $self->first_version
    unless $self->has_previous_versions;

  my $last_ver = $self->last_version;
  my $new_ver  = Version::Next::next_version($last_ver);
  $self->log("Bumping version from $last_ver to $new_ver");

  return "$new_ver";
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;



=pod

=head1 NAME

Dist::Zilla::Plugin::Git::NextVersion - provide a version number by bumping the last git release tag

=head1 VERSION

version 1.120970

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::NextVersion]
    first_version = 0.001       ; this is the default
    version_regexp  = ^v(.+)$   ; this is the default

=head1 DESCRIPTION

This does the L<Dist::Zilla::Role::VersionProvider> role.  It finds the last
version number from your git tags, increments it using L<Version::Next>, and
uses the result as the C<version> parameter for your distribution.

The plugin accepts the following options:

=over

=item *

C<first_version> - if the repository has no tags at all, this version
is used as the first version for the distribution.  It defaults to "0.001".

=item *

C<version_regexp> - regular expression that matches a tag containing
a version.  It must capture the version into $1.  Defaults to ^v(.+)$
which matches the default C<tag_format> from L<Dist::Zilla::Plugin::Git::Tag>.
If you change C<tag_format>, you B<must> set a corresponsing C<version_regexp>.

=back

You can also set the C<V> environment variable to override the new version.
This is useful if you need to bump to a specific version.  For example, if
the last tag is 0.005 and you want to jump to 1.000 you can set V = 1.000.

  $ V=1.000 dzil release

=for Pod::Coverage provide_version

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


