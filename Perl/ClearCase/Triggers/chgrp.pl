#!/usr/bin/perl -w
###########################################################################
#                                                                         #
# Garry Short, 07/11/12                                                   #
# chgrp.pl v0.1                                                           #
#                                                                         #
# chgrp.pl is a trigger which uses a config file, chgrp.cfg (stored in    #
# the same folder) to determine what the default group should be for all  #
# elements in a given VOB. It is linked to the mkelem action as a POSTOP  #
# trigger to change the group owner when required.                        #
#                                                                         #
# History                                                                 #
# =======                                                                 #
# v0.1 Initial version                                                    #
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

my $config_file = "\\\\denu01asp001.symphonyteleca.com\\triggers\\chgrp.cfg";
my $current_vob = $ENV{"CLEARCASE_VOB_PN"};
my $current_elem = $ENV{"CLEARCASE_PN"};
my $default_group = "DE-NU-CLC-JLR-USR";


###########################################################################
#                                                                         #
# SUBROUTINES                                                             #
#                                                                         #
###########################################################################

sub Has_Special_Group {         # $current_vob
  # Takes the current VOB, then reads the config file and looks for a match.
  # Returns $group if it finds a match, or 0 otherwise.
  #
  my ($current_vob) = (@_);
  $current_vob =~ s/^.//;
  open CONFIG_FILE, $config_file or &Generate_Error("CONFIG_FILE");
  chomp (my @file = <CONFIG_FILE>);
  close CONFIG_FILE;
  my %map;
  foreach my $line (@file) {
    next if $line =~ /^#/;      # Ignore comments
    chomp $line;
    my ($vob, $group) = split /  /, $line;
    $map{$vob} = $group;
  }
  if ($map{$current_vob}) {
    # Current VOB is listed in the config file
    return $map{$current_vob};
  } else {
    # No match, so don't need to do anything.
    return 0;
  }
}


sub Generate_Error {            # $error_string
  # Takes an error string to identify the error, and generates the 
  # appropriate message before terminating.
  #
  my ($error_string) = (@_);
  # In the following $prompt_cmd variable, CHGRP_PROMPT needs to be replaced
  # with a valid string before use.
  my $prompt_cmd = "clearprompt proceed -type error -default abort " .
        "-mask abort -prompt \"CHGRP_PROMPT\"";
  my $prompt_string = "";
  # Find which error code we've been passed.
  if ($error_string eq "CONFIG_FILE") {
    # The config file is missing; ask the user to inform CC Admins, and 
    # abort the action.
    # To fix, copy the config file from ClearCase to the relevant TRIGGERS
    # share
    $prompt_string = "Cannot find CONFIG file; \n";
  } elsif ($error_string =~ /^UNKNOWN_GROUP/) {
    # The domain group we've been told to use cannot be found
    # To fix, either correct the CONFIG file or have the group created
    $error_string =~ s/^UNKNOWN_GROUP_//;
    $prompt_string = "Cannot find group $error_string; \n";
  } elsif ($error_string =~ /^MISSING_GROUP_/) {
    # The domain group we've been told hasn't been added to the VOB's list;
    # To fix, run cleartool protectvob -add_group
    $error_string =~ s/^MISSING_GROUP_//;
    $prompt_string = "Group $error_string hasn't been added to VOB " .
          "$current_vob; \n";
  } else {
    # The error we've been passed is undefined!
    $prompt_string = "Unknown error; \n";
  }
  $prompt_string .= "Please screenshot this ERROR MESSAGE and forward it " .
    "to your ClearCase Administrator\n\ntrigger = chgrp\n" .
    "element = $current_elem";
  # Output the error_string we've defined
  $prompt_cmd =~ s/CHGRP_PROMPT/$prompt_string/;
  qx/$prompt_cmd/;
  exit 1;          # Now the error's been displayed, stop processing.
}


###########################################################################
#                                                                         #
# MAIN SCRIPT                                                             #
#                                                                         #
###########################################################################

{
  my $groupname = &Has_Special_Group($current_vob);
  # If there isn't a special group, use the default group instead
  $groupname = $default_group unless $groupname;
  if ($groupname) {
    # The current VOB has a specific group ownership
    my $output = 
      qx/cleartool protect -chown desaccad -chgrp $groupname -chmod 775 -nc \"$current_elem\" 2>&1/;
    print "OUTPUT=[$output]\n";
    if ($output =~ /Error: Unknown group name:/) {
      &Generate_Error("UNKNOWN_GROUP_$groupname");
    } elsif ($output =~ /not in the VOB/) {
      &Generate_Error("MISSING_GROUP_$groupname");
    }
  }
}


