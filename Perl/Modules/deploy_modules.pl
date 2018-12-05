#!/usr/bin/perl -w
###############################################################################
#                                                                             #
# (c) Garry Short, 24/03/04                                                   #
# v0.1                                                                        #
# Deploys modules into the LIB path, first taking a backup of the original.   #
# It also allows a backout, simply by providing an argument.                  #
#                                                                             #
###############################################################################

###############################################################################
#                                                                             #
# USED Libraries                                                              #
#                                                                             #
###############################################################################


###############################################################################
#                                                                             #
# Constants                                                                   #
#                                                                             #
###############################################################################

my $deploy_path = "/usr/lib/perl5/site_perl/5.8.1/";


###############################################################################
#                                                                             #
# Variables                                                                   #
#                                                                             #
###############################################################################


###############################################################################
#                                                                             #
# Subroutines                                                                 #
#                                                                             #
###############################################################################


###############################################################################
#                                                                             #
# MAIN                                                                        #
#                                                                             #
###############################################################################

{
  opendir DIR, "." or die "Can't open current dir: $!\n";
  chomp( my @modules = readdir DIR );
  closedir DIR;
  foreach my $m (@modules) {
    next unless $m =~ /\.pm$/;
    if (-e "$deploy_path$m") {
      my $bak = $m;
      $bak =~ s/\.pm$/\.bak/;
      `cp $deploy_path$m $deploy_path$bak`;
    }
    `cp $m $deploy_path$m`;
  }
}
