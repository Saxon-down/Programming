#!/usr/bin/perl -w
###########################################################################
#                                                                         #
# Garry Short, <DATE>                                                     #
# <SCRIPT NAME> v<VERSION>                                                #
#                                                                         #
# <DESCRIPTION>                                                           #
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

my @streams;
my %views;
my %projects;
my @oldviews;

my $debug = 0;          # Change this to 1 if you want debug output


###########################################################################
#                                                                         #
# SUBROUTINES                                                             #
#                                                                         #
###########################################################################

###########################################################################
#                                                                         #
# MAIN SCRIPT                                                             #
#                                                                         #
###########################################################################

{
  my $current = (split / /, qx/date \/T/)[1];
  my ($d, $m, $y) = split /\//, $current;
  $current = ($y * 365) + ($m * 30) + $d;
  print "DEBUG: CURRENT = [$current]\n" if $debug;
  print "DEBUG: =======================\n" if $debug;
  chomp (@streams = qx/cleartool lsstream -s -invob \\stc_pvob_src/);
  foreach my $s (@streams) {
    print "DEBUG: STREAM = [$s]\n" if $debug;
    chomp (my @details = qx/cleartool lsstream -l $s\@\\stc_pvob_src/);
    my $view_marker = 0;
    my $prj;
    foreach my $line (@details) {
      if ($line =~ s/^  project: //) {
        print "DEBUG: PRE-CLEAN PROJECT [$line]\n" if $debug;
        $line =~ s/ .*$//;
        $prj = $line;
        $projects{$prj} = 1;
        print "DEBUG: PROJECT = [$line]\n" if $debug;
      } elsif ($line =~ /^  views:/) {
        $view_marker = 1;
      } elsif ($line =~ /^  \w/) {
        $view_marker = 0;
      } elsif ($view_marker) {
        $line =~ s/^    //;
        $views{$line} = $prj unless $line =~ /:..:..:..:/; # This is a UUID
        print "DEBUG: VIEW = [$line]\n" if $debug;
      }
    }
  }
  print "DEBUG: =======================\n" if $debug;
  foreach my $v (sort keys %views) {
    print "DEBUG2: VIEW = [$v]\n" if $debug;
    my $proj = $views{$v};
    print "DEBUG2: PROJECT = [$proj]\n" if $debug;
    chomp (my @details = qx/cleartool lsview -s -age $v/);
    my $access = (split / /, $details[1])[2];
    $access =~ s/T.*$//;
    my ($y, $m, $d) = split /-/, $access;
    $access = ($y * 365) + ($m * 30) + $d;
    print "DEBUG2: AGE = [$access]\n" if $debug;
    print "DEBUG2: CURRENT vs AGE [$current] [$access]\n" if $debug;
    if (($current - 100) > $access) {   # Not been used in ~3mths
      $projects{$proj} = 2 unless ($projects{$proj} == 3);
      print "DEBUG3: UNUSED PROJECT? [$proj]\n" if $debug;
      push(@oldviews, $v);
    } else {
      $projects{$proj} = 3;
      print "DEBUG3: USED PROJECT [$proj]\n" if $debug;
    }
  }
  # OUTPUT
  print "===================================\n";
  print "Old Views:\n\n";
  foreach my $v (sort @oldviews) {
    print "  $v\n";
  }
  print "===================================\n";
  print "Old Projects:\n\n";
  foreach my $p (sort keys %projects) {
    print "  $p\n" if ($projects{$p} == 2);
  }
  print "===================================\n";

}


