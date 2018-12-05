#!perl
########################################################################
# When uncheckouts are performed, remove the parent branch
# if it has no checkouts, sub-branches or labeled versions
# associated with it, but only IFF the uncheckout file is the 0th
# element or removing the branch causes the parent branch to also be
# "empty".
########################################################################

# This trigger is believed to work with ccperl (5.001).
require 5.001;

# Conceptually this is "use constant MSWIN ..." but ccperl can't do that.
# Perl 5.005 and above uses MSWin32, prior versions use Windows_NT.
sub MSWIN { ($^O || $ENV{OS}) =~ /MSWin32|Windows_NT/i ? 1 : 0 }

# On Windows we must rely on PATH to find cleartool. On Unix,
# /usr/atria/bin/cleartool is always a valid path so we use it.
my $CT = MSWIN() ? 'cleartool' : '/usr/atria/bin/cleartool';

# Windows portability hack - turn \ into / in key EV values.
if (MSWIN()) {
    for (@ENV{qw(CLEARCASE_ID_STR CLEARCASE_XPN)}) { s%\\%/%g }
}

# Quit right away unless we're looking at a /0 version.
exit 0 if $ENV{CLEARCASE_OP_KIND} eq 'uncheckout' &&
	  $ENV{CLEARCASE_ID_STR} !~ m%/0$%;

# Derive the name of the parent branch (relies on perl greedy RE's).
my($xname) = ($ENV{CLEARCASE_XPN} =~ m%(.+)/.+%);

# Never try to remove the main branch!
exit 0 if $xname =~ m%/main$%;

# Check if there are other versions, other branches, labels, or checked
# out versions on this branch: if so, don't do anything. Snapshot views
# have no view-extended space so we need 'cleartool lsvt' to get the
# equivalent data.
if (opendir(VER, $xname)) {
    #### Dynamic-view case ####
    my @all = readdir VER;
    closedir(VER);
    exit 0 unless @all == 4;	# magic number: qw(. .. LATEST 0)
    if (MSWIN()) {
	# No sense scaring naive users with messages
	close(STDOUT) unless $ENV{CLEARCASE_TRACE_TRIGGERS};
	exit(system($CT, qw(rmbranch -force -nc), qq("$xname"))>>8);
    } else {
	exec($CT, qw(rmbranch -force -nc), $xname);
    }
} else {
    #### Snapshot-view case ####
    my @vt = qx($CT lsvt -a -obs "$xname");
    # Probably redundant with the CLEARCASE_ID_STR check above.
    exit 0 if @vt > 2;
    # If there's any metadata on the /0 version, leave it alone.
    exit 0 if $vt[1] =~ m%\s\(.*\)$%;
    # No sense scaring naive users with messages
    close(STDOUT) unless $ENV{CLEARCASE_TRACE_TRIGGERS};
    if (MSWIN()) {
	system($CT, qw(rmbranch -force -nc), qq("$xname")) && exit $?;
	exit system($CT, qw(update -log NUL), qq("$ENV{CLEARCASE_PN}"));
    } else {
	system($CT, qw(rmbranch -force -nc), $xname) && exit $?;
	exec($CT, qw(update -log /dev/null), $ENV{CLEARCASE_PN});
    }
}

__END__

=pod

=head1 DESCRIPTION

This trigger handles removing empty branches after an unco operation.
It handles UNIX and Windows, dynamic and snapshot views, and requires
a modern (5.004+) build of Perl.

=head1 AUTHOR

David Boyce (dsb@cleartool.com)

=head1 COPYRIGHT

Copyright (c) 1998-2002 David Boyce (dsb@cleartool.com), Clear Guidance
Consulting.  All rights reserved.

=cut

