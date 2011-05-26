#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
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
