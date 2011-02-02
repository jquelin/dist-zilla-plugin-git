use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git;
# ABSTRACT: update your git repository after release

use Dist::Zilla 2.100880;    # Need mvp_multivalue_args in Plugin role
1;
__END__


=head1 DESCRIPTION

This set of plugins for L<Dist::Zilla> can do interesting things for
module authors using L<git|http://git- scm.com> to track their work. The
following plugins are provided in this distribution:

=over 4

=item * L<Dist::Zilla::Plugin::Git::Check>

=item * L<Dist::Zilla::Plugin::Git::Commit>

=item * L<Dist::Zilla::Plugin::Git::CommitBuild>

=item * L<Dist::Zilla::Plugin::Git::Init>

=item * L<Dist::Zilla::Plugin::Git::NextVersion>

=item * L<Dist::Zilla::Plugin::Git::Push>

=item * L<Dist::Zilla::Plugin::Git::Tag>

=back

A L<Dist::Zilla::PluginBundle::Git> bundle is also provided for your
convenience, check its documentation to see which plugins it will load.



=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-Git>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-Git>

=item * Mailing-list (same as L<Dist::Zilla>)

L<http://www.listbox.com/subscribe/?list_id=139292>

=item * Git repository

L<http://github.com/jquelin/dist-zilla-plugin-git>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-Plugin-Git>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Git>

=back

