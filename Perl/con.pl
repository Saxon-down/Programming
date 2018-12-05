#!/usr/bin/perl
# Takes a jumbled word and searches the dictionary for any correctly spelled
# words which may match, e.g. aelpp returns apple
#
my $dict = "/usr/share/dict/words";
open FILE, $dict or die "Oops!: $!\n";
chomp (my @dict = <FILE>);
close FILE;
print "Enter letters: ";
chomp (my $input = <STDIN>);
my $a = length  $input;
foreach my $w (@dict) {
  my $b = length $w;
  next unless $a == $b;
  next unless &same_chars($w, $input);
  print "$w ($a) [$b]\n";
}


sub same_chars {
  my ($a, $b) = (@_);
  my (@a1, @b1);
  my $return = 1;
  @a1 = sort split //, $a;
  @b1 = sort split //, $b;
  while (@a1) {
    $ca = shift(@a1);
    $cb = shift(@b1);
    $return = 0 unless $ca eq $cb;
  }
  return $return;
};
