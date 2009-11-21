#!perl

use strict;
use warnings;

use File::Path            qw{ remove_tree };
use Cwd                   qw{ getcwd  };
use File::Temp            qw{ tempdir };
use File::Spec::Functions qw{ catdir  };
use Git::Wrapper;
use Test::More            tests => 3;

# build fake repository
chdir( catdir('t', 'push') );
system "git init";
my $git = Git::Wrapper->new('.');
$git->add( qw{ dist.ini Changes } );
$git->commit( { message => 'initial commit' } );

# create a clone, and use it to set up origin
my $clone = tempdir( CLEANUP => 1 );
my $curr  = getcwd;
{
    chdir $clone;
    system qq{ git clone $curr };
}
chdir $curr;
$git->remote('add', 'origin', catdir($clone, 'push'));

# do the release
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
system "dzil release";

# check if everything was pushed
$git = Git::Wrapper->new( catdir($clone, 'push') );
my ($log) = $git->log( 'HEAD' );
is( $log->message, "v1.23\n\n- foo\n- bar\n- baz\n", 'commit pushed' );

# check if tag has been correctly created
my @tags = $git->tag;
is( scalar(@tags), 1, 'one tag pushed' );
is( $tags[0], 'v1.23', 'new tag created after new version' );

# clean & exit
remove_tree( '.git' );
unlink 'Foo-1.23.tar.gz';
exit;

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}
