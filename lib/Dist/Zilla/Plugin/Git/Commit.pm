use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::Commit;
# ABSTRACT: commit dirty files

use File::Temp           qw{ tempfile };
use Git::Wrapper;
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Str };
use Path::Class::Dir ();

use String::Formatter method_stringf => {
  -as => '_format_string',
  codes => {
    c => sub { $_[0]->_get_changes },
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

with 'Dist::Zilla::Role::AfterRelease';
with 'Dist::Zilla::Role::Git::DirtyFiles';


# -- attributes

has commit_msg => ( ro, isa=>Str, default => 'v%v%n%n%c' );
has time_zone  => ( ro, isa=>Str, default => 'local' );
has dirty_dir  => ( ro, isa=>'ArrayRef[Str]', default => sub { [] } );

# -- public methods

sub mvp_multivalue_args { qw( dirty_dir ) }

sub after_release {
    my $self = shift;
    my $git  = Git::Wrapper->new('.');
    my @output;

    # check if there are dirty files that need to be committed.
    # at this time, we know that only those 2 files may remain modified,
    # otherwise before_release would have failed, ending the release
    # process.
    @output = sort { lc $a cmp lc $b } $self->list_dirty_files($git, 1);

    # add the files in dirty_dir to be committed
    if ( @{ $self->dirty_dir } ) {
        my @untracked_files = $git->ls_files( { others=>1, 'exclude-standard'=>1 } );
        foreach my $f ( @untracked_files ) {
            foreach my $path ( @{ $self->dirty_dir } ) {
                if ( Path::Class::Dir->new( $path )->subsumes( $f ) ) {
                    push( @output, $f );
                    last;
                }
            }
        }
    }

    # if nothing to commit, we're done!
    return unless @output;    

    # write commit message in a temp file
    my ($fh, $filename) = tempfile( 'DZP-git.XXXX', UNLINK => 1 );
    print $fh $self->get_commit_message;
    close $fh;

    # commit the files in git
    $git->add( @output );
    $self->log_debug($_) for $git->commit( { file=>$filename } );
    $self->log("Committed @output");
}


=method get_commit_message

This method returns the commit message.  The default implementation
reads the Changes file to get the list of changes in the just-released version.

=cut

sub get_commit_message {
    my $self = shift;

    return _format_string($self->commit_msg, $self);
} # end get_commit_message

# -- private methods

sub _get_changes {
    my $self = shift;

    # parse changelog to find commit message
    my $changelog = Dist::Zilla::File::OnDisk->new( { name => $self->changelog } );
    my $newver    = $self->zilla->version;
    my @content   =
        grep { /^$newver(?:\s+|$)/ ... /^\S/ } # from newver to un-indented
        split /\n/, $changelog->content;
    shift @content; # drop the version line
    # drop unindented last line and trailing blank lines
    pop @content while ( @content && $content[-1] =~ /^(?:\S|\s*$)/ );

    # return commit message
    return join("\n", @content, ''); # add a final \n
} # end _get_changes


1;
__END__

=for Pod::Coverage
    after_release mvp_multivalue_args


=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::Commit]
    changelog = Changes      ; this is the default


=head1 DESCRIPTION

Once the release is done, this plugin will record this fact in git by
committing changelog and F<dist.ini>. The commit message will be taken
from the changelog for this release.  It will include lines between
the current version and timestamp and the next non-indented line.


The plugin accepts the following options:

=over 4

=item * changelog - the name of your changelog file. Defaults to F<Changes>.

=item * allow_dirty - a file that will be checked in if it is locally
modified.  This option may appear multiple times.  The default
list is F<dist.ini> and the changelog file given by C<changelog>.

=item * commit_msg - the commit message to use. Defaults to
C<v%v%n%n%c>, meaning the version number and the list of changes.

=item * time_zone - the time zone to use with C<%d>.  Can be any
time zone name accepted by DateTime.  Defaults to C<local>.

=item * dirty_dir - a path that will have it's contents checked in if
it is locally modified. This option may appear multiple times. The default
list is empty.

=back

You can use the following codes in commit_msg:

=over 4

=item C<%c>

The list of changes in the just-released version (read from C<changelog>).

=item C<%{dd-MMM-yyyy}d>

The current date.  You can use any CLDR format supported by
L<DateTime>.  A bare C<%d> means C<%{dd-MMM-yyyy}d>.

=item C<%n>

a newline

=item C<%N>

the distribution name

=item C<%{-TRIAL}t>

Expands to -TRIAL (or any other supplied string) if this is a trial
release, or the empty string if not.  A bare C<%t> means C<%{-TRIAL}t>.

=item C<%v>

the distribution version

=back
