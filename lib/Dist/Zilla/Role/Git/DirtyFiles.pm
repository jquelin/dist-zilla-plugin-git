use 5.008;
use strict;
use warnings;

package Dist::Zilla::Role::Git::DirtyFiles;
# ABSTRACT: provide the allow_dirty & filename attributes

use Moose::Role;
use Moose::Autobox;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ ArrayRef Str };

has allow_dirty => (
  ro, lazy,
  isa     => ArrayRef[Str],
  builder => '_build_allow_dirty',
);

has filename => ( ro, isa=>Str, default => 'Changes' );

sub _build_allow_dirty { [ 'dist.ini', shift->filename ] }

sub mvp_multivalue_args { qw(allow_dirty) }

=for Pod::Coverage::TrustPod
    mvp_multivalue_args

=method list_dirty_files

  @dirty = $plugin->list_dirty_files($git, $listAllowed);

This returns a list of the modified or deleted files in C<$git>,
filtered against the C<allow_dirty> attribute.  If C<$listAllowed> is
true, only allowed files are listed.  If it's false, only files that
are not allowed to be dirty are listed.

In scalar context, returns the number of dirty files.

=cut

sub list_dirty_files
{
  my ($self, $git, $listAllowed) = @_;

  my %allowed = map { $_ => 1 } $self->allow_dirty->flatten;

  return grep { $allowed{$_} ? $listAllowed : !$listAllowed }
      $git->ls_files( { modified=>1, deleted=>1 } );
} # end list_dirty_files

no Moose::Role;
no MooseX::Has::Sugar;
1;
