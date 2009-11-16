use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git;
# ABSTRACT: update your git repository after release

use Git::Wrapper;
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Str };

with 'Dist::Zilla::Role::BeforeRelease';


# -- attributes

has filename => ( ro, isa=>Str, default => 'Changes' );


sub before_release {
    my $self = shift;
    my $git = Git::Wrapper->new('.');
    my @output;

    # fetch current branch
    my ($branch) =
        map { /^\*\s+(.+)/ ? $1 : () }
        $git->branch;

    # check if some changes are staged for commit
    @output = $git->diff( { cached=>1, 'name-status'=>1 } );
    if ( @output ) {
        my $errmsg =
            "[Git] branch $branch has some changes staged for commit:\n" .
            join "\n", map { "\t$_" } @output;
        die "$errmsg\n";
    }

    # everything but changelog and dist.ini should be in a clean state
    @output =
        grep { $_ ne $self->filename }
        grep { $_ ne 'dist.ini' }
        $git->ls_files( { modified=>1, deleted=>1 } );
    if ( @output ) {
        my $errmsg =
            "[Git] branch $branch has some uncommitted files:\n" .
            join "\n", map { "\t$_" } @output;
        die "$errmsg\n";
    }

    # no files should be untracked
    @output = $git->ls_files( { others=>1, 'exclude-standard'=>1 } );
    if ( @output ) {
        my $errmsg =
            "[Git] branch $branch has some untracked files:\n" .
            join "\n", map { "\t$_" } @output;
        die "$errmsg\n";
    }
}


sub after_release {
	my $self = shift;

}




1;
__END__

=for Pod::Coverage::TrustPod
    after_release
    before_release


=head1 SYNOPSIS

In your F<dist.ini>:

    [Git]
    filename = Changes      ; this is the default


=head1 DESCRIPTION

This plugin does two things for module authors using L<git|http://git-
scm.com> to track their work:

=over 4

=item * before releasing: checks that git is in a clean state

=item * after releasing: perform some simple git actions

=back


=head2 Checks before releasing

The following checks are performed before releasing:

=over 4

=item * there should be no files in the index (staged copy)

=item * there should be no untracked files in the working copy

=item * the working copy should be clean. The changelog and F<dist.ini>
can be modified locally, though.

=back

If those conditions are not met, the plugin will die, and the release
will then be aborted. This lets you fix the problems before continuing.


=head2 Simple git actions after releasing

This plugin is called after you released your distribution, and does the
following actions:

=over 4

=item * commit your changelog (and your dzil config if you update the
version manually) to git. The commit message will be the changelog entry
for this release.

=item * create a tag named C<v$VERSION>.

=item * push the branch and the tags to your remote repository. Since
it's a simple push, it means that the remotes should be correctly
configured in your local repository.

=back


The plugin accepts the following options:

=over 4

=item * filename - the name of your changelog file. defaults to F<Changes>.

=back


=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-Git>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-Git>

=item * Mailing-list (same as L<Dist::Zilla>)

L<http://www.listbox.com/subscribe/?list_id=139292>

=item * Git repository

L<http://github.com/jquelin/dist-zilla-plugin-git.git>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-Plugin-Git>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Git>

=back

