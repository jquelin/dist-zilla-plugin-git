use strict;
use warnings;
use Test::More 0.88;
# This is a relatively nice way to avoid Test::NoWarnings breaking our
# expectations by adding extra tests, without using no_plan.  It also helps
# avoid any other test module that feels introducing random tests, or even
# test plans, is a nice idea.
our $success = 0;
END { $success && done_testing; }

my $v = "\n";

eval {                     # no excuses!
    # report our Perl details
    my $want = '5.010';
    my $pv = ($^V || $]);
    $v .= "perl: $pv (wanted $want) on $^O from $^X\n\n";
};
defined($@) and diag("$@");

# Now, our module version dependencies:
sub pmver {
    my ($module, $wanted) = @_;
    $wanted = " (want $wanted)";
    my $pmver;
    eval "require $module;";
    if ($@) {
        if ($@ =~ m/Can't locate .* in \@INC/) {
            $pmver = 'module not found.';
        } else {
            diag("${module}: $@");
            $pmver = 'died during require.';
        }
    } else {
        my $version;
        eval { $version = $module->VERSION; };
        if ($@) {
            diag("${module}: $@");
            $pmver = 'died during VERSION check.';
        } elsif (defined $version) {
            $pmver = "$version";
        } else {
            $pmver = '<undef>';
        }
    }

    # So, we should be good, right?
    return sprintf('%-45s => %-10s%-15s%s', $module, $pmver, $wanted, "\n");
}

eval { $v .= pmver('Class::MOP','any version') };
eval { $v .= pmver('Cwd','any version') };
eval { $v .= pmver('DateTime','any version') };
eval { $v .= pmver('Dist::Zilla','4') };
eval { $v .= pmver('Dist::Zilla::Role::AfterBuild','any version') };
eval { $v .= pmver('Dist::Zilla::Role::AfterMint','any version') };
eval { $v .= pmver('Dist::Zilla::Role::AfterRelease','any version') };
eval { $v .= pmver('Dist::Zilla::Role::BeforeRelease','any version') };
eval { $v .= pmver('Dist::Zilla::Role::PluginBundle','any version') };
eval { $v .= pmver('Dist::Zilla::Role::Releaser','any version') };
eval { $v .= pmver('Dist::Zilla::Role::VersionProvider','any version') };
eval { $v .= pmver('Dist::Zilla::Tester','any version') };
eval { $v .= pmver('File::Copy','any version') };
eval { $v .= pmver('File::Copy::Recursive','any version') };
eval { $v .= pmver('File::Find','any version') };
eval { $v .= pmver('File::Path','any version') };
eval { $v .= pmver('File::Spec::Functions','any version') };
eval { $v .= pmver('File::Temp','any version') };
eval { $v .= pmver('File::Which','any version') };
eval { $v .= pmver('File::chdir','any version') };
eval { $v .= pmver('File::pushd','any version') };
eval { $v .= pmver('Git::Wrapper','any version') };
eval { $v .= pmver('IPC::Open3','any version') };
eval { $v .= pmver('List::Util','any version') };
eval { $v .= pmver('Module::Build','0.3601') };
eval { $v .= pmver('Moose','any version') };
eval { $v .= pmver('Moose::Autobox','any version') };
eval { $v .= pmver('Moose::Role','any version') };
eval { $v .= pmver('MooseX::AttributeShortcuts','any version') };
eval { $v .= pmver('MooseX::Has::Sugar','any version') };
eval { $v .= pmver('MooseX::Types::Moose','any version') };
eval { $v .= pmver('Path::Class','any version') };
eval { $v .= pmver('Path::Class::Dir','any version') };
eval { $v .= pmver('String::Formatter','any version') };
eval { $v .= pmver('Test::Exception','any version') };
eval { $v .= pmver('Test::More','0.88') };
eval { $v .= pmver('Version::Next','any version') };
eval { $v .= pmver('namespace::autoclean','0.09') };
eval { $v .= pmver('strict','any version') };
eval { $v .= pmver('version','0.80') };
eval { $v .= pmver('warnings','any version') };



# All done.
$v .= <<'EOT';

Thanks for using my code.  I hope it works for you.
If not, please try and include this output in the bug report.
That will help me reproduce the issue and solve you problem.

EOT

diag($v);
ok(1, "we really didn't test anything, just reporting data");
$success = 1;

# Work around another nasty module on CPAN. :/
no warnings 'once';
$Template::Test::NO_FLUSH = 1;
exit 0;
