#!/usr/bin/perl -w
##############################################################################################################
#                                                                                                            #
# Garry Short, 06/01/2004                                                                                    #
# v0.1                                                                                                       #
# Rewrite_CQ_Group_Info.pl                                                                                   #
# This script is to be used to flatten the existing FIRC CQ group structure. At the moment, CQ FIRC uses     #
# a large number of nested groups which are really hammering system performance. Having exported the user    #
# admin info, we now have a text file full of user and group definitions. The script will read this in,      #
# flatten it appropriately and write it back out to a file.                                                  #
#                                                                                                            #
##############################################################################################################

##############################################################################################################
#                                                                                                            #
# USES AND INCLUDES                                                                                          #
#                                                                                                            #
##############################################################################################################

use strict;


##############################################################################################################
#                                                                                                            #
# GLOBAL CONSTANTS AND VARIABLES                                                                             #
#                                                                                                            #
##############################################################################################################

# Constants
#
my $file = "p:\\live_userinfo.txt";
my $new_file = "p:\\new_live_userinfo.txt";
my @keys = (
  "    is_active      ",
  "    is_subscribed_to_all_dbs",
  "    members        ",
  "    subgroups      ",
  "    databases      "
);


# Variables 
#
my %records;					# Primary data storage (HoH)
my %group_levels;				# Used for determining which order to process the groups.
my @orderlist;					# The order list for processing the HoH (%records)


##############################################################################################################
#                                                                                                            #
# SUBROUTINES                                                                                                #
#                                                                                                            #
##############################################################################################################

sub Build_GroupLevel_Hash {			# ($href, $integer)
# Processes the HoH (%records) and builds a new hash, where each group name is a key, and the value is an 
# integer indicating the lowest level in the tree at which it is found (when processing the HoH, those groups
# with the highest values will need to be processed first).
#
  my ($href, $integer);
  foreach my $group (sort keys %records) {
    $integer = 0;
    my $group_data = $records{$group};
    if ($$group_data{$keys[3]}) {
      &Examine_SubGroup($$group_data{$keys[3]}, $integer, $group);
      &Write_GroupLevel_Hash($group, $integer);
    } else {
      &Write_GroupLevel_Hash($group, $integer);
    }
  }
}


sub Examine_SubGroup {				# ($str, $integer, $group)
# Provides the recursive element for &Build_GroupLevel_Hash
#
  my ($str, $integer, $group) = (@_);		# Set our variables to whatever we've been passed and ..
  $integer++;					# .. increment our current level
  my @subgroups = split / /, $str;		# .. find out what they all are ..
  if (@subgroups) {
    foreach my $next (@subgroups) {		# .. and process each in turn.
      my $complete_record = $records{$next};
      &Examine_SubGroup($$complete_record{$keys[3]}, $integer, $next);
      &Write_GroupLevel_Hash($group, $integer);
    }
  } else {					# This group has no subgroups, so ..
    &Write_GroupLevel_Hash($group, $integer);
  }
}


sub Generate_GroupOrder {
# Takes the %group_levels hash and inverts it (swaps the keys and values around so that the keys are integer 
# values, and the "values" are space-separated lists of group names. It then takes the inverted hash and 
# transfers it to the orderlist array.
# 
  my %temp_hash;				# Temporary hash
  foreach my $group (keys %group_levels) {	# Work through the group_levels hash ..
    my $value = $group_levels{$group};
    $temp_hash{$value} .= " $group";		# .. swap the key/val over and load it into the temp.hash
    $temp_hash{$value} =~ s/^ //;		# Strip out any leading spaces
  }
  foreach my $value (reverse sort keys %temp_hash) {	# Now process the temp.hash
    my @group = split / /, $temp_hash{$value};	# Generate the list of groups in the current key ..
    push (@orderlist, @group);			# .. and append them to the @orderlist array.
  }
  %temp_hash = ();
}


sub Process_All_Groups {
# This subroutine actually does the work of rewriting the HoH.
#
  foreach my $group (@orderlist) {		# Process each group in the HoH
    my $href = $records{$group};		# Get the current group
    my @subgroups = split / /, $$href{$keys[3]};	# Find out what it's subgroups are ..
    foreach my $subgroup (@subgroups) {		# .. and loop through them.
      my $temp = $records{$subgroup};		# For each subgroup, get it's group info ..
      my $members = $$temp{$keys[2]};		# .. and find it's members list.
      if ($$href{$keys[2]}) {
        $$href{$keys[2]} .= " $members";		# Append it to the parent group's members list
      } else {
	$$href{$keys[2]} = $members;
      }
    }
    $$href{$keys[3]} = "";			# Now clear the parent group's subgroups list
    my %temp_mem;				# Now need to unique sort the members list, so ..
    foreach my $mem (split / /, $$href{$keys[2]}) {	# Break the members string into an array and loop thru
      $temp_mem{$mem} = 1;			# Load the member into a hash (don't care if he's already there)
    }
    my $new_mems = "";
    foreach my $mem (sort keys %temp_mem) {	# Now loop through the sorted members hash ..
      if ($new_mems) {				# .. and append onto a string
	$new_mems .= " $mem";
      } else {
	$new_mems = $mem;
      }
    }
    $$href{$keys[2]} = $new_mems;		# Now write the new members string back to the hash ..
    %temp_mem = ();
    $records{$group} = $href;			# .. and store back in %records.
  }
}


sub Read_File {
# Reads the file into a Hash of Hashes (stored in the global variable %records).
#
  my $default = $/;				# Take a note of the default record seperator
  $/ = "\n\n";					# Reset the record seperator before importing the file
  open FILE, $file or die "Can't open $file: $!\n";
  chomp (my @data = <FILE>);			# Import the file into memory
  close FILE;
  $/ = $default;				# Set the record seperator back to default.
  foreach my $record (@data) {			# Process each record
    my @elems = split /\n/, $record;		# Split the record into lines
    my (%record_data, $group);
    foreach my $e (@elems) {			# For each line in the record ..
      my ($key, $value);
      if ($e =~ /^GROUP (.*)/) {		# Make a note of the group name, or ..
	$group = $1;
      } else {
        ($key, $value) = split / = /, $e;	# .. split the line into a key/value pair
        $record_data{$key} = $value;		# .. and then load the data into a temporary hash
      }
    }
    $records{$group} = \%record_data;		# Then load that temp.hash into the records hash (stored by grp)
  }
}


sub Write_File {
# Takes the global HoH (%records) and writes it out to a file.
  open FILE, ">$new_file" or die "Can't write to $new_file: $!\n";
  foreach my $key (sort keys %records) {	# Process each record ..
    print FILE "GROUP $key\n";			# .. print the group name to the file ..
    my $href = $records{$key};
    foreach my $k (@keys) {			# .. then do the same with each key/value pair
      my $v = $$href{$k};
      if ($v) {
        print FILE "$k = $v\n";
      } else {
	print FILE "$k =\n";
      }
    }
    print FILE "\n";
  }
  close FILE;					# Now close and save the file.
}


sub Write_GroupLevel_Hash {
# Checks to see if the current group is stored in the group_levels hash; if it is, it compares the current 
# value to the stored one, and writes the current value in if it is greater. If the group is not already in 
# the hash, it simply adds it.
  my ($group, $integer) = (@_);
  if ($group_levels{$group}) {			# Check to see if we've stored this group yet.
    if ($group_levels{$group} <= $integer) {	# If we have, check the new value is <= stored value ..
      $group_levels{$group} = $integer;		# .. and overwrite
    }
  } else {
    $group_levels{$group} = $integer;		# Otherwise, just write the group data.
  }
}

    
##############################################################################################################
#                                                                                                            #
# MAIN                                                                                                       #
#                                                                                                            #
##############################################################################################################

{
  &Read_File;
  &Build_GroupLevel_Hash;
  foreach my $group (sort keys %group_levels) {
    my $val = $group_levels{$group};
  }
  &Generate_GroupOrder;
  &Process_All_Groups;
  &Write_File;
}


