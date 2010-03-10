#!perl

use strict;
use warnings;

use Dist::Zilla  1.093250;
use Git::Wrapper;
use Path::Class;
use Test::More   tests => 2;

# build fake repository
chdir( dir('t', 'tag') );
system "git init";
my $git = Git::Wrapper->new('.');
$git->config( 'user.name'  => 'dzp-git test' );
$git->config( 'user.email' => 'dzp-git@test' );
$git->add( qw{ dist.ini Changes } );
$git->commit( { message => 'initial commit' } );

# do the release
my $zilla = Dist::Zilla->from_config;
$zilla->release;

# check if tag has been correctly created
my @tags = $git->tag;
is( scalar(@tags), 1, 'one tag created' );
is( $tags[0], 'v1.23', 'new tag created after new version' );

# clean & exit
dir('.git')->rmtree;
unlink 'Foo-1.23.tar.gz';
exit;
