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
use Cwd          qw{ getcwd  };
use File::Temp   qw{ tempdir };
use Git::Wrapper;
use Path::Class;
use Test::More;
use version;

# Mock HOME to avoid ~/.gitexcludes from causing problems
$ENV{HOME} = tempdir( CLEANUP => 1 );

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => dir('corpus/push-multi')->absolute,
});

chdir $zilla->tempdir->subdir('source');
system "git init";
my $git = Git::Wrapper->new('.');

# rt#56485 - skip test to avoid failures for old git versions
my ($version) = $git->version =~ m[^( \d+ \. \d+ \. \d+ )]x;
my $gitversion = version->parse( $version );
if ( $gitversion < version->parse('1.7.0') ) {
    plan skip_all => 'git 1.7.0 or later required for this test';
} else {
    plan tests => 6;
}

$git->config( 'user.name'  => 'dzp-git test' );
$git->config( 'user.email' => 'dzp-git@test' );
$git->add( qw{ dist.ini Changes } );
$git->commit( { message => 'initial commit' } );

# create a clone, and use it to set up origin
my $clone1 = tempdir( CLEANUP => 1 );
my $clone2 = tempdir( CLEANUP => 1 );
my $curr  = getcwd;
$git->clone( { quiet=>1, 'no-checkout'=>1, bare=>1 }, $curr, $clone1 );
$git->clone( { quiet=>1, 'no-checkout'=>1, bare=>1 }, $curr, $clone2 );
$git->remote('add', 'origin', $clone1);
$git->remote('add', 'another', $clone2);
$git->config('branch.master.remote', 'origin');
$git->config('branch.master.merge', 'refs/heads/master');

# do the release
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
$zilla->release;

for my $c ( $clone1, $clone2 ) {
  # check if everything was pushed
  $git = Git::Wrapper->new( $c );
  my ($log) = $git->log( 'HEAD' );
  like( $log->message, qr/v1.23\n[^a-z]*foo[^a-z]*bar[^a-z]*baz/, "commit pushed to $c" );

  # check if tag has been correctly created
  my @tags = $git->tag;
  is( scalar(@tags), 1, 'one tag pushed' );
  is( $tags[0], 'v1.23', 'new tag created after new version' );
}

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}
