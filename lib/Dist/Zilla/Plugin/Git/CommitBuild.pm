use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::CommitBuild;
# ABSTRACT: checkin build results on separate branch

use Git::Wrapper;
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
			b => sub { (shift->name_rev( '--name-only', 'HEAD' ))[0] },
			h => sub { (shift->rev_parse( '--short',    'HEAD' ))[0] },
			H => sub { (shift->rev_parse('HEAD'))[0] },
		}
	}
);

with 'Dist::Zilla::Role::AfterBuild';

# -- attributes

has branch  => ( ro, isa => Str, default => 'build/%b', required => 1 );
has message => ( ro, isa => Str, default => 'Build results of %h (on %b)', required => 1 );

# -- role implementation

sub after_build {
	my $self  = shift;
	my $args  = shift;
	my $src_dir = abs_path('.');

	my $src   = Git::Wrapper->new($src_dir);
	my $target_branch = _format_branch( $self->branch, $src );

	my $exists = eval { $src->rev_parse( '--verify', '-q', $target_branch ); 1; };

	eval {
		my $build = Git::Wrapper->new( $args->{build_root} );
		$build->init('-q');
		$build->remote('add','src',$src_dir);
		$build->fetch(qw(-q src));
		if($exists){
			$build->reset('--soft', "src/$target_branch");
		}
		$build->add('.');
		$build->commit('-a', -m => _format_message($self->message, $src));
		$build->checkout('-b',$target_branch);
		$build->push('src', $target_branch);
	};
	if (my $e = $@) {
		$self->log_fatal("failed to commit build: $e");
	}
}

1;
__END__

=for Pod::Coverage
    after_build

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
build contents

A single formatting code (C<%b>) is defined for this attribute and will be
substituted with the name of the current branch in your git repository.

=item * message - L<String::Formatter> string for what commit message
to use when committing the results of the build.

This option supports three formatting codes:

=over 4

=item * C<%b> - Name of the current branch

=item * C<%H> - Commit hash

=item * C<%h> - Abbreviated commit hash

=back

=back

=cut
