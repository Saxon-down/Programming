#!/user/bin/perl -w
##########################################################################
#                                                                        #
# calculate_path_lengths.pl                                              #
# v0.1                                                                   #
# Garry Short, 13/11/08                http://www.saxon-down.com/scripts #
#                                                                        #
# Walks a tree and calculates the path length of every element within it #
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
my $root_path;
my $minimum_size = 0;
my $sort_type = "A";
my %resultset;


##########################################################################
#                                                                        #
# Subroutines                                                            #
#                                                                        #
##########################################################################

sub Display_Help {
  # No arguments have been passed, so display the usage help
  #
  print "\n
  calculate_path_lengths.pl
  =========================\n
  This script takes a root path (absolute or relative) and walks through
  the entire sub-tree; for every leaf-node it finds, it will calculate 
  the total path length. There are two options that can be passed:
  
  \t<root_path>: the path you wish to scan.

  \t<minimum_length>: The minimum path length you wish to be informed of. 
  \t\tNot providing a value will result in the lengths of all paths being
  \t\treturned.

  \t<sort_type>: can be one of two options ...
  \t\t-s = the files are output in reverse order of size, largest first.
  \t\t-a = the files are sorted alphabetically by path.
  
  e.g. ccperl calculate_path_lengths.pl . 200 -s
  \twill run the script on the current folder. The output will be limited to
  \tpaths in excess of 200 characters, reverse-sorted by size.
  ";
}


sub Process_Folder {            # $path
  # Takes a path and scans it, working out the total length of each element.
  # If the current path contains subfolders, recursively calls itself to
  # process them too.
  #
  my ($path) = (@_);
  my $path_length;
  my @len = split //, $path;
  $path_length = scalar(@len);
  opendir DIR, $path or die "Can't read DIR $path: $!\n";
  my @dir = readdir DIR;
  closedir DIR;
  foreach my $elem (@dir) {     # We've read the DIR into memory
    next if $elem =~ /^\.\.?$/; # Skip . and ..
    @len = split //, $elem;
    $resultset{"$path/$elem"} = $path_length + scalar(@len);
    if (-d "$path/$elem") {    # We've found a subdir, so process that too
      &Process_Folder("$path/$elem");
    }
  }
}


##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  # First, find and process the arguments we've been provided, displaying
  # the usage file if anything's wrong.
  &Display_Help() unless $ARGV[0];      # No root argument's been passed
  $root_path = $ARGV[0];
  if ($ARGV[1]) {                       # We've been passed an optional arg
    if ($ARGV[1] =~ /^\d+$/) {          
      $minimum_size = $ARGV[1];         # It's a minimum size
    } elsif ($ARGV[1] =~ /^\-[aA]$/) {
      $sort_type = "A";                 # It's an alphabetical sort
    } elsif ($ARGV[1] =~ /^\-[aA]$/) {
      $sort_type = "S";                 # It's a sort by length
    } else {
      &Display_Help();                  # It's plain wrong!
    }
  }
  if ($ARGV[2]) {
    # We've found an alphabetical sort flag
    $sort_type = "A" if $ARGV[2] =~ /^\-[aA]$/;
    # We've found a reverse-size sort flag
    $sort_type = "S" if $ARGV[2] =~ /^\-[sS]$/;
    # We've found rubbish
    &Display_Help() unless $ARGV[2] =~ /^\-[aAsS]$/;
  }
  # Now to process the folder we've been given!
  &Process_Folder($root_path);
  if ($sort_type eq "A") {
    # We're outputting alphabetically, so ...
    foreach my $path (sort keys %resultset) {
      my $val = $resultset{$path};      # Get the path length
      if ($val > $minimum_size) {       # if it's greater than our minimum
        $val = sprintf "%3d", $val;     # .. format it into 3 digits ..
        print "$val\t$path\n";          # .. and print the information
      }
    }
  } else {
    # We're outputting in reverse size order, which is a bit more tricky ..
    # First generate a list of paths in the order we want them
    my @paths = reverse sort { $resultset{$a} <=> $resultset{$b} }
        keys %resultset;
    # Now process that list ..
    foreach my $path (@paths) {
      my $val = $resultset{$path};      # First get the size
      if ($val > $minimum_size) {       # Skip if it's below our limit
        $val = sprintf "%3d", $val;     # Format it to 3 digits ..
        print "$val\t$path\n";          # .. and output the information
      }
    }
  }
}
