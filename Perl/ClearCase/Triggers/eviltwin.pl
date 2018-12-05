#!/usr/local/bin/perl -w

# This trigger is believed to work with ccperl (5.001), though it is
# strongly recommended that ccperl not be used and I will not support
# it in a ccperl configuration.
require 5.001;

# Allow knowledgeable users to short-circuit the trigger with this EV.
BEGIN { exit 0 if $ENV{CLEARCASE_SKIP_MKELEM_PRE} }

# Ensure that the view-private file will get named back on rejection.
BEGIN {
    END {
	rename("$ENV{CLEARCASE_PN}.mkelem", $ENV{CLEARCASE_PN})
	    if $? && ! -e $ENV{CLEARCASE_PN} && -e "$ENV{CLEARCASE_PN}.mkelem";
    }
}

# Conceptually this is "use constant MSWIN ..." but ccperl can't do that.
# Perl 5.005 and above uses 'MSWin32', prior versions use 'Windows_NT'.
sub MSWIN { ($^O || $ENV{OS}) =~ /MSWin32|Windows_NT/i ? 1 : 0 }

# On Windows we must rely on PATH to find cleartool. On Unix,
# /usr/atria/bin/cleartool is always a valid path so we use it.
my $CT = MSWIN() ? 'cleartool' : '/usr/atria/bin/cleartool';

# Derive the filename and dir parts of the element-to-be.
use File::Basename;
my $pn = $ENV{CLEARCASE_PN};
$pn =~ s%\\%/%g if MSWIN();	# because dirname() is broken in ccperl
my $base = basename($pn);
my $dir = dirname($pn);

# Derive a list of the versioned elements in $dir.
my %found = map {chomp; lc(basename($_)) => $_} qx($CT ls -vob -s -nxn "$dir");

# Now check that we don't already have something which differs only by case.
die "Error: case collision between '$pn' and '$found{lc($base)}'\n"
	if $found{lc($base)};

# Just in case the site has changed their extended naming symbol from '@@'.
my $sfx = $ENV{CLEARCASE_XN_SFX} || '@@';

# Are we in a snapshot view?
my $snapview;
if (exists($ENV{CLEARCASE_VIEW_KIND})
	&& $ENV{CLEARCASE_VIEW_KIND} ne 'dynamic') {
    $snapview = 1;
} else {
    # The 2nd test is a special case for the vob root.
    $snapview = ! -e "$dir$sfx/main" && ! -e "$dir/$sfx/main";
}

# Last, look for a file by the same name (case sensitive) in a previous
# version of the directory. This situation is complicated by the
# need to consider snapshot views, and by a design requirement to
# allow people who don't know better to use ccperl 5.001 (this is
# why we do all the closing and reopening of file descriptors).
my $dupver = 0;
{
    local(*SAVE_STDOUT, *SAVE_STDERR);
    open(SAVE_STDOUT, '>&STDOUT');
    open(SAVE_STDERR, '>&STDERR');
    close(STDOUT);
    close(STDERR);
    for (reverse qx($CT lsvtree -a -s -obs -nco "$dir")) {
	chomp;
	$dupver = $_ if ($snapview ?
	    system(qq($CT desc -s "$_/$base$sfx/main")) == 0 :
	    -e "$_/$base$sfx/main");
	if ($dupver) {
	    $dupver =~ s%\\%/%g;			# normalize path sep
	    $dupver =~ s%(.*/)(.*$sfx.*)%$2%;		# strip directory part
	    last;
	}
    }
    open(STDOUT, '>&SAVE_STDOUT');
    open(STDERR, '>&SAVE_STDERR');
}

# No duplicate found, allow operation to proceed.
exit 0 unless $dupver;

# Now, we can either die or ask the user what to do.
my $msg = "duplicate name '$base' found in directory version $dupver";
die("Error: $msg\n");
#exit(system(qw(clearprompt proceed -def a -pro), "Warning: $msg\n") != 0);

__END__

=head1 DESCRIPTION

This trigger implements two similar-but-different policies:

=over 4

=item *

No element can be created if an element with an I<identical name
(including case)> exists in a prior version of the directory. This
is a so-called evil twin.

=item *

No element can be created if an element already exists I<in the same
version of the directory> whose name is the same except for case.  This
is not an evil twin but approximates one on a case-insensitive
filesystem such as Windows. The trigger discourages these pairings in
order to avoid confusion on Windows.

=back

The algorithm is complicated by the possibility of snapshot views
where version-extended space is not available.

=head1 AUTHOR

David Boyce (dsb@cleartool.com)

=head1 COPYRIGHT

Copyright (c) 1998-2002 David Boyce (dsb@cleartool.com), Clear Guidance
Consulting.  All rights reserved.

