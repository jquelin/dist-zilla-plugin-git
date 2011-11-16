package Dist::Zilla::Role::Git::Repo;

use Moose::Role;

has 'repo_root'   => ( is => 'ro', isa => 'Str', default => '.' );

1;
