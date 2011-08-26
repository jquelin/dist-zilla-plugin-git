#!perl
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

use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use File::Temp qw{ tempdir };
use Git::Wrapper;
use Path::Class;
use Test::More   tests => 4;
use Cwd qw(cwd);

# Mock HOME to avoid ~/.gitexcludes from causing problems
$ENV{HOME} = tempdir( CLEANUP => 1 );

my $cwd = cwd();
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir('corpus/commit-build')->absolute,
});

# build fake repository
chdir $zilla->tempdir->subdir('source');
system "git init -q";

my $git = Git::Wrapper->new('.');
$git->config( 'user.name'  => 'dzp-git test' );
$git->config( 'user.email' => 'dzp-git@test' );
$git->add( qw{ dist.ini Changes } );
$git->commit( { message => 'initial commit' } );

$zilla->build;
ok( $git->rev_parse('-q', '--verify', 'refs/heads/build/master'), 'source repo has the "build/master" branch') or diag $git->branch;
is( $git->log('build/master'), 2, 'one commit on the build/master branch') or diag $git->branch;

chdir $cwd;

my $zilla2 = Dist::Zilla::Tester->from_config({
  dist_root => dir('corpus/commit-build')->absolute,
});

# build fake repository
chdir $zilla2->tempdir->subdir('source');
system "git init -q";
my $git2 = Git::Wrapper->new('.');
$git2->config( 'user.name'  => 'dzp-git test' );
$git2->config( 'user.email' => 'dzp-git@test' );
$git2->remote('add','origin', $zilla->tempdir->subdir('source'));
$git2->fetch;
$git2->reset('--hard','origin/master');
$git2->checkout('-b', 'topic/1');
append_to_file('dist.ini', "\n");
$git2->commit('-a', '-m', 'commit on topic branch');
$zilla2->build;

ok( $git2->rev_parse('-q', '--verify', 'refs/heads/build/topic/1'), 'source repo has the "build/topic/1" branch') or diag $git2->branch;

chdir $cwd;
my $zilla3 = Dist::Zilla::Tester->from_config({
  dist_root => dir('corpus/commit-build')->absolute,
});

# build fake repository
chdir $zilla3->tempdir->subdir('source');
system "git init -q";
my $git3 = Git::Wrapper->new('.');
$git3->config( 'user.name'  => 'dzp-git test' );
$git3->config( 'user.email' => 'dzp-git@test' );
$git3->remote('add','origin', $zilla->tempdir->subdir('source'));
$git3->fetch;
$git3->branch('build/master', 'origin/build/master');
$git3->reset('--hard','origin/master');
append_to_file('dist.ini', "\n\n");
$git3->commit('-a', '-m', 'commit on master');
$zilla3->build;
is( $git3->log('build/master'), 4, 'two commits on the build/master branch') or diag $git3->branch;

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}
