#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Dist::Zilla::PluginBundle::Git;
{
  $Dist::Zilla::PluginBundle::Git::VERSION = '1.120970';
}
# ABSTRACT: all git plugins in one go

use Moose;
use Class::MOP;

with 'Dist::Zilla::Role::PluginBundle';

# bundle all git plugins
my @names   = qw{ Check Commit Tag Push };

my %multi;
for my $name (@names) {
    my $class = "Dist::Zilla::Plugin::Git::$name";
    Class::MOP::load_class($class);
    @multi{$class->mvp_multivalue_args} = ();
}

sub mvp_multivalue_args { keys %multi; }

sub bundle_config {
    my ($self, $section) = @_;
    #my $class = ( ref $self ) || $self;
    my $arg   = $section->{payload};

    my @config;

    for my $name (@names) {
        my $class = "Dist::Zilla::Plugin::Git::$name";
        my %payload;
        foreach my $k (keys %$arg) {
            $payload{$k} = $arg->{$k} if $class->can($k);
        }
        push @config, [ "$section->{name}/$name" => $class => \%payload ];
    }

    return @config;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;


=pod

=head1 NAME

Dist::Zilla::PluginBundle::Git - all git plugins in one go

=head1 VERSION

version 1.120970

=head1 SYNOPSIS

In your F<dist.ini>:

    [@Git]
    changelog   = Changes             ; this is the default
    allow_dirty = dist.ini            ; see Git::Check...
    allow_dirty = Changes             ; ... and Git::Commit
    commit_msg  = v%v%n%n%c           ; see Git::Commit
    tag_format  = %v                  ; see Git::Tag
    tag_message = %v                  ; see Git::Tag
    push_to     = origin              ; see Git::Push

=head1 DESCRIPTION

This is a plugin bundle to load all git plugins. It is equivalent to:

    [Git::Check]
    [Git::Commit]
    [Git::Tag]
    [Git::Push]

The options are passed through to the plugins.

=for Pod::Coverage bundle_config
    mvp_multivalue_args

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

