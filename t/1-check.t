#!perl

use strict;
use warnings;

use Dist::Zilla           1.093250;
use File::Path            qw{ remove_tree };
use File::Spec::Functions qw{ catdir };
use Git::Wrapper;
use Test::More            tests => 4;
use Test::Exception;


# build fake repository
chdir( catdir('t', 'check') );
system "git init";
my $git   = Git::Wrapper->new('.');
my $zilla = Dist::Zilla->from_config;

# create initial .gitignore
# we cannot ship it in the dist, since PruneCruft plugin would trim it
append_to_file('.gitignore', 'Foo-*');
$git->add('.gitignore');
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

# clean & exit
remove_tree( '.git' );
unlink 'Foo-1.23.tar.gz', '.gitignore';
exit;

sub append_to_file {
    my ($file, @lines) = @_;
    open my $fh, '>>', $file or die "can't open $file: $!";
    print $fh @lines;
    close $fh;
}
