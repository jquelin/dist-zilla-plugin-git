# taken from DZP::ArchiveRelease, thanks CJM!
package Dist::Zilla::Plugin::MyTestArchiver;
use Moose;
use Moose::Autobox;
use Path::Class::Dir ();
use File::Copy ();

with 'Dist::Zilla::Role::Releaser';

sub release {
    my ($self, $tgz) = @_;

    chmod(0444, $tgz);
    my $dir = 'releases';
    mkdir $dir or $self->log_fatal( "Unable to create directory $dir: $!" );
    my $dest = Path::Class::Dir->new( $dir )->file($tgz->basename);
    File::Copy::move($tgz, $dest) or $self->log_fatal( "Unable to move: $!" );
    $self->log("Moved $tgz to $dest");
}

1;
