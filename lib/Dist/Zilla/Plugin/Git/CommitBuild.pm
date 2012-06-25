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
{
  $Dist::Zilla::Plugin::Git::CommitBuild::VERSION = '1.121770';
}
# ABSTRACT: checkin build results on separate branch

use Git::Wrapper;
use IPC::Open3;
use IPC::System::Simple; # required for Fatalised/autodying system
use File::chdir;
use File::Spec::Functions qw/ rel2abs catfile /;
use File::Temp;
use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;
use Path::Class;
use MooseX::Types::Path::Class ':all';
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Str };
use Cwd qw(abs_path);
use Try::Tiny;

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

# debugging...
#use Smart::Comments '###';

with 'Dist::Zilla::Role::AfterBuild', 'Dist::Zilla::Role::AfterRelease';
with 'Dist::Zilla::Role::Git::Repo';

# -- attributes

has branch  => ( ro, isa => Str, default => 'build/%b', required => 1 );
has release_branch  => ( ro, isa => Str, required => 0 );
has message => ( ro, isa => Str, default => 'Build results of %h (on %b)', required => 1 );
has release_message => ( ro, isa => Str, lazy => 1, builder => '_build_release_message' );
has build_root => ( rw, coerce => 1, isa => Dir );
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
    my $src     = Git::Wrapper->new( $self->repo_root );
    $self->_git($src);

    my $target_branch = _format_branch( $branch, $src );
    my $dir           = $self->build_root;

    # returns the sha1 of the created tree object
    my $tree = $self->_create_tree($src, $dir);

    my ($last_build_tree) = try { $src->rev_parse("$target_branch^{tree}") };
    $last_build_tree ||= 'none';

    ### $last_build_tree
    if ($tree eq $last_build_tree) {

        $self->log("No changes since the last build; not committing");
        return;
    }

    my @parents = grep {
        eval { $src->rev_parse({ 'q' => 1, 'verify'=>1}, $_ ) }
    } $target_branch;

    ### @parents

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

    ### @commit
    $src->update_ref( 'refs/heads/' . $target_branch, $commit[0] );
}

sub _create_tree {
    my ($self, $repo, $fs_obj) = @_;

    ### called with: "$fs_obj"
    if (!$fs_obj->is_dir) {

        my ($sha) = $repo->hash_object({ w => 1 }, "$fs_obj");
        ### hashed: "$sha $fs_obj"
        return $sha;
    }

    my @entries;
    for my $obj ($fs_obj->children) {

        ### working on: "$obj"
        my $sha  = $self->_create_tree($repo, $obj);
        my $mode = sprintf('%o', $obj->stat->mode); # $obj->is_dir ? '040000' : '
        my $type = $obj->is_dir ? 'tree' : 'blob';
        my $name = $obj->basename;

        push @entries, "$mode $type $sha\t$name";
    }

    ### @entries

    my $sha = do {
        use autodie 'system';
        my $cmd = join '\n', @entries, q{};
        $cmd  = qq{echo -en "$cmd" | git mktree};

        #### $cmd
        my $sha = `$cmd`;
        chomp $sha;

        ### tree created at: $sha
        $sha;
    };

    return $sha;
}

1;


=pod

=head1 NAME

Dist::Zilla::Plugin::Git::CommitBuild - checkin build results on separate branch

=head1 VERSION

version 1.121770

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


