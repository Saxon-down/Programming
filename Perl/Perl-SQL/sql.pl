#!/usr/bin/perl -w
###############################################################################
#                                                                             #
# data_changer.pl                                                             #
# Garry Short, 19/06/06                                                       #
#                                                                             #
# Performs search-and-replaces within an MS SQL Database.                     #
#                                                                             #
###############################################################################

###############################################################################
#                                                                             #
# USE statements                                                              #
#                                                                             #
###############################################################################

use DBI;
use DBD::ODBC;


###############################################################################
#                                                                             #
# CONSTS and VARS                                                             #
#                                                                             #
###############################################################################

# CONSTS

my $datalist_file = "datalist.cfg";
my $fieldlist_file = "fieldlist.cfg";
my %files = (
  "DATA" => $datalist_file,
  "FIELDS" => $fieldlist_file
);
my $dsn = "cq_shell_lond1";     # This should be configured in the ODBC section
                                # in your Control Panel
my $user = "cq_shell";          # Standard CQ account
my $password = "N0tFu553d";     # Standard CQ password

# VARS
my (%fields, %data);



###############################################################################
#                                                                             #
# SUBROUTINES                                                                 #
#                                                                             #
###############################################################################

sub slurp_config_files {
  my (@temp_data, @temp_fields);
  foreach my $file_type (sort keys %files) {
    my $file = $files{$file_type};
    open FILE, $file or die "Cannot open file $file: $!\n";
    if ($file_type eq "DATA") {
      chomp (@temp_data = <FILE>);
    } elsif ($file_type eq "FIELDS") {
      chomp (@temp_fields = <FILE>);
    }
    close FILE;
  }
  foreach my $line (@temp_data) {
    next if $line =~ /^#/;
    my ($key, $value) = split /##/, $line;
    $data{$key} = $value;
  }
  foreach my $line (@temp_fields) {
    next if $line =~ /^#/;
    my ($key, $value) = split /##/, $line;
    $fields{$key} = $value;
  }
}


###############################################################################
#                                                                             #
# MAIN                                                                        #
#                                                                             #
###############################################################################

{
  my @fetched;
  &slurp_config_files;
  my $dbh = DBI->connect('dbi:ODBC:cq_shell_lond1', $user, $password);
  foreach my $table (sort keys %fields) {
    my @fields = split /,/, $fields{$table};
    foreach my $field (@fields) {
      my $sth = $dbh->prepare("select id,$field from $table");
      $sth->execute;
      while (@row = $sth->fetchrow_array) {
        next unless @row;
        my $string = $row[0] . "####" . $row[1];
        next unless $string =~ /LON/;
        push (@fetched, $string);
      }
      foreach my $string (@fetched) {
        my ($id, $header) = split /####/, $string;
        $header =~ s/'/''/;
        foreach my $search (sort keys %data) {
          my $subst = $data{$search};
          $header =~ s/$search/$subst/;
          print "DEBUG: $table\t$field\t$id\t$header\n";
          my $sth2 = $dbh->do("update $table set $field='$header' where id='$id'");
        }
      }
    }
  }
  $dbh->disconnect;
}
