package Dist::Zilla::Plugin::Git::Role::Repo;

use Moose::Role;

has 'repo_root'   => ( is => 'ro', isa => 'Str', default => '.' );

1;
