#!/user/bin/perl -w
##########################################################################
#                                                                        #
# convert_epoch_time.pl                                                  #
# v0.1                                                                   #
# Garry Short, 11/06/08                                                  #
#                                                                        #
# Converts an epoch time into a human-readable one.                      #
#                                                                        #
##########################################################################

##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  # If we've been passed an epoch at the command prompt, grab it.
  my $epoch = $ARGV[0] or 0;
  unless ($epoch) {     # Otherwise, request one and read the input
    print "Please enter the epoch time: ";
    chomp($epoch = <STDIN>);
  }
  # Convert the epoch into local time
  my @time = localtime($epoch);
  # Format the components we're interested in
  my ($min, $hr, $date, $mon, $yr) = (@time)[1..5];
  $date++;
  $mon++;
  $yr += 1900;
  # Format and print the output
  print sprintf "%02d:%02d %02d/%02d/%02d\n", $hr, $min, $date, $mon, $yr;
}
