#!/user/bin/perl -w
##########################################################################
#                                                                        #
# mkstream.pl                                                            #
# v0.1                                                                   #
# Garry Short, 08/05/08                                                  #
# perl@saxon-down.com    ##    http://www.saxon-down.com/scripts         #
#                                                                        #
# ClearCase post-op trigger to check that stream names are no longer     #
# than the provided limit. Provides the option of either removing or     #
# renaming streams which exceed the limit, depending on the argument     #
# provided at the commandline.                                           #
# Run the script without arguments to get usage instructions.            #
# To create the trigger, run the following command:                      #
#     cleartool mktrtype -ucm -all -postop mkstream -exec _              #
#       "ccperl <path>\mkstream.pl <ARGS>" -nc POST_MKSTREAM@<PVOB_TAG>  #
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
my $number_of_args = 2;                 # How many arguments we're expecting

# Variables
my ($which_opt, $stream_length, $vob, $stream_name);


##########################################################################
#                                                                        #
# Subroutines                                                            #
#                                                                        #
##########################################################################

sub Get_Passed_Parameters {
  # @ARGV is a system array of all the data the script was passed when it
  # was called. Grab that data and assign it to the relevant variables.
  $which_opt = $ARGV[0];
  $stream_length = $ARGV[1];
  unless (
    (($which_opt eq "REMOVE") or ($which_opt eq "RENAME")) and
    ($stream_length > 0)
  ) {
    # One or more of the supplied parameters doesn't meet the criteria we
    # expect, so give the usage information and quit.
    &Give_Usage_Information;
    exit;
  }
  # The following data shouldn't be passed to the script, but should instead
  # be read from the environment.
  $vob = $ENV{"CLEARCASE_VOB_PN"};
  $stream_name = $ENV{"CLEARCASE_STREAM"};
}


sub Give_Usage_Information {
  # Prints out information on how to use this script.
  #
  print
    "To use this trigger, you need to provide the following arguments:\n" .
    "1. <which_option>\n" .
    "\tREMOVE: removes any stream which exceeds the maximum length\n" .
    "\tRENAME: renames any stream by using clearprompt to allow the\n" .
    "\t\tuser to enter a new name.\n" .
    "2. <length>\n" .
    "\tdefines the maximum length a stream name can be.\n"
  ;
}


sub stream_remove {
  # Handles the removal of a stream. Works, but crashes Project Explorer!
  #
  my $command = "cleartool rmstream -force -nc stream:$stream_name" . "@" .
        $vob;
  my $clearprompt = "clearprompt proceed -type warning -default proceed " .
        "-mask proceed -prompt \"This stream name does not meet the " .
        "company policy of using no more than $stream_length characters " .
        "and will be deleted - please try again.\n\n" .
        "Please note that this policy is in place to reduce the likelihood ".
        "of delivery/rebase problems\"";
  qx/$clearprompt/;     # execute the clearprompt
  qx/$command/;         # remove the stream
#  print "$command\n";
}


sub stream_rename {
  # Handles the renaming of a stream. When creating a stream in ClearCase,
  # a brtype (branch type) also gets created with the same name - this needs
  # to be renamed too
  #
  my ($new_name, $time, $temp);
  # Need to generate an input box to allow the user to enter a new name for
  # his stream. ClearCase's clearprompt command is ideal for this, but 
  # writes the inputted text back to a file. To prevent different instances
  # of the script messing each other up, we need to generate a unique 
  # filename. Localtime unfortunately only generates times to the second,
  # so we'll use the DOS command 'time' instead (which returns to 1/100th of
  # a second, but needs filtering).
  while (1) {           # Keep looping till we have a valid name
    my $output_file = join(
      "", 
      "c:\\windows\\temp\\newstream.", (($temp = (qx/echo | time/)) =~ /[0-9]/g)
    );
    # Define the clearprompt command we need
    my $clearprompt = "clearprompt text -outfile $output_file -prompt \"The".
    " stream name you've selected doesn't meet the company policy on name " .
    "length.\nIt should be no more than $stream_length characters. Please " .
    "enter a new name (note: no spaces):\"";
    # Execute clearprompt
    qx/$clearprompt/;
    # Read the new stream name from the output file
    open FILE, $output_file;
    chomp (my @file = <FILE>);
    close FILE;
    $new_name = $file[0];
    $new_name =~ s/\s//g;       # Strip out whitespace
    # Clean up behind ourselves and delete the output file
    qx/del $output_file/;
    # Find out if the stream already exists by getting the results from 
    # trying to describe it. If the result is the stream name, the describe
    # succeeded and hence it exists
    my $stream_exists = qx/cleartool desc -short stream:$new_name/;
    # Split the new name into an array where each element is a single char.
    # We can then use the number of elements to determine the stream name 
    # length
    my @len = split //, $new_name;
    if ($#len >= $stream_length) {
      # $#len is the index of the last element of the array, not the length.
      # The length is one higher than the index. '$#len >= $stream_length' is
      # just as easy as '($#len+1) > $stream_length', and has exactly the 
      # same result.
      next;             # Still doesn't meet requirements, so try again
    } elsif ($new_name =~ /^$/) {    # Empty name
      next;
    } elsif ($stream_exists eq $new_name) {
      qx/clearprompt proceed -prompt "Error: $new_stream already exists, please try again" -mask proceed/;
      next;
    } else {
      # Now rename the stream
      my $comment = "\"Renamed due to policy enforcement\"";
      my $command = "cleartool rename -nc stream:" . 
        $stream_name . "@" . $vob . " stream:$new_name" . "@" . $vob;
      chomp(my $result = qx/$command/);
      # When creating a stream, ClearCase also creates a brtype (branch type)
      # which also needs to be renamed. The command is almost identical, and
      # the brtype name is identical to the stream name.
      $command =~ s/stream/brtype/g;
      chomp($result = qx/$command/);
      exit;             # Success, so drop out of the loop
    }
  }
}


##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  my $last_arg = $number_of_args - 1;
  unless ($ARGV[$last_arg]) {
    # We've not been passed the arguments we expected, so give the usage
    # instructions and exit.
    &Give_Usage_Information;
    exit;
  }
  &Get_Passed_Parameters;
  # Work out how long the current stream name is
  ($stream_name) = (split /@/, $stream_name)[0];
  my @temp = split //, $stream_name;
  $actual_length = $#temp + 1;
  # If the stream name's too long, deal with it
  if ($actual_length > $stream_length) {
    if ($which_opt eq "REMOVE") {
      &stream_remove;
    } elsif ($which_opt eq "RENAME") {
      &stream_rename;
    } else {
      # This should never happen, since &Get_Passed_Parameters has already 
      # validated $which_opt for us.
    }
  }
  qx/clearprompt proceed -prompt "You may need to refresh your view to see the rename completed" -mask proceed/;
}
