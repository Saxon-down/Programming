#!/user/bin/perl -w
##########################################################################
#                                                                        #
# stream_protection.pl                                                   #
# v0.4                                                                   #
# Garry Short, 17/09/08                                                  #
# perl@saxon-down.com    ##    http://www.saxon-down.com/scripts         #
#                                                                        #
# Trigger script to check permissions on certain UCM actions depending   #
# on which stream the action's performed in.                             #
# Allows for the use of an override file, allowing you to change         #
# permissions for a specific user for a specific PVOB (or * for all      #
# PVOBs)                                                                 #
#                                                                        #
# HISTORY:                                                               #
# v0.4 17/09/08                                                          #
#      Finally pushed v0.3 live and found a bug; this fixes it.          #
# v0.3 17/06/08                                                          #
#      Found a problem in that creds only returns 32 groups; going to    #
#      use "net user <user> /DOMAIN" instead                             #
# v0.2 17/06/08                                                          #
#      Fixing problem with permission overrides. Also added more info to #
#      the logfile                                                       #
# v0.1 16/05/08                                                          #
#      Initial Version                                                   #
#                                                                        #
##########################################################################

##########################################################################
#                                                                        #
# USEs, INCLUDEs, etc                                                    #
#                                                                        #
##########################################################################

use Time::Localtime;


##########################################################################
#                                                                        #
# Global constants & variables                                           #
#                                                                        #
##########################################################################

# Constants
# Paths for input / output files
my $config = "\\\\vl2rat002\\Trigger_scripts\\permissions.cfg";
my $logfile = "\\\\vl2rat002\\LOGS\$\\stream_actions.log";
# ClearCase environment variables
my $cc_performed_action = $ENV{"CLEARCASE_OP_KIND"};
my $deliver_rebase = ($ENV{"CLEARCASE_POP_KIND"} or "");
my $cc_stream = ($ENV{"CLEARCASE_STREAM"} or $ENV{"CLEARCASE_BRTYPE"});
my $cc_stream_stored = $cc_stream;
my $cc_user = $ENV{"CLEARCASE_USER"};
my $cc_xpn = $ENV{"CLEARCASE_BRTYPE"};
my $cc_vob = $ENV{"CLEARCASE_VOB_PN"};
# Domain groups
my $admin_group = "\\\*ClearCase";
my $LAPs_group = "\\\*LAPs";


# Variables
my $actions;
my $permissions;
my $streams;
my $comment;


##########################################################################
#                                                                        #
# Subroutines                                                            #
#                                                                        #
##########################################################################

sub Generate_Timestamp {
  # Generates a timestamp to be used for the logfile.
  #
  my $stamp;
  my (@elems) = (localtime)[0..5];
  $elems[5] -= 100;  # Years since 1900; switch to Years since 2000
  $elems[4] += 1;    # Jan is normally 0, so make it more human-readable
  # Create formatted time and date of the form DD/MM/YY and HH:MM:SS
  # respectively
  my $date = sprintf "%02d\/%02d\/%02d", $elems[3], $elems[4], $elems[5];
  my $time = sprintf "%02d:%02d:%02d", $elems[2], $elems[1], $elems[0];
  # Combine them into a single timestamp of the format DD/MM/YY HH:MM:SS
  $stamp = "$date $time";
  return $stamp;
}


sub IsUserAllowed {     # $user, $permissions, $actions, $cc_action
  # Takes the current user, the list of actions, the list of permissions 
  # for this stream and the current action, and determines whether to allow
  # the action to happen or not.
  my ($u, $p, $a, $cca) = (@_);
  my $return = 0;                       # Set the default value to FALSE
  my $counter = 0;                      # Used to index the $p aref
  foreach my $action (@$a) {            # Go through each action in the list
    if ($action eq $cc_performed_action) {# .. and compare to current action
      my $group = $$p[$counter];         # Get the group with permissions
      if (&User_Is_Member($u, $group)) {
        $return = 1;                    # Set return value to TRUE
      }
    }
    $counter++;                         # Increment index to next element
  }
  return $return;                       
}


sub Override_For_This_PVOB {    # $pvob
  # Works out what the PVOB is for this component VOB, then looks to see
  # if the user has overridden permissions for this PVOB.
  #
  my ($pvob) = (@_);            # The PVOB listed in the override file
  my $return = 0;               # Set default to FALSE
  if ($pvob eq "\*") {          # Override applies to all PVOBs
    $return = 1;
  } else {
    # Describe the current VOB - included in the description is a hyperlink
    # to the PVOB
    my @temp = qx/cleartool desc vob:$cc_vob/;
    # The AdminVOB (which is the PVOB in UCM) is on the last line; find that
    # line and grab everything after the \
    my ($vob_pvob) = (split /\\/, $temp[-1])[-1];
    # Strip the newline off the end - don't want that
    $vob_pvob =~ s/\n//;
    &Write_to_Log("  Checking $pvob is the same as $vob_pvob or $cc_vob");
    $return = 1 if $vob_pvob eq $pvob;
    $return = 1 if "\\$pvob" eq $cc_vob;  # Action's being performed on pvob!
  }
  return $return;
}


sub Override_Permissions {      # $user
  # We determine permissions from domain group memberships. This function
  # allows us to override these permissions and grant either less or more
  # abilities than the user would normally have (either for testing
  # purposes or to temporarily change someone's permissions [e.g. a normal
  # developer filling in for a LAP while the LAP's off work]).
  #
  my ($user) = (@_);
  # Location of creds.exe, which we'll use to determine group membership
#  my $creds_command = 
#    "c:\\Program Files\\Rational\\ClearCase\\etc\\utils\\creds.exe";
  # Run creds and grab the output into an array of lines
#  my $results = qx/$creds_command/;
  my $net_command = "net user $cc_user /domain";
  my $results = qx/$net_command/;
  if (-e "\\\\vl2rat002\\Trigger_scripts\\override.txt") {
    # Incorporating a quick and easy way of testing by using an override file
    # which overrides my actual permissions with the ones I wish to test.
    open FILE, "\\\\vl2rat002\\Trigger_scripts\\override.txt" or 
      &Write_to_Log("Can't read override file: $!");
    chomp (my @override = <FILE>);
    close FILE;
    my ($pvob, $lap, $admin);
    # Having read the override file into memory, process it.
    foreach my $line (@override) {
      next if $line =~ /^#/;    # Skip comments
      if ($line =~ / $user /i) {
        # We've found the current user, so overwrite the results we got from
        # creds
        &Write_to_Log("  Reading override file for $user");
        ($pvob, $user, $lap, $admin) = split / /, $line;
        if (&Override_For_This_PVOB($pvob) == 1) {
#          qx/clearprompt proceed -prompt "Overriding domain permissions for PVOB $pvob" -mask proceed/;
          &Write_to_Log("  Overriding on $pvob for $user [$lap] [$admin]");
          $results = "results = ";      # Blank out the current results 
                                        # (which was provided by creds)
          if ($lap eq "1") {            # LAP column was set to 1 so ..
            $results .= "$LAPs_group "; # .. insert the LAP domain group
          }
          if ($admin eq "1") {          # Admin column was set to 1 so ..
            $results .= "$admin_group ";# .. insert the Admin domain group
          }
        }
      }
    }
  }
  $results =~ s/\\\\/\\/g;              # Convert \\ to \
  return $results;
}


sub Read_Permissions {          # $stream
  # Reads the config file into a collection of global variables.
  #
  my ($given_stream) = (@_);
  my (@p, @a);
  # Read config file
  open FILE, $config or &Write_to_Log("ERROR: Can't open FILE $config: $!");
  chomp (my @data = <FILE>);
  close FILE;
  my $counter = 0;
  # Process config file
  foreach my $line (@data) {
    if (($line =~ /^#/) or ($line =~ /^\s*$/)) {
      # This is a comment or blank line, so treat it as non-existent.
      $counter--;       # This is purely to counter the $counter++ command
    } elsif ($counter == 0) {
      # This is the first line, which is a list of actions (except the first
      # entry, which is just a placeholder
      @a = split /\s+/, $line;
      shift(@a);        # Throw away the placeholder
    } else {
      # This is a permissions line, so split it into the stream and a list
      # of permissions
      my ($stream, @perms) = (split /\s+/, $line);
      @p = @perms if ($stream eq $given_stream);
      # put the data into an action-keyed hash of arefs
    }
    $counter++;
  }
  return (\@p, \@a);
}


sub User_Is_Member {            # $user, $group
  # Checks to see if the given user is allowed to perform the given role.
  #
  my ($u, $g) = (@_);
  my $return = 0;                       # Set default to DENIED
  my $results = &Override_Permissions($u);
  if (
    ($g eq "admins") and                # This function is Admins only
    ($results =~ /$admin_group/i)       # User's a member of the Admins group
  ) {
    # This is an admins-only command, and the user is in the ClearCase
    # admins group
    $return = 1;                        # Set to ALLOWED
  } elsif ($g eq "1") {
    # This command is open to everyone
    $return = 1;                        # Set to ALLOWED
  } elsif (
    ($g eq "laps") and (                # This function is LAPs only
      ($results =~ /$LAPs_group/i) or   # User's a member of the LAPs group
      ($results =~ /$admin_group/i)     # User's a member of the Admin group
    )
  ) {
    # This command should be available to LAPs (and hence also to Admins)
    $return = 1;                        # Set to ALLOWED
  } else {
  }
  return $return;
}


sub Write_to_Log {      # $string
  # Writes the information we wish to track to a log file.
  #
  my ($string) = (@_);
  # The only time we don't want the error to go to the logfile is if we 
  # can't actually write to it, so should that happen, let's build a 
  # clearprompt command we can use instead.
  my $comment = "ERROR: Cannot write to the logfile '$logfile'- please " .
    "contact your ClearCase Administrator";
  my $clearprompt = "clearprompt proceed -type error -prompt \"$comment\" " .
    "-mask abort -default abort";
  # Generate a timestamp to be used in the logfile
  my $timestamp = &Generate_Timestamp();
  # Append the message we've generated to the logfile
  open FILE, ">>$logfile" or qx/$clearprompt/;
  print FILE "[$timestamp] $string\n";
  close FILE;
}


##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  # First line's purely for development purposes
#  qx/clearprompt proceed -prompt "1. '$cc_vob' '$cc_user' '$cc_performed_action' '$cc_stream' '$deliver_rebase'"/;
  # deliveries and rebases comprise of 4 actions, so in order to find out
  # if one of these parent actions is taking place, look at the POP_KIND
  # instead. If one is, change the performed_action accordingly.
  if ($deliver_rebase eq "deliver_start") {
    $cc_performed_action = "deliver";
  } elsif ($deliver_rebase eq "rebase_start") {
    $cc_performed_action = "rebase";
  }
  # For delivery or rebase actions, the initial action is deliver_start or
  # rebase_start
  $cc_performed_action =~ s/_start//;
  # Strip the stream down to it's first two chars
  $cc_stream = uc(join("", (split //,$cc_stream)[0,1]));
  # Read the permissions file into memory.
  ($permissions, $actions) = &Read_Permissions($cc_stream);
  # work out if the user is allowed to perform this action on this stream
  my $result = 
    &IsUserAllowed($cc_user, $permissions, $actions, $cc_performed_action);
  # Default $result_string to DENIED (only used when writing info to the log)
  my $result_string = "DENIED.";
  $result_string = "ALLOWED" if ($result == 1);
  # Record the action which has been attempted.
  &Write_to_Log("$result_string $cc_stream $cc_user $cc_performed_action" .
  " to $cc_stream_stored");
  if ($result == 0) {           # Action is denied
    # Define the error message
    $comment = "Sorry $cc_user, you are not allowed to perform " .
      "$cc_performed_action on the $cc_stream stream. Please contact the " .
      "ClearCase Administrator if you have any questions";
    # Define the clearprompt command, which uses the error message
    $clearprompt = "clearprompt proceed -type error -prompt \"$comment\" " .
      "-mask abort -default abort";
    # Fire off clearprompt
    qx/$clearprompt/;
    exit 1;             # Exit with a failure notice
  }
}

