#!/user/bin/perl -w
##########################################################################
#                                                                        #
# unpick_baseline.pl                                                     #
# v0.1                                                                   #
# Garry Short, 27/11/08                http://www.saxon-down.com/scripts #
#                                                                        #
# Allows the deletion of a rejected baseline, by checking the activities #
# to build a changeset, then processing the changeset to remove the      #
# relevant versions of every file. Once the changeset's undone, the      #
# activities can then be deleted, and then the baseline.                 #
# NOTE: This will only work on baselines of the correct promotion level  #
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
%removable_promotion_levels = (
  "REJECTED"            => 1
);
my $baseline = $ARGV[0];

# Variables
my @activities;
my $stream;
my $found_activity = 0;


##########################################################################
#                                                                        #
# Subroutines                                                            #
#                                                                        #
##########################################################################

sub Display_Help {      
  # Displays usage information if required
  #
  print "
  ";
}


sub Process_Activity {          # $activity
  # Takes an activity name and finds it's changeset. It then processes each
  # version in the changeset and deletes it, then deletes the activity
  # afterwards.
  #
  my ($activity) = (@_);
  # Get the activity details
  my @details = reverse qx/cleartool lsact -l $activity/;
  print "Processing activity $activity ...\n@details----\n";
  foreach my $line (@details) {
    # Skip through until we find the changeset
    next unless $line =~ s/^    //;
    chomp $line;
    # Now delete this file version
    print "#### Attempting to remove $line ...\n";
    print qx/cleartool rmver -xlabel -xattr -xhlink -f "$line"/;
  }
  # Once all the changes have been undone, remove the activity.
  print "#### Attempting to remove activity $activity ...\n";
  print qx/cleartool rmact -f $activity/;
}


##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  # Display the usage information if no baseline's been provided, or if the
  # script's been called with a -h
  if (($baseline =~ /^-h/i) or ($baseline  eq "")) {
    &Display_Help();
    exit;
  }
  # Look up the baseline details
  my @baseline_details = reverse qx/cleartool lsbl -l $baseline/;
  # Exit if it's not a valid baseline
  if ($baseline_details[-1] =~ /cleartool: Error:/) {
    print "Sorry, you've provided an invalid baseline!\n";
    exit;
  }
  print qx/cleartool rmbl -f $baseline/;
  print "@baseline_details" . "----\n";
  # Find the baseline's current promotion level
  chomp(my $current_promotion = (split /: /,$baseline_details[1])[1]);
  # Exit if it's not a permitted promotion level for deletion
  exit unless $removable_promotion_levels{$current_promotion};
  # Okay, we've got this far, so we know it's a valid baseline and we're 
  # allowed to delete it.
  foreach my $line (@baseline_details) {
    # Remember the output's been reversed, so we're doing everything upside
    # down!
    if ($line =~ /^  stream: /) {
      # Found the stream name, so make a note of it
      chomp ($stream = (split /: /, $line)[1]);
    } elsif ($line =~ /  change sets:/) {
      # Found the start of the activity list, so unflag it
      # will be activities
      $found_activity = 0;
    } elsif ($line =~ /  promotion /) {
      # Passed the end of the activity list, so flag it
      $found_activity = 1;
    } elsif ($found_activity eq 1) {
      # This line's an activity in the changeset, so add it to the list.
      $line =~ s/^    (.*)\n$/$1/;
      &Process_Activity($line);
    }
  }
}


# INCOMPLETE SCRIPT, NEEDS TESTING!
