# Generates a list of all the VOBs that were created by someone other than 
# the vobadmin account.
my @vobs = qx/ct lsvob -s/;
chomp @vobs;
foreach $v (@vobs) {
  my @desc = qx/ct desc -l vob:$v/;
  foreach $line (@desc) {
    if ($line =~ /storage global pathname/) {
      $path = $line;
      $path =~ s/^.* "//;
      $path =~ s/".*$//;
    }
    next unless $line =~ / owner /;
    next if $line =~ /SVCVobadmin/;
    $line =~ s/^\s+//;          # Strip out leading whitespace
    $line =~ s/^owner //;
    print "$v:\n\t$line\t$path";
  }
}
