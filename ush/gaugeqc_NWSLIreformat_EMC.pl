#! /usr/local/bin/perl
#-----------------------------------------------------------------------------
#  NOAA/ERL
#  Forecast Systems Laboratory
#  Facility Division
#  NIMBUS Software
#
#  This software and its documentation are in the public domain and are
#  furnished "as is".  The United States Government, its instrumentalities,
#  officers, employees, and agents make no warranty, express or implied, as to
#  the usefulness of the software and documentation for any purpose.  They
#  assume no responsibility (1) for the use of the software and documentation;
#  or (2) to provide technical support to users.
#
#  NWSLIreformat.pl  --  reformats the NWSLI text file
#
#   03/21/03  Richard Ryan     New
#   01/31/07  Randall Collander modified for use at EMC/precipqc
#-----------------------------------------------------------------------------
#  $Header: /cvsroot/rt/scripts/NWSLIreformat.pl,v 1.6 2004/01/21 16:25:09 lipschut Exp $


use strict;
#use warnings;

use Carp;
use Getopt::Long;

# redirect STDIN, STDOUT and STDERR according to options given
my ($opt_f, $opt_o, $opt_l) = (undef) x 3;
GetOptions ('input-file|f=s' => \$opt_f,
	    'output-file|o=s' => \$opt_o,
	    'log-file|l=s' => \$opt_l);
if (defined ($opt_f)) {
  open (SAVESTDIN, "<&STDIN") or croak $!;
  open (STDIN, "<$opt_f") or croak $!;
}
if (defined ($opt_o)) {
  open (SAVESTDOUT, ">&STDOUT") or croak $!;
  open (STDOUT, ">$opt_o") or croak $!;
}
if (defined ($opt_l)) {
  open (SAVESTDERR, ">&STDERR") or croak $!;
  open (STDERR, ">$opt_l") or croak !$;
}
print STDERR "$0 ($$): started at ", scalar gmtime, "\n";
#$ENV{'PATH'} = "/usr/local/rtsys/scripts:/usr/local/rtoper/scripts:$ENV{'PATH'}";

my $numrecs = 0;
my $line = '';			# The input buffer to process
while (<>) {
  # find each line
  chop;
  next if /^\s*$/;
  $line .= $_;			# append to previous line buffer
  my (@fields) = split (/\|/, $line);
  if (@fields < 17) {		# The row is continued on the next input line
    $line =~ s/[\r\s]+$//;
    next;
  }
  pop (@fields);		# The last field is empty
  # process the fields
  foreach my $field (@fields) {
    $field =~ s/^\"([^\"]*)\"$/$1/;
  }
  # hush up Perl from griping when printf args take more than one line
  my ($fmt) =
    "%5s %-5s %-25s %-30s %-2s %-116s %-255s %-2s %1s %-7s %-5s %-5s" .
      " %-10s %-10s %8s %9s\n";
  printf ($fmt, @fields);
  $line = '';			# clear line buffer
  $numrecs++;
}
print STDERR "Processed $numrecs records\n";
print STDERR "$0 ($$): finished at ", scalar gmtime, "\n";

# Clean up of file handles---probably not necessary
if (defined ($opt_l)) {
  close (STDERR);
  open (STDERR, ">&SAVESTDERR") or croak $!; # probably can't croak---oh well
  close (SAVESTDERR);
}
if (defined ($opt_o)) {
  close (STDOUT);
  open (STDOUT, ">&SAVESTDOUT") or croak $!;
  close (SAVESTDOUT);
}
if (defined ($opt_f)) {
  close (STDIN);
  open (STDIN, "<&SAVESTDIN") or croak $!;
  close (SAVESTDIN);
}







