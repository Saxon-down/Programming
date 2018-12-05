#!/user/bin/perl -w
##########################################################################
#                                                                        #
# comp_in_proj.pl                                                        #
# v0.1                                                                   #
# Garry Short, 14/07/08                http://www.saxon-down.com/scripts #
#                                                                        #
# Generates a list of components for each Project in a PVOB              #
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


# Variables


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
  my $pvob = $ARGV[0];
  my @projs = qx/cleartool lsproj -s -invob $pvob/;
  foreach my $p (@projs) {
    my $found_projs = 0;
    chomp $p;
    my @details = qx/cleartool lsproj -l $p\@$pvob/;
    print "$p:";
    foreach my $line (@details) {
      last if (($found_projs == 1) and ($line =~ /^  \w/));
      if ($line =~ /modifiable components:/) {
        $found_projs = 1;
        next;
      }
      if ($found_projs == 1) {
        $line =~ s/    //;
        $line =~ s/\@.*$//;
        chomp $line;
        print " $line";
      }
    }
    print "\n\n";
  }
}
