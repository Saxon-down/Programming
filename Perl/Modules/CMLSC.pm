##############################################################################
#                                                                            #
# (c) Garry Short (cm_perl@saxon-down.com) on behalf of Xansa                #
# 18/11/03                                                                   #
#                                                                            #
# Perl Module for performing ConfigMgmt tasks within the LSC web interface.  #
#                                                                            #
##############################################################################

package CMLSC;


##############################################################################
#                                                                            #
# Use, include, etc                                                          #
#                                                                            #
##############################################################################

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use CMCC;	# ConfigMgmt ClearCase
use CMWI;	# ConfigMgmt WebInterface

##############################################################################
#                                                                            #
# Global constants & vars                                                    #
#                                                                            #
##############################################################################

$VERSION = 1.00;
@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw(
  	general_page
	get_template
	print_page
        );
# %EXPORT_TAGS = (
#         DEFAULT => [qw()],
# );
my $htmlref = {		# Hashref to annoymous hash
  	"TEXT"		=> "#000000",		# Black
	"BG"		=> "#FFFFFF",		# White
	"TITLE_TEXT"	=> "#FFFFFF",		# White
	"TITLE_BG"	=> "#000000",		# Black
	"PAGE_BG"	=> "#FFFFFF"		# White
}; 	
# Menu choices for general.cgi
my %restricted_options = (
  "01" => "Create Project",
  "02" => "Unlock Label"
);
my %public_options = (
  "01" => "Create Deployment",
  "02" => "Create View",
  "03" => "Create and Apply Label"
);
# Page choices for general.cgi
my @restricted_access = (
  "<P>",
  "  Welcome to the RESTRICTED ACCESS area of the Configuration Management ",
  "  system. If you do not have the relevant access rights, you will not be ",
  "  able to access any of these systems.",
  "</P>",
  "<P>",
  "  Please select one of the options below:",
  "</P>",
  "<P>",
  "  <FORM ACTION=\"CMTeam/initial.cgi\" METHOD=\"POST\">"
);
my @public_access = (
  "<P>",
  "  Welcome to the Configuration Management system. Please select one of the ",
  "  options listed below:",
  "</P>",
  "<P>",
  "  <FORM ACTION=\"public.cgi\" METHOD=\"POST\">"
);
my $deployments = 'd:\published\deployments';
my @subdirs = qw(
    00_FULL_DEPLOYMENT
    01_BusinessModeling
    02_Requirements
    03_Analysis&Design
    04_Implementation
    05_Test
    06_Deployment
    07_Configuration&ChangeMgt
    08_ProjectMgt
    09_Environment
);
my @viewtypes = qw(DYNAMIC SNAPSHOT);
my @locations = qw(Birmingham Northampton);
my @releases = qw/00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 
  19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40/;
# Filter for view names (note: DEV and INT views both include the VOB tag, and 
# hence can't be defined before the VOB tag is determined.
my $f_live_view = "^[lL][iI][vV][eE]_[0-9]{6}";
# Filter for labels names.
my $f_dev_label = "^U[A-Z]{2,8}";
my $f_int_label = "^.V[0-9]{9}";
my $f_live_label = "^L[0-9]{9}";


##############################################################################
#                                                                            #
# Subroutines                                                                #
#                                                                            #
##############################################################################

sub DeployMe {		# ($vob, $subfolder, $branch, $label, $view);
  # Takes the VOB, subfolder, branch, label and view names. 
  #
  my ($v, $s, $b, $l, $view) = (@_);
  my @return;
  # Blank out subdir if 00_FULL_DEPLOYMENT was selected
  if ($s =~ /^00/) {
    $s = "";
  } else {
    $s = "\\$s";
  }
  # Generate timestamp for deployment folder name
#  my $date = &timestamp;
  chdir $deployments;
  $l =~ s/ \(locked\)//;
  $b =~ s/ \(locked\)//;
  my $deploy = "$deployments\\$v-$b-$l";
  chdir "m:\\$view$v$s" or push (@return, "ERROR: Source DIR: $!");
  if (-e $deploy) {
    push (@return, 
      "<BR>Folder $deploy already exists: erasing contents ...<BR>");
    qx(del /F /S /Q $deploy\\*.*);
  } else {
    push (@return, "<BR>Creating deployment folder for $deploy ...<BR>");
    mkdir "$deploy";
  }  
  chdir $deploy or push (@return, "ERROR: Target DIR: $!");
  my @tmp = 
  	qx(xcopy /S /E /V /Y m:\\$view\\$v$s\\*.* $deploy);
  push (@return, "Copying from m:\\$view\\$v$s\\*.* to $deploy ...<BR>");
  push (@return, @tmp);
  push (@return, "<BR>");
  return \@return;
}


sub general_page {	# ();
  # This script is used to generate the "general.cgi" page. It returns an 
  # arrayref to the HTML code it's generated.
  # 
  my (@return, $page);
  my $public = CMWI::cgi_fetch_arg("cgi_public");
  my $private = CMWI::cgi_fetch_arg("cgi_private");
  my $iteration = CMWI::cgi_fetch_arg("cgi_iteration");
  if ($private) {
    if ($private eq "Create Deployment") {
      $page = &PRIVATE_create_deployment($iteration);
      push (@return, "PRIVATE: $private");
#    } elsif ($private eq "Unlock Label") {
#      push (@return, "PRIVATE: $private");
#    } elsif ($private eq "Update this Site") {
#      push (@return, "PRIVATE: $private");
    } elsif ($private eq "Create Project") {
      push (@return, "PRIVATE: $private");
      $page = &PRIVATE_create_project($iteration);
    } elsif ($private eq "Apply LIVE Label") {
      $page = &PRIVATE_create_label($iteration, 2);
    } elsif ($private eq "Apply INT Label") {
      $page = &PRIVATE_create_label($iteration, 1);
    } elsif ($private eq "Create VOB") {
      push (@return, "PRIVATE: $private");
      $page = &PRIVATE_create_VOB($iteration);
    } else {
      # Oops, not coded this yet!
      push (@return, "<FONT COLOR=\"#FF0000\"><B>ERROR!</B> This option has " .
      		"yet to be coded! Please contact the Configuration Management" .
		" team (the task was \"PRIVATE: <B>$private</B>\").");
    }
  } else {
    push (@return, "PUBLIC: $public");
    if ($public eq "Create View") {
      $page = &PUBLIC_create_view($iteration);
    } elsif ($public eq "Apply DEV Label") {
      $page = &PRIVATE_create_label($iteration, 0);
    } else {
      # Oops, not coded this yet!
      push (@return, "<FONT COLOR=\"#FF0000\"><B>ERROR!</B> This option has " .
      		"yet to be coded! Please contact the Configuration Management" .
		" team (the task was \"PUBLIC: <B>$public</B>\").");
    }
  }
  if ($page) {		# A valid page has been created, so return it.
    return $page;
  } else {		# Only generated error codes, so return a reference to
    return \@return;	# .. them.
  }
}


sub GetDevelopers {
  # Creates a table for Create Project, asking for developer names, workstation
  # names, and dynamic or snapshot view required.
  #
  my @return;
  my $tbg = $$htmlref{"TITLE_BG"};
  my $tfg = $$htmlref{"TITLE_TEXT"};
  push (@return, "
    <TABLE>
      <TR BGCOLOR=\"$tbg\">
        <TD>
	  <FONT COLOR=\"$tfg\">
	    Developer
	  </FONT>
	</TD>
        <TD>
	  <FONT COLOR=\"$tfg\">
	    Location
	  </FONT>
	</TD>
        <TD>
	  <FONT COLOR=\"$tfg\">
	    View Type
	  </FONT>
	</TD>
        <TD>
	  <FONT COLOR=\"$tfg\">
	    Work Type
	  </FONT>
	</TD>  
        <TD>
	  <FONT COLOR=\"$tfg\">
	    Work No.
	  </FONT>
	</TD>
        <TD>
	  <FONT COLOR=\"$tfg\">
	    Workstation
	  </FONT>
	</TD>
      </TR>
  ");
  foreach my $i (1..10) {
    push (@return, "
      <TR>
        <TD>
	  <INPUT TYPE=\"TEXT\" NAME=\"cgi_devname_$i\">
	</TD>
        <TD>
	  <SELECT NAME=\"cgi_location_$i\">
	  ");
    foreach my $t (@locations) {
      push (@return, "<OPTION>$t</OPTION>");
    }
    push (@return, "	
	  </SELECT>  
	</TD>
        <TD>
	  <SELECT NAME=\"cgi_viewtype_$i\">
	  ");
    foreach my $t (@viewtypes) {
      push (@return, "<OPTION>$t</OPTION>");
    }
    push (@return, "
	  </SELECT>  
	</TD>
        <TD>
	  <SELECT NAME=\"cgi_worktype_$i\">
	    <OPTION>Package</OPTION>
	    <OPTION>Bugfix</OPTION>
	    <OPTION>RFC</OPTION>
	  </SELECT>  
	</TD>
	<TD>
	  <INPUT TYPE=\"TEXT\" NAME=\"cgi_workno_$i\">
	</TD>
        <TD>
	  <INPUT TYPE=\"TEXT\" NAME=\"cgi_wksname_$i\">
	</TD>
      </TR>
    ");
  }
  push (@return, "</TABLE>");
  return \@return;
}


sub GetNextAvailable {
  # Takes a branch type, and tells you what the next number should be.
  #
  my ($type) = (@_);
  my $return;
  my $root = "m:\\web_interface\\ConfigMgmt\\CC_Web_Interface\\dev\\config\\";
  my $pf = $root . "packages";
  my $bf = $root . "bugfixes";
  my $rf = $root . "RFCs";
  if ($type eq "Package") {
    open FILE, $pf;
  } elsif ($type eq "Bugfix") {
    open FILE, $bf;
  } elsif ($type eq "RFC") {
    open FILE, $rf;
  }
  chomp ($return = <FILE>);
  $return++;
  if ($type eq "Package") {
    open FILE, ">$pf";
  } elsif ($type eq "Bugfix") {
    open FILE, ">$bf";
  } elsif ($type eq "RFC") {
    open FILE, ">$rf";
  }
  print FILE "$return";
  close FILE;
  $type =~ s/^(.).*$/\L$1/;
  $return = $type . sprintf "%06d", $return;
  return $return;
}


sub GetPassedDevelopers {
  # Get all of the developer details we've been passed. Each set of details
  # goes into a seperate hashref, which then gets loaded into an arrayref.
  #
  my (@return);
  my $i = 0;
  foreach my $i (1..50) {
    my %dev;
    my $d = CMWI::cgi_fetch_arg("cgi_devname_$i");
    next unless $d;
    next unless ($d =~ /^[a-zA-Z]/);		# Arg empty, 
    $dev{"Dev"} = "$d";
    my $l = CMWI::cgi_fetch_arg("cgi_location_$i");
    my $v = CMWI::cgi_fetch_arg("cgi_viewtype_$i");
    my $t = CMWI::cgi_fetch_arg("cgi_worktype_$i");
    my $n = CMWI::cgi_fetch_arg("cgi_workno_$i");
    my $w = CMWI::cgi_fetch_arg("cgi_wksname_$i");
    $dev{"Loc"} = $l;
    $dev{"VT"} = $v;
    $dev{"WT"} = $t;
    $dev{"WN"} = $n;
    $dev{"Wks"} = $w;
    push (@return, \%dev);	# Load hashref onto array.
    # Clear hash.
  }
  return \@return;	# Return arrayref.
}


sub get_template {	# ();
  # Gets the template HTML file and splits it into two arrays (header and 
  # footer). It then returns two arrayrefs.
  # 
  my ($aref1, $aref2);
  my @store;
  my $template = 'm:\web_interface\ConfigMgmt\CC_Web_Interface\dev\config' .
  	'\template.html';
  open TEMPLATE, $template;
  my @file = <TEMPLATE>;
  close TEMPLATE;
  while (@file) {
    my $line = shift(@file);	# Take off next line
    last if $line =~ /<!--XANSA::LSC::BODY-->/;	# Stop if marker is found
    push (@store, $line);	# Add to end of array.
  }
  return (\@store, \@file);	# Return list of arrayrefs
}


sub Get_Full_Username {		# ($logon_id);
  # Gets the current logon ID and converts it into the user's full name, if 
  # possible. 
  # (Currently only support NT Domains)
  #
  my $name = $ENV{"USERNAME"};		# Get username from system environment
  my @data = qx(net user $name /domain);	# Get user details
  chomp($name = $data[3]);			# Get FULLNAME line (strip \n)
  $name =~ s/Full Name\s+(\w+.*)$/$1/;		# Strip out all but full name
  return $name;				# Return Full Name
}


sub is_valid_user {	# ($allowed_group);
  # Takes the username and password, and determines whether this is a valid
  # combination. Invalid combinations result in resetting the iteration counter
  # back to 0, which returns the user to the login page.
  #
  my ($group) = (@_);
  my $return = 0;
  my $user = CMWI::cgi_fetch_arg("cgi_username");
  my $pw = CMWI::cgi_fetch_arg("cgi_password");
  if ($user && $pw) {
    open FILE, "d:\\cms_passwords.txt";
    while (<FILE>) {	# One username & password, seperated by tabs, per line.
      chomp;		# Get rid of trailing newline
      next if /^#/;	# Ignore comments
      next unless /^($group|0)\t$user\t$pw$/;	
      		# Skip unless correct group/name/pw
      $return = 1;	# If you've made it this far, you've found a match.
    }
    close FILE;
  } 
  return $return;
}


sub LOGIN {	# ();
  # Log in
  #
  my @return;
  push (@return, "Please enter a valid USERNAME and PASSWORD:<BR><BR>");
  my @tmp;
  $tmp[0] = CMWI::build_inputbox("USERNAME: ", "cgi_username", "TEXT");
  $tmp[1] = CMWI::build_inputbox("PASSWORD: ", "cgi_password", "PASSWORD");
  foreach my $aref (@tmp) {
    push (@return, @$aref);
  }
  push (@return, "<BR><BR>");
  return \@return;
}


sub PassExistingDevelopers {
  # Fetch all developer details that were passed on from the previous screen,
  # and pass them on to the next.
  #
  my (@return);
  my $aref = &GetPassedDevelopers;
  my $i = 10;
  foreach my $href (@$aref) {
    $i++;
    my $dev = $$href{"Dev"};
    my $loc = $$href{"Loc"};
    my $VT = $$href{"VT"};
    my $WT = $$href{"WT"};
    my $WN = $$href{"WN"};
    my $wks = $$href{"Wks"};
    my $newaref = CMWI::return_cgi(	# Return the developer details with ..
      {		# new numbers (so they don't clash with the next 10 requested).
	"cgi_devname_$i" 	=> $dev,
	"cgi_location_$i"	=> $loc,
	"cgi_viewtype_$i"	=> $VT,
	"cgi_worktype_$i"	=> $WT,
	"cgi_workno_$i"		=> $WN,
	"cgi_wksname_$i"	=> $wks
      }
    );
    push (@return, $newaref);	# Load the aref into the array.
  }
  return \@return;		# Return a reference to the array.
}


sub print_page {	# ($html_aref);
  # Prints the HTML page
  #
  my ($aref) = (@_);
  my ($head, $foot) = get_template;
  my $line;
  print "Content-type: text/html\n\n";
  foreach $line (@$head) { print "$line\n"; }
  foreach $line (@$aref) { print "$line\n"; }
  foreach $line (@$foot) { print "$line\n"; }
} 


sub PRIVATE_create_deployment {		# ($iteration);
  # Takes the current iteration number. It then looks up any relevant CGI
  # variables, builds an array of HTML code, and returns an arrayref to it.
  #
  my ($i) = (@_);
  my @return;
  my $vob = CMWI::cgi_fetch_arg("cgi_selected_vob");
  my $br = CMWI::cgi_fetch_arg("cgi_selected_branch");
  my $lb = CMWI::cgi_fetch_arg("cgi_selected_label");
  my $subdir = CMWI::cgi_fetch_arg("cgi_selected_subdir");
  push (@return, "<FORM ACTION=\"general.cgi\" METHOD=\"POST\">");
  if($i < 2) { $i = 0 unless &is_valid_user(1); }
  if ($i == 0) {
    my $tmp = &LOGIN;
    push (@return, @$tmp);
  } elsif ($i == 1) {
    # Get required VOB
    push (@return, "Please select the VOB you wish to create a deployment " .
    	"from:<BR><BR>");
    my $menu = CMWI::build_dropdown("cgi_selected_vob", CMCC::lsVOB("SHORT",1));
    push (@return, @$menu);
  } elsif ($i == 2) {
    # Get required branch and label
    $vob =~ s/\\//;
    push (@return, "Please select the Branch and Label you wish to create a " .
    	"deployment from: ($vob)<BR><BR>");
    my $menu = CMWI::build_dropdown("cgi_selected_branch",
    	CMCC::lsELEM("BRANCH", $vob));
    push (@return, @$menu);
    $menu = CMWI::build_dropdown("cgi_selected_label",
    	CMCC::lsELEM("LABEL", $vob));
    push (@return, @$menu);
  } elsif ($i == 3) {
    # Confirm options, request subfolder.
    $br =~ s/ .*$//;	# Strip out everything after a space; this allows the
    $lb =~ s/ .*$//;	#  script to handle locked branches and labels, which
    			#  fail otherwise.
    push (@return, "Your deployment is going to be from the $vob VOB, using " .
    	"$br branch and $lb label.<BR><BR>");
    push (@return, "If you wish to deploy from a subfolder, please select it "
	. "from this menu.<BR><BR><I><B>Note:</B> if the branch does not exist "
	. "in this VOB, the whole VOB will be deployed.</I>"
	. "<BR><BR>"); 
    my $menu = CMWI::build_dropdown("cgi_selected_subdir",
    	\@subdirs);
    push (@return, @$menu);	
  } else {
    # Perform the deployment, returning relevant messages to the screen.
    push (@return, "Mounting VOB ...");
    push (@return, CMCC::mount_vob($vob));
    push (@return, "<BR><BR>");
    my $tmp = CMCC::mkVIEW("CCDEPLOY");
    push (@return, "<B>Creating temporary view ...</B><BR>");
    push (@return, @$tmp);
    my $branch = "/main";
    if ($br !~ /main/) { $branch .= "/$br"; }
    $branch .= "/" . $lb;
    $tmp = CMCC::appCS("CCDEPLOY", "DYNAMIC", "", CMCC::mkCS($branch));
    push (@return, "<BR><B>Applying relevant config spec ...</B><BR>");
    push (@return, "Starting View ...<BR>");
    push (@return, "<BR><BR>");
    push (@return, @$tmp);
    my $msgs = &DeployMe($vob, $subdir, $br, $lb, "CCDEPLOY");
    push (@return, "<B>Deploying ...</B><BR>");
    push (@return, @$msgs);
#    $tmp = CMCC::rmVIEW("CCDEPLOY");
    push (@return, "<B>Removing temporary view ...</B><BR>");
    push (@return, @$tmp);
    push (@return, "<BR><BR><FONT COLOR=\"#FF0000\">" .  
      "Please look <A HREF=\"\\\\birlscclc01\\deployments\">here</A>");
    push (@return, "for your deployment.</FONT>"); 
    push (@return, "<BR><BR>");
  }
  push (@return, 
  	"<INPUT TYPE=\"SUBMIT\" NAME=\"cgi_submit\" VALUE=\"Next -->\">")
	unless ($i > 3);
  $i++;
  my $cgi_returns = CMWI::return_cgi(
    {
      "cgi_iteration" 		=> $i,
      "cgi_private"  		=> "Create Deployment",
      "cgi_selected_vob"	=> $vob,
      "cgi_selected_branch"	=> $br,
      "cgi_selected_label"	=> $lb,
      "cgi_selected_subdir"	=> $subdir
    }
  );
  push (@return, @$cgi_returns);
  push (@return, "</FORM>");
  return \@return;
}


sub PRIVATE_create_label {		# ($iteration, $instance)
  # Creates, applies and locks a label, on either the MAIN, INT or DEV branch,
  # according to which instance is provided (0 = DEV, 1 = INT, 2 = MAIN).
  #
  my ($i, $o) = (@_);
  my (@return, @tmp);
  my $filter;
  my $vob = CMWI::cgi_fetch_arg("cgi_selected_VOB");
  my $major = CMWI::cgi_fetch_arg("cgi_selected_major");
  my $minor = CMWI::cgi_fetch_arg("cgi_selected_minor");
  my $patch = CMWI::cgi_fetch_arg("cgi_selected_patch");
  my $drop = CMWI::cgi_fetch_arg("cgi_entered_drop");
  my $name = CMWI::cgi_fetch_arg("cgi_entered_name");
  my $f_dev_view = "^[a-zA-Z]{2,8}_$vob" . "_[nb][fpr][0-9]{6}";
  my $f_int_view = "^$vob" . "_[nb]v[0-9]{6}";
  $vob =~ s/\\//;
  my $view = CMWI::cgi_fetch_arg("cgi_selected_view");
  my $label = CMWI::cgi_fetch_arg("cgi_selected_label");
  if(($i < 2) && ($o > 0)) { $i = 0 unless &is_valid_user(1); }
  push (@return, "<FORM ACTION=\"general.cgi\" METHOD=\"POST\">");
  if ($i == 0) {
    if ($o) {
      $tmp[0] = &LOGIN;
    } else {
      push(@return, "Applying a developer label, so no username or password" .
        " is required. Click Next to continue.<BR><BR>");
    }
  } elsif ($i == 1) {
    # Request VOB and view tag/storage
    push (@return, "Please select the required VOB from the dropdown ".
    	"list. Please ensure that all files are checked in.<BR><BR>");
    $tmp[0] = CMWI::build_dropdown("cgi_selected_VOB", CMCC::lsVOB("SHORT", 1));
  } elsif ($i == 2) {
    push (@return, "Please select the required View from the dropdown ".
    	"list. Please ensure that all files are checked in.<BR><BR>");
    if ($o == 0) {	# Dev
      $filter = $f_dev_view;
    } elsif ($o == 1) {	# Int
      $filter = $f_int_view;
    } else {		# Live
      $filter = $f_live_view;
    }
    $tmp[0] = 
      CMWI::build_dropdown("cgi_selected_view", CMWI::filter_results(
	CMCC::lsVIEW(""), $filter));
  } elsif ($i == 3) {
    # Either generate or get the required label
    my @comment;
    if ($o == 0) {		# Dev
      $filter = $f_dev_label;
      @comment = (
	"Please enter your full name (e.g. Tom Brown):<BR><BR>"
      );
      $tmp[2] = CMWI::build_inputbox("NAME:", "cgi_entered_name", "TEXT");
    } elsif ($o == 1) {		# Int
      $filter = $f_int_label;
      @comment = (
	"If the label doesn't currently exist, " .
	"please select the Major, Minor and Patch numbers from the dropdown " .
	"menus provided, and enter the Drop number into the comment box." .
	" (The drop number should be a maximum of three digits only. " .
	"Incompatible drop numbers will result in the script not creating " .
	"a label)." .
	"<BR><BR>"
      );
      $tmp[2] = CMWI::build_dropdown("cgi_selected_major", \@releases);
      $tmp[3] = CMWI::build_dropdown("cgi_selected_minor", \@releases);
      $tmp[4] = CMWI::build_dropdown("cgi_selected_patch", \@releases);
      $tmp[5] = CMWI::build_inputbox("DROP:", "cgi_entered_drop", "TEXT");
    } else {			# Live
      $filter = $f_live_label;
      @comment = (
	"If the label doesn't currently exist, " .
	"please select the Major, Minor and Patch numbers from the dropdown " .
	"menus provided, and enter the Drop number into the comment box." .
	" (The drop number should be a maximum of three digits only. " .
	"Incompatible drop numbers will result in the script not creating " .
	"a label)." .
	"<BR><BR>"
      );
      $tmp[2] = CMWI::build_dropdown("cgi_selected_major", \@releases);
      $tmp[3] = CMWI::build_dropdown("cgi_selected_minor", \@releases);
      $tmp[4] = CMWI::build_dropdown("cgi_selected_patch", \@releases);
      $tmp[5] = CMWI::build_inputbox("DROP:", "cgi_entered_drop", "TEXT");
    }
    # First, build a dropdown to select an existing label.
    push (@return, "If the required label already exists, please select it " .
      "from the following dropdown menu:<BR><BR>");
    $tmp[0] = CMWI::build_dropdown("cgi_selected_label",
      CMWI::filter_results(CMCC::lsELEM("LABEL", $vob), $filter));
    $tmp[1] = \@comment;  
    # Then build a system for allowing a new label.
    # Need major, minor, patch lists, plus entry boxes for drop and name.
  } else {
    # Got all the required information; now need to apply label.
    # Start the relevant view.
    my $cmd;
    my $prefix = $view;
    $prefix = "" if $prefix =~ /^live/i;
    $prefix =~ s/^.*_([a-z]{2})[0-9]{6}$/\U$1/;
    if ($drop ne "") {	# Drop is specified, so must be new LIVE/INT label
      # Build proper label name.
      $prefix = "L" unless $prefix;
      $label = $prefix . 
        sprintf "%02d%02d%02d%03d", $major, $minor, $patch, $drop;
      # Now need to create the label.
      $tmp[0] = CMCC::mkELEM("LABEL", $label, $vob);
    } elsif ($name ne "") {	# Name is specified, so must be new DEV label
      # Build proper label name.
      $name =~ s/^([a-zA-Z])[^ ]* ([a-zA-Z]{1,7}).*$/U\U$2\U$1/;
      $label = $name;
      # Now need to create the label.
      $tmp[0] = CMCC::mkELEM("LABEL", $label, $vob);
    } 	# If neither of these were defined, the label must already exist.
    push (@return, "Label = $label<BR>");
    push (@return, "View = $view<BR>");
    # Start view.
    push (@tmp, CMCC::startVIEW($view));
    # chdir to view.
    push (@return, chdir("m:\\$view\\$vob") . "<BR>");
    # run command.
    if ($o == 0) {		# Dev
      $cmd = "mklabel -replace -recurse -nc $label .";
    } elsif ($o == 1) {		# Int
      $cmd = "mklabel -recurse -nc $label .";
    } else {		# Int or Live
      $cmd = "mklabel -recurse -nc $label .";
    }
    push (@tmp, CMCC::appLB($label, ".", 1, 0)); 
    if ($0) { push (@return, CMCC::lckELEM("LABEL", $label)); }
  }
  $i++;
  my ($func, $cgi);
  if ($o == 0) {
    $func = "Apply DEV Label";
    $cgi = "cgi_public";
  } elsif ($o == 1) {
    $func = "Apply INT Label";
    $cgi = "cgi_private";
  } else {
    $func = "Apply LIVE Label";
    $cgi = "cgi_private";
  }
  my $cgi_returns = CMWI::return_cgi(
    {
      "cgi_iteration"			=> $i,
      "cgi_selected_VOB"		=> $vob,
      "cgi_selected_view"		=> $view,
      "cgi_requested_label"		=> $label,
      "cgi_selected_major"		=> $major,
      "cgi_selected_minor"		=> $minor,
      "cgi_selected_patch"		=> $patch,
      "cgi_entered_drop"		=> $drop,
      "cgi_entered_name"		=> $name,
      $cgi				=> $func
    }
  );
  foreach my $aref (@tmp) {
    push (@return, @$aref);
  }
  push (@return, @$cgi_returns);
  push (@return, 
    "<INPUT TYPE=\"SUBMIT\" NAME=\"cgi_submit\" VALUE=\"Next -->\">")
    unless ($i > 4);
  push (@return, "</FORM>");
  return \@return;
}


sub PRIVATE_create_project {	# ($iteration);
  # Takes the current iteration number. It then looks up any relevant CGI
  # variables, builds an array of HTML code, and returns an arrayref to it.
  #
  my ($i) = (@_);
  my (@return, @tmp, $ver, @r, $location);
  my $vob = CMWI::cgi_fetch_arg("cgi_selected_vob");
  my $major = CMWI::cgi_fetch_arg("cgi_selected_major");
#  my $label = CMWI::cgi_fetch_arg("cgi_selected_label");
  my $int_loc = CMWI::cgi_fetch_arg("cgi_selected_location");
  if ($major) {
    $ver = $location . "v" . $major  
      . CMWI::cgi_fetch_arg("cgi_selected_minor")
      . CMWI::cgi_fetch_arg("cgi_selected_patch");
  } else {
    $ver = CMWI::cgi_fetch_arg("cgi_version");
  }
  push (@return, "<FORM ACTION=\"general.cgi\" METHOD=\"POST\">");
  if($i < 2) { $i = 0 unless &is_valid_user(1); }
  if ($i == 0) {
    my $tmp = &LOGIN;
    push (@return, @$tmp);
  } elsif ($i == 1) {		# Get info for INT branch
    push (@return, "Please select a VOB and the project's " .
    	"Version Number from the dropdown menus below. Please also select " .
	"the location the project will be based in." .
	"<BR><BR>");
    # Select VOB
    $tmp[0] = CMWI::build_dropdown("cgi_selected_vob", CMCC::lsVOB("SHORT", 1));
    # Offer three dropdowns for version number.
    $tmp[1] = CMWI::build_dropdown("cgi_selected_major", \@releases);
    $tmp[2] = CMWI::build_dropdown("cgi_selected_minor", \@releases);
    $tmp[3] = CMWI::build_dropdown("cgi_selected_patch", \@releases);
#    $tmp[4] = CMWI::build_dropdown("cgi_selected_label", CMWI::filter_results(
#	    CMCC::lsELEM("LABEL",),"^R"));
    $tmp[4] = CMWI::build_dropdown("cgi_selected_location", \@locations);
  } elsif ($i == 2) {		# Get info for DEV branches
    push (@return, "Selected version is <B>$ver</B><BR>");
    # See if the branch exists; if not, create it in the Admin VOB
    my @branches = CMCC::lsELEM("BRANCH", $vob);
    my $br_found = 0;
    foreach my $tmp (@branches) {
      chomp($tmp);
      if ($tmp eq $ver) {	# Integration branch exists!
	$br_found = 1;
	last;
      }
    }
    if ($br_found) {
      push (@return, "Branch $ver already exists; no need to create it.<BR>");
    } else {
      # Create the integration branch
      $int_loc =~ s/^(.).*$/\L$1/;
      $ver = $int_loc . $ver;
      push (@tmp, CMCC::mkELEM("BRANCH", $ver, "\\Admin"));
#      push (@return, "<BR><BR>");
    }
    # Create an integration view for this version
    $vob =~ s/^\\(.*)$/$1/;
    push (@tmp, CMCC::mkVIEWcomplete(
      "$vob" . "_$ver", $ver, $ver, "LATEST" , "DYNAMIC", )); 
    # Get a list of developer branches, etc
    push (@return, "<BR><B><FONT COLOR=\"#FF0000\">Usage instructions are " .
    	"given below.</FONT></B><BR>");
    push (@tmp, &GetDevelopers);
    # Output all the arefs
#    foreach my $t (@tmp) {
#      push (@return, @$t);
#    }
    my @t = (
    	"<BR>" . 
	"<INPUT TYPE=\"SUBMIT\" NAME=\"cgi_submit\" VALUE=\"More Devs\">" .
	"<BR><BR>"
    );
    push (@tmp, \@t);
    push (@r, "<BR><BR>Please enter the required developer details above; " .
    	"if you wish to create local views for the developers, you must " .
	"enter either their workstation name or IP address in the column " .
	"provided. Note that if the workstation is not connected to the " .
	"network, or if it doesn't have a \"ccviews\" share, the view " .
	"creation will fail (however, the developer can follow the usual " .
	"process for creating their own view when they're ready).<BR><BR>");
    push (@r, "<I>NOTE:</I> If SNAPSHOT is selected, but no workstation " .
    	"details given (of the workstation cannot be contacted), no view " .
	"will be created. If DYNAMIC is selected, but no workstation details " .
	"given, the view will be server-based; if the workstation is given " .
	"but inaccessible, no view will be created.<BR><BR>");
    push (@r, "<I>NOTE ALSO:</I> If Package is selected as the work type, " .
        "the Work No. will be allocated automatically, and the Work No. " .
	"field will be ignored. If you've selected either of Bugfix or RFC, " .
	"you <B>must</b> enter the relevant work number. Failure means that " .
	"the branch does not get created.");
  } elsif ($i == 3) {
    # Work out which submit button was pressed - was it "More Devs", or "Next"?
    if (CMWI::cgi_fetch_arg("cgi_submit") eq "More Devs") {
#      my $debug = CMWI::cgi_dump_args;
#      push (@tmp, $debug);
      push (@tmp, &GetDevelopers);
      my $aref = &PassExistingDevelopers;
      push (@tmp, @$aref);
      my @x = ("<BR>");
      push (@x, 
      	"<INPUT TYPE=\"SUBMIT\" NAME=\"cgi_submit\" VALUE=\"More Devs\">" .
	"<BR><BR>");
      push (@tmp, \@x);
      # This isn't really an iteration, it's just a chance to enter more
      # developer details, so decrement the counter to ignore this iteration.
      $i--;
    } else {
      my $aref = &GetPassedDevelopers;
#      push (@return, "<TABLE BORDER=\"1\">");
      foreach my $href (@$aref) {
	my $view = $$href{"Dev"};
	$location = $$href{"Loc"};
	my $no = $$href{"WN"};
        $location =~ s/^(.).*/\L$1/;
	if ($location ne "Birmingham") {
	  # Need to change mastership for the branch created!
	}
	my $next;
	if ($$href{"WT"} eq "Package") {
  	  $next = $location . &GetNextAvailable($$href{"WT"});
	} else {
	  if ($$href{"WN"} eq "") {
	    push (@return, "<B>ERROR!</B> No view has been created for $view" .
	      ". No Work Number was given.<BR><BR>");
	    my @hr = ("<CENTER><HR WIDTH=\"33%\"></CENTER>");
	  }
	  $next = sprintf "%06d", $$href{"WN"};
	  my $tmp = $location . $$href{"WT"};
	  $tmp =~ s/^(..).*$/\L$1/;
	  $next = $tmp . $next;
	}
	$view =~ s/['`-]//;
	$view =~ s/^(.)[^ ]* ([^ ]{1,7}).*$/$2$1/;	# Convert view name 
			# .. into first 7 letters of surname, first initial
	$view .= "_$vob" . "_$next";
	my $storage = "";
	# create required branch.
	push (@tmp, CMCC::mkELEM("BRANCH", $next, "\\Admin"));
	if ($$href{"VT"} =~ /dynamic/i) {
 	  push (@tmp, CMCC::mkVIEWcomplete(
		$view, $next, $ver, "LATEST", $$href{"VT"}, $$href{"Wks"}));
	} else {
	  my @warn = ("<FONT COLOR=\"#FF0000\"><B>SNAPSHOT view $view will " .
	    "have to be created by the developer. The details he will need " .
	    "are as follows: <BR>" .
	    "&nbsp;&nbsp;&nbsp;&nbsp;" .
	    "VOB = $vob<BR>" .
	    "&nbsp;&nbsp;&nbsp;&nbsp;" .
	    "Developer Branch = $next<BR>" .
	    "&nbsp;&nbsp;&nbsp;&nbsp;" .
	    "Integration Branch = $ver<BR>" .
	    "With these details, the developer can use the \"Create View\" " .
	    "script available on this site.</B></FONT><BR><BR>");
	  push (@tmp, \@warn);
	}
	my @hr = ("<CENTER><HR WIDTH=\"33%\"></CENTER>");
	push (@tmp, \@hr);
      }
    }
  }
  $i++;
  foreach my $e (@tmp) {
    push (@return, @$e);
  }
  push (@return, 
  	"<INPUT TYPE=\"SUBMIT\" NAME=\"cgi_submit\" VALUE=\"Next -->\">")
	unless ($i > 3);
  if (@r) { push (@return, @r); }
  my $cgi_returns = CMWI::return_cgi (
    {
      "cgi_iteration"		=> $i,
      "cgi_version"		=> $ver,
      "cgi_selected_vob"	=> $vob,
      "cgi_selected_location"	=> $location,
      "cgi_private"		=> "Create Project"
    }
  );
  push (@return, @$cgi_returns);
  push (@return, "</FORM>");
  return \@return;
}


sub PRIVATE_create_VOB {	# ($iteration);
  # Used to create a VOB, and create a Birmingham replica.
  #
  my ($i) = (@_);
  my (@return);
  my @tmp;
  push (@return, "<FORM ACTION=\"general.cgi\" METHOD=\"POST\">");
  my $tag = CMWI::cgi_fetch_arg("cgi_new_vobtag");
  my $comment = CMWI::cgi_fetch_arg("cgi_new_vobcomment");
  my $reg_pw = CMWI::cgi_fetch_arg("cgi_regpw");
  if($i < 2) { $i = 0 unless &is_valid_user(2); }
  if ($i == 0) {
    my $tmp = &LOGIN;
    push (@return, @$tmp);
  } elsif ($i == 1) {
    $tmp[0] = CMWI::build_inputbox("VOB Tag", "cgi_new_vobtag", "TEXT");
    $tmp[1] = CMWI::build_inputarea("Comments", "cgi_new_vobcomment", "TEXT");
    $tmp[2] = 
      CMWI::build_inputbox("CC Registry Password", "cgi_regpw", "PASSWORD");
    foreach my $aref (@tmp) { push (@return, @$aref); }
  } else {
    push (@return, "Creating BIRMINGHAM replica with the following details:" .
    	"<BR>TAG = $tag<BR>COMMENTS = $comment<BR><BR>");
    push (@tmp, CMCC::mkVOB($tag, $comment, $reg_pw, \@locations));
    foreach my $aref (@tmp) { push (@return, @$aref); }
  }
  push (@return, 
  	"<INPUT TYPE=\"SUBMIT\" NAME=\"cgi_submit\" VALUE=\"Next -->\">")
	unless ($i > 3);
  $i++;	
  my $cgi_returns = CMWI::return_cgi (
    {
      "cgi_iteration"		=> $i,
      "cgi_private"		=> "Create VOB"
    }
  );
  push (@return, @$cgi_returns);
  push (@return, "</FORM>");
  return \@return;
}


sub PUBLIC_create_view {	# ($iteration);
  # Takes the current iteration number. It then looks up any relevant CGI
  # variables, builds an array of HTML code, and returns an arrayref to it.
  # 
  my ($i) = (@_);
  my @return;
  my $dev = CMWI::cgi_fetch_arg("cgi_selected_DevBranch");
  my $int = CMWI::cgi_fetch_arg("cgi_selected_IntBranch");
  my $vob = CMWI::cgi_fetch_arg("cgi_selected_VOB");
  my $view = CMWI::cgi_fetch_arg("cgi_viewname");
  my $label = CMWI::cgi_fetch_arg("cgi_selected_Label");
  my $viewtype = CMWI::cgi_fetch_arg("cgi_selected_viewtype");
  my $storage = CMWI::cgi_fetch_arg("cgi_selected_storage");
  push (@return, "<FORM ACTION=\"general.cgi\" METHOD=\"POST\">");
  my @tmp;
  if ($i == 0) {
    push (@return, "Please select your required VOB from the list below, " .
  	"and enter the developer name in the box provided (<I>NOTE: you can " .
	"create an integration view by putting \"integration\" as the " .
	"developer name</I>).<BR><BR>");
    push (@return, "Please also select the type of view you require, along " .
    	"with the ID (or IP address) of the workstation you'd like it " .
	"created on (e.g. " .
	"ZZL005ZW3G1J. Note that a \"CCVIEWS\" share <B>MUST</B> exist " .
	"before creating this view. Note also that failure to supply a " .
        "storage location will result in this view being stored on the " .
        "ClearCase View server).<BR><BR>");
    $tmp[0] = CMWI::build_dropdown(
      	"cgi_selected_VOB", CMCC::lsVOB("SHORT", "filtered")
    );
    $tmp[1] = CMWI::build_inputbox("Developer Name:", "cgi_viewname", "TEXT");
    $tmp[2] = CMWI::build_dropdown(
      "cgi_selected_viewtype", \@viewtypes
    );
    $tmp[3] = CMWI::build_inputbox(
      "Workstation ID", "cgi_selected_storage", "TEXT"
    );
  } elsif ($i == 1) {
    $view =~ s/['`-]//;
    $view =~ s/^(.)[^ ]* ([^ ]{1,7}).*$/$2$1/ 
    	unless ($view =~ s/^(int).*$/$1/);
    $vob =~ s/^\\(.*)$/$1/;
    $view .= "_$vob";
    push (@return, "VIEW NAME = $view<BR>VIEW TYPE = $viewtype<BR>" .
      "STORAGE = $storage<BR><BR>");
    push (@return, "Please select your required Development and Integration " .
    	"branches from the list below, plus the required label. " .
	"<BR><BR><I>NOTE: If you don't need a " .
    	"dedicated development branch, please select the integration branch " .
	"in both boxes</I><BR><BR>");
    $tmp[0] = 
      CMWI::build_dropdown(
	"cgi_selected_DevBranch", CMCC::lsELEM("BRANCH", ));
    $tmp[1] = 
      CMWI::build_dropdown(
	"cgi_selected_IntBranch", 
	CMWI::filter_results(CMCC::lsELEM("BRANCH", ),"^.v"));
    $tmp[2] =
      CMWI::build_dropdown(
	"cgi_selected_Label", CMCC::lsELEM("LABEL", $label));
    my @warning = qw(
    	<FONT COLOR="#FF0000"><B>WARNING!</B> If you are creating a 
	snapshot view, it will take up to about 25 minutes for the view 
	to be created and populated. Once this is complete, the next 
	page will finally load.</FONT>);
    $tmp[3] = \@warning;
  } else {
    $view .= "_$dev";
    push (@return, "VIEW TYPE = $viewtype<BR>STORAGE = $storage<BR><BR>");
    $tmp[0] = CMCC::mkVIEWcomplete(
      $view, $dev, $int, $label, $viewtype, $storage);
  }
  foreach my $aref (@tmp) {
    push (@return, @$aref);
  }
  push (@return, "<BR><BR>");
  push (@return, 
  	"<INPUT TYPE=\"SUBMIT\" NAME=\"cgi_submit\" VALUE=\"Next -->\">")
	unless ($i > 1);
  $i++;	
  my $cgi_returns = CMWI::return_cgi(
    {
      "cgi_iteration" 		=> $i,
      "cgi_viewname"		=> $view,
      "cgi_selected_VOB"	=> $vob,
      "cgi_selected_DevBranch"	=> $dev,
      "cgi_selected_IntBranch"	=> $int,
      "cgi_selected_Label"	=> $label,
      "cgi_selected_viewtype"	=> $viewtype,
      "cgi_selected_storage"	=> $storage,
      "cgi_public"  		=> "Create View"
    }
  );
  push (@return, @$cgi_returns);
  push (@return, "</FORM>");
  return \@return;
}


sub timestamp {		# ();
  # Generates and returns a current formatted timestamp.
  #
  my ($s, $m, $h, $d, $mo, $yr) = (localtime)[0..5];
  $mo++;
  $yr += 1900;
  return sprintf "%04d%02d%02d_%02d%02d%02d", $yr, $mo, $d, $h, $m, $s;
}


sub Valid_Comment {	# ($comment);
  # This checks a comment to make sure that it is valid; to be valid, a comment
  # has to meet the following criteria:
  #   1. A minimum of $min words
  #   2. A minimum of $dict words has to be in the dictionary file
  #
  my ($comment) = (@_);		# Get the comment we've been passed
  my $min = 10;			# The number of minimum permissible words
  my $dict = 5;			# The number of minimum dictionary words
  my %d;			# Dictionary hash
  my $dictionary = 		# Define dictionary file
  	"m:/web_interface/ConfigMgmt/CC_Web_Interface/dictionary.txt";	
  open DICT, $dictionary or 	# Open the file ...
    &Prompt("ABORT", "Error: Can't open $dictionary: $!");
  foreach my $word (<DICT>) {		# ... and load it into the hash
    chomp($word = lc($word));
    $d{$word} = 1;			# .. (in lower case!)
  }
  close DICT;
  my @c = split /\s+/, $comment;
  my ($count, $dcount) = (0,0);		# Define counters
  foreach my $word (@c) {
    $word =~ s/[",._]//g;
    $count++;				# Count the words
    $dcount++ if ($d{$word});		# Count the dictionary words
  }
  if (($count >= $min) and ($dcount >= $dict)) {
    return 1;		# TRUE; this is a valid comment
  } else {
    return 0;		# FALSE; this is invalid
  }  
}


##############################################################################
#                                                                            #
# Main Program                                                               #
#                                                                            #
##############################################################################

1;	# Module has loaded correctly.

