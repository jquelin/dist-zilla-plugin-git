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

use Dist::Zilla     1.093250;
use Dist::Zilla::Tester;
use File::Temp qw{ tempdir };
use Git::Wrapper;
use Path::Class;
use Test::More      tests => 4;
use Test::Exception;

# Mock HOME to avoid ~/.gitexcludes from causing problems
$ENV{HOME} = tempdir( CLEANUP => 1 );

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir('corpus/check')->absolute,
});

chdir $zilla->tempdir->subdir('source');
system "git init";
my $git   = Git::Wrapper->new('.');
$git->config( 'user.name'  => 'dzp-git test' );
$git->config( 'user.email' => 'dzp-git@test' );

# create initial .gitignore
# we cannot ship it in the dist, since PruneCruft plugin would trim it
append_to_file('.gitignore', 'Foo-*');
$git->add( { force => 1 }, '.gitignore');
$git->commit( { message=>'ignore file for git' } );

# untracked files
throws_ok { $zilla->release } qr/untracked files/, 'untracked files';

# index not clean
$git->add( qw{ dist.ini Changes foobar } );
throws_ok { $zilla->release } qr/some changes staged/, 'index not clean';
$git->commit( { message => 'initial commit' } );

# modified files
append_to_file('foobar', 'Foo-*');
throws_ok { $zilla->release } qr/uncommitted files/, 'uncommitted files';
$git->checkout( 'foobar' );

# changelog and dist.ini can be modified
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
lives_ok { $zilla->release } 'Changes and dist.ini can be modified';

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}
