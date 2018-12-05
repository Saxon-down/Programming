#!/user/bin/perl -w
##########################################################################
#                                                                        #
# find_views_owned_by.pl                                                 #
# v0.3                                                                   #
# Garry Short, 13/06/08                http://www.saxon-down.com/scripts #
#                                                                        #
# Given a domain login, finds all of the ClearCase views owned by a      #
# given user account. If passed a login when calling the script, it uses #
# that; otherwise, it assumes you're looking for views owned by the      #
# current user.                                                          #
#                                                                        #
# HISTORY:                                                               #
# v0.3 19/06/08                                                          #
#      Modified to include view creation date. Also reformatted the      #
#      output.                                                           #
# v0.2 13/06/08                                                          #
#      Adding functionality to also display the view type and storage    #
#      hostname                                                          #
#                                                                        #
##########################################################################

##########################################################################
#                                                                        #
# Main                                                                   #
#                                                                        #
##########################################################################

{
  my ($view, $owner, $type, $host, $creation);
  # Get the login we've been passed, if any.
  my $given = $ARGV[0] or 0;
  # Get the current user if we've not been passed a login.
  $given = $ENV{USERNAME} unless $given;        
  my @output = qx/cleartool lsview -l -properties -full/;   # List all views
  chomp @output;
  print "\n\nViews owned by $given:\n";
  print "\tTYPE       HOST        CREATED         VIEW\n";
  print "\t====       ====        =======         ====\n";
  foreach my $line (@output) {
    if ($line =~ /^Tag:/) {                     # Found a new view, so ..
      $view = (split / /, $line)[1];            # .. get the view tag
    } elsif ($line =~ /^  Server host:/) {      # Found the hostname, so ..
      $host = (split /: /, $line)[1];           # .. store it
    } elsif ($line =~ /^View attributes/) {     # Found the viewtype, so ..
      if ($line =~ /snapshot/) {
        $type = "snapshot";
      } else {
        $type = "dynamic ";
      }
    } elsif ($line =~ /View owner:/) {          # Found the owner, so ..
      $owner = (split /\\/, $line)[1];          # .. get the login
    } elsif ($line =~ /^Created /) {
      $creation = (split / /,(split /T/, $line)[0])[1];
      if (lc($owner) eq lc($given)) {
        # The view's owner matches the login we've been given (or the 
        # current user's login if we weren't provided with one)
        print "\t[$type] [$host] [$creation]    $view\n";
      }
    } else {
      next;     # This line's just junk, as far as we're concerned.
    }
  }
  print "<<END>>\n";
}
