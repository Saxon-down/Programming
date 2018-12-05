#!/user/bin/perl -w
##########################################################################
#                                                                        #
# baseline_changeset.pl                                                  #
# v0.1                                                                   #
# Garry Short, 22/05/08                                                  #
#                                                                        #
# Given a baseline and pvob, it returns the complete changeset for that  #
# baseline                                                               #
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
  $bl = $ARGV[0];
  $pvob = $ARGV[1];


# Variables
my (@desc_bl, @changeset, @list);


##########################################################################
#                                                                        #
# Subroutines                                                            #
#                                                                        #
##########################################################################


##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  @desc_bl = qx/cleartool lsbl -l baseline:$bl\@$pvob/;
  # Throw away the "depends on:" line
  pop(@desc_bl);
  # Throw away the "promotion level:" line
  pop(@desc_bl);
  # Throw away the preceding lines - don't care about them
  shift @desc_bl while ($desc_bl[0] !~ / change sets:/);
  # Throw away the "change sets:" line. Should just have a list of 
  # activities now
  shift(@desc_bl);
  foreach my $act (@desc_bl) {
    $act =~ s/\s+//g;     # Strip off leading / trailing space
    @changeset = qx/cleartool lsact -l $act/;
    # Again, throw away the preceding lines
    shift @changeset while ($changeset[0] !~ /change set versions:/);
    # Throw away the "change set versions:" line
    shift(@changeset);
    # Add the rest to our complete list
    push @list, @changeset;
  }
  # Sort and print it
  print sort @list;
}
