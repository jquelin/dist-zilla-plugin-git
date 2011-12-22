#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dist::Zilla::Role::Git::Repo;
{
  $Dist::Zilla::Role::Git::Repo::VERSION = '1.113560';
}

# ABSTRACT: Provide repository information for Git plugins

use Moose::Role;

has 'repo_root'   => ( is => 'ro', isa => 'Str', default => '.' );


1;




=pod

=head1 NAME

Dist::Zilla::Role::Git::Repo - Provide repository information for Git plugins

=head1 VERSION

version 1.113560

=head1 DESCRIPTION

This role is used within the git plugin to get information about the repository structure.

=head1 ATTRIBUTES

=head2 repo_root

The repository root, either as a full path or relative to the distribution root. Default is C<.>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

