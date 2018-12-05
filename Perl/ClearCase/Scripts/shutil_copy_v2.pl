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
my $destination;        # The relative path within the View to copy files to
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
my $UNIXSEP = "\/";      # Used for $OSSEP

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

    ccperl shutil_copy.pl -h[elp] | (-src <PATH> -view <PATH> -dest <PATH>) [-remove] [-debug]

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


sub DEBUG {           # $string
# Debug output has been requested, so make sure output requests get printed
#
  my ($str) = (@_);
  print "$str\n" if $debug_on;
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


sub Generate_Path {           # $src, $v, $dst, $elem
  # GMS: this needs some error-checking! Make sure there's 
  # no empty elements in the array, that the splits have
  # worked correctly, etc
  my ($src, $v, $dst, $elem) = (@_);
  &DEBUG("SUB Generate_Path [$src] [$v] [$dst] [$elem] [$OSSEP]");
  my ($gensrc, $gendst);
  my @sc = &Strip_Empties(split /$OSSEP+/, $src);
  my @vc = &Strip_Empties(split /$OSSEP+/, $v);
  my @dc = &Strip_Empties(split /$OSSEP+/, $dst);
  my @ec = &Strip_Empties(split /$OSSEP+/, $elem);
  $gensrc = join($OSSEP, ($src, $elem));
  $gendst = join($OSSEP, ($dst, $elem));
  &DEBUG("  src = [$gensrc]\n  dst = [$gendst]");
  return ($gensrc, $gendst);
}


sub Process_Args {
# Sorts out the arguments and stores them in the correct variables. If
# any problems are found, or Help is requested, display the Help
#
  if ($ARGV[-1] =~ /^-debug$/i) {
    $debug_on = 1;
  }
  &DEBUG("SUB Process_Args @ARGV");
  &Display_Help() unless @ARGV;                 # No arguments provided
  &Display_Help() if ($ARGV[0] =~ /^-h/i);      # User requested help
  &DEBUG("  Processing paths ..");
  &Display_Help() unless (
    ($ARGV[0] =~ /^-src$/i) and
    ($ARGV[2] =~ /^-view$/i) and
    ($ARGV[4] =~ /^-dst$/i)
  );
  $source = $ARGV[1];                         # .. so store it
  $view = $ARGV[3];
  $destination = $ARGV[5];
  &DEBUG("  source = $source\n  view = $view\n  dest = $destination");
  if ($ARGV[6]) {
    if ($ARGV[6] =~ /^-remove$/i) {
      $remove_required = 1;
      &DEBUG("  REMOVE requested");
    }
  }
  unless (-d $source) {         # We've not been given a valid source
    &DEBUG("  Error: source path \"$source\" does not exist");
    &PanicMode("path");
  }
  unless (-d $view) {           # We've not been given a valid View
    &DEBUG("  Error: View path \"$view\" does not exist");
    &PanicMode("view");
  }
  if ($ENV{"OS"} =~ /Windows/) {
    $WHICHOS = "WIN";
    $OSSEP = $WINSEP;
  } else {
    $WHICHOS = "LINUX";
    $OSSEP = $UNIXSEP;
  }
  &DEBUG("  OS=$WHICHOS (sep=$OSSEP)");
}


sub Split_File {      # $path
  # Splits a full pathname into path and filename
  #
  my ($path) = (@_);
  my @elems = split /$OSSEP/, $path;
  my $file = pop(@elems);
  $path = join $OSSEP, @elems;
  return ($path, $file);
}


sub STC_CCCO {        # $elem
  # Handles the checkout and ensures that it works correctly
  #
  my ($e) = (@_);
  &DEBUG("SUB STC_CCCO $e");
  chomp (my $result = qx/cleartool checkout -nc \"$e\" 2>&1/);
  if ($result =~ /must be set to an activity/) {
    &DEBUG("  Error: Your View doesn't have an Activity set. Please");
    &DEBUG("  create one using cleartool mkactivity <name>; once you");
    &DEBUG("  have an Activity, you can set it using cleartool setact");
    &DEBUG("  <name>\n");
    &PanicMode("activity");
  } elsif ($result =~ /error/i) {
    # GMS: need to flesh this out
  }
}

sub STC_CCCI {        # $elem
  # Handles the checkin, checks for identical versions and 
  # performs the uncheckout if needed
  #
  my ($e) = (@_);
  chomp (my $result = qx/cleartool checkin -nc \"$e\" 2>&1/);
  if ($result =~ /data identical to predecessor/) {
    chomp ($result = qx/cleartool uncheckout -rm \"$e\" 2>&1/);
  } elsif ($result =~ /error/i) {
    # GMS need to flesh this out too
  }
}


sub STC_Copy {                # $source, $dest
  # Rewrite of previous STC_Copy module to minimise OS-specific
  # calls
  my ($source, $dest) = (@_);
  &DEBUG("SUB STC_Copy $source $dest");
  my $need_copy = 0;
  if (-d $source) {           # Directory, so doesn't need copying
    &DEBUG("  No copy needed, DIR");
  } elsif (-B $source) {  # Binary file, which ClearCase can't diff
    &DEBUG("  $source is BINARY");
    my $s_size = -s $source;
    my $d_size = -s $dest;
    if ($s_size == $d_size) {
      # Files are the same size; unchanged
      &DEBUG("  $source exists in destination and is same size - skipping");
    } else {
      # File needs to be copied
      &DEBUG("  Copying BINARY $source");
      &STC_CCCO($dest);
      &STC_Do_Copy($source, $dest, "bin");
      &STC_CCCI($dest);
    }
  } elsif (-f $source) {  # Plain text - let ClearCase handle diff
    &DEBUG("  copying TEXT $source");
    # GMS: need to do checkout / checkin / uncheckout
    &STC_CCCO($dest);
    &STC_Do_Copy($source, $dest, "txt");
    $checkin_list{$dest} = 1;
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
  open SRC, $s or (
    &DEBUG("  Can't read from source $s: $!") and
    &PanicMode("path")
  );
  # Open destination for output
  open DST, ">$d" or (
    &DEBUG("  Can't write to dest $d: $!") and
    &PanicMode("path")
  );
  if ($t eq "bin") {
    # Set binmode for binary files
    binmode(SRC) or (
      &DEBUG("  Can't set binmode for $s: $!") and
      &PanicMode("path")
    );
  }
  # Copy the file over, 8k at a time
  while (read(SRC, my $buffer, 8 * 2**10)) {
    print DST $buffer;
  }
  # Save and close both files
  close SRC;
  close DST;
}


sub STC_mkelem {          # $src, $dst
#
  my ($src, $dst) = (@_);
  my $type;
  my $t;
  if (-d $src) {          # $src is a directory
    $type = "directory";
    $t = "dir";
  } elsif (-B $src) {
    $type = "compressed_file";
    $t = "bin";
  } elsif (-f $src) {
    $type = "text_file";
    $t = "txt";
  } else {
  }
  chomp (my $result = 
    qx/cleartool mkelem -eltype $type -nc \"$dst\" 2>&1/
  );
  # GMS: process results
  if (($t eq "txt") or ($t eq "bin")) {
    &STC_Do_Copy($src, $dst, $t);
  }
  $checkin_list{$dst} = 1;
}


sub Strip_Empties {     # @array
  # Strips empty elements out of an array, and returns whatever's left
  #
  my (@old) = (@_);
  &DEBUG("SUB Strip_Empties @old");
  my @new;
  foreach my $elem (@old) {
    next unless $elem;
    push (@new, $elem);
  }
  &DEBUG("  Strip_Empties: @new");
  return @new;
}


sub TreeWalk {          # $root, $sub, $counter
# Treewalks through a directory structure and builds a list of files.
#
  my ($root, $sub, $spacer) = (@_);
  $spacer .= "  ";
  &DEBUG($spacer . "SUB TreeWalk $root $sub");
  my $path = $root . $OSSEP . $sub;
  my @twlist;
  # Read the contents of the current directory
  opendir(my $dir, $path) or (
    &DEBUG($spacer . "  Can't opendir $path: $!") and
    &PanicMode("path")
  );
  my @children = readdir($dir);
  closedir($dir);
  # Process the contents
  foreach my $elem (@children) {
    next if $elem =~ /^\.\.?$/;         # Skip . and ..
    my $elempath = $sub . $OSSEP . $elem; # Build a full pathname
    next if &Exclude_File($root . $OSSEP . $elempath);   # Skip bad filetypes
    push(@twlist, $elempath);
    &DEBUG($spacer . "  $elempath");
    if (-d $root . $OSSEP . $elempath) { # Found a directory, so process that too
      push(@twlist, &TreeWalk($root, $elempath));
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
  @element_list = &TreeWalk($source, "", ""); 
  foreach my $elem (@element_list) {
    my ($fullsrc, $fulldst) = &Generate_Path($source, $view, $destination, $elem);
    next if -d $fullsrc;    # Skip folders!
    my ($dpath, $dfile) = &Split_File($fulldst);
    chomp(my $result = qx/cleartool find \"$dpath\" -name \"$dfile\" -nxname -print/);
    if ($result =~ /$dfile/) {   # element exists in CC
      $result = qx/cleartool update -add_loadrules $elem/;
      &PanicMode("clearcase") unless $result =~ /Done loading/;
      &STC_Copy($fullsrc, $fulldst);
    } else {                                            # element not in CC
      &STC_mkelem($fullsrc, $fulldst);
    }
  }
  foreach my $elem (sort keys %checkin_list) {
    # We've been keeping a lost of elements to checkin, rather than do them one
    # at a time. Part of the reason is because the alternative would mean folders
    # get checked out and back in for each child, resulting in tons of versions.
    &STC_CCCI($elem);
  }
}

b m



# first off, snapshot View will be empty - don't want to have to download everything
#
# Given filename:
#   break filename into folders;
#   loop through each level <--- ####### GMS
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





# This doesnt take into account the requirement to remove elements which arent in the 
# source folder. Is rhat still a requirement, and how do we handle it?? Leave that till later

# the path-handling isnt working in line 195 - needs investigating