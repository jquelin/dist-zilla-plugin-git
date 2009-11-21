use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::Check;
# ABSTRACT: check your git repository before releasing

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

    $self->zilla->log( "[Git] branch $branch is in a clean state\n" );
}


1;
__END__

=for Pod::Coverage::TrustPod
    before_release


=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::Check]
    filename = Changes      ; this is the default


=head1 DESCRIPTION

This plugin checks that git is in a clean state before releasing. The
following checks are performed before releasing:

=over 4

=item * there should be no files in the index (staged copy)

=item * there should be no untracked files in the working copy

=item * the working copy should be clean. The changelog and F<dist.ini>
can be modified locally, though.

=back

If those conditions are not met, the plugin will die, and the release
will thus be aborted. This lets you fix the problems before continuing.


The plugin accepts the following options:

=over 4

=item * filename - the name of your changelog file. defaults to F<Changes>.

=back

