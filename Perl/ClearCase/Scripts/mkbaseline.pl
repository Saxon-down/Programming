#!/usr/bin/perl -w
###########################################################################
#                                                                         #
# Garry Short, 04/10/13                                                   #
# mkbaseline.pl v1.1                                                      #
#                                                                         #
# <DESCRIPTION>                                                           #
# Baselines the Integration stream of a given Project, either using the   #
# auto-generated name or the one provided.                                #
# Supports the following flags:                                           #
# -p <Project_Name>                                                       #
# -s <baseline_suffix>                                                    #
# -v                                                                      #
# - OR -                                                                  #
# -o <full_baseline>                                                      #
#                                                                         #
#                                                                         #
# History                                                                 #
# =======                                                                 #
# v1.1 Additional changes made due to feedback after testing              #
# v1.0 Initial version                                                    #
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

my %user_args;
my $baseline;
my $project;
my $suffix;
my $date;


###########################################################################
#                                                                         #
# SUBROUTINES                                                             #
#                                                                         #
###########################################################################

sub Append_Index {      # $str, $base
  # Checks to see what baselines have been created today; if >1, any 
  # subsequent baselines will have an index number at the end. Find the 
  # highest index number and increment it for the new baseline.
  #
  my ($str, $base) = (@_);
  chomp (@existing = qx/cleartool lsbl -s -stream $str/);
  my $index = 0;
  foreach my $current (@existing) {
    if ($current =~ /^$base\-?(\d+)?$/) {
      if ($1) {
        $index = $1 + 1 if $1 >= $index;
      } else {
        $index = 1;
      }
    }
  }
  if ($index) {
    $base .= "-$index";
    print "New baseline = $base\n";
  }
  return $base;
}


sub Create_Baseline {   # $bl
  # Takes the baseline provided, creates a new View on the Project's 
  # Integration stream, baselines it and removes the View
  #
  my $bl = $_[0];
  my @details = qx/cleartool lsproj -l $project/;
  foreach my $line (@details) {
    next unless $line =~ /integration stream:/;
    my $stream = (split / /, $line)[-1];
    qx/cleartool mkview -tag mkbaseline_script -stream $stream -stgloc -auto/;
    $bl = &Append_Index($stream, $bl);
    qx/cleartool mkbl -c "Created using mkbaseline.pl" -all -identical -full -view mkbaseline_script $bl/;
    # check to see if there's no changes to baseline, and inform the user!!
    # <<GMS>>
    qx/cleartool rmview -tag mkbaseline_script/;
  }
}


sub Get_Args {
  # Takes the arguments provided and loads them into a hash table in pairs
  #
  my $return = 0;
  $return = 1 if @ARGV;
  while (@ARGV) {
    unless ($ARGV[0] =~ /^-[psoh]$/) {
      &Show_Help();
      $return = 0;
      exit;
    }
    if ($ARGV[1]) {
      $user_args{lc($ARGV[0])} = $ARGV[1];
    } else {
      $user_args{lc($ARGV[0])} = 1;
    }
    shift @ARGV;
    shift @ARGV;
  }
  unless ($user_args{"-p"}) {
    print "No Project has been provided\n";
    &Show_Help();
  }
  unless ($user_args{"-o"} or $user_args{"-s"}) {
    print "Neither an override (-o) or suffix (-s) have been provided\n";
    &Show_Help();
  }
  if ($user_args{"-o"} and $user_args{"-s"}) {
    print "Both override (-o) and suffix (-s) have been provided;\n";
    print "These parameters are mutually exclusive; please use one or the\n";
    print "other\n";
    &Show_Help();
  }
  return $return;
}


sub Get_Date_String {
  # Returns a timestamp string to be used in the baseline.
  #
  my ($sec, $min, $hr, $mday, $mon, $yr, $wday, $yday, $isdst) =
    localtime(time);
  $yr += 1900;
  $mon++;
  my $timestamp = $yr . 
    sprintf("%02d%02d", $mon, $mday);
#  $timestamp .= "." .                          # No longer needed
#    sprintf("%02d%02d%02d", $hr, $min, $sec);  # No longer needed
  return $timestamp;
}


sub Show_Help {
  # Displays help text.
  print "

    mkbaseline.pl
    =============

    This script uses the following arguments:

      -p <ClearCase_Project_Name>\t(must include PVOB)
      
      -s <Project_Suffix>
    OR
      -o <Baseline>\t\t\t(Overwrites defaults)


    Examples:
    ccperl mkbaseline.pl -p RadioTuner\@\\stc_pvob_src -s 1.0
           ... creates RadioTuner-1.0-20131014
    ccperl mkbaseline.pl -p SDARS\@\\stc_pvob_src -o mybaseline
           ... creates mybaseline

  ";
  exit;
}


###########################################################################
#                                                                         #
# MAIN SCRIPT                                                             #
#                                                                         #
###########################################################################

{
  &Show_Help unless &Get_Args();
  if ($user_args{"-h"}) {
    # They've asked for help
    &Show_Help();
  }
  $project = $user_args{"-p"};
  my $return = qx/cleartool lsproj -s $project 2>&1/;
  if ($return =~ /Error: Project not found/) {
    print "Cannot find Project $project - aborting\n\n";
    exit;
  }
  if ($user_args{"-o"}) {
    $baseline = $user_args{"-o"};
  } else {
    $suffix = $user_args{"-s"};
    $date = &Get_Date_String();
    my $pr = (split /\@/, $project)[0];
    $baseline = "$pr-$suffix-$date";
  }
  print "Baseline = $baseline\n";
  &Create_Baseline($baseline);
}

