#!/usr/bin/perl -w
###########################################################################
#                                                                         #
# Garry Short, 17/07/14                                                   #
# multisite_sync_checker.pl v1.0                                          #
#                                                                         #
# <DESCRIPTION>                                                           #
# When run on several different sites it generates a list of VOBs, works  #
# out which are multisited and creates a list of epoch values, which are  #
# then logged in a central location. Once all logs are generated, running #
# with a -report flag compares all the values to make sure the sites are  #
# in sync.                                                                #
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

my $report_flag;
my %vob_list;


###########################################################################
#                                                                         #
# SUBROUTINES                                                             #
#                                                                         #
###########################################################################

sub Find_VOBs {
  # Generates a list of all the VOBs it can find, then weeds out the ones
  # which aren't multisited
  #
  chomp (my @temp = qx/cleartool lsvob -s/);
  foreach my $v (@temp) {
     
  }
}


###########################################################################
#                                                                         #
# MAIN SCRIPT                                                             #
#                                                                         #
###########################################################################

{
}


