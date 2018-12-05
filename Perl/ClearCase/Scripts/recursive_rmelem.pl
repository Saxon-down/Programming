#!/user/bin/perl -w
##########################################################################
#                                                                        #
# recursive_rmelem.pl                                                    #
# v0.1                                                                   #
# Garry Short, 21/04/08                http://www.saxon-down.com/scripts #
#                                                                        #
# Given a path, it recursively builds a list of elements to remove and   #
# then destroy them.                                                     #
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


##########################################################################
#                                                                        #
# Subroutines                                                            #
#                                                                        #
##########################################################################

sub Display_Usage {
  # Displays instructions on how to use this script.
  #
  print
    "\nrecursive_rmelem.pl\n" .
    "-------------------\n\n" .
    "Please pass the folder you wish to work on as an argument to this:\n" .
    "e.g. ccperl recursive_rmelem.pl \\my_view\\my_vob\\folder1\\folder2\n".
    "\nNote:\n" .
    "You can also provide a 2nd argument (-list) to just generate a\n" .
    "list of files to be removed\n\n"
  ;
  exit;
}


sub Nuke_Elem {         # $file
  # Takes an element and performs rmelem to destroy it.
  #
  my ($file) = (@_);
  my $result = qx/cleartool rmelem -f -nc $file/;
  print $result;
}


sub Scan_Dir {          # $path
  # Generates a list of elements
  #
  my ($path) = (@_);
  my @return;
  # Read the contents of the current directory into memory
  opendir DIR, $path or die "Can't open DIR $path:$!\n";
  chomp (my @files = readdir(DIR));
  closedir DIR;
  foreach my $f (@files) {      # Process each file in turn
    next if $f eq ".";          # Skip this - don't care about it
    next if $f eq "..";         # .. and same here
    $f = $path . "\\" . $f;     # Turn the file into a full path
    push (@return, $f);         # .. and add it to the return list
    if (-d $f) {                # If the file's a directory ..
      my $aref = &Scan_Dir($f); # .. recursively loop to process it
      push (@return, @$aref);   # .. and add it's children to the return list
    }
  }
  return \@return;              # Return everything we've found
}


##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  my $path = $ARGV[0];
  print "LIST mode!\n\n" if $ARGV[1];
  &Display_Usage unless $path;
  my $flist = &Scan_Dir($path);         # Grab the folder we need to process
  foreach my $f (reverse sort @$flist) {
#    print "$f\n";
    next if $ARGV[1];                   # If 2 args are passed, assume this
                                        #   run is just to display the files
    &Nuke_Elem($f);
  }
}
