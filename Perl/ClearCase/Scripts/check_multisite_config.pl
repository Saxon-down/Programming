#!/usr/bin/perl -w
###########################################################################
#                                                                         #
# Garry Short, 24/04/13                                                   #
# check_multisite_config.pl v1.0                                          #
#                                                                         #
# <DESCRIPTION>                                                           #
# ClearCase Multisite has been configured to replicate VOBs only to the   #
# next site in the chain. That configuration is handled by custom         #
# scheduled jobs and config files, which are prone to human error. This   #
# script scans those config files and checks for irregularities.          #
#                                                                         #
# <NOTES>                                                                 #
# - Assumes that each destination site has it's own config file           #
# - Must be run locally on each VOB Server                                #
# - Assumes replica names are of the format <VOB_TAG>_<SITE_ID>           #
#           (e.g. ngi_pvob_si_stc_ger, where VOB_TAG=ngi_pvob_si, and     #
#           SITE_ID=stc_ger)                                              #
#                                                                         #
# History                                                                 #
# =======                                                                 #
# v1.0 Initial version                                                    #
#                                                                         #
###########################################################################

###########################################################################
#                                                                         #
# USEs, INCLUDEs, etc                                                     #
#                                                                         #
###########################################################################

###########################################################################
#                                                                         #
# GLOBAL CONSTANTS AND VARIABLES                                          #
#                                                                         #
###########################################################################

# path to where the config files are kept
my $config_path = $ENV{"RATIONAL_HOME"} .
        "\\ClearCase\\config\\multisite\\";


###########################################################################
#                                                                         #
# SUBROUTINES                                                             #
#                                                                         #
###########################################################################

sub Get_File_List {
  # Scans the directory and generates a list of config files; it then calls
  # &Scan_File() to scan each file in turn.
  opendir DIR, $config_path or die "Can't find $config_path: $!\n";
  chomp (my @files = readdir DIR);
  closedir DIR;
  foreach my $f (@files) {
    next if $f =~ /^\.\.?$/;
    &Scan_File($f);
  }
}


sub Scan_File {         # $filename
  # Takes a config file and scans it for errors.
  #
  my $filename = $config_path . $_[0];
  my $master;   # assumes all entries should point to the same destination,
        # so flags errors for any which doesn't match the first entry.
  open FILE, $filename or die "Cannot open file $filename: $!\n";
  print "\n$_[0]\n================================\n";
  chomp (my @file = <FILE>);
  close FILE;
  my $line_count = 0;
  foreach my $line (@file) {
    # Process file line-by-line
    $line_count++;
    next if $line eq "";        # Empty line, ignore it
    # Lines must be of the format "replicas:<replica>@<VOB>
    my ($replica_string, $replica, $vob) = split /[:@]/, $line;
    my $repl = $replica;
    $vob =~ s/\\//;     # Don't want the \, it messes up matches
    my @errors;         # Keep a list of errors so we can group them up
    # Possible errors:
    # 1) "replicas" has been typed incorrectly
    push (@errors, "TYPO $replica_string vs replicas") unless 
                ($replica_string eq "replicas");
    # 2) There's a typo in the replica name - it doesn't match the VOB tag
    push (@errors, "VOB_MISMATCH $replica vs $vob") unless
                ($replica =~ s/$vob//);
    $replica =~ s/^_//;
    $master = $replica unless $master;
    # 3) There's a typo in the replica name - the site is different
    push (@errors, "REPL_MISMATCH $replica vs $master") unless
                ($replica =~ /$master$/);
    chomp (my $ccvob = qx/cleartool lsvob -s \\$vob 2>&1/);
    # 4) There's a typo in the VOB tag; ClearCase can't find it
    push (@errors, "VOB_MISSING $vob not found") unless
                ($ccvob =~ /^\\$vob$/);
    chomp (my $ccreplica = qx/multitool lsreplica -s $repl\@\\$vob 2>&1/);
    # 5) There's a typo in the replica name; ClearCase can't find it
    push (@errors, "REPLICA_MISSING $repl not found") unless
                ($ccreplica eq $repl);
    if (@errors) {
      # We've found 1 or more errors, so ...
      print "ERROR line $line_count [$line]:\n";
      # Print the line number where we found the error, and include the text
      foreach my $line (@errors) { print "\t$line\n"; }
      # Print each error we found
    }
  }
}

###########################################################################
#                                                                         #
# MAIN SCRIPT                                                             #
#                                                                         #
###########################################################################

{
  &Get_File_List();
}


