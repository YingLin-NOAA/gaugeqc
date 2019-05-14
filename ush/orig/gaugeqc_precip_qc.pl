#!/usr/bin/perl

use strict;
use Date::Calc qw(Add_Delta_Days Day_of_Week);
 
# March 25, 2004
# script to pre-process hourly and daily precipitation data
# Author: Randall Collander, CSU/CIRA and NOAA/FSL
# randall.s.collander@noaa.gov

#yl system('source /home/mab/collande/.cshrc');

# declare variables

my (@today);
my ($dow,$curdt,$yr,$mo,$dt);

#yltest
print "$ENV{USHgauge}\n";
print "About to call gaugeqc_refnwsli.pl\n";
#yltest
system("$ENV{USHgauge}/gaugeqc_refnwsli.pl");

# usage check - quit if missing command line parameter

# set begin and end dates

#print "$ENV{USHgauge}\n";
system("$ENV{USHgauge}/gaugeqc_getneigh.pl $ARGV[0]");
system("$ENV{USHgauge}/gaugeqc_qc_precip_pre.pl $ARGV[0]");
system("$ENV{USHgauge}/gaugeqc_qc_precip.pl $ARGV[0]");
system("$ENV{USHgauge}/gaugeqc_qc_latlon.pl $ARGV[0]");
system("$ENV{USHgauge}/gaugeqc_pcp_r2l.pl $ARGV[0]");
system("$ENV{USHgauge}/gaugeqc_daily_sum.pl $ARGV[0]");
system("$ENV{DATA}/pcp_qc_gz.scr");

#system("/home/mab/collande/pcp_qc/temp6/qc_precip_pre.pl");
#system("/home/mab/collande/pcp_qc/temp6/qc_precip.pl $ARGV[0]");
#system("/home/mab/collande/pcp_qc/temp6/qc_latlon.pl $ARGV[0]");
#system("/home/mab/collande/pcp_qc/temp6/pcp_r2l.pl $ARGV[0]");
#system("/data/mab/PVstrm/pcp_qc/pcp_qc_gz.scr");
