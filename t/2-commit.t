#!perl

use strict;
use warnings;

use Dist::Zilla  1.093250;
use Git::Wrapper;
use Path::Class;
use Test::More   tests => 1;

# build fake repository
chdir( dir('t', 'commit') );
system "git init";
my $git = Git::Wrapper->new('.');
$git->config( 'user.name'  => 'dzp-git test' );
$git->config( 'user.email' => 'dzp-git@test' );
$git->add( qw{ dist.ini Changes } );
$git->commit( { message => 'initial commit' } );

# do a release, with changes and dist.ini updated
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
my $zilla = Dist::Zilla->from_config;
$zilla->release;

# check if dist.ini and changelog have been committed
my ($log) = $git->log( 'HEAD' );
is( $log->message, "v1.23\n\n- foo\n- bar\n- baz\n", 'commit message taken from changelog' );

# clean & exit
dir( '.git' )->rmtree;
unlink 'Foo-1.23.tar.gz';
exit;

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}
