#!/usr/bin/perl -w
###########################################################################
#                                                                         #
# Garry Short, 31/03/14                                                   #
# changed_since_baseline.pl v1.1                                          #
#                                                                         #
# <DESCRIPTION>                                                           #
# Checks each Project's Integration stream and looks to see if there's    #
# been any activity since the last baseline. If there has it logs the     #
# stream for build; at the same time it also writes a detailed log of     #
# what the script's found.                                                #
#                                                                         #
# History                                                                 #
# =======                                                                 #
# v1.1 Now copies the completed logfile to Witali's Linux server          #
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

my $region;             # Am I running in Germany or India?
my $logfile;            # Where to output the results
my $debuglog;           # Complete logfile for debugging
my @changed_streams;
my @projects;

# Constants
my $log_ind = "\\\\inbe01asp001\\triggers\\gms\\cmweb\\csb_india.log";
my $debug_ind = "\\\\inbe01asp001\\triggers\\gms\\cmweb\\debug_india.log";
my $log_ger = "\\\\inbe01asp001\\triggers\\gms\\cmweb\\csb_germany.log";
my $debug_ger = "\\\\inbe01asp001\\triggers\\gms\\cmweb\\debug_germany.log";
my $pvob = "\\stc_pvob_src";
my $pscp_path = "\\\\inbe01asp001\\triggers\\gms\\cmweb\\pscp.exe";
my $pscp_command = "$pscp_path -l ukexgash -pw 4cmweb ";
my $pscp_tail = "ukexgash\@denu01lsv002:ci\/";


###########################################################################
#                                                                         #
# SUBROUTINES                                                             #
#                                                                         #
###########################################################################


sub Detailed_Compare {  # $int, $act, $bl
  # Does a detailed compare between the Baseline and Activity
  #
  my ($int, $act, $bl) = (@_);
  my ($out, $dbg);
  $dbg = "cleartool diffbl -versions -stream:$int baseline:$bl\@$pvob";
  chomp(my @diffbl = 
    qx/cleartool diffbl -versions stream:$int baseline:$bl\@$pvob/
  );
  my $dbi = 0;
  foreach my $line (@diffbl) {
    $dbi++;
    my $next = $diffbl[$dbi];
    next unless $line =~ /^Differences:/;
    if ($next =~ /^  none/) {
      # Looks like the Activity was empty so it's a false match; ignore
      $dbg .= "\n  $int has not changed since latest baseline";
      $dbg .= "\n    [$next]";
      $out = "";
      last;
    } else {
      $dbg .= "\n  Detailed compare for $int: build needed";
      $dbg .= "\n    [$next]";
      $out = $int;
      last;
    }
    $dbg .= "\n      LINE=$line";
  }
  return ($out, $dbg);
}


sub Initialise {
  # Sets things up
  chomp(my @temp = qx/cleartool lsregion -s/);
  if ($temp[0] =~ /^inbe/i) {
    $region = "stc_ind";
    $logfile = $log_ind;
    $debuglog = $debug_ind;
  } else {
    $region = "stc_ger";
    $logfile = $log_ger;
    $debuglog = $debug_ger;
  }
  qx/cleartool startview default_view/;
  chdir "m:\\default_view";
}


sub Process_Int {       # $intstr
  my ($intstr) = (@_);
  my ($latest_act, $latest_bl);
  my ($out, $dbg, $dc_dbg);
  my @list = qx/cleartool lsbl -s -stream $intstr/;
  if (@list) {
    chomp($latest_bl = $list[-1]);
  } else {
    $latest_bl = 1;
  }
  @list = qx/cleartool lsact -s -in $intstr/;
  if (@list) {
    chomp($latest_act = $list[-1]);
  } else {
    $latest_act = 1;
  }
  $dbg = "  DEBUG PI: i=[$intstr] a=[$latest_act] b=[$latest_bl]";
  if (($latest_act =~ /\D+/) and 
                      ($latest_bl =~ /\D+/)) {
    ($out, $dc_dbg) = &Detailed_Compare($intstr, $latest_act, $latest_bl);
    $dbg .= "\n  $dc_dbg";
  } elsif ($latest_bl == 1) {
    if ($latest_act =~ /\D+/) {
      $dbg .= "\n    No baseline in $intstr";
      $out = $intstr;
    } else {
      $dbg .= "\n    $intstr never been used";
      $out = "";
    }
  } elsif ($latest_act == 1) {
    $dbg .= "\n    No activities in $intstr";
  } else {
    ($out, $dc_dbg) = &Detailed_Compare($intstr, $latest_act, $latest_bl);
    $dbg .= "\n  $dc_dbg";
  }
  return ($out, $dbg);
}


sub My_Timestamp {
  # Generates a timestamp for the logfile
  chomp (my $d = qx/date \/T/);
  chomp (my $t = qx/time \/T/);
  return "# $d, $t";
}


###########################################################################
#                                                                         #
# MAIN SCRIPT                                                             #
#                                                                         #
###########################################################################

{
  &Initialise();
  open LOG, ">$logfile" or die "Error: Can't write to $logfile: $_\n";
  open DEBUG, ">$debuglog" or die "Error: Can't write to $logfile: $_\n";
#  print LOG "START: " . &My_Timestamp() . "\n";
  print DEBUG "START: " . &My_Timestamp() . "\n";
  chomp (@projects = qx/cleartool lsproj -s -invob $pvob/);
  foreach my $prj (@projects) {
    chomp (my @details = qx/cleartool lsproj -l $prj\@$pvob/);
    foreach my $line (@details) {
      if ($line =~ /master replica:/i) {
        print DEBUG "PROJ=$prj, $line\n";
        last unless $line =~ /$region/i;        
      } elsif ($line =~ s/^  integration stream: //i) {
        my ($output, $debug) = &Process_Int($line);
        $output =~ s/\@\\stc_pvob_src//i if $output;
        print LOG "$output\n" if $output;
        print DEBUG "$debug\n" if $debug;
      }
    }
  }
#  print LOG "END: " . &My_Timestamp() . "\n";
  close LOG;
  if (-s $logfile) {    # $logfile is non-empty
    chomp (my @pscp = qx/$pscp_command $logfile $pscp_tail 2>&1/);
    print DEBUG "\nPSCP output=\"@pscp\"\n";
  } else {
    print DEBUG "\nPSCP: logfile was empty, not copied\n";
  }
  print DEBUG "END: " . &My_Timestamp() . "\n";
  close DEBUG;
}


