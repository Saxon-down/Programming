#!/usr/bin/perl -w
###########################################################################
#                                                                         #
# Garry Short, 13/05/2013                                                 #
# create_project.pl v1.0                                                  #
#                                                                         #
# <DESCRIPTION>                                                           #
# when passed a config file (list of baselines), this script will create  #
# a new Project seeded from the specified baselines.                      #
#                                                                         #
#                                                                         #
#                                                                         #
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

my $cfg_file = "create_project.cfg";    # Default config file


###########################################################################
#                                                                         #
# GLOBAL CONSTANTS AND VARIABLES                                          #
#                                                                         #
###########################################################################

my $pvob;
my $project;
my $comment;
my $integration;
my $folder;
my %baselines;
my @components;


###########################################################################
#                                                                         #
# SUBROUTINES                                                             #
#                                                                         #
###########################################################################

sub Create_Project {
  # Creates a new Project and associated Integration stream
  #
  # Step 1: Create the Project
  my $command = "cleartool mkproj ";
  if ($comment) {
    $command .= "-c \"$comment\" ";
  } else {
    $command .= "-nc ";
  }
  if (@components) {
    $command .= "-modcomp " . join(",", @components) . " ";
  }
  if ($folder) {
    $command .= "-in $folder ";
  }
  $command .= "$project\@\\$pvob";
  # Now that the command has been put together for mkproject, we want to log
  # the command and execute it.
  &Process_Error("EXEC_CMD", $command);
  &Process_Error("CMD_OUT", qx/$command 2>&1/);
  # Step 2: Create the Stream
  $command = "cleartool mkstream -integration -in $project\@\\$pvob ";
  if ($comment) {
    $command .= "-c \"$comment\" ";
  }
  $command .= "-baseline " . join(",", keys %baselines) . " ";
  $command .= "$integration\@\\$pvob";
  # Now that the command has been put together for mkstream, we want to log
  # the command and execute it.
  &Process_Error("EXEC_CMD", $command);
  &Process_Error("CMD_OUT", qx/$command 2>&1/);
  # Finally, our new Stream could probably do with a View, so let's create
  # that too!
  $command = "cleartool mkview -tag $integration " .
                "-stream $integration\@\\$pvob -stgloc -auto";
  &Process_Error("EXEC_CMD", $command);
  &Process_Error("CMD_OUT", qx/$command 2>&1/);
}


sub Display_Help {
  # Displays the HELP text for this script.
  #
  print "
  
  
  create_project.pl

    This script can be called with the following arguments:

        <none>           : Runs the script and processes the default config
                           file, .\\create_project.cfg
        -help            : Displays this HELP
        -file <filename> : Runs the script using the specified config file
                           (full or relative paths can be used).



  ";
  exit;
}


sub Process_Args {
  # Handles the Arguments which have been passed to the script.
  #
  if (@ARGV) {
    # The script has been called with some arguments; let's see what they 
    # are.
    if ($ARGV[0] =~ /^-help$/i) {
      &Display_Help();
    } elsif ($ARGV[0] =~ /^-file$/i) {
      # We've been asked to use a specific config file
      if ($ARGV[1]) {
        if (-e $ARGV[1]) {
          # The file we've been provided exists; we'll use that instead of the
          # default
          $cfg_file = $ARGV[1];
        } else {
          &Process_Error(
            "FILENAME",
            "The filename you provided does not exist ($ARGV[1])"
          );
        }
      } else {
        # Not been provided a filename at all!
        &Process_Error(
          "FILENAME", 
          "You've used the -file flag, but not provided a filename"
        );
      }
    } else {
      # We've been passed an argument but it's not one we expect!
      &Process_Error(
        "ARGUMENT",
        "Do not recognise ARGUMENT ($ARGV[0])"
      );
    }
  } else {
    # Not been provided any arguments, so 
  }
}


sub Process_Error {             # $error_code, $error_string
  my ($code, $string) = (@_);
  print "$code->$string\n";
}


sub Read_Config_File {
  # Processes the config_file
  #
  my ($pr_action, $bl_action, $bl, $bl_pvob, $bl_modifiable); 
  open FILE, $cfg_file or &Process_Error("CONFIG", "$_");
  chomp (my @temp = <FILE>);
  close FILE;
  foreach my $line (@temp) {
    next if $line =~ /^#/;      # Skip comments
    next if $line =~ /^$/;      # Skip blank lines
    my ($type, $string) = split /\s*=\s*/, $line;
    if ($type =~ /^pvob$/i) {
      # pvob=<pvob>
      $pvob = $string;
    } elsif ($type =~ /^project$/i) {
      # project=<ProjectName>,<Action>
      $project = $string;
    } elsif ($type =~ /^comment$/i) {
      # comment=<comment>
      $comment = $string;
    } elsif ($type =~ /^int_stream$/i) {
      # stream=<stream_name>
      $integration = $string;
    } elsif ($type =~ /^folder$/i) {
      $folder = $string;
    } elsif ($type =~ /^baseline$/i) {
      # baseline=<Action>,<Baseline>,<Baseline_PVOB>,<Modifiable>
      ($bl, $bl_pvob, $bl_modifiable) = split /,/, $string;
      $baselines{"$bl\@\\$bl_pvob"} = $bl_action;
      if ($bl_modifiable =~ /^y$/i) {
        # Should be a modifiable component, so need to work out what the 
        # component actually is.
        chomp (my @details = qx/cleartool lsbl $bl\@\\$bl_pvob/);
        foreach my $line (@details) {
          next unless $line =~ s/  component: //;
          # We've found which component the baseline was applied to, so
          # store it.
          push @components, $line;
        }
      }
    } else {
      # Invalid entry
      &Process_Error("CONFIG", "Don't know what to do with '$line'");
    }
  }
}


###########################################################################
#                                                                         #
# MAIN SCRIPT                                                             #
#                                                                         #
###########################################################################

{
  &Process_Args();
  &Process_Error("INIT", "Beginning script ..");
  my $action = &Read_Config_File();
  &Create_Project();
  &Process_Error("EXIT", "Script complete");
}


