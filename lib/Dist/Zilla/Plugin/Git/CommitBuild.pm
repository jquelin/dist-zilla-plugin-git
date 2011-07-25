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

package Dist::Zilla::Plugin::Git::CommitBuild;
BEGIN {
  $Dist::Zilla::Plugin::Git::CommitBuild::VERSION = '1.112060';
}
# ABSTRACT: checkin build results on separate branch

use Git::Wrapper;
use IPC::Open3;
use File::chdir;
use File::Spec::Functions qw/ rel2abs catfile /;
use File::Temp;
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Str };
use Cwd qw(abs_path);
use String::Formatter (
	method_stringf => {
		-as   => '_format_branch',
		codes => {
			b => sub { (shift->name_rev( '--name-only', 'HEAD' ))[0] },
		},
	},
	method_stringf => {
		-as   => '_format_message',
		codes => {
			b => sub { (shift->_git->name_rev( '--name-only', 'HEAD' ))[0] },
			h => sub { (shift->_git->rev_parse( '--short',    'HEAD' ))[0] },
			H => sub { (shift->_git->rev_parse('HEAD'))[0] },
		    t => sub { shift->zilla->is_trial ? '-TRIAL' : '' },
		    v => sub { shift->zilla->version },
		}
	}
);

with 'Dist::Zilla::Role::AfterBuild', 'Dist::Zilla::Role::AfterRelease';

# -- attributes

has branch  => ( ro, isa => Str, default => 'build/%b', required => 1 );
has release_branch  => ( ro, isa => Str, required => 0 );
has message => ( ro, isa => Str, default => 'Build results of %h (on %b)', required => 1 );
has release_message => ( ro, isa => Str, lazy => 1, builder => '_build_release_message' );
has build_root => ( rw );
has _git => (rw, weak_ref => 1);

# -- attribute builders

sub _build_release_message { return shift->message; }

# -- role implementation

sub after_build {
    my ( $self, $args) = @_;

    # because the build_root mysteriously change at
    # the 'after_release' stage
    $self->build_root( $args->{build_root} );

    $self->_commit_build( $args, $self->branch, $self->message );
}

sub after_release {
    my ( $self, $args) = @_;

    $self->_commit_build( $args, $self->release_branch, $self->release_message );
}

sub _commit_build {
    my ( $self, undef, $branch, $message ) = @_;

    return unless $branch;

    my $tmp_dir = File::Temp->newdir( CLEANUP => 1) ;
    my $src     = Git::Wrapper->new('.');
    $self->_git($src);

    my $dir = rel2abs( $self->build_root );

    my $tree = do {
        # don't overwrite the user's index
        local $ENV{GIT_INDEX_FILE} = catfile( $tmp_dir, "temp_git_index" );
        local $ENV{GIT_DIR}        = catfile( $CWD,     '.git' );
        local $ENV{GIT_WORK_TREE}  = $dir;

        local $CWD = $dir;

        my $write_tree_repo = Git::Wrapper->new('.');

        $write_tree_repo->add({ v => 1, force => 1}, '.' );
        ($write_tree_repo->write_tree)[0];
    };

    my $target_branch = _format_branch( $branch, $src );

    # no change, abort
    return
      if eval {
              $src->rev_parse({q=>1, verify => 1}, $target_branch );
        }
          and not $src->diff({ 'stat' => 1 }, $target_branch, $tree );

    my @parents = grep {
        eval { $src->rev_parse({ 'q' => 1, 'verify'=>1}, $_ ) }
    } $target_branch, 'HEAD';

    my @commit;
    {
        # Git::Wrapper doesn't read from STDIN, which is 
        # needed for commit-tree, so we have to everything
        # ourselves
        #
        my ($fh, $filename) = File::Temp::tempfile();
        $fh->autoflush(1);
        print $fh _format_message( $message, $self );

        my @args=('git', 'commit-tree', $tree, map { ( -p => $_ ) } @parents);
        push @args,'<'.$filename;
        my $cmdline=join(' ',@args);
        @commit=qx/$cmdline/;

        chomp(@commit);

    }

    $src->update_ref( 'refs/heads/' . $target_branch, $commit[0] );
}

1;


=pod

=head1 NAME

Dist::Zilla::Plugin::Git::CommitBuild - checkin build results on separate branch

=head1 VERSION

version 1.112060

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::CommitBuild]
	; these are the defaults
    branch = build/%b
    message = Build results of %h (on %b)

=head1 DESCRIPTION

Once the build is done, this plugin will commit the results of the
build to a branch that is completely separate from your regular code
branches (i.e. with a different root commit).  This potentially makes
your repository more useful to those who may not have L<Dist::Zilla>
and all of its dependencies installed.

The plugin accepts the following options:

=over 4

=item * branch - L<String::Formatter> string for where to commit the
build contents.

A single formatting code (C<%b>) is defined for this attribute and will be
substituted with the name of the current branch in your git repository.

Defaults to C<build/%b>, but if set explicitly to an empty string
causes no build contents checkin to be made.

=item * release_branch - L<String::Formatter> string for where to commit the
build contents

Same as C<branch>, but commit the build content only after a release. No
default, meaning no release branch.

=item * message - L<String::Formatter> string for what commit message
to use when committing the results of the build.

This option supports five formatting codes:

=over 4

=item * C<%b> - Name of the current branch

=item * C<%H> - Commit hash

=item * C<%h> - Abbreviated commit hash

=item * C<%v> - The release version number

=item * C<%t> - The string "-TRIAL" if this is a trial release

=back

=item * release_message - L<String::Formatter> string for what
commit message to use when committing the results of the release.
Defaults to the same as C<message>.

=back

=for Pod::Coverage after_build
    after_release

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


