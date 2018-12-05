œ#!/user/bin/perl -w
##########################################################################
#                                                                        #
# add_files_to_sourcecontrol.pl                                          #
# v0.2                                                                   #
# Garry Short, 08/12/08                http://www.saxon-down.com/scripts #
#                                                                        #
# Recursively adds view-private files to source-control.                 #
# The -file functionality is not currently supported!                    #
#                                                                        #
# HISTORY                                                                #
# v0.2 08/12/08                                                          #
#      Added functionality for handling snapshot views                   #
# v0.1 19/09/08                                                          #
#      Initial version                                                   #
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
my %excluded_extension = (
  "suo"                                 => 1,
  "mkelem"                              => 1,
  "old"                                 => 1,
  "keep"                                => 1,
  "swp"                                 => 1
);
my %excluded_file = (
  "add_files_to_sourcecontrol.pl"       => 1
);
my $input_source = $ARGV[0];
my $input = $ARGV[1];
my $stderr = "h:\\stderr.log";


# Variables
my ($error, $parent);



##########################################################################
#                                                                        #
# Subroutines                                                            #
#                                                                        #
##########################################################################

sub Display_Help {
  # Outputs the Usage instructions for this script.
  #
  print "
    add_files_to_sourcecontrol.pl
    =============================

    Running this script will recursively add all files within the specified
    folder to source control. 

    This script expects one of two arguments:
        -path <path>
             This scans a subfolder for view-private files and adds them
             to source control.
        -file <textfile>
             When provided a list of files, it searches for and specifically
             adds those files. This is useful for when you've provided a
             third party with a list of the view-private files, so that 
             they can reply and let you know which ones specifically need
             to be added (the rest being ignored). THIS IS NOT CURRENTLY
             FUNCTIONAL!

    Note: This version is limited in that the script has to be copied into
          the folder structure you wish to add, but it won't add itself to
          source control.


  ";
  exit;
}


sub Read_STDERR {               # $command
  # When passed a system command, execute it and divert STDERR to a 
  # temporary file. Then read the error into memory, delete the temporary
  # file, and return the error to whatever's called us.
  #
  my ($command) = (@_);
  # Execute the command, diverting STDERR to the temporary file we've
  # specified. Print out STDOUT as normal.
  print qx/$command 2> $stderr/;
  my $return = "";
  if (-e $stderr) {
    open FILE, $stderr;           # Open the STDERR file we've created
    $return = <FILE>;             # Read it into memory
    close FILE;
    unlink $stderr;               # Delete the temporary file
    print "STDERR: $return" if $return;
  }
  return $return;               # Return the error that was generated
}


##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  &Display_Help() unless $input;        # We've not been provided 2 args
  if ($input_source =~ /^\-path$/i) {
    # We've been provided a path to process
    $parent = $input;                   # Grab the path we were provided
    # Now work out which kind of view we're using so that we can issue the
    # relevant command to get a list of view-private files
    my $view_details = qx/cleartool lsview -l -cview/;
    if ($view_details =~ /View attributes: snapshot/) {
      # Snapshot view
      @vp = qx/cleartool ls -recurse -view_only "$parent" 2>> $stderr/;
    } else {
      # Dynamic view
      @vp = qx/cleartool lsprivate "$parent" 2>> $stderr/;
    }
    @vp = sort @vp;
    chomp @vp;
    foreach my $elem (@vp) {
      next if $elem =~ /\[checkedout\]/;        # File's checked out!
      my $extension = (split /\./, $elem)[-1];  # Get the file extension
      next if $excluded_extension{$extension};  # Skip if it's in the list
      next if $elem =~ /\\bin\\/;               # Don't want this
      next if $elem =~ /\\obj\\/;               # .. or this
      $parent = $elem;
      $parent =~ s/\\[^\\]*$//;
      $error = &Read_STDERR("cleartool co -nc \"$parent\"");
      if (-d $elem) {                           # This is a folder, so ...
        # We can't create a folder element while the folder's in the way ..
        my $old = "$elem" . "\.old";            # .. so back it up
        $error = &Read_STDERR("move \"$elem\" \"$old\"");
        # Now the original's out of the way, we can create the folder
        $error = &Read_STDERR(
          "cleartool mkelem -eltype directory -nc \"$elem\""
        );
        # Now copy the original back into place .
        $error = &Read_STDERR(
          "xcopy \/E \/I \/Y \"$old\\*.*\" \"$elem\""
        );
        # .. Check it in ..
        $error = &Read_STDERR("cleartool ci -nc \"$elem\"");
        # .. and delete the backup copy
        $error = &Read_STDERR("rmdir \/S \/Q \"$old\"");
      } else {
        # Create the element and check it in
        $error = &Read_STDERR("cleartool mkelem -nc \"$elem\""); 
        $error = &Read_STDERR("cleartool ci -nc \"$elem\"");
      }
      # Check in the parent folder
      $error = &Read_STDERR("cleartool ci -nc \"$parent\"");
    }
  } elsif ($input_source =~ /^\-file$/i) {
    # We've got an input file, so we specifically want to add that list
    # of files/folders
  } else {
    # Wrong argument, so display the Help
    &Display_help();
  }
}

# TO DO:
# Write the functionality to accept an input file containing a list of files
# Read and handle messages in STDERR?
