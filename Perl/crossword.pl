my $dict = "/usr/share/dict/words";
open FILE, $dict or die "Oops!: $!\n";
chomp (my @dict = <FILE>);
close FILE;
foreach my $w (@dict) {
  next unless $w =~ /^c....c..m$/i;
  print "$w\n";
}
