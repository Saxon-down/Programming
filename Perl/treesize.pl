#!/user/bin/perl -w
##########################################################################
#                                                                        #
# treesize.pl                                                            #
# v0.1                                                                   #
# Garry Short, 11/08/08                http://www.saxon-down.com/scripts #
#                                                                        #
# Mimics UNIX's du command                                               #
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
my $initial_dir = $ARGV[0];
my $total = 0;

# Variables


##########################################################################
#                                                                        #
# Subroutines                                                            #
#                                                                        #
##########################################################################

sub format_number {     # $integer
  # Takes a numeric string and turns it into human-readable formatted (i.e.
  # inserts the commas where appropriate). Also limits it to 2 decimal places
  #
  my ($size) = (@_);
  $size = $size/1024;                   # Convert from bytes to kb
  $size = sprintf "%.2d", $size;        # Reduce it to 2 decimal places
  $size = reverse $size;                # Insert the commas ...
  $size =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
  $size = reverse $size;
  return $size;                         # Returns the formatted number
}


sub Process_Dir {       # $path
  # Takes a path and scans it; for each file, looks up the size and adds it
  # to the total for this folder. It also adds that value to the running 
  # total for this tree, and returns that value to the calling routine. It 
  # then outputs the total size for this directory, and the summed size for
  # all subdirs.
  # Additionally, For each subdirectory it recursively calls itself.
  #
  my ($path) = (@_);
  # Read the directory
  opendir DIR, $path or die "Can't read DIR $path: $!\n";
  chomp (my @files = readdir DIR);
  closedir DIR;
  # Reset the totals
  my $current = 0;
  my $total = 0;
  foreach my $f (@files) {              # Loop through each file
    next if $f =~ /\.\.?$/;             # Skip . and ..
    if (-d "$path\\$f") {               # This is a subdirectory so ..
      $total += &Process_Dir("$path\\$f");      # .. call myself
    } else {                            # This is a file, so ..
      my $file = (-s "$path\\$f");      # .. find it's size
      $current += $file;                # .. and update the running total
      $total += $current;               # .. and the overall total
    }
  }
  # Now print the output.
  print &format_number($total) . " kb\t" .
    &format_number($current) . " kb\t" .
    "$path\n"
  ;
  return $total;
}


##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  print "TOTAL\tFOLDER\tPATH\n";
  $initial_dir =~ s/\\$//;              # Strip off the trailing \, if needed
  &Process_Dir($initial_dir);
}
