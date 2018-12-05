##############################################################################
#                                                                            #
# (c) Garry Short (cm_perl@saxon-down.com) on behalf of Xansa                #
# 18/11/03                                                                   #
# v1.0                                                                       #
#                                                                            #
# Perl Module for providing a web interface for the Xansa CM website.        #
#                                                                            #
##############################################################################

package CMWI;


##############################################################################
#                                                                            #
# Use, include, etc                                                          #
#                                                                            #
##############################################################################

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use CGI;
#use CMLSC;

##############################################################################
#                                                                            #
# Global constants & vars                                                    #
#                                                                            #
##############################################################################

$VERSION = 1.00;
@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw(
        build_dropdown
	build_inputbox
	build_passwordbox
  	cgi_get_args
	cgi_fetch_args
	cgi_dump_args
	general_page
	return_cgi
        );
# %EXPORT_TAGS = (
#         DEFAULT => [qw()],
# );

my %cgi_args;
##############################################################################
#                                                                            #
# Subroutines                                                                #
#                                                                            #
##############################################################################

sub build_dropdown {	# ($title, @list);
  # Takes a title and list of arguments, and generates the required HTML to
  # build a dropdown list. Returns an arrayref.
  #
  my ($name, $aref) = (@_);
  my @list = sort @$aref;
  my @return;
  my $label = $name;
  $label =~ s/^cgi_selected_(.*)$/$1/;
  $label = uc($label);
  push (@return, "<TABLE WIDTH=\"800\" BORDER=\"0\" BORDERCOLOR=\"#FFFFFF\" " .
  	"ALIGN=\"CENTER\">");
  push (@return, "<TR><TD WIDTH=\"150\">$label:</TD><TD>");
  push (@return, "<SELECT NAME=\"$name\">");
  foreach my $o (@list) {
    chomp($o);
    push (@return, "<OPTION>$o</OPTION>");
  }
  push (@return, "</SELECT>");
  push (@return, "</TD></TR></TABLE><BR>");
  return \@return;
}


sub build_inputarea {	# ($title, $cgi_field, $textboxtype);
  # Takes a title/description text and a cgi field, and returns the HTML code
  # necessary to build a text input box.
  #
  my ($title, $cgi, $type) = (@_);
  my @return;
  push (@return, "<TABLE BORDER=\"0\">");
  push (@return, "<TR>");
  push (@return, "<TD WIDTH=\"150\" VALIGN=\"TOP\">$title</TD>");
  push (@return, "<TD><TEXTAREA NAME=\"$cgi\" ROWS=\"5\" COLS=\"50\">" .
  	"</TEXTAREA></TD>");
  push (@return, "</TR>");
  push (@return, "</TABLE><BR>");
  return \@return;
}


sub build_inputbox {	# ($title, $cgi_field, $textboxtype);
  # Takes a title/description text and a cgi field, and returns the HTML code
  # necessary to build a text input box.
  #
  my ($title, $cgi, $type) = (@_);
  my @return;
  push (@return, "<TABLE BORDER=\"0\">");
  push (@return, "<TR>");
  push (@return, "<TD WIDTH=\"150\">$title</TD>");
  push (@return, "<TD><INPUT TYPE=\"$type\" NAME=\"$cgi\"></TD>");
  push (@return, "</TR>");
  push (@return, "</TABLE><BR>");
  return \@return;
}


sub cgi_get_args {	# ();
  # Gets all CGI arguments that have been passed to the current page, and
  # loads them into a hash.
  #
  my $form = new CGI;
  foreach my $key ($form->param) {
    $cgi_args{$key} = $form->param($key);
  }
}


sub cgi_dump_args {
  my @return;
  foreach my $key (%cgi_args) {
    push (@return, "$key = $cgi_args{$key}<BR>");
  }
  return \@return;
}


sub cgi_fetch_arg {	# ($required_cgi);
  # Takes a list of arguments to look up, and returns a hash of args+vals
  #
  my ($opt) = (@_);
  return $cgi_args{$opt};
}


sub filter_results {	# ($aref, $filter);
  # Takes an arrayref and a filter to match, and returns only the subset in a
  # new arrayref
  #
  my ($aref, $filter) = (@_);
  my @return;
  foreach my $elem (@$aref) {
    if ($elem =~ /$filter/) {
      push (@return, $elem);
    }
  }
  return \@return;
}


sub return_cgi {	# ($list_href);
  # Takes a hashref of cgi variables to pass on to the next iteration of the
  # script; Returns an arrayref of relevant HTML code.
  #
  my ($list) = (@_);
  my @return;
  foreach my $key (sort keys %$list) {
    my $val = $$list{$key};
    push (@return, "<INPUT TYPE=\"HIDDEN\" NAME=\"$key\" VALUE=\"$val\">");
  }
  return \@return;
}


sub tabulate {		# ($type, $columns, $title, $data_aref, $colour_href);
  # When presented with data, this function wraps it within an HTML table
  # and returns it as an array.
  # It takes the following inputs:
  #   $type	:	one of TEXT or BULLET (how to display the table).
  #   $cols	: 	integer; the number of columns that should be created.
  #   $title	:	BOOLEAN; should the first value be treated as a title?
  #   $arrayref	:	Should be passed an arrayref; the array it points to 
  #   			should contain one arrayref per column required.
  #   $colref   :	hashref of colour refs (defined in CMLSC)
  my ($type, $cols, $title, $arrayref, $colref) = (@_);
  my (@return, $format);
  # Dereference values in CMLSC::$htmlref, and store the results.
  my $st = $$colref{"TEXT"};
  my $sb = $$colref{"BG"};
  my $tt = $$colref{"TITLE_TEXT"};
  my $tb = $$colref{"TITLE_BG"};
  if ($type == "TEXT") {
    if ($title) {	# First VAL is TITLE
      $format = "BGCOLOR=\"$tb\" FONT COLOR=\"$tt\"";
    } else {
      $format = "BGCOLOR=\"$sb\" FONT COLOR=\"$st\"";
    }
  } elsif ($type == "BULLET") {
  } else {		
  }
  return @return;
}


##############################################################################
#                                                                            #
# Main Program                                                               #
#                                                                            #
##############################################################################

1;	# Module has loaded correctly.

