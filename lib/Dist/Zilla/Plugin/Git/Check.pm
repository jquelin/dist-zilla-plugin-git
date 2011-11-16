use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::Check;
# ABSTRACT: check your git repository before releasing

use Git::Wrapper;
use Moose;

with 'Dist::Zilla::Role::BeforeRelease';
with 'Dist::Zilla::Role::Git::DirtyFiles';
with 'Dist::Zilla::Role::Git::Repo';


# -- public methods

sub before_release {
    my $self = shift;

    my $git = Git::Wrapper->new( $self->repo_root );
    my @output;

    # fetch current branch
    my ($branch) =
        map { /^\*\s+(.+)/ ? $1 : () }
        $git->branch;

    # check if some changes are staged for commit
    @output = $git->diff( { cached=>1, 'name-status'=>1 } );
    if ( @output ) {
        my $errmsg =
            "branch $branch has some changes staged for commit:\n" .
            join "\n", map { "\t$_" } @output;
        $self->log_fatal($errmsg);
    }

    # everything but files listed in allow_dirty should be in a
    # clean state
    @output = $self->list_dirty_files($git);
    if ( @output ) {
        my $errmsg =
            "branch $branch has some uncommitted files:\n" .
            join "\n", map { "\t$_" } @output;
        $self->log_fatal($errmsg);
    }

    # no files should be untracked
    @output = $git->ls_files( { others=>1, 'exclude-standard'=>1 } );
    if ( @output ) {
        my $errmsg =
            "branch $branch has some untracked files:\n" .
            join "\n", map { "\t$_" } @output;
        $self->log_fatal($errmsg);
    }

    $self->log( "branch $branch is in a clean state" );
}


1;
__END__

=for Pod::Coverage
    before_release


=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::Check]
    allow_dirty = dist.ini
    allow_dirty = README
    changelog = Changes      ; this is the default


=head1 DESCRIPTION

This plugin checks that git is in a clean state before releasing. The
following checks are performed before releasing:

=over 4

=item * there should be no files in the index (staged copy)

=item * there should be no untracked files in the working copy

=item * the working copy should be clean. The files listed in
C<allow_dirty> can be modified locally, though.

=back

If those conditions are not met, the plugin will die, and the release
will thus be aborted. This lets you fix the problems before continuing.


The plugin accepts the following options:

=over 4

=item * changelog - the name of your changelog file. defaults to F<Changes>.

=item * allow_dirty - a file that is allowed to have local
modifications.  This option may appear multiple times.  The default
list is F<dist.ini> and the changelog file given by C<changelog>.  You
can use C<allow_dirty => to prohibit all local modifications.

=back

