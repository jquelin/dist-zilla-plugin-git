use strict;
use warnings;

use Dist::Zilla::Tester;
use Git::Wrapper;
use Path::Class;
use File::pushd qw/pushd tempd/;
use File::Copy::Recursive qw/dircopy/;

use Test::More 0.88 tests => 6;

# we chdir around so make @INC absolute
BEGIN { 
  @INC = map {; ref($_) ? $_ : dir($_)->absolute->stringify } @INC;
}

# save absolute corpus directory path
my $corpus_dir = dir('corpus/version-default')->absolute;

# isolate repo directory from possible git actions from bugs
my $tempd = tempd;

## shortcut for new tester object
sub _new_zilla {
  my $root = shift;
  return Dist::Zilla::Tester->from_config({
    dist_root => $corpus_dir,
  });
}

## Tests start here

my ($zilla, $version);
$zilla = _new_zilla;
# enter the temp source dir and make it a git dir
my $wd = pushd( $zilla->tempdir->subdir('source')->stringify );

system "git init";
my $git   = Git::Wrapper->new('.');
$git->add(".");
$git->commit({ message => 'import' });

# with no tags and no initialization, should get default
$zilla = _new_zilla;
$version = $zilla->version;
is( $version, "0.001", "default is 0.001" );

# initialize it
{
    local $ENV{V} = "1.23";
    $zilla = _new_zilla;
    is( $zilla->version, "1.23", "initialized with \$ENV{V}" );
}

# tag it
$git->tag("v1.2.3");
ok( (grep { /v1\.2\.3/ } $git->tag), "wrote v1.2.3 tag" );

{
    $zilla = _new_zilla;
    is( $zilla->version, "1.2.4", "initialized from last tag" );
}

# tag it
$git->tag("v1.23");
ok( (grep { /v1\.23/ } $git->tag), "wrote v1.23 tag" );

{
    $zilla = _new_zilla;
    is( $zilla->version, "1.24", "initialized from last tag" );
}



done_testing;

