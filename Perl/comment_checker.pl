# Display the usage information if an incorrect number of parameters have
# been passed.
unless ($#ARGV == 1) {
  print 
    "Error: arguments should be the file to be checked followed by the\n" .
    "\tcode delimiter to be used; e.g. to check script.pl, run the " .
    "following:\n" .
    "\tperl comment_checker.pl script.pl #\n\n";
  exit;
}
my $file = $ARGV[0];                    # Get the file to check
my $comment_delimiter = $ARGV[1];       # Get the comment delimiter
# Read the file we've been asked to check
open FILE, $file or die "Can't open file '$file': $!\n";
chomp (@file = <FILE>);
close FILE;
# Set the counters to 0
my $comment = $space = $code = $filesize = 0;
# Process the file ..
foreach my $line (@file) {
  $filesize++;
  if ($line =~ /^\s*$comment_delimiter/) {
    # We've found a comment
    $comment++;
  } elsif ($line =~ /^\s*$/) {
    # We've found a spacer line
    $space++;
  } else {
    # We've found some code
    $code++;
  }       
}
# Output the results
print "\nFile $file consists of \n\t" .
        "$code lines of code\n\t" .
        "$space lines of whitespace and \n\t" .
        "$comment lines of comments\n" .
        "($filesize lines in total)\n";
