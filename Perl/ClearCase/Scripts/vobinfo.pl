#!/usr/bin/perl -w
###########################################################################
#                                                                         #
# Garry Short, 06/02/2013                                                 #
# vobinfo.pl v1.1                                                         #
#                                                                         #
# <DESCRIPTION>                                                           #
# Takes one of several flags, and displays information about all VOBs     #
# that it can find within the registry server. All regions are checked.   #
#                                                                         #
# NOTE: calling the script without any arguments displays the usage guide #
#                                                                         #
# History                                                                 #
# =======                                                                 #
# v1.1 Added -replicas flag                                               #
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

my %sites = (
  "ger" => "GERMANY",
  "stc_ger" => "GERMANY",
  "stc_ind" => "INDIA",
  "jlr" => "JLR"
);
my $default_group = "STC\\Domain Users";
my $cc_group = "DE-NU-CLC-JLR-USR";


my %vobs;
my $reg_count;


###########################################################################
#                                                                         #
# SUBROUTINES                                                             #
#                                                                         #
###########################################################################

sub Check_Perms {       # $vob, @data
  # We've been passed a subsection of the data from cleartool describe;
  # process it and work out who the owner and group(s) are.
  #
  my ($vob, @data) = (@_);
  my ($owner, @groups);
  foreach my $line (@data) {
    next if $line =~ /^VOB ownership:/;
    if ($line =~ s/^    owner (.*)$/$1/) {      # Found the owner
      $owner = $line;
    }
    if ($line =~ s/^    group (.*)$/$1/) {      # Found (one of) the group(s)
      push (@groups, $line);
    }
  }
  return ($owner, join(", ", @groups));
}


sub Evil_Twin {         # $vob, $string
  # Checks to see whether Evil Twin detection is enabled, and if so what 
  # type.
  #
  my ($vob, $string) = (@_);
  my $return;
  if ($string =~ /\: disabled$/) {
    $return = "NONE";
  } elsif ($string =~ /\: enabled, case sensitive$/) {
    $return = "FULL";
  } elsif ($string =~ /\: enabled/) {
    $return = "PARTIAL";
  } else {
    $return = "ERROR";
  }
  return $return;
}


sub Find_Master {       # $vob, $string
  # Works out where the current VOB is mastered
  my ($vob, $string) = (@_);
  my $repl;
  foreach my $key (keys %sites) {
    # Check each of the defined sites for mastership
    $vob =~ s/\\//;
    $repl = $vob . "_" . $key;
    if ($string =~ /\: $repl/) {
      # Found the Master replica!
      $repl = $sites{$key};
      last;
    } else {
      # No match
      $repl = "";
    }
  }
  $repl = "CHECK_ME" unless $repl;      # Didn't find any matches!
  return $repl;
}


sub Get_VobList {
  # Generates a full voblist across all available Regions; stores all the 
  # information we're interested in as an array reference in a hash table.
  #
  chomp (my @regions = qx/cleartool lsregion/);         # Get Regions list
  my $counter = 0;
  foreach my $reg (@regions) {                          # Check each Region
    $reg_count = $#regions+1;         # $#region actually shows the offset
                                      # .. for the last cell, starting at 0
    $counter++;
    chomp (my @data = qx/cleartool lsvob -region $reg/);# Generate VOB list
    foreach my $line (sort @data) {
      my ($tag, $path);         # Only want tag and path; discard rest
      ($tag, $path) = (split /\s+/, $line)[1,2];
      $tag =~ s/\//\\/;
      next if $tag =~ /PTYPE2/;
      next if $tag =~ /training/i;
      my $temp;
      if ($vobs{$tag}) {
        # This VOB has been discovered before, so extract the data array
        $temp = $vobs{$tag};
      } else {
        # This VOB hasn't been discovered yet, so create blank data array
        foreach my $x (0..$#regions) {
          $$temp[$x] = "";
        }
        $$temp[0] = lc($path);          # Store the VOB storage path
      }
      $$temp[$counter] = $reg;          # Mark VOB as present in this Region
      $vobs{$tag} = $temp;              # Import data into hash
    }
  }
  # Now that we have a basic structure of VOBs, storage locations and the
  # regions they're in, we want to store additional data.
  foreach my $v (sort keys %vobs) {
    my ($pvob, $ucm, $vobtype, $master, $twin);
    my ($getting_perms, @perms);
    $master = "NOMASTER";
    # Most of the additional information we require is available from
    # cleartool describe, so we'll grab the output from that and then
    # extract and store the information we're interested in.
    chomp(my @details = qx/cleartool desc -l vob:$v/);
    foreach my $line (@details) {
      # Process the output we've received from cleartool describe
      $master = &Find_Master($v, $line) if ($line =~ /^  master replica:/);
      $pvob = 1 if $line =~ /^  project VOB$/;
      $twin = &Evil_Twin($v, $line) if $line =~ /^  evil twin detection:/;
      $getting_perms = 1 if $line =~ /^  VOB ownership:/;
      $getting_perms = 0 if $line =~ /^  [pm]/;
      push (@perms, $line) if $getting_perms;
      $ucm = 1 if $line =~ / -> /;
    }
    # Ownership details are spread across multiple lines so we've extracted
    # that whole lot so that we can process it separately
    my ($owner, $groups) = 
        &Check_Perms ($v, @perms) if ((@perms) and ($getting_perms == 0));
    $vobtype = &VOB_Type($pvob, $ucm);
    # Now that we have everything we want, we need to extract the existing 
    # data from the hash table, append the new information we've gathered, 
    # and reinsert it into the hash table
    my $data = $vobs{$v};
    push (@$data, $vobtype, $master, $twin, $owner, $groups);
    $vobs{$v} = $data;
}


sub Process_Arg {
  # Work out which flag this script was called with, and call the 
  # appropriate functions.
  #
  my @args = @ARGV;
  &Show_Help() unless @args; # No args were given, so show the Help
  &Show_Help() if $#args > 0;   # Too many args were given, so show the Help
  if ($args[0] =~ /^-show$/i) {
    &Selected_Show();
  } elsif ($args[0] =~ /^-perms$/i) {
    &Selected_Perms();
  } elsif ($args[0] =~ /^-regions$/i) {
    &Selected_Regions();
  } elsif ($args[0] =~ /^-list$/i) {
    print "Selected -list\n";
  } elsif ($args[0] =~ /^-triggers$/i) {
    &Selected_Triggers();
  } elsif ($args[0] =~ /^-replicas$/i) {
    &Selected_Replicas();
  } else {                      # An invalid arg was given, so show the Help
    &Show_Help();
  }
}


sub Selected_List {
  # Can't remember why I added this option, so it's left blank for now.
}


sub Selected_Perms {
  # Takes the information we've gathered about the VOBs, then extracts and
  # displays the owner and group(s) information. In the case of there being
  # more than one group listed, the first is the owning group, and the
  # successive ones are additional groups.
  #
  &Get_VobList();
  print "             VOB, Owner       , Group(s)\n";
  print "==================================================\n";
  foreach my $v (sort keys %vobs) {
    my $data = $vobs{$v};
    my ($owner, $groups) = (@$data)[-2, -1];
    printf "%20s %12s $groups\n", $v, $owner;
  }
  print "\n\n";
  }
}


sub Selected_Regions {
  # Takes the extracted information and displays the regions each VOB is
  # tagged in.
  #
  &Get_VobList();
  print "                 VOB : Region(s)\n";
  print "=========================================\n";
  foreach my $v (sort keys %vobs) {
    my @reg;
    my $data = $vobs{$v};
    foreach my $count (1..$reg_count) {
      push (@reg, (@$data)[$count]);
    }
    printf("%20s : ", $v);
    foreach my $entry (@reg) {
      if ($entry eq "") {
        print "           ";
      } else {
        printf("%10s ", $entry);
      }
    }
    print "\n";
  }
  print "\n\n";
}


sub Selected_Replicas {
  # Takes a list of VOBs and displays a list of replicas for each
  #
  &Get_VobList();
  my $repl_count = 1;   # Starting at 1 since 0 also gets counted as FALSE
  my %repls;
  print "                 VOB : Replica(s)\n";
  print "==================================================\n";
  foreach my $v (sort keys %vobs) {
    my @replicas;
    chomp (my @data = qx/multitool lsreplica -s -invob $v/);
    printf "%20s : ", $v;
    $v =~ s/\\//;
    $v .= "_";  # Appending "_" for the next search-and-replace
    foreach my $rep (@data) {
      $rep =~ s/$v//;   # Remove the VOB tag from replica name
      # Populate the replica hash and array
      if ($repls{$rep}) {       # Exists in hash, so look up array position
                                # and insert data in array
        $replicas[$repls{$rep}] = $rep;
      } else {                  # Not in hash, so add it and insert data in
                                # array.
        $repls{$rep} = $repl_count;
        $replicas[$repl_count] = $rep;
        $repl_count++;
      }
    }
    shift(@replicas);   # Throw away the first entry because we know it's
                        # empty.
    foreach my $rep (@replicas) {
      $rep = "  " unless $rep;
      printf "%9s", $rep;
    }
    print "\n";
  }
  print "\n\n";
}


sub Selected_Show {
  &Get_VobList();
  print "VOB, Path, Regions, TYPE, MASTER, EVIL TWINS, OWNER, GROUPS\n";
  print "===========================================================\n";
  foreach my $v (sort keys %vobs) {
    my $data = $vobs{$v};
    my $extracted = join ", ", @$data;
    print "$v, $extracted\n";
  }
  print "\n\n";
}


sub Selected_Triggers {
  &Get_VobList();
  foreach my $v (sort keys %vobs) {
    chomp(my @data = qx/cleartool lstype -kind trtype -s -invob $v/);
    printf "%20s : @data\n", $v;
  }
}


sub Show_Help {
  print "\n
  This script can be used with the following flags:

  -show         Generates and displays information about each VOB on the
                local server, including Tag, Type (Base, UCM, PVOB), where
                it's mastered (assuming it's a multisite VOB), whether 
                protectvob -evil_twin has been run, who the owner and groups
                are, and where it's stored.

  -perms        Runs through all VOBs on the local server and checks the 
                owner and group; if the owner is NOT desaccad it will 
                change it; it will also remove \"$default_group\" from the
                group list and replace it with $cc_group. 

  -regions      Goes through each VOB on the local server and checks which 
                Regions the VOB is tagged in. For any VOB that's not tagged
                in all Regions, you will be asked if you want to do that.

  -Replicas     Goes through all VOBs and generates a list of Multisite
                replicas for each.
  
  -triggers     Goes through each VOB in turn and checks that all of the 
                required triggers are applied; adds any which are missing.

  
  ";
  exit;
}


sub VOB_Type {  # $pvob, $ucm
  # Processes each VOB depending on whether it's PVOB, UCM or base
  my ($pvob, $ucm) = (@_);
  my $return;
  if ($pvob) {
    $return = "PVOB";
  } elsif ($ucm) {
    $return = "UCM";
  } else {
    $return = "BASE";
  }
  return $return;
}


###########################################################################
#                                                                         #
# MAIN SCRIPT                                                             #
#                                                                         #
###########################################################################

{
  &Process_Arg();
}
