
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Dist::Zilla::Role::Releaser' => '0',
    'Dist::Zilla::Tester' => '0',
    'File::Copy' => '0',
    'File::Copy::Recursive' => '0',
    'File::Find' => '0',
    'File::pushd' => '0',
    'Module::Build' => '0.3601',
    'Path::Class' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'update your git repository after release',
  'dist_author' => [
    'Jerome Quelin'
  ],
  'dist_name' => 'Dist-Zilla-Plugin-Git',
  'dist_version' => '1.112060',
  'license' => 'perl',
  'module_name' => 'Dist::Zilla::Plugin::Git',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Class::MOP' => '0',
    'Cwd' => '0',
    'DateTime' => '0',
    'Dist::Zilla' => '4',
    'Dist::Zilla::Role::AfterBuild' => '0',
    'Dist::Zilla::Role::AfterMint' => '0',
    'Dist::Zilla::Role::AfterRelease' => '0',
    'Dist::Zilla::Role::BeforeRelease' => '0',
    'Dist::Zilla::Role::PluginBundle' => '0',
    'Dist::Zilla::Role::VersionProvider' => '0',
    'File::Spec::Functions' => '0',
    'File::Temp' => '0',
    'File::chdir' => '0',
    'Git::Wrapper' => '0',
    'IPC::Open3' => '0',
    'Moose' => '0',
    'Moose::Autobox' => '0',
    'Moose::Role' => '0',
    'MooseX::Has::Sugar' => '0',
    'MooseX::Types::Moose' => '0',
    'Path::Class::Dir' => '0',
    'String::Formatter' => '0',
    'Version::Next' => '0',
    'namespace::autoclean' => '0.09',
    'perl' => '5.010',
    'version' => '0.80'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
