#!/usr/bin/perl -w
#############################################################################################################
#                                                                                                           #
# Garry Short (garry@saxon-down.com) for UBS Warburg                                                        #
# 30/11/2004                                                                                                #
#                                                                                                           #
# Branch Auto-Merger                                                                                        #
# v0.1                                                                                                      #
# STM_FIRC_GSD branch auto-merger (merges the stm_tools and ldn_tools branches from the Tools folder down). #
#                                                                                                           #
# HISTORY                                                                                                   #
# v0.1	Initial Version                                                                             	    #
#                                                                                                           #
#############################################################################################################

#############################################################################################################
#                                                                                                           #
# USEs, INCLUDEs, ETC                                                                                       #
#                                                                                                           #
#############################################################################################################

use strict;


#############################################################################################################
#                                                                                                           #
# GLOBAL CONSTANTS AND VARIABLES                                                                            #
#                                                                                                           #
#############################################################################################################

# Constants
my $ct = "/usr/atria/bin/cleartool";
my $root = "/vobs/STM_FIRC_GSD";
my %view = (
  "stm"		=>	"firc_tools_unix",
  "ldn"		=>	"firc_tools_ldn_unix"
);
my %br = (
  "ldn"		=>	"stm_tools",
  "stm"		=>	"ldn_tools"
);


#############################################################################################################
#                                                                                                           #
# MAIN                                                                                                      #
#                                                                                                           #
#############################################################################################################

{
  chomp (my $rgn = qx/hostname/);		# Only runs on UNIX boxes, so easy way to get region
  $rgn =~ s/^.(...).*$/$1/;			# Now take hostname and strip all but chars 2-4
  my $viewtag = $view{$rgn};			# Set the viewtag according to the region we're in
  chdir "/view/$viewtag$root/Tools" or die "######   Can't CHDIR to /view/$viewtag$root/Tools: $!\n";
  my $branch = $br{$rgn};			# Set the branch according to the region we're in
  qx/$ct findmerge . -fversion \/main\/$branch\/LATEST -merge -nc/;	# Perform the merge
  # To find the logfile, we open the current directory and get a list of the files
  opendir DIR, "/view/$viewtag$root/Tools/" or die "Can't open DIR for reading: $!\n";	
  my @allfiles = readdir DIR or die "Can't read DIR: $!\n";
  closedir DIR;
  my $logfile;
  # Generate a rough timestamp so we'll be able to identify the correct logfile
  my ($junk, $m, $d, $t, $y) = split / +/, localtime;
  $y =~ s/^..(..)/$1/;
  $t =~ s/^(.{2}).*$/$1/;
  $d = "0$d" if $d =~ /^.$/;
  # Process the file list and look for our logfile
  foreach my $file (sort @allfiles) {
    next unless $file =~ /findmerge.log/;
    next unless $file =~ /$d-$m-$y\.$t/;
    $logfile = $file;
  }
  # Read the logfile into memory
  open FILE, $logfile or die "Can't read $logfile: $!\n";
  chomp (my @file = <FILE>);
  close FILE;
  foreach my $line (@file) {			# Read through the logfile and find processed files
    next unless $line =~ /^#/;			# If the line doesn't start with "#", it wasn't checked out
    $line =~ s/^.*cleartool findmerge (.*) -fver .*$/$1/;	# Strip out everything but the filename
    qx/$ct ci -nc $line/;			# Now check the file in ..
    qx/rm $line.contrib/;			# .. and remove the contrib file
  }
  unlink $logfile;				# Now delete the logfile
}


