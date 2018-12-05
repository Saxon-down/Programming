#!/user/bin/perl -w
# Quick script to list all components by PVOB. First it works out all the
# PVOBs, then generates a list of components for that PVOB, then outputs
# the information in a structured format. GMS.
my @vobs = qx/cleartool lsvob -s/;
chomp @vobs;
foreach my $vob (@vobs) {
  next unless $vob =~ /pvob/i;
  print "PVOB = $vob\n";
  my @details = qx/cleartool lscomp -invob $vob/;
  foreach my $line (@details) {
    if ($line =~ /"/) {
      $line =~ s/.*"(.+)".*/$1/;
      print "    Root directory = $line";
    } else {
      my $comp = (split /\s+/, $line)[1];
      print "  Component = $comp\n";
    }
  }
}
