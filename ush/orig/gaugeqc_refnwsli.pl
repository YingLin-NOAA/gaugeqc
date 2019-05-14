#!/usr/bin/perl

use strict;

### Variables

#  fdat -  file date
# outloc - output file location
#    per - number of days to process
# srcloc - source code location
#      y - EMC NWSLI filename

###

# declare variables

my (@files,@ref);
my ($cmd,$fdat,$y);
my (%ref);


@files = `ls -1 $ENV{DCOMgauge}/NWSLI*.TXT`;

foreach $y (@files) {
    ($fdat) = $y =~ /^.*(\d\d\d\d\d\d\d\d)\.TXT/;
    $y =substr($y,0,length($y)-1);
    if (! -e "$ENV{DATA}/$fdat.NWSLI") {
       print "perl $ENV{USHgauge}/gaugeqc_NWSLIreformat_EMC.pl \-f $y \-o $ENV{DATA}/$fdat.NWSLI\n";
       system("perl $ENV{USHgauge}/gaugeqc_NWSLIreformat_EMC.pl \-f $y \-o $ENV{DATA}/$fdat.NWSLI");
#yl
       system("cp $fdat.NWSLI $ENV{COMOUT}/.");
#yl
    }
}







