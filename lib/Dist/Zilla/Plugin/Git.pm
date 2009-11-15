use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git;
# ABSTRACT: update your git repository after release


1;
__END__

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git]

=head1 DESCRIPTION

This plugin is called after you released your distribution, and does the
following actions:

=over 4

=item * commit your changelog (and your dzil config if you update the
version manually) to git. The commit message will be the changelog entry
for this release.

=item * create a tag named C<v$VERSION>.

=item * push the branch and the tags to your remote repository. Since
it's a simple push, it means that the remotes should be correctly
configured in your local repository.

=back



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

L<http://github.com/jquelin/dist-zilla-plugin-git.git>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-Plugin-Git>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Git>

=back

