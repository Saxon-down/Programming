#!/user/bin/perl -w
##########################################################################
#                                                                        #
# Test_Membership.pl                                                     #
# v0.1                                                                   #
# Garry Short, 21/04/08                                                  #
#                                                                        #
# Tests for group membership by using CREDS                              #
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
my $creds_path = "c:\\Program Files\\Rational\\ClearCase\\etc\\utils\\creds.exe";


# Variables


##########################################################################
#                                                                        #
# Subroutines                                                            #
#                                                                        #
##########################################################################

sub Get_Creds_Output {
  # Takes the creds path and executes the external, ClearCase creds command.
  # Returns the results as an array reference.
  #
  my ($creds_path) = (@_);
  my @creds_output = qx/$creds_path/;
  return \@creds_output;
}


sub Test_Group_Membership {
  # Takes a group name and tests it against the CREDS output. Returns a 
  # TRUE or FALSE value
  # NOTE: Ignores case sensitivity!
  #
  my ($group, $creds) = (@_);
  my $test_result = 0;
  foreach my $line (@$creds) {
    next unless $line =~ /^    /;       # Only the groups are indented by
                                        # 4 chars, so skip all other lines
                                        # so we don't get bogus results!
    $test_result = 1 if $line =~ /$group/i;
  }
  return $test_result;
}


##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  unless (@ARGV) {
    # No parameters have been passed, so give the usage instructions.
    print "Please supply the group membership(s) you wish to test\n";
    print "\t e.g. ccperl Test_Membership.pl cc_users clearcase\n";
    exit;
  }
  my $creds_results = &Get_Creds_Output($creds_path);
  foreach my $test_group (@ARGV) {
    if (&Test_Group_Membership($test_group, $creds_results)) {
      print "SUCCESS: user is in $test_group\n";
    } else {
      print "FAILURE: user is not in $test_group\n";
    }
  }
}
