#!perl

use strict;
use warnings;

use File::Spec::Functions qw{ catdir };
use Git::Wrapper;
use Test::More tests => 2;

# build fake repository
chdir( catdir('t', 'tag') );
system "git init";
my $git = Git::Wrapper->new('.');
$git->add( qw{ dist.ini Changes } );
$git->commit( { message => 'initial commit' } );

# do the release
system "dzil release";

# check if tag has been correctly created
my @tags = $git->tag;
is( scalar(@tags), 1, 'one tag created' );
is( $tags[0], 'v1.23', 'new tag created after new version' );

#
exit;
