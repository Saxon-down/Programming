#!/usr/bin/perl -w
###########################################################################
#                                                                         #
# Garry Short, 15/12/13                                                   #
# find_rpm.pl v1.0                                                        #
#                                                                         #
# <DESCRIPTION>                                                           #
# Takes an RPM base name and finds any matches within a specific baseline #
# or Project.                                                             #
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

my %arglist;
my $source;
my $int_stream;


###########################################################################
#                                                                         #
# SUBROUTINES                                                             #
#                                                                         #
###########################################################################

sub Get_Stream {
  # Uses the details we've been passed to find the relevant Integration
  # stream, which it then stores.
  #
  my @details;
  if ($arglist{"project"}) {    # We were passed a Project
    chomp(@details = qx/cleartool lsproj -l $arglist{"project"}/);
    $source = "p";
  } elsif ($arglist{"baseline"}) {      # We were passed a baseline`
    chomp(@details = qx/cleartool lsbl -l $arglist{"baseline"}/);
    $source = "b";
  } else {      # Something's wrong!
    &Display_Help();
  }
  foreach my $line (@details) { # Process the details we generated
    next unless $line =~ /stream: $/;   # Strip everything except the stream
    $line =~ s/^.*stream: //;   # Clean it up
    $int_stream = $line;        # Store the stream information
    last;
  }
}


sub Display_Help {
  print "
    find_rpm.pl
    ===========

    -project <projname>
      or
    -baseline <blname>

    -rpmbase <search_string>
    
  ";
  exit;
}


sub Process_Args {
  # Sorts out the arguments that were passed to the script and stores them
  # for later use.
  #
  while (@ARGV) {       # Process all arguments
    my $key = lc(shift(@ARGV)); # Remove the first element and store it
    &Display_Help() unless $key =~ s/^\-//;
    my $val = shift(@ARGV);     # Remove the next element and store it
    &Display_Help() unless $val;
    $arglist{$key} = $val;
  }
}


###########################################################################
#                                                                         #
# MAIN SCRIPT                                                             #
#                                                                         #
###########################################################################

{
  &Display_Help() unless @ARGV;
  &Display_Help() if ($ARGV[0] =~ /^\-h(elp)?$/i);
  &Process_Args();
  &Get_Stream();
}


