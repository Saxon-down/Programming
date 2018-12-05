##############################################################################
#                                                                            #
# (c) Garry Short (cm_perl@saxon-down.com) on behalf of Xansa                #
# 18/11/03                                                                   #
#                                                                            #
# Perl Module for performing simple ClearCase commands via a subroutine call #
#                                                                            #
##############################################################################

package CMCC;


##############################################################################
#                                                                            #
# Use, include, etc                                                          #
#                                                                            #
##############################################################################

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use ClearCase::Argv qw(ctqx);


##############################################################################
#                                                                            #
# Global constants & vars                                                    #
#                                                                            #
##############################################################################

$VERSION = 1.00;
@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw(
        lsELEM
	lsSUBDIRS
	lsVOB
        );
# %EXPORT_TAGS = (
#         DEFAULT => [qw()],
# );

my $dictionary = "dictionary.txt";	# Define dictionary file
# These are used as various default parameters for ClearPrompt
my @cp_yesno = qw(yes_no -mask "y,n" -type ok -prompt);	# Confirmation box
my @cp_async = qw(proceed -mask p -type ok -prompt);	# Information box
my @cp_abort = qw(proceed -default abort -mask a -type error -prompt);	
							# Information abort box
my @cp_text = qw(text -prefer_gui -prompt);		# Text input
my @cp_memo = qw(text -multi_line -prefer_gui -prompt);	# Big text input
# These are used to determine element type
my %kind = (
  ATTRIB  => "attype",
  BRANCH  => "brtype",
  ELEMENT => "eltype",
  HLINK   => "hltype",
  LABEL   => "lbtype",
  TRIGGER => "trtype"
);


##############################################################################
#                                                                            #
# Subroutines                                                                #
#                                                                            #
##############################################################################

sub appLB {
  # Apply Label
  # Takes a label name and a view name and applies the label to every element 
  # within that view.
  #
  my ($label, $view) = (@_);
  my $results = ctqx("mklabel -recurse $label $view");
  # $results will look something like this:
  #   Attempted to apply labels to 100 versions.
  #           70 newly applied
  #           0 moved
  #           0 already in place
  #           30 failed
  my $errors = (split /\n/, $results)[-1];	# Take the last line.
  my $return = (split /\s+/, $errors)[1];	# Take only the numbers.
  if ($return) {				# If there were errors ...
    $return *= -1;				# ... convert it to a negative,
  } else {					# ... else ...
    $return = 1;				# ... set it to 1
  }	# This has the effect that no errors == TRUE (1 or more) while ..
  	# .. errors == FALSE (0 or less)
  return $return;		# Return the number of errors to the caller.
}


sub appCS {
  # Apply ConfigSpec
  # Takes a view name and an aref, and applies the config spec (array) to the
  # view.
  #
  my ($v, $vt, $s, $cs) = (@_);
  my @return;
  push (@return, ctqx("startview $v"));
  # Write config spec to temporary file
  open CS, ">c:\\cs.cc" or die "Can't write to 'c:\\cs.cc': $!\n";
#  push (@return, "SUB CMCC::appCS:<BR>\$v = $v; \$vt = $vt; \$s = $s<BR><BR>");
#  push (@return, "Config Spec = {<BR>");
  foreach my $line (@$cs) {
    print CS "$line\n";
#    push (@return, "&nbsp;&nbsp;$line<BR>");
  }
#  push (@return, "}<BR>");
  if ($vt eq "SNAPSHOT") {
    my ($vob) = (split /_/, $v)[-2];
    print CS "load \\$vob\n";
    # Mount share to drive letter
    my $drive = (split /\s/, qx("net use * $s"))[1];
    push (@return, "\$s = $s<BR>\$drive = $drive<BR><BR>");
    # determine drive letter & switch to it
    chdir($drive) or die "Can't switch DIR to $drive: $!\n";
    # apply cs
    push (@return, ctqx("setcs c:\\cs.cc"));
    # switch to m:
    qx("m:");
    # unmap drive letter
    qx("net use $drive /d");
  } else {	# Dynamic; much easier!
    my $tmp = ctqx("setcs -tag $v c:\\cs.cc");	
    push (@return, $tmp);
  }
  close CS;
  						# Apply config spec to view
						#unlink "c:\\cs.cc";				# Delete temp file  
  return \@return;
}


sub appLB {
  # Locks a label.
  #
  my ($label, $location, $recurse, $replace) = (@_);
  my @return;
  my $cmd = "mklabel ";
  $cmd .= "-replace " if $replace;
  $cmd .= "-recurse " if $recurse;
  $cmd .= "-nc $label $location";
  @return = ctqx($cmd);
  return \@return;
}


sub CO {
  # Check out
}


sub CI {
  # Check in
}


sub lckELEM {
  # Lock ELTYPE
  # Takes an option and a tag, determines the element by it's type and tag, 
  # and locks it.
  # Takes an option of ELTYPE (see %kind)
  #
  my ($opt, $tag) = (@_);
  my $comment = "$opt $tag has been locked by module CMCC::lckELEM";
  ctqx("lock -comment \"$comment\" $kind{$opt}:$tag");
}


sub lsELEM {	# ($eltype, $vob);
  # List existing types of a specific element
  # Interrogates the system to find out what element tpyes already exist 
  # within this VOB.
  # Takes an option of ELTYPE (see %kind)
  #
  my ($opt, $vob) = (@_);
  my @return;
  my $opts;
  if ($vob) {
    $opts = "$kind{$opt} -invob \\$vob";
  } else {
    $opts = "$kind{$opt} -invob \\Admin";
  }
  # Get list of elements 
  @return = ctqx("lstype -short -kind $opts");
  return \@return;
}


sub lsVOB {	# ($display_type, $filtered);
  # List existing VOBs
  # Takes two arguments: the first can be either SHORT or LONG, or blank. 
  # Either gets applied to the lsvob call; no option returns the default 
  # information.
  # The second argument, if present, excludes certain VOBs (ConfigMgmt & Admin).
  #
  my ($opt, $x) = (@_);
  my %o = (
    SHORT => "-short",
    LONG  => "-long"
  );
  my @return = ctqx("lsvob $o{$opt}");
  if ($x) {
    my @new;
    while (@return) {
      my $vob = shift(@return);
      push(@new, $vob) unless ($vob =~ /^\\(Admin|ConfigMgmt)$/);
    }
    return \@new;
  } else {
    return \@return;
  }
}


sub lsVIEW {
  # List existing Views
  #
  my ($opt) = (@_);
  my @return;
  my %o = (
    SHORT => "-short",
    LONG  => "-long"
  );
  my @full = ctqx("lsview $o{$opt}");
  foreach my $view (@full) {
    push (@return, (split / +/, $view)[1]);
  }
  return \@return;
}


sub mkELEM {	# ($eltype, $label, $vob)
  # Make branch type
  #
  my ($opt, $label, $vob) = (@_);
  my @return;
  my $opts;
  push (@return, "Using $opt, $label, $vob<BR>");
  $vob = "\\Admin" unless $vob;
  chdir ("m:\\web_interface");
  $vob =~ s/^\\(.*)$/$1/;
  chdir ($vob);
  if ($opt eq "BRANCH") {
    $label = "-global $label";
  }
  push (@return, "Creating $opt <B>$label</B> in the $vob VOB<BR>");
  my @tmp = ctqx("mk$kind{$opt} -c \"Created from CMCC\" $label");
  push (@return, @tmp);
  return \@return;
}


sub mkCS {	# (@branch_specs);
  # Make ConfigSpec
  # Takes a full branch spec and builds a config spec. Returns a full config
  # spec in an array.
  # Example branch spec: /main/v01_02_00/WP002
  # 
#  my %existing_BL = &Existing_Branches_and_Labels;	# Find existing B/L
  my ($lb, @cs) = (@_);	# Get full branch specs
  my @return;		# Define return array for built config spec.
  if ($lb) {
    $lb = (split / /, $lb)[0];
  } else {
    $lb = "LATEST";
  }
  push(@return, "element * CHECKEDOUT");
  if ($cs[1]) {
    my $cs = shift(@cs);
    push (@return, "element 04_Implementation/.../* $cs");
    my $dev = (split /\//, $cs)[2];
    push (@return, 
    	"element 04_Implementation/.../* /main/$lb -mkbranch $dev");
  }
  push (@return, "element * $cs[0]");
  my $int = (split /\//, $cs[0])[2];
  push (@return, "element * /main/$lb -mkbranch $int");
  return \@return;
}
    

sub mkVIEW {	# ($view, $type, $storage);
  # Make view. Takes a view tag name and and storage location, and returns any 
  # errors. If a storage location is provided, look at the type (assuming 
  # dynamic if none is provided).
  #
  my ($view, $type, $storage) = (@_);
  my (@return, $error, $ping);
  $error = ctqx("lsview $view");
  if ($error =~ /^( |\*) $view /) {		# View already exists!
    push (@return, "<B>ERROR: View $view already exists!</B><BR>");
  } else {				# Create view.
    if ($storage) {			# User has specified storage location
      $ping = qx("ping $storage");	# Check storage location is accessible
      $storage = "\\\\$storage" . "\\ccviews\\$view.vws"; 
    } else {				# Use default view server
      $ping = qx("ping birlscclc01");
      $storage = '\\\\birlscclc01\views\\' . $view . '.vws';
    }
    if ($ping =~ /Reply from/) {
      if ($type eq "SNAPSHOT") {	# SNAPSHOT view
        $error = ctqx("mkview -snapshot -tag $view $storage");
        if ($error =~ /Created view\./) {
          push (@return, $error);
          push (@return, "<BR><BR><B>View $view has been created in $storage"
            . "</B> ($type)<BR><BR>");
          push (@return, ctqx("startview $view"));
        } else {
          push (@return, "<BR><BR><B>ERROR! SNAPSHOT View $view not created!</B><BR><BR>");
        }
      } else {    			# DYNAMIC view
        $error = ctqx("mkview -tag $view $storage");
        if ($error =~ /Created view\./) {
          push (@return, $error);
          push (@return, "<BR><BR><B>View $view has been created in $storage"
            . "</B> ($type)<BR><BR>");
        } else {
          push (@return, "<BR><BR><B>ERROR! DYNAMIC View $view not created!</B><BR>($error)($view)($storage)<BR>");
          push (@return, ctqx("startview $view"));
        }
      } 
    } else {
      push (@return, "<BR><BR><B>ERROR! Can't create view because $storage " .
      	"cannot be contacted.</B><BR><BR>");
    }
  }  
  return \@return;
}


sub mkVIEWcomplete {	# ($view, $dev_br, $int_br, $lb, $viewtype, $storage);
  # The complete process of making a view, building the config spec and 
  # applying it.
  #
  my ($view, $dev, $int, $lb, $vt, $s) = (@_);
  my (@return, @cs, $e);
  if ($vt eq "SNAPSHOT") {
    push (@return, "mkVIEWcomplete: SNAPSHOT VIEW @ $s<BR>");
    exit unless $s;
  }
  my $tmp = mkVIEW($view, $vt, $s);
  push (@return, "Development Branch = $dev<BR>" .
  	"Integration Branch = $int<BR>" .
 	"Label = $lb<BR><BR>");
  foreach my $line (@$tmp) {
    $e .= $line;
  }
  push (@return, @$tmp);
  if ($dev ne $int) {
    push (@cs, "/main/$dev/LATEST");
  }
  push (@cs, "/main/$int/LATEST");
  if ($s) {
    $s .= "\\ccviews";
  } else {
    $s = "birlscclc01\\views";
  }
  $tmp = appCS($view, $vt, "\\\\$s\\$view.vws", mkCS($lb, @cs));
  push (@return, @$tmp);
  if ($e !~ /ERROR!/) {
    push (@return, 
  	"View <B>$view</B> has been created successfully.<BR><BR>");
  }	
  return \@return;
}


sub mkVOB {	# ($vobtag, $comment, $reg_pw, $aref_to_locations);
  # Creates a VOB, returning any messages that may occur.
  # The current logic is that all VOBs should be mastered in Birmingham; other
  # sites merely have replicas.
  #
  my ($tag, $comment, $password, $aref) = (@_);
  my (@return, $wd, $new, $out, $replica);
  # mkvob -tag $tag -c $comment -public -password $password $storage
  my $storage = "\\\\birlscclc01\\vobs\\$tag.vbs";
  @return = ctqx("mkvob -tag \\$tag -c \"$comment\" -public " .
    "-password $password $storage");
  push (@return, ctqx("mount \\$tag"));
  chdir("m:\\web_interface\\$tag") or push (@return, "Error on CHDIR: $!<BR>");
  push (@return, qx("multitool rename replica:original birmingham"));
  $wd = "d:\\temp\\workdir";
  foreach my $r (@$aref) {
    next if $r =~ /birmingham/i;
    push (@return, "Need to create $r replica ... <BR>");
    $new = "\"Create $r replica of $tag VOB\"";
    $out = "\\\\nhtlscfil01\\shipping\\$r" . "_$tag.pkt";
    $replica = "nhtlscfil01:$r\@\\$tag";
    push (@return, "Creating replica of \\$tag for $replica<BR>");
    push (@return, "<B>multitool mkreplica -export -workdir $wd -c $new -out $out $replica<B><BR>");
    push (@return, 
      qx("multitool mkreplica -export -workdir $wd -c \"$new\" -out $out $replica")
    );
  }
  return \@return;  
}


sub mount_vob {		# ($vob);
  # Takes a VOB tag and mounts it.
  #
  my ($vob) = (@_);
  return ctqx("mount \\$vob");
}


sub prompt {
  # Takes a prompt type and a message, and returns anything that comes back from
  # the prompt.
  my %types = (		# Create a types hash and populate it with arrayrefs
	  YESNO => \@cp_yesno,
	  ASYNC => \@cp_async,
	  ABORT => \@cp_abort,
	  TEXT  => \@cp_text,
	  MEMO  => \@cp_memo
  );
  my $r;
  my ($type, $msg) = (@_);	# Get the parameters we've been passed.
  if ($types{$type}) {		# If the type exists ..
    my $t = $types{$type};	# .. get the array reference ..
    $r = clearprompt(@$t, $msg);# .. deference it and pass to clearprompt
  } else {			# Otherwise, throw up an error.
    $msg = "You have specified an invalid prompt type: $type";
    $r = clearprompt(@cp_abort, $msg);
  }  
  return $r;  
}


sub rmVIEW {
  # Stops and removes a view.
  #
  my ($view) = (@_);
  my @return;
  push (@return, ctqx("endview $view"));
  push (@return, ctqx("rmview -tag $view"));
  return \@return;
}


sub startVIEW {		# ($view);
  # Takes a view name and starts it.
  #
  my ($view) = (@_);
  my @return = ctqx("startview $view");
  return \@return;
}


sub stopVIEW {
}


sub VOB_mounted {
  # When supplied with a VOB tag, determines whether the VOB is mounted or not.
  # If the VOB tag does not exist, it returns with -1.
  # 
  my $return = -1;	# Define the return variable with default value.
  my ($vob) = (@_);	# Get the VOB tag we've been passed.
  $vob = lc($vob);	# Change $vob to lower case
  my @all_vobs = lsVOB("SHORT");	# List existing VOBs
  foreach my $v (@all_vobs) {
    $v = lc($v);
    next unless ($v =~ /\\$vob\b/);	# Current line contains VOB Tag
    if ($v =~ /^\*/) {			# Mounted VOBs are preceeded with "*"
      $return = 1;			# "*" found, so VOB is mounted
    } else {
      $return = 0;			# "No "*", so VOB not mounted.
    }
  }
  return $return;			# Return value.
}


##############################################################################
#                                                                            #
# Main Program                                                               #
#                                                                            #
##############################################################################

1;	# Module has loaded correctly.

