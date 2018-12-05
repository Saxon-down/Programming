#!/usr/bin/perl -w
###########################################################################
#                                                                         #
# Garry Short, 23/04/2013                                                 #
# supplier_release.pl v1.1                                                #
#                                                                         #
# <DESCRIPTION>                                                           #
# Finds all baselines which have been created by JLR's Partners. It then  #
# filters out anything over a month old, and any baselines which match    #
# certain name criteria.                                                  #
# For those that are left, it generates a new Project whenever one        #
# doesn't exist, and also creates an Integration stream. Finally it works #
# out whether a View has been created, and creates any which are missing. #
#                                                                         #
# History                                                                 #
# =======                                                                 #
# v1.1 10/06/14                                                           #
#      Updated the script; when finding a new supplier_baseline, see if   #
#      that component is used in the continuous integration Project; if   #
#      it is, update the Project with the new baseline                    #
# v1.0 Initial version                                                    #
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

my $JLR_PVOB = "ngi_pvob_si";
my $STC_PVOB = "stc_pvob_si";
my $STC_Folder = "ThirdParty_Deliveries";
my $STC_Releases = "$STC_Folder\@\\$STC_PVOB";
my $config = "supplier_releases.ini";
my %special_streams;
my %special_components;


###########################################################################
#                                                                         #
# SUBROUTINES                                                             #
#                                                                         #
###########################################################################

sub Check_Comp_vs_Config {  # $bl
  # Compares the component with the list of special_components .. if it's a match
  # we need to look up the special_streams and update their baseline list with
  # this new one.
  #
  my ($bl) = (@_);
  print "DEBUG: CCvC: $bl\n";
  chomp(my $comp = qx/cleartool lsbl -fmt "%[component]Xp" $bl/);
  $comp = (split /:/, $comp)[1];
  if ($special_components{$comp}) {
    print "DEBUG: CCvC: sc=$comp\n";
    # We've got Project(s) that need to be updated with this baseline
    foreach my $str (sort keys %special_streams) {
      print "DEBUG: CCvC: processing str=$str\n";
      # create view
      qx/cleartool mkview -tag supplier_releases -stream $str -stgloc -auto/;
      # cleartool rebase -baseline <blah> .. do we need to rebase -dbaseline <old> first?
      qx/cleartool rebase -baseline $bl -view supplier_releases/;
      qx/cleartool rebase -complete -view supplier_releases/;
      # remove view
      qx/cleartool rmview -tag supplier_releases/;
      ### WHAT HAPPENS IF STREAM DOESN'T HAVE COMPONENT BASELINE TO UPDATE??
      ## Only need to use lsstream if we're doing rebase -dbaseline <old>
    }
  }
}


sub Find_Baselines {    # $component
  # Given a component, returns a list of its baselines
  #
  my ($component) = (@_);
  chomp (my @list = qx/cleartool lsbl -s -component $component/);
  return @list;
}


sub Find_Components {       # $vob
  # Given a PVOB, generates a list of components which are associated with it
  #
  my ($vob) = (@_);
  chomp(my @components = qx/cleartool lscomp -s -invob \\$vob/);
  return @components;
}


sub JLR_Find_Baselines {
  # Find out which Baselines have been created so far.
  #
  my @baselines;
  # No easy way to generate a list of baselines in a PVOB, so need to do it
  # component by component.
  my @components = &Find_Components($JLR_PVOB);
  foreach my $comp (@components) {
    push(@baselines, &Find_Baselines($comp));
  }
  ### DEBUG - just here for testing!!
  push(@baselines, &Find_Baselines("STC_TstBinGer_si\@\\training_pvob"));
  ### END_DEBUG
  return sort @baselines;
}


sub old_baseline {      # $baseline
  # Checks to see if a baseline is more than a month old.
  #
  my ($baseline) = (@_);
  chomp (my @details = qx/cleartool lsbl $baseline 2>&1/);
  if ($details[0] =~ /^cleartool: Error:/) {
    print "Baseline not found: $baseline\n";
    return 1;
  } else {
    my $timestamp = (split /T/, $details[0])[0];
    my ($bl_yr, $bl_mon, $bl_day) = split /-/, $timestamp;
    $timestamp = qx/date \/T/;
    my ($curr_mon, $curr_day, $curr_yr) = 
                      split /\//, (split / /, $timestamp)[1];
    my $age = (365 * ($curr_yr - 2010)) +
              (30 * ($curr_mon - 1)) +
              $curr_day;
    $age -=  ((365 * ($bl_yr - 2010)) +
              (30 * ($bl_mon - 1)) +
              $bl_day);
    if ($age > 30) {
      return 1;
    } else {
      return 0;
    }
  } 
}


sub import_config {
  # We're in Germany so open the config file and extract it
  #
  my ($ss, $sc);
  open CFG, $config or die "Cannot open config file $config: $!\n";
  chomp(my @cfg = <CFG>);
  close CFG;
  foreach my $line (@cfg) {
    if ($line =~ /\[SPECIAL_STREAMS\]/) {
      $ss = 1;
    } elsif ($line =~ /\[END_SS\]/) {
      $ss = 0;
    } elsif ($line =~ /\[SPECIAL_COMPONENTS\]/) {
      $sc = 1;
    } elsif ($line =~ /\[END_SC\]/) {
      $sc = 0;
    } else {
      print "debug:$line\n";
      $special_streams{$line} = 1 if $ss;
      $special_components{$line} = 1 if $sc;
    }
  }
  print "CONFIG imported\n";
}

sub STC_Check_Region {
  # We only want new Projects to be created in Germany, where they can then 
  # replicate out to India. However, India also wants to check that the 
  # relevant View exists
  #
  chomp (my $hostname = qx/hostname/);
  if ($hostname =~ /denu/i) {
    &import_config();
    return "GER";
  } else {
    return "IND";
  }
}


sub STC_Create_Project {        # $baseline
  # Takes a Supplier baseline and creates a new Project in the relevant
  # folder. It then creates a Stream for that Project and adds the required
  # Component Baseline. Finally, it hands off to &STC_View_Missing() to 
  # create a View for it.
  #
  my ($baseline) = (@_);
  chomp (my @details = qx/cleartool lsbl $baseline/);
  my $component = (split / /, $details[-1])[-1];
  $component =~ s/\@.*$//;      # Strip off PVOB info
  $component =~ s/_si$//;       # Strip off "_si";
  $component =~ s/_rel$//;      # Strip off "_rel";
  if (qx/cleartool lsfolder -s $component\@\\$STC_PVOB 2>&1/ =~ 
                  /cleartool: Error: Folder not found/) {
    # Need to create the folder
    print qx/cleartool mkfolder -nc -in $STC_Folder $component\@\\$STC_PVOB/;
    # Now create the Project
  }
  print "DEBUG:STC_CP:$baseline\n";
  if ($baseline =~ /$JLR_PVOB/) {
    $baseline =~ s/\@.*$//;
    print qx/cleartool mkproj -nc -in $component $baseline\@\\$STC_PVOB/;
    # Next step - create an Integration stream for our new Project
    my $command = "cleartool mkstream -integration -in project:$baseline" .
        "\@\\$STC_PVOB -nc -baseline $baseline\@\\$JLR_PVOB $baseline" .
        "_Int\@\\$STC_PVOB";
    print qx/$command/;
    # Finally, create a View
    &STC_View_Missing($baseline);
  }
}


sub STC_Find_Projects {
  # Generates a list of Projects which exist within the $STC_Folder folder
  # structure, and returns it as a hash table.
  #
  my %Projects;
  chomp (my @projects = qx/cleartool lsproj -s -in $STC_Releases -recurse/);
  foreach my $proj (@projects) {
#    print "DEBUG:STC_FP:$proj\n";
    $Projects{$proj} = 1;
  }
  return %Projects;
}


sub STC_View_Missing {  # $project
  # Takes a Project and sees if a View exists for it. If not, it creates one
  #
  my ($project) = (@_);
  my $stream = $project . "_Int";
  # Check to see if a View exists
  chomp (my $string = qx/cleartool lsview -s BL_$project 2>&1/);
  if ($string =~ /cleartool: Error: No matching entries/) {
    # Not found a View, so need to create one.
    my $command = "cleartool mkview -tag BL_$project -stream $stream\@\\" .
          "$STC_PVOB -stgloc -auto";
    qx/$command/;
  }
}


###########################################################################
#                                                                         #
# MAIN SCRIPT                                                             #
#                                                                         #
###########################################################################

{
  my %STC_Projects = &STC_Find_Projects();
  if (&STC_Check_Region() eq "GER") {
    # We only check for new baselines and create Projects in Germany
    print "DEBUG: we're on GER\n";
    my @JLR_Baselines = &JLR_Find_Baselines();
    foreach my $bl (sort @JLR_Baselines) {
      next if $bl =~ /INITIAL$/;        # Don't care about INITIAL baselines
      next if $bl =~ /ucm_start$/;      # Don't care about these either
      next if $bl =~ /_test_/i;         # .. or these!
      next if $bl =~ /_BINARY_/;        # Auto-created by JLR OBS/Jenkins
      next if $bl =~ /_REPORT_/;        # Auto-created by JLR OBS/Jenkins
      my $bl2 = $bl;
      $bl2 =~ s/\@.*$//;
      next if &old_baseline($bl);
      next if $STC_Projects{$bl2};      # This Baseline already has a Project
      # Also skip baselines more than a certain age, since it means we've
      # manually removed the Project.
      print "DEBUG:MAIN:Through the next loop\n";
      &STC_Create_Project($bl);
      &Check_Comp_vs_Config($bl);
    }
  } else {
    # Not Germany, so only need to create any missing Views
    foreach my $proj (sort keys %STC_Projects) {
      if (&STC_View_Missing($proj)) {
      }
    }
  }
}


