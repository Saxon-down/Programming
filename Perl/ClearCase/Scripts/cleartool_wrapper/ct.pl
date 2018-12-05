#!/user/bin/perl
##########################################################################
#                                                                        #
# ct.pl                                                                  #
# v0.1                                                                   #
# Garry Short, 21/04/08                http://www.saxon-down.com/scripts #
#                                                                        #
# A wrapper for ClearCase cleartool utility, designed to do nothing more #
# than display coloured output in an attempt to make it easier to spot   #
# certain information.                                                   #
#                                                                        #
#                                                                        #
#                                                                        #
##########################################################################

##########################################################################
#                                                                        #
# USEs, INCLUDEs, etc                                                    #
#                                                                        #
##########################################################################

use Win32::Console::ANSI;
use Term::ANSIColor;


##########################################################################
#                                                                        #
# Global constants & variables                                           #
#                                                                        #
##########################################################################

# Constants
my $settings = "settings.cfg";
my %help_colours = (
  "separator"   => ["WHITE", "BLACK", "BOLD"],
  "0"           => ["CYAN", "BLACK", "BOLD"],
  "1"           => ["GREEN", "BLACK", "BOLD"],
  "2"           => ["YELLOW", "BLACK", "BOLD"],
  "3"           => ["RED", "BLACK", "BOLD"],
  "4"           => ["MAGENTA", "BLACK", "BOLD"]
);

# Variables
my %script_config;


##########################################################################
#                                                                        #
# Subroutines                                                            #
#                                                                        #
##########################################################################

sub ANSI_Print {        # $print_string, $fg_colour, $bg_colour, $bold
  # Takes a string and prints it in the required colour
  # nb: this is a large but *very* simple script, used to output the 
  # correctly coloured string. Unfortunately it seems necessary because 
  # you can't use variables for the ANSI colours :-(
  #
  my ($str, $fg, $bg, $bold) = (@_);
  print color $fg;
  print color "on_" . $bg;
  print color "bold" if $bold;
  print $str;
  print color "reset";
}


sub filter_help {       # @data
  #
  my (@data) = (@_);
  my $counter = 0;
  my $separator = $help_colours{"separator"};
  foreach my $line (@data) {
    chomp $line;
    my @words = split / /, $line;
    foreach my $word (@words) {
      if ($word =~ /^[-\[\{]/) {
        $counter++;
        $counter = 0 if $counter > 4;
      }
      my $colour = $help_colours{$counter};
      if ($word =~ /[\[\]\|\{\}]/) {
        &ANSI_Print($`, @$colour);
        &ANSI_Print($&, @$separator);
        if ($' =~ /\]+$/) {
          &ANSI_Print ($`, @$colour);
          &ANSI_Print($&, @$separator);
        } else {
          &ANSI_Print($', @$colour);
        }
      } else {
        &ANSI_Print($word, @$colour);
      }
      print " ";
    }
    $counter++;
    $counter = 0 if $counter > 4;
    print "\n";
  }
}


sub filter_line {       # $line, $int
  #
  #
  my ($line, $i) = (@_);
  my ($before, $after);
  my $been_printed = 0;
  foreach my $regex (sort keys %script_config) {
    if ($line =~ /$regex/i) {
      $before = $`;
      my $match = $&;
      $after = $';
      &filter_line($before) if $before;
      my ($fg, $bg) = split /,/, $script_config{$regex};
      &ANSI_Print($match, $fg, $bg);
      $been_printed = 1;
      &filter_line($after) if $after;
      last if $been_printed;
    }
  }
  print $line unless $been_printed;
}


sub filter_output {     # @data;
  # Takes the output from the command we've run and process it accordingly
  #
  my (@data) = (@_);
  my $counter = 0;
  foreach my $line (@data) {
    chomp $line;
    $counter++;
    &filter_line($line, $counter);
    print "\n";
  }
}


sub read_settings {
  # Reads the config file into memory
  #
  open FILE, $settings or die "Can't open $settings: $!\n";
  chomp (my @data = <FILE>);
  close FILE;
  my $user_settings = 0;
  foreach my $line (@data) {
    next if $line =~ /^#/;      # Skip comments
    if ($line =~ /^----/) {     
      # This is the separator between the predefined and user-defined 
      # settings, so set the relevant flag and then skip the line
      next;
    }
    my ($str, $colours) = split /::::/, $line;  # Grab the definition
    $script_config{$str} = $colours;
  }
}


##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  &read_settings();                         # Read in the config
  my $command = join " ", @ARGV;            # Grab the command that was used
  &ANSI_Print("cleartool " . $command . "\n", "BOLD WHITE", "CYAN");
  if ($command =~ /-h$/) {      # Help command!
    &filter_help (qx/cleartool $command/);
  } else {                      # Execute it and grab the output
    &filter_output(qx/cleartool $command/);   
  }
  print reset "\n";
}
