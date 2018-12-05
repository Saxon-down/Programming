#!/usr/bin/perl -w
###############################################################################
#                                                                             #
# (c) Garry Short, 28/01/10                                                   #
# packet_scan.pl v0.1                                                         #
#                                                                             #
# Uses tcpdump to monitor network traffic, and throw out messages whenever it #
# sees a new host.                                                            #
#                                                                             #
###############################################################################

###############################################################################
#                                                                             #
# USED Libraries                                                              #
#                                                                             #
###############################################################################


###############################################################################
#                                                                             #
# Constants                                                                   #
#                                                                             #
###############################################################################


###############################################################################
#                                                                             #
# Variables                                                                   #
#                                                                             #
###############################################################################

my @logdata;    # Stores the output from TCPDUMP, once it's been read
my %hosts_found;        # Lists all the hosts who've been discovered so far


###############################################################################
#                                                                             #
# Subroutines                                                                 #
#                                                                             #
###############################################################################

sub Grab_TCPDUMP {
# At the moment it just grabs a file created by TCPDUMP; the idea is eventually
# to rewrite this to continuously read the data from a currently running 
# TCPDUMP shell command
#
  open FILE, "/Users/Garry/tcpdump1.log" or 
              die "Error: logfile does not exist: $!\n";
  chomp (@logdata = <FILE>);
  close FILE;
  foreach my $line (@logdata) {
    # skip data lines
    next unless $line =~ /^\d{2}:\d{2}:/;
    next if $line =~ /224\.0\.0\.25/;
    my (@elements) = split / /, $line;
    # Skipping the data if it's incoming traffic
    my $host = $elements[4];
    # Skip these, we don't need to worry about them
    next if $host =~ /ff02::fb/;
    next if $host =~ /all-systems.mcast/;
    next if $host =~ /broadcasthost/;
    next if $host =~ /192\.168\.\d{1,3}\.\d{1,3}/;
    $host =~ s/\.[^.]+:$//;             # Strip off the port number
    $hosts_found{$host}++;    # Don't care about the counter provided it's non-0
    if ($hosts_found{$host} == 1) {     # It's a new host
      if ($host =~ /[a-zA-Z]/) {        # Should be a valid hostname
        print "$host\n";
      } elsif ($host =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\s*$/) {
        # We've got an IP address instead of a hostname, so resolve it.
        chomp (my @ns = qx/nslookup $host/);
      } else {
        if ($elements[7] eq "seq") {
          print "$host\t$elements[-1]\n";
        } else {
          print "$host\t$elements[7]\n";
        }
#        print "$line\n";
      }
    }
  }
}                       # end Grab_TCPDUMP


###############################################################################
#                                                                             #
# MAIN                                                                        #
#                                                                             #
###############################################################################

{
  &Grab_TCPDUMP();
}
