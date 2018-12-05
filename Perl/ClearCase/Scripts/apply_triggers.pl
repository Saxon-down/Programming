#!/user/bin/perl -w
##########################################################################
#                                                                        #
# apply_triggers.pl                                                      #
# v0.1                                                                   #
# Garry Short, 15/09/08                http://www.saxon-down.com/scripts #
#                                                                        #
# Applies all triggers as per the parameters passed to the script.       #
# Options include:                                                       #
#   -all            : finds each PVOB and it's component VOBs and        #
#                     applies the relevant triggers to each.             #
#                                                                        #
#   -pvob <vob_tag> : Applies the triggers to the specified PVOB and all #
#                     related component VOBs                             #
#   -comp <vob_tag> : Applies the triggers to the specified component    #
#                     VOB                                                #
#   -base <vob_tag> : Applies the triggers to a single, specified Base   #
#                     ClearCase VOB                                      #
#   -help           : Shows the helpfile for the script                  #
# This script will also automatically replace any existing triggers to   #
# make sure that they're all up to date and consistent                   #
#                                                                        #
##########################################################################

##########################################################################
#                                                                        #
# USEs, INCLUDEs, etc                                                    #
#                                                                        #
##########################################################################


##########################################################################
#                                                                        #
# Global constants & variables                                           #
#                                                                        #
##########################################################################

# Constants
my $passed_arg = $ARGV[0];              # Passed parameter
my $passed_vob = $ARGV[1];              # passed parameter
# VOB types
my $pvob_type = "PVOB";
my $comp_type = "COMP";
# Trigger commands
my $trigger_comp_rmelem = "cleartool mktrtype -element -all -preop rmelem" .
  " -nusers SVCVobAdmin,garry.short -exec \"ccperl \\\\vl2rat002\\" .
  "Trigger_Scripts\\deny.pl\" -nc NO_RMELEM\@";
my $trigger_comp_rmtrtype = "cleartool mktrtype -type -preop rmtype " .
  "-trtype -all -nusers SVCVobAdmin -exec \"ccperl \\\\vl2rat002\\" .
  "Trigger_Scripts\\deny.pl\" -nc NO_RMTRTYPE\@";
my $trigger_comp_eviltwin = "cleartool mktrtype -element -all -preop " .
  "mkelem -exec \"ccperl \\\\VL2RAT002\\Trigger_Scripts\\evilTwin.pl\" " .
  "-nc EVIL_TWIN\@";
my $trigger_comp_rmemptybranch = "cleartool mktrtype -element -all -preop " .
  "uncheckout -exec \"ccperl \\\\VL2RAT002\\Trigger_Scripts\\" .
  "rm_empty_branch.pl\" -nc RM_EMPTY_BRANCH\@";
my $trigger_comp_streamprotect = "cleartool mktrtype -element -all -preop " .
  "checkout -exec \"ccperl \\\\vl2rat002\\Trigger_scripts\\stream_" .
  "protection.pl\" -nc  STREAM_PROTECT\@";
my $trigger_comp_chown = "cleartool mktrtype -element -all " .
  "-postop mkelem -exec \"ccperl \\\\VL2RAT002\\Trigger_Scripts\\" .
  "chown.pl\" -nc CHOWN\@";
my $trigger_pvob_streamprotect = "cleartool mktrtype -ucm -all -preop " .
  "deliver_start,rebase_start,mkbl,chbl -exec \"ccperl \\\\vl2rat002\\" .
  "Trigger_scripts\\stream_protection.pl\" -nc  STREAM_PROTECT\@";
my $trigger_pvob_mkstream = "cleartool mktrtype -ucm -all -postop mkstream" .
  " -exec \"ccperl \\\\vl2rat002\\trigger_scripts\\mkstream.pl RENAME 15\"" .
  " -nc MKSTREAM\@";
my $trigger_pvob_rmtrtype = "cleartool mktrtype -type -preop rmtype " .
  "-trtype -all -nusers SVCVobAdmin -exec \"ccperl \\\\vl2rat002\\" .
  "Trigger_Scripts\\deny.pl\" -nc NO_RMTRTYPE\@";
# Component triggers list
my %triggers_comp = (
  "NO_RMELEM"           => $trigger_comp_rmelem,
  "NO_RMTRTYPE"         => $trigger_comp_rmtrtype,
  "EVIL_TWIN"           => $trigger_comp_eviltwin,
  "RM_EMPTY_BRANCH"     => $trigger_comp_rmemptybranch,
  "STREAM_PROTECT"      => $trigger_comp_streamprotect,
  "CHOWN"               => $trigger_comp_chown
);
# PVOB triggers list
my %triggers_pvob = (
  "STREAM_PROTECT"      => $trigger_pvob_streamprotect,
  "NO_RMTRTYPE"         => $trigger_pvob_rmtrtype,
  "MKSTREAM"            => $trigger_pvob_mkstream
);


# Variables
my $comp_vobs;


##########################################################################
#                                                                        #
# Subroutines                                                            #
#                                                                        #
##########################################################################

sub Apply_Triggers {            # $vob_tag, $vob_type
  #
  my ($vob, $type) = (@_);
  my (%existing, %trigger_list);
  # Get a list of the triggers that currently exist on the VOB
  my @current = qx/cleartool lstype -kind trtype -s -invob $vob/;
  chomp @current;
  foreach my $tr (sort @current) {
    $existing{$tr} = 1;
  }
  # Populate %trigger_list according to the VOB type we're applying them to
  if ($type eq $pvob_type) {
    %trigger_list = %triggers_pvob;
  } else {
    %trigger_list = %triggers_comp;
  }
  # Now apply each trigger to the VOB
  foreach my $trigger (sort keys %trigger_list) {
    my $tr_command = $trigger_list{$trigger};
    if ($existing{$trigger}) {
      # This trigger already exists, so replace it
      $tr_command =~ s/mktrtype/mktrtype -replace/;
      print "Replacing trigger ... ";
    }
    $tr_command .= $vob;    # Append the VOB tag to the trigger command
    print "Applying the $trigger trigger to the $vob VOB\n";
    qx/$tr_command/;            # Execute the command
  }
}


sub Display_Help {
  # Displays the usage help file for this script
  #
  print "
    APPLY_TRIGGERS.PL HELP
    ======================
    
    Automatically applies the relevant triggers according to the parameter
    you use, updating any existing triggers it finds to ensure that they're
    up to date and consistent across the board.
    
    PARAMETERS:
    \t-all            : Scans all existing VOBs to find the PVOBs, then 
    \t                  generates a list of component VOBs for each PVOB.
    \t                  It then applies the triggers to everything it's
    \t                  found.
    \t-pvob <vob_tag> : Generates a list of component VOBs related to the
    \t                  specified PVOB, and applies the relevant triggers
    \t                  accordingly.
    \t-comp <vob_tag> : Applies the relevant triggers to the specified
    \t                  component VOB.
    \t-base <vob_tag> : Applies the triggers to a single Base ClearCase VOB
   

  ";
}               # end Display_Help


sub Find_Component_VOBs {               # $pvob
  # When passed a PVOB, finds and returns a list of associated component VOBs
  #
  my ($pvob) = (@_);
  my %return;
  # Generate a list of related components.
  my @components = qx/cleartool lscomp -s -invob $pvob/;
  foreach my $comp (@components) {      # For each component ..
    chomp $comp;                        # .. strip off the newline ..
    my @details = qx/cleartool lscomp $comp\@$pvob/;    # .. get details ..
    # .. and find the component VOB it lives in
    my $comp_vob = "\\" . (split /\\/, $details[-1])[1]; 
    chomp $comp_vob;
    $comp_vob =~ s/"//g;
    $return{$comp_vob} = 1;     # Now add it to the return hash
  }
  return \%return;
}               # Find_Component_VOBs


sub Find_PVOBs {
  # Scans the list of existing VOBs and returns just the PVOBs. These are
  # filtered according to a suffix of _pvob
  #
  my @return;
  my @all_vobs = qx/cleartool lsvob -s/;
  foreach my $vob (sort @all_vobs) {
    next unless $vob =~ /_pvob$/i;
    chomp $vob;
    push (@return, $vob);
  }
  return \@return;
}               # Find_PVOBs


##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  if (! $passed_arg) {
    &Display_Help;
  } elsif ($passed_arg =~ /^-all$/i) {
    my $pvobs = &Find_PVOBs();
    foreach my $pvob (@$pvobs) {
      &Apply_Triggers($pvob, $pvob_type);
      $comp_vobs = &Find_Component_VOBs($pvob);
      foreach my $cvob (sort keys %$comp_vobs) {
        &Apply_Triggers($cvob, $comp_type);
      }
    }
  } elsif ($passed_arg =~ /^-pvob$/i) {
    &Apply_Triggers($passed_vob, $pvob_type);
    $comp_vobs = &Find_Component_VOBs($passed_vob);
    foreach my $cvob (sort keys %$comp_vobs) {
      &Apply_Triggers($cvob, $comp_type);
    }
  } elsif ($passed_arg =~ /^-comp$/i) {
    &Apply_Triggers($passed_vob, $comp_type);
  } elsif ($passed_arg =~ /^-base$/i) {
    &Apply_Triggers($passed_vob, $comp_type);
  } else {
    # Looks like they've specified an invalid parameter, so display the help
    &Display_Help;
  }
}
