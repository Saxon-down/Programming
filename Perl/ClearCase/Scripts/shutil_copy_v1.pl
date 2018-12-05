#!/usr/bin/perl -w
###########################################################################
#                                                                         #
# Garry Short, 16/06/14                                                   #
# shutil_copy.pl v0.1                                                     #
#                                                                         #
# <DESCRIPTION>                                                           #
# ClearCase interface for Paul's script; copies files, updates existing   #
# elements and creates new ones.                                          #
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

my $source;             # The path to the source files which should be imported
my $view;               # The path to the ClearCase view which will be used for the 
                        # import.
my @element_list;       # List of elements which needs to be processed
my @target_list;        # Need a list of elements in the target too
my %checkin_list;       # Elements that need to be checked in
my %check_source;       # @target_list in hash form for easy lookup
my $remove_required;    # Been asked to remove elements which aren't in source
my $debug_on;           # Has debug output been requested?
my $WHICHOS;
my $OSSEP;


my @excluded = qw/keep mkelem suo old swp/;     # Filetypes to be skipped
my $WINSEP = "\\";      # Used for $OSSEP
my UNIXSEP = "\/";      # Used for $OSSEP

###########################################################################
#                                                                         #
# SUBROUTINES                                                             #
#                                                                         #
###########################################################################

sub PanicMode {
# This script will be called by another script so sensible error codes
# would be useful. To that end, this provides a mechanism to handle that
#
  my ($error) = (@_);
  my $code;
  if ($error eq "path") { $code = 1;
  } elsif ($error eq "file") { $code = 2;
  } elsif ($error eq "copy") { $code = 3;
  } elsif ($error eq "remove") { $code = 4;
  } elsif ($error eq "clearcase") { $code = 11;
  } elsif ($error eq "view") { $code = 12;
  } elsif ($error eq "activity") { $code = 13;
  } elsif ($error eq "checkout") { $code = 14;
  } elsif ($error eq "checkin") { $code = 15;
  } elsif ($error eq "unco") { $code = 16;
  } elsif ($error eq "help") { $code = 91;          
    # &Display_Help() was triggered ... bad args?
  } elsif ($error eq "shutil") { $code = 999;
    # Generic error - not thought wbout this one yet
  } else { $code = 1001;
    # Unknown error string ... mis-typed?
  }
  &DEBUG("Exiting with error code $code ($error)");
  exit $code;
}


sub Display_Help {
  print "
    shutil_copy.pl
    ===============

    ccperl shutil_copy.pl -h[elp] | (-src <PATH> -view <PATH>) [-remove] [-debug]

      -src <PATH>       Where the files should be imported from
      -view <PATH>      Which View_Root you're using for the import (*1)
      -dst <PATH>       Relative destination within View_Root
      -remove           OPTIONAL: removes elements which aren't in source
      -debug            OPTIONAL: switches on verbose output

    (*1) Note that the View must exist and, for dynamic views, be started.
         Also the View must have an Activity already created and set.
         
         
    e.g.
    ccperl shutil_copy.pl -src c:\\temp m:\\myview\\codevob\\mypath
    ccperl shutil_copy.pl -src /temp ~/myview/codevob/mypath -remove
    ccperl shutil_copy.pl -src ~\\tempcode m:\\myview\\codevob\\mypath -remove -debug
  ";
  &PanicMode("help");
}


sub Copy_Source {       # $file
# Given a source file, checks to see if it exists in the View.
#
  # GMS - How much of this is no longer needed?
  my ($file) = (@_);
  &DEBUG("SUB Copy_Source $file");
  my $return = 0;
  my $elem_type;
  my $sourcefile = $file;
  my $csource = $source;
  $csource =~ s/\\/\\\\/g if $WHICHOS =~ /WIN/;
  &DEBUG("Copy_Source:");
  &DEBUG("  Source = $csource");
  &DEBUG("  View = $view");
  &DEBUG("Copy_Source: Before = $file");
  $file =~ s/$csource/$view/;
  &DEBUG("Copy_Source: After = $file");
  if (-e $file) {
    $return = 1;
    &DEBUG("    Updating $file");
    if (&Elem_IsCheckedout($file)) {
      &DEBUG("    Currently checkedout ...");
      $checkin_list{$file} = 1;
    } else {
      my $result = qx/cleartool co -nc \"$file\" 2>&1/;
      if ($result =~ /must be set to an activity/) {
        &DEBUG("Error: Your View doesn't have an Activity set. Please");
        &DEBUG("create one using cleartool mkactivity <name>; once you");
        &DEBUG("have an Activity, you can set it using cleartool setact");
        &DEBUG("<name>\n");
        &PanicMode("activity");
      }
      $checkin_list{$file} = 1;
    }
    &DEBUG("    copying ... ");
    if ($sourcefile =~ /$OSSEP\~/) {
      &DEBUG("Skipping tempfile $sourcefile");
    } else {
      &STC_Copy("$sourcefile", "$file");
    }
  } else {      # File doesn't exist, so we can create it
    &DEBUG("    Adding file $sourcefile");
    # We want to check for element_types
    if (-d $sourcefile) {                 # It's a directory
      $elem_type = "directory";
    } elsif (-B $sourcefile) {            # It's a binary file
      $elem_type = "compressed_file";
    } elsif (-f $sourcefile) {            # It's plain text
      $elem_type = "text_file";
    } else {                        # This shouldn't happen, so report it!
      &DEBUG("    ERROR: Can't recognise filetype for '$sourcefile'");
    }
    qx/cleartool mkelem -eltype $elem_type -nc \"$file\"/;
    &STC_Copy("$sourcefile", "$file");
    $checkin_list{$file} = 1;
  }
  return $return;
}


sub DEBUG {           # $string
# Debug output has been requested, so make sure output requests get printed
#
  my ($str) = (@_);
  print "$str\n" if $debug_on;
}

sub Elem_IsCheckedout { # $elem
# Looks to see if the element is already checkedout
#
  my ($elem) = (@_);
  &DEBUG("SUB Elem_IsCheckedout $elem");
  chomp(my $result = qx/cleartool ls -s \"$elem\" 2>&1/);
  my $return = 0;
  if ($result =~ /CHECKEDOUT$/) {
    $return = 1;
  } elsif ($result =~ /Error: Unable to access/) {
    # Can't find the file
    &DEBUG($result);
    &DEBUG("This shouldn't have happened - please report the error to your");
    &DEBUG("ClearCase Admin")
    &PanicMode("clearcase");
  } elsif ($result =~ /Error: Pathname is not within a VOB/) {
    # User's provided an invalid View path?
    &DEBUG($result);
    &DEBUG("Please check your View argument and try again");
    &PanicMode("view");
  } elsif ($result !~ /error/i) {
    # File isn't checked out - don't need to do anything
  } else {
    # Something's happened which the script cannot account for
    &DEBUG($result);
    &DEBUG("This shouldn't have happened - please report the error to your");
    &DEBUG("ClearCase Admin");
    &PanicMode("shutil");
  }
  return $return;
}


sub Exclude_File {      # $file
# Compares the filename with the @excluded list (filetypes which should
# be skipped). If it finds a match, flag it to be ignored.
#
  my ($file) = (@_);
  my $return = 0;
  foreach my $bad_type (@excluded) {
    $return = 1 if $file =~ /\.$bad_type$/;
  }
  return $return;
}


sub Process_Args {
# Sorts out the arguments and stores them in the correct variables. If
# any problems are found, or Help is requested, display the Help
#
  &DEBUG("SUB Process_Args");
  &Display_Help() unless @ARGV;                 # No arguments provided
  &Display_Help() if ($ARGV[0] =~ /^-h/i);      # User requested help
  &Display_Help() unless $ARGV[1];              # Path wasn't specified
  &Display_Help() unless $ARGV[3];              # Path wasn't specified
  if ($ARGV[0] =~ /^-src$/i) {                  # Dealing with the Source var
    $source = $ARGV[1];                         # .. so store it
  } elsif ($ARGV[0] =~ /^-view$/i) {            # Dealing with the View var
    $view = $ARGV[1];                           # .. so store it
  } else { &Display_Help(); }                   # Invalid arg, display help
  if ($ARGV[2] =~ /^-src$/i) {
    $source = $ARGV[3];
  } elsif ($ARGV[2] =~ /^-view$/i) {
    $view = $ARGV[3];

  } else { &Display_Help(); }
  if ($ARGV[4]) {
    if ($ARGV[4] =~ /^-remove$/i) {
      $remove_required = 1;
    } else { &Display_Help(); }
  }
  unless (-d $source) {         # We've not been given a valid source
    &DEBUG("Error: source path \"$source\" does not exist");
    &PanicMode("path");
  }
  unless (-d $view) {           # We've not been given a valid View
    &DEBUG("Error: View path \"$view\" does not exist");
    &PanicMode("view");
  }
  if ($ARGV[-1] =~ /^-debug$/i) {
    $debug_on = 1;
  }
  if ($ENV{"OS"} =~ /Windows/) {
    $WHICHOS = "WIN";
    $OSSEP = $WINSEP;
  } else {
    $WHICHOS = "LINUX";
    $OSSEP = $UNIXSEP;
  }
}


sub STC_Copy {                # $source, $dest
  # Rewrite of previous STC_Copy module to minimise OS-specific
  # calls
  my ($source, $dest) = (@_);
  &DEBUG("SUB STC_Copy $source $dest");
  my $need_copy = 0;
  if (-d $source) {           # Directory, so doesn't need copying
    &DEBUG("No copy needed, DIR");
    unless (-e $dest) {       # if $dest does not exist ..
      unless (mkdir $dest) {  # if mkdir fails ..
        &DEBUG("Error creating DIR $dest");
        &PanicMode("path");
      }
      &DEBUG("Created DIR $dest");
    }
  } elsif (-B $source) {  # Binary file, which ClearCase can't diff
    &DEBUG("$source is BINARY");
    if (-d $dest) {
      # File exists in destination - need to compare them and see if
      # we need to do anything
      my $s_size = -s $source;
      my $d_size = -s $dest;
      if ($s_size == $d_size) {
        # Files are the same size; unchanged
        &DEBUG("$source exists in destination and is same size - skipping");
        $checkin_list{$dest} = 0;
        my $result = qx/cleartool uncheckout -rm \"$dest\" 2>&1/;
        # GMS - need to check result
      } else {
        # File needs to be copied
        &DEBUG("Copying BINARY $source");
        &STC_Do_Copy($source, $dest, "bin");
      }
    }
  } elsif (-f $source) {  # Plain text - let ClearCase handle diff
    &DEBUG("copying TEXT $source");
    &STC_Do_Copy($source, $dest, "txt");
  }
}


sub STC_Do_Copy {         # $source, $dest, $type
  # Performs the actual file copy
  #
  # GMS : WIP
  my ($s, $d, $t) = (@_);
  &DEBUG("SUB STC_Do_Copy $s $d $t");
  my @file;
  # Open source for reading
  open SRC, $s or {
    &DEBUG("Can't read from source $s: $!");
    &PanicMode("path");
  }
  # Open destination for output
  open DST, ">$d" or {
    &DEBUG("Can't write to dest $d: $!");
    &PanicMode("path");
  }
  if ($t eq "bin") {
    # Set binmode for binary files
    binmode(SRC) or {
      &DEBUG("Can't set binmode for $s: $!");
      &PanicMode("path");
    }
  }
  # Copy the file over, 8k at a time
  while (read(SRC, my $buffer, 8 * 2**10)) {
    print DST $buffer;
  }
  # Save and close both files
  close SRC;
  close DST;
}


sub STC_Copy2 {          # $source, $dest
# Copies a single source file to it's destination
  # GMS: FUNCTION TO BE REMOVED
#
  my ($source, $dest) = (@_);
  my $copycmd = "";
  my $result = "";
  if (-d $source) {     # Directory, so skip it, doesn't need copying
    &DEBUG("No copy needed, DIR");
  } elsif ($WHICHOS =~ /WIN/) {
    $source =~ s/$UNIXSEP/$WINSEP/g;
    $dest =~ s/$UNIXSEP/$WINSEP/g;
    # do file compare using fc #########################################
    $copycmd = "xcopy \"$source\" \"$dest\" \/Y \/V \/Q \/H";
    &DEBUG("WIN: $copycmd");
  } else {
    $source =~ s/$WINSEP/$UNIXSEP/g;
    $dest =~ s/$WINSEP/$UNIXSEP/g;       
    # do file compare using diff #######################################
    $copycmd = "cp \"$source\" \"$dest\"";
    &DEBUG("LNX: $copycmd");
  }
  chomp($result = qx/$copycmd 2>&1/) if $copycmd;
  if ($result =~ /^0 File/) {   # Windows copy failed
    &DEBUG("########## FAILED ##########");
  } elsif ($result =~ /^1 File/) {      # Windows copy succeeded
    &DEBUG("successful");
  } else {                      # Linux - don't know the return messages yet
    &DEBUG($result);
  }
}


sub TreeWalk {          # $path
# Treewalks through a directory structure and builds a list of files.
#
  my ($path) = (@_);
  &DEBUG("SUB TreeWalk $path");
  my @twlist;
  # Read the contents of the current directory
  opendir(my $dir, $path) or {
    &DEBUG("Can't opendir $path: $!");
    &PanicMode("path");
  }
  my @children = readdir($dir);
  closedir($dir);
  # Process the contents
  foreach my $elem (@children) {
    next if $elem =~ /^\.\.?$/;         # Skip . and ..
    my $elempath = $path . $OSSEP . $elem; # Build a full pathname
    next if &Exclude_File($elempath);   # Skip bad filetypes
    push(@twlist, $elempath);
    if (-d $elempath) { # Found a directory, so process that too
      push(@twlist, &TreeWalk($elempath));
    }
  }
  return @twlist;
}


###########################################################################
#                                                                         #
# MAIN SCRIPT                                                             #
#                                                                         #
###########################################################################

{
  &Process_Args();
  &DEBUG("VIEW = $view");
  &DEBUG("SOURCE = $source");
  @element_list = &TreeWalk($source);
  &DEBUG("Copying SOURCE to hash table for lookup ..");
  foreach my $elem (@element_list) {
    # Copy the source list into a hash table for easy lookup; later we'll
    # loop through the Target list and remove anything that's not in this
    # hash table
    $check_source{$elem} = 1;
  }
  if ($remove_required) {
    &DEBUG("Need to remove missing files ...");
    @target_list = &TreeWalk($view);
    foreach my $t (sort @target_list) {
      &DEBUG("  TARGET: $t");
    }
    foreach my $s (sort keys %check_source) {
      &DEBUG("  SOURCE: $s");
    }
    my $nview = $view;
    $nview =~ s/\\/\\\\/g if $WHICHOS =~ /WIN/;
    foreach my $elem (@target_list) {
      my $test_elem = $elem;
      &DEBUG("  BEGIN SUBST in $test_elem");
      $test_elem =~ s/$nview/$source/;
      &DEBUG("    SUBST complete: $test_elem");
      if ($check_source{$test_elem}) {
        &DEBUG("    Matched $test_elem");
      } else {
        &DEBUG("    Element exists in View but not source - removing \'$elem\' ...");
        # GMS: Need to check if parent folder is checked-out
        # if not, checkout parent, checkin afte
        &DEBUG("    Execute: cleartool rmname -nc -nco -force \'$elem\' ..");
        chomp (my $result = qx/cleartool rmname -nc -nco -force \"$elem\" 2>&1/);
        &DEBUG("    RESULT=$result");
        # GMS: Need to check this result and make sure it succeeded
      }
    }
  }
  &DEBUG("Removals complete, begin copy ..");
  &DEBUG(qx/cleartool checkout -nc $view 2>&1/);
  $checkin_list{$view} = 1;
  &DEBUG("Beginning checkin ...");
  foreach my $elem (@element_list) {
    &DEBUG("  Calling Copy_Source on '$elem'..");
    &Copy_Source($elem);
  }
  &DEBUG("\n");
  my $count = scalar keys %checkin_list;
  # GMS: changed checkin_list from array to hash .. is this correct?
  &DEBUG("# files to be checked in: $count");
  foreach my $f (sort keys %checkin_list) {
    &DEBUG("Checking in $f ...");
    chomp(my $result = qx/cleartool ci -nc \"$f\" 2>&1/);
    if ($result =~ /data identical to predecessor/) {
      &DEBUG("\t... No changes - undoing checkout ... ");
      chomp($result = qx/cleartool unco -rm \"$f\"/);
      if ($result =~ /Checkout cancelled/) {
        &DEBUG("complete");
      } else {
        &DEBUG("$result");
      }
    }
  }
}



# Rewrite STC_Copy to use Perl commands instead of OS ones
#
# cleartool checkin cannot identify identical versions of binaries - need 
# to handle separately
#
# Separate out the element removal stuff to its own subroutine. 
# Can the existing code handle folder removal??



# first off, snapshot View will be empty - don't want to have to download everything
#
# Given filename:
#   break filename into folders;
#   loop through each level
#     cleartool find $file .. see if it exists in CC
#     if exists:
#       if LASTNODE:
#         cleartool update -add_loadrule $file
#         compare with source
#         if different, copy and checkin
#         else DON'T NEED MORE THAN EXISTENCE CHECK
#     if NOT exist:
#       mkelem
#       if NOT FOLDER
#         copy file
#         checkin
#
# split DESTINATION into view_root and relative path




my ($src, $vroot, $dest);
my @path = split /$OSSEP/, $dest;
my @r = split /$OSSEP/, $vroot;
my @elemlist = &TreeWalk($src);   # modify to remove $src from each element path
foreach my $elem (@elemlist) {
  my @temp = split /$OSSEP/, $vroot;
  @temp .= split /$OSSEP/, $dest;
  @temp .= split /$OSSEP/, $elem;
  my $destination = join($OSSEP, @temp);
  chomp(my $result = qx/cleartool find \"$destination\"/);
  if ($result =~ /WHATEVER_STRING_SHOWS_SUCCESS/) {   # element exists in CC
    $result = qx/cleartool update -add_loadrules $destination/;
    # check it succeeded; we´ll assume it did
    # Now compare source and dest ...
    # if different, checkout, copy, checkin
  } else {                                            # element not in CC
    # find element type
    # checkout
    # copy
    # checkin
  }
}
# This doesnt take into account the requirement to remove elements which arent in the 
# source folder. Is rhat still a requirement, and how do we handle it??