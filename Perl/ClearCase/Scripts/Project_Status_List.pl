#!/usr/bin/perl -w
# Goes through all of our source-code Projects and finds out which are
# linked to CQ, which have been marked obsolete. Squirts out the data in
# tab-separated format, ready for import to MS Excel. Includes a summary
# at the bottom for convenience.
#
# Needs cleaning up sometime - this was knocked out in a hurry!
#

my $total_proj =0;
my $total_cq = 0;
my $total_lock = 0;
my $intstr;
chomp (my @projects = qx/cleartool lsproj -s -obsolete -invob \\stc_pvob_src/);
foreach my $proj (sort @projects) {
  $total_proj++;
  chomp (my @details = qx/cleartool lsproj -l $proj\@\\stc_pvob_src/);
  my $cqlink = 0;
  foreach my $line (@details) {
    $cqlink = 1 if $line =~ /clearquest user database name: NGI/;
    $intstr = $line if $line =~ s/^  integration stream: //;
  }
  chomp (my $lock = qx/cleartool lslock -l project:$proj\@\\stc_pvob_src/);
  print "$proj\t";
  print "CQ-ENABLED" if $cqlink;
  $total_cq++ if $cqlink;
  print "\t";
  if ($lock) {
    $lock = join(" ", (split /\s+/, $lock)[0,1,2,7]);
    $lock =~ s/T..:..:.....:..//;
  }
  print "LOCKED: $lock" if $lock;
  $total_lock++ if $lock;
  print "\n";
}
print "\n\n";
print "TOTAL = $total_proj\n";
print "CQ-Enabled = $total_cq\n";
print "Locked = $total_lock\n";
