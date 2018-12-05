#!/user/bin/perl -w
##########################################################################
#                                                                        #
# find_component_vobs.pl                                                 #
# v0.1                                                                   #
# Garry Short, 16/09/08                http://www.saxon-down.com/scripts #
#                                                                        #
# Given a PVOB, finds a list of VOBs that all related components live in #
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
my $pvob = $ARGV[0];


# Variables


##########################################################################
#                                                                        #
# Subroutines                                                            #
#                                                                        #
##########################################################################

sub Find_CompVOBs {             # $pvob
  #
  my ($pvob) = (@_);
  my %comp_vobs;
  my @comps = qx/cleartool lscomp -s -invob $pvob/;
  foreach my $comp (sort @comps) {
    chomp $comp;
    my @details = qx/cleartool lscomp $comp\@$pvob/;
    my $cv = (split /\\/, $details[1])[1];
    $cv =~ s/["']//g;
    $comp_vobs{$cv} = 1;
  }
  print "For PVOB $pvob, the component VOBs are:\n";
  foreach my $comp (sort keys %comp_vobs) {
    print "    $comp\n";
  }
  print "\n";
}


sub Find_PVOBs {
  # Returns a list of all PVOBs
  #
  my %return;
  my @vobs = qx/cleartool lsvob -s/;            # Get a list of VOBs
  chomp @vobs;                                  # Strip out the newlines
  foreach my $vob (sort @vobs) {        
    next unless $vob =~ /pvob/i;                # Strip out the non-pvobs
    $return{$vob} = 1;                          # Add the pvob to the list
  }
  return \%return;                              # Return the list
}               # Find_PVOBs


##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  print "\n";
  if (! $pvob) {
    # Find all PVOBs and process them accordingly.
    my $pvobs = &Find_PVOBs();
    foreach my $pv (sort keys %$pvobs) {
      &Find_CompVOBs($pv);
    }
  } else {
    &Find_CompVOBs($pvob);
  }
}
