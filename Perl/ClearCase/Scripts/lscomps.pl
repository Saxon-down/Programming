#!/usr/bin/perl -w
###########################################################################
#                                                                         #
# Garry Short, 02/07/13                                                   #
# lscomps.pl v0.1                                                         #
#                                                                         #
# <DESCRIPTION>                                                           #
# Takes a Project name and returns a list of associated components, along #
# with which VOBs they're in. If no Project name is given, it will ask    #
# for one.                                                                #
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

my $project;
my %all_comp;
my %mod_comp;


###########################################################################
#                                                                         #
# SUBROUTINES                                                             #
#                                                                         #
###########################################################################


sub Output_Data {       # $project
  # Takes the information we've discovered and outputs it to the screen.
  #
  my ($proj) = (@_);
  print "\n\nProject = $proj\n";
  print "==========================================================\n\n";
  foreach my $c (sort keys %all_comp) {
    # For each component we've fount ...
    if ($mod_comp{$c}) {
      # If it's a modifiable component, prefix it with a *
      print "* ";
    } else {
      print "  ";
    }
    my $short_c = (split /\@/, $c)[0];  # Don't really want the information
        # .. on which pvob the component is registered to, so get rid of it
    printf "%-25s", $short_c;   # Format it nicely
    print "    $all_comp{$c}\n";
  }
  print "\n\n";
  print "Any components prefixed with '*' can be modified in this Project\n";
  print "\n\n";
}


sub Process_Project {   # $project
# Takes the Project name and builds a list of components, making note of 
# any that are modifiable.
#
  my ($proj) = (@_);
  my @details = qx/cleartool lsproj -l $proj/;
  my $mod_comp = 0;
  my $comp = 0;
  foreach my $line (@details) {
    if ($line =~ /^  modifiable components:$/) {
      # Found the start of the modifiable components list, so switch the 
      # flag on
      $mod_comp = 1;
      next;     # Don't actually care about this line except for toggling
                # .. the flag, so discard it
    } elsif ($line =~ /^  recommended baselines:$/) {
      # Found the baselines list, which also gives us the full component 
      # list. Again, toggle the flag but discard the actual line
      $comp = 1;
      next;
    } elsif ($line =~ /^  \w/) {
      # This marks the start of a section we don't care about; toggle both
      # flags off but otherwise ignore it
      $mod_comp = 0;
      $comp = 0;
    } elsif ($mod_comp) {
      # This line contains information on a modifiable component, so clean
      # the data up and store it.
      chomp $line;
      $line =~ s/^\s+//;
      $mod_comp{$line} = 1;
    } elsif ($comp) {
      # This line contains information about a baseline, which therefore
      # also contains information about a component. Clean the data up and
      # discard everything we're not interested in
      my $c = (split /\(/, $line)[1];
      $c =~ s/\)//;
      chomp $c;
      # Now we have the component information, we need to find it's storage
      # location
      my @desc_c = qx/cleartool lscomp $c/;
      $all_comp{$c} = (split /"/, $desc_c[1])[1];
    }
  }
}


sub Project_Exists {    # $project
# Performs a simple check to make sure the Project we've been supplied
# actually exists.
  my ($proj) = (@_);
  my $check = qx/cleartool lsproj -l $proj 2>&1/;
  if ($check =~ /Error/) {
    # cleartool returned an error
    return 0;
  } else {
    return 1;
  }
}


sub Show_Help {
  print "\n\nThis script can be used in one of two ways:\n";
  print "\t1) Call the script on it's own; it will prompt you to provide\n";
  print "\t   a Project name in the format <PROJECT>\@<PVOB>\n";
  print "\t   e.g. ccperl lscomps.pl\n\n";
  print "\t2) Call the script with a Project name as an argument, where\n";
  print "\t   the Project name is of the format, <PROJECT>\@<PVOB>\n";
  print "\t   e.g. ccperl lscomps.pl UCM_Training\@\\training_pvob\n\n";
  exit;
}


###########################################################################
#                                                                         #
# MAIN SCRIPT                                                             #
#                                                                         #
###########################################################################

{
  if ($ARGV[0]) {
    # The user has passed an argument
    if ($ARGV[0] =~ /^-help$/i) {
      # HELP has been requested, so display it.
      &Show_Help();
    } else {
      $project = $ARGV[0];
    }
  } else {
    # Not been given a Project name so request one.
    print "\nPlease enter the name of a Project (including PVOB)\n";
    print "e.g. 'UCM_Training\@\\training_pvob'\n> ";
    chomp ($project = <STDIN>);
  }
  if (&Project_Exists($project)) {
    &Process_Project($project);
    &Output_Data($project);
  } else {
    print "\n\nERROR: $project is not a valid ClearCase Project!\n";
    print "\tDid you include the PVOB in the Project name?\n";
    print "\te.g. UCM_Training\@\\training_pvob\n\n";
    print "Correct usage is 'ccperl lscomps.pl <PROJECT>@<PVOB>'\n\n";
    print "Terminating ..\n\n";
  }
}


