#!/user/bin/perl -w
##########################################################################
#                                                                        #
# apply_policies.pl                                                      #
# v1.1                                                                   #
# Garry Short, 12/05/08                                                  #
#                                                                        #
# Script to apply the standard policies to a new UCM Project             #
#                                                                        #
# History                                                                #
# =======                                                                #
# 1.1 Modified for STC Policies, added CQ support                        #
# 1.0 Initial version                                                    #
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
# Next two are used for defining UCM Project policies
my $enable = "-policy";
my $disable = "-npolicy";
my %project_policies = (
  POLICY_WIN_INT_SNAP                                   => $disable,
  POLICY_UNIX_INT_SNAP                                  => $enable,
  POLICY_WIN_DEV_SNAP                                   => $disable,
  POLICY_UNIX_DEV_SNAP                                  => $enable,
  POLICY_CHPROJECT_UNRESTRICTED                         => $disable,
  POLICY_CHSTREAM_UNRESTRICTED                          => $enable,
  POLICY_DELIVER_REQUIRE_REBASE                         => $enable,
  POLICY_DELIVER_NCO_DEVSTR                             => $enable,
  POLICY_DELIVER_NCO_SELACT                             => $disable,
  POLICY_REBASE_CO                                      => $disable,
  POLICY_INTRAPROJECT_DELIVER_FOUNDATION_CHANGES        => $enable,
  POLICY_INTRAPROJECT_DELIVER_ALLOW_MISSING_TGTCOMPS    => $enable,
  POLICY_INTERPROJECT_DELIVER                           => $enable,
  POLICY_INTERPROJECT_DELIVER_FOUNDATION_CHANGES        => $enable,
  POLICY_INTERPROJECT_DELIVER_REQUIRE_TGTCOMP_VISIBILITY => $disable,
  POLICY_INTERPROJECT_DELIVER_ALLOW_NONMOD_TGTCOMPS     => $enable
);      # See "cleartool man mkstream" for more information on policies
my $blname_template = "stream,date,time";       # Baseline naming template
my $cqdb = "NGI";
my $cqconn = "8.0.0";


# Variables
my $ucmproj = $ARGV[0] or 0;
my $cqenable = lc($ARGV[1]) or "n";
my $crmenable;      # Used for linking to CQ

##########################################################################
#                                                                        #
# Subroutines                                                            #
#                                                                        #
##########################################################################

sub Script_Usage {
  # Outputs information on how to use this script, and then exits.
  #
  print "\n\napply_policies.pl Usage\n";
  print "=======================\n\n";
  print "ccperl apply_policies.pl <stream_selector> [y|n]\n\n";
  print "This script applies the corporate-required policies to the\n";
  print "specified project. It can also be used, if required, in a \n";
  print "mkproject trigger\n\n";
  print "The second flag should be a y or n, indicating whether the\n";
  print "Project should be linked to ClearQuest\n\n";
  exit;
}


##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  &Script_Usage() unless $ucmproj;      # Give usage instructions if needed
  if ($cqenable eq "y") {
    $crmenable = "-crmenable $cqdb -connection $cqconn";
  }
  foreach my $policy (keys %project_policies) { # Foreach policy ..
    my $flag = $project_policies{$policy};
    # Apply the policy
    print qx/cleartool chproject $flag $policy $ucmproj/;
  }
  # Apply the baseline naming template
  print qx/cleartool chproject -bln $blname_template $crmenable $ucmproj/;
  print "\n\nYou now have to manually set the ClearQuest policies ";
  print "yourself. This functionality\nwill be added as soon as I can ";
  print "work out how.\n\n";
}
