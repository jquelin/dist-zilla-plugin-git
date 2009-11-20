#!perl

use strict;
use warnings;

use Cwd;
use File::Temp            qw{ tempdir };
use File::Spec::Functions qw{ catdir };
use Git::Wrapper;
use IPC::Open3            qw{ open3 };
use Symbol;
use Test::More            tests => 7;


# build fake repository
chdir( catdir('t', 'foo') );
system "git init";
my $git = Git::Wrapper->new('.');

# create initial .gitignore
# we cannot ship it in the dist, since PruneCruft plugin would trim it
append_to_file('.gitignore', 'Foo-*');
$git->add('.gitignore');
$git->commit( { message=>'ignore file for git' } );

# untracked files
like( check_dzil_release(), qr/untracked files/, 'untracked files' );

# index not clean
$git->add( qw{ dist.ini Changes foobar } );
like( check_dzil_release(), qr/some changes staged/, 'index not clean' );
$git->commit( { message => 'initial commit' } );

# modified files
append_to_file('foobar', 'Foo-*');
like( check_dzil_release(), qr/uncommitted files/, 'uncommitted files' );
$git->checkout( 'foobar' );

# create a clone, and use it to set up origin
my $clone = tempdir( CLEANUP => 1 );
my $curr  = getcwd;
{
    chdir $clone;
    system qq{ git clone $curr };
}
chdir $curr;
$git->remote('add', 'origin', catdir($clone, 'foo'));


# changelog and dist.ini can be modified
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
is( check_dzil_release(), '', 'Changes and dist.ini can be modified' );

# check if dist.ini and changelog have been committed
my ($log) = $git->log( 'HEAD' );
is( $log->message, "v1.23\n\n- foo\n- bar\n- baz\n", 'commit message taken from changelog' );

# check if tag has been correctly created
my @tags = $git->tag;
is( scalar(@tags), 1, 'one tag created' );
is( $tags[0], 'v1.23', 'new tag created after new version' );

#
exit;

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}

sub check_dzil_release {
    my ($infh, $outfh, $out, $err);
    my $errfh = Symbol::gensym;

    my $pid = IPC::Open3::open3($infh, $outfh, $errfh, qw{ dzil release } );
    close $infh;
    $out = do { local $/; <$outfh> };
    $err = do { local $/; <$errfh> };
    waitpid $pid, 0;

    my $rv = $? >> 8;
    return $rv == 0 ? '' : $err;
}
