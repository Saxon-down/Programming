#!/user/bin/perl
##########################################################################
#                                                                        #
# changeset_since_recommended_baseline.pl                                #
# v0.2                                                                   #
# Garry Short, 27/06/08                http://www.saxon-down.com/scripts #
#                                                                        #
# Generates a complete changeset that has occurred since the recommended #
# baseline.                                                              #
#                                                                        #
# HISTORY                                                                #
# v0.3 08/12/08                                                          #
#      Fixed Convert_To_Epoch to handle the date conversion correctly    #
# v0.2 27/06/08                                                          #
#      Broken the deliveries down into activities and their changesets   #
#                                                                        #
##########################################################################

##########################################################################
#                                                                        #
# USEs, INCLUDEs, etc                                                    #
#                                                                        #
##########################################################################

use Time::Local;


##########################################################################
#                                                                        #
# Global constants & variables                                           #
#                                                                        #
##########################################################################

# Constants


# Variables


##########################################################################
#                                                                        #
# Subroutines                                                            #
#                                                                        #
##########################################################################

sub Convert_Delivery_to_Activities {    # $delivery, $stream
  # Takes an activity and finds and prints it's changeset.
  #
  my ($delivery, $stream) = (@_);
  $delivery = (split /  /, $delivery)[1];
  my $pvob = (split /@/, $stream)[1];
  my @desc = qx/cleartool lsactivity -l $delivery\@$pvob/;
  print "Delivery: $delivery\n";
  foreach my $line (@desc) {
    if ($line =~ /^  title:/) {
      print "$line";
    } elsif ($line =~ /^  change set versions:/) {
      print "$line";
    } elsif ($line =~ /^    /) {
      print "$line";
    }
  }
  print "\n";
}


sub Convert_to_Epoch {          # $cc_timedate
  # Takes the datestamp from a ClearCase command and converts it to an
  # epoch timestamp.
  #
  my ($cc_timedate) = (@_);
  my ($year, $month, $day) = split /-/, (split /T/, $cc_timedate)[0];
  my ($hour, $min, $sec) = split /:/, 
      (split /\+/, (split /T/, $cc_timedate)[-1])[0];
  $month--;             # ClearCase returns 1-12, Perl expects 0-11
  $day--;               # .. and similar with dates
  return timelocal($sec, $min, $hour, $day, $month, $year);
}


sub Generate_Changeset_Since_Date {     # $date, $stream
  # Generates a complete changeset that's occurred since a given date
  #
  my ($date, $stream) = (@_);
  # Now generate a list of all activities on that stream ...
  my @activities = qx/cleartool lsact -in $stream/;
  # .. and find any that are newer than the recommended baseline.
  foreach my $act (@activities) {
    my $act_epoch = &Convert_to_Epoch((split / /, $act)[0]);
    if ($act_epoch > $bl_epoch) {
      &Convert_Delivery_to_Activities($act, $stream);
    }
  }
}


sub Get_Recommended_Baseline_Timestamp {        # $stream
  # Takes the stream name and finds the recommended baseline for it, then
  # finds it's creation date and converts the timestamp into an epoch time
  my ($stream) = (@_);
  my $baseline;
  my @desc = qx/cleartool desc -l stream:$stream/;
  my $found = 0;
  foreach my $line (@desc) {
    if ($line =~ /^  recommended baselines/) {
      $found = 1;
    } elsif ($found eq 1) {
      $baseline = (split / +/, $line)[1];
      $found = 0;
      last;
    }
  }
  my $date = (split / /, qx/cleartool lsbl $baseline/)[0];
  # Convert that to an epoch time
  return &Convert_to_Epoch($date);
}


##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  my $stream = $ARGV[0];                # Grab the stream off the commandline
  # Grab the description of the stream and process it for the recommended
  # baseline
  my $date = &Get_Recommended_Baseline_Timestamp($stream);
  print "$date  LAST RECOMMENDED BASELINE\n";
  &Generate_Changeset_Since_Date($date, $stream);
}
