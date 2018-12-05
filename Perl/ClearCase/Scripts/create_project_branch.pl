#!/usr/bin/perl -w
###########################################################################
#                                                                         #
# Garry Short, 21/03/14                                                   #
# create_project_branch.pl v1.0                                           #
#                                                                         #
# <DESCRIPTION>                                                           #
# Creates a new Project off an existing Project. Also takes a list of     #
# RPM versions, finds when they were added to ClearCase and copies them   #
# and their associated files into the newly created Project.              #
#                                                                         #
# History                                                                 #
# =======                                                                 #
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

my $inifile = "create_project_branch.ini";
my $new_project;        # Should be from config file
my $in_folder;          # Should be from config file
my $source_baseline;    # Should be from config file
my @rpm_list;           # Should be from config file
my @file_list;          # Complete list of rpm-related files to copy
my $tempfolder = "c:\\cpbtemp"; # Need a temp location to copy them to
my %found_rpms;


###########################################################################
#                                                                         #
# SUBROUTINES                                                             #
#                                                                         #
###########################################################################


sub Initialise {
  open FILE, $inifile or die "Error, cannot find INI file:$_\n";
  chomp (my @contents = <FILE>);
  close FILE;
  foreach my $line (@contents) {
    next if $line =~ /^#/;      # Ignore comments
    next if $line =~ /^$/;      # Ignore empty lines
    if ($line =~ /NEW_PROJECT=/i) {
      $new_project = (split /=/,$line)[1] . "\@\\stc_pvob_si";
    }
    if ($line =~ /IN_FOLDER=/i) {
      $in_folder = (split /=/, $line)[1] . "\@\\stc_pvob_si";
    }
    if ($line =~ /SOURCE_BASELINE=/i) {
      $source_baseline = (split /=/, $line)[1] . "\@\\stc_pvob_si";
    }
    if ($line =~ /CHANGED_RPM=/i) {
      push(@rpm_list,(split /=/, $line)[1]);
    }
  }
  print "Initialising ...\n";
  print "Project = $new_project\n";
  print "Folder = $in_folder\n";
  print "Baseline = $source_baseline\n";
  print "RPMs = [@rpm_list]\n\n";
}


sub Create_Project { # $project, $folder, $baseline
  my ($prj, $fldr, $bl) = (@_);
  print "\nCreate_Project($prj, $fldr, $bl)\n";
  my $int = my $view = $prj;
  $int =~ s/\@/_Int\@/;
  $view =~ s/\@.*$/_Int/;
  my $mkproj_args = "-nc -modcomp stc_int\@\\stc_pvob_si " .
    "-in $fldr $prj";
  print "## ct mkproj $mkproj_args\n";
  print qx/cleartool mkproj $mkproj_args/;
  my $mkstr_args = "-integration -in $prj -nc " .
    "-baseline $bl $int";
  print "## ct mkstr $mkstr_args\n";
  print qx/cleartool mkstream $mkstr_args/;
  print qx/cleartool mkview -tag $view -stream $int -stgloc -auto/;
  return $view;
}


sub Locate_RPM {
  print "Searching ..\n";
  chomp(my @blist = 
    qx/cleartool lsbl -s -comp stc_int\@\\stc_pvob_si/
  );
  my $counter = 0;
  foreach my $curr (reverse @blist) {
    $counter++;
    print ".";
    $curr .= "\@\\stc_pvob_si";
    print "Checking $curr\n";
    chomp (my @results = qx/cleartool diffbl -predecessor -elements $curr/);
    foreach my $line (@results) {
      foreach my $curr_rpm (@rpm_list) {
        next if $found_rpms{$curr_rpm};
        if ($line =~ /$curr_rpm/) {
          $found_rpms{$curr_rpm} = $curr;
          print "\n$curr_rpm found in $curr\n";
        }
      }
    }
  }
  print "\n\n";
  foreach my $k (sort keys %found_rpms) {
    my $v = $found_rpms{$k};
    print "[$k] => [$v]\n";
  }
  print "\n\n";
  &Copy_RPMs();
}


sub Copy_RPMs {
  print "\nCopy_RPMs\n";
  qx/mkdir $tempfolder/;
  foreach my $rpm (sort keys %found_rpms) {
    my $bl = $found_rpms{$rpm};
    print "\nCopy_RPMs:Scanning $bl for $rpm ...\n";
    my $v = &Create_Project("cpb_$bl", "cpb.pl\@\\stc_pvob_si", $bl);
    qx/cleartool startview $v/;
    print "\n";
    my $currpath = "m:\\$v\\stc_binaries_si\\stc_int";
    chdir $currpath;
    print "Calling Scan_Dir($currpath, $tempfolder, $rpm)\n";
    &Scan_Dir("$currpath", "$tempfolder", "$rpm");
  }
#  qx/rmdir \/S \/Q $tempfolder/;
}


sub Scan_Dir {  # $path, $dest, $file
  my ($path, $dest, $file) = (@_);
  print "Scan_Dir($path, $dest, $file)\n";
  opendir DIR, $path;
  my @children = readdir DIR;
  closedir DIR;
  foreach my $c (@children) {
    next if $c =~ /^\.\.?$/;    # Skip . and ..
    &Scan_Dir("$path\\$c", "$dest\\$c", $file) if (-d "$path\\$c");
    if ($c =~ /$file/) {        # Found a match
      print "mkdir \"$dest\"\n";
      qx/mkdir "$dest"/;
      print "xcopy \/V \"$path\\$c\" \"$dest\\$c\"\n"; 
      qx/echo F | xcopy \/V "$path\\$c" "$dest\\$c"/;
    }
  }
}

###########################################################################
#                                                                         #
# MAIN SCRIPT                                                             #
#                                                                         #
###########################################################################

{
  &Initialise();
  &Locate_RPM();
}


