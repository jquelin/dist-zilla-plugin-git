package Dist::Zilla::Plugin::Git::Init;
# ABSTRACT: initialize git repository on dzil new

use Moose;
use Git::Wrapper;

with 'Dist::Zilla::Role::AfterMint';

has commit_message => (
    is      => 'ro',
    isa     => 'Str',
    default => 'initial commit',
);

sub after_mint {
    my $self = shift;
    my ($opts) = @_;
    my $git = Git::Wrapper->new($opts->{mint_root});
    $self->log("Initializing a new git repository in " . $opts->{mint_root});
    $git->init;
    $git->add($opts->{mint_root});
    $git->commit({message => $self->commit_message});
}

1;
