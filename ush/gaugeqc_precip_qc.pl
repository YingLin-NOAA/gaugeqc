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
my ($ScriptStartTime,$ElapsedTime);

$ScriptStartTime = time();
$ElapsedTime = time() - $ScriptStartTime;
print "At the start of gaugeqc_precip_qc.pl, elapsed time=", $ElapsedTime, "\n";

system("$ENV{USHgauge}/gaugeqc_refnwsli.pl");

$ElapsedTime = time() - $ScriptStartTime;
print "After gaugeqc_refnwsli.pl, elapsed time=", $ElapsedTime, "\n";

# usage check - quit if missing command line parameter

# set begin and end dates

#print "$ENV{USHgauge}\n";
system("$ENV{USHgauge}/gaugeqc_getneigh.pl $ARGV[0]");
$ElapsedTime = time() - $ScriptStartTime;
print "After gaugeqc_getneigh.pl, elapsed time=", $ElapsedTime, "\n";

system("$ENV{USHgauge}/gaugeqc_qc_precip_pre.pl $ARGV[0]");
$ElapsedTime = time() - $ScriptStartTime;
print "After gaugeqc_qc_precip_pre.pl, elapsed time=", $ElapsedTime, "\n";

system("$ENV{USHgauge}/gaugeqc_qc_precip.pl $ARGV[0]");
$ElapsedTime = time() - $ScriptStartTime;
print "After gaugeqc_qc_precip.pl, elapsed time=", $ElapsedTime, "\n";

system("$ENV{USHgauge}/gaugeqc_qc_latlon.pl $ARGV[0]");
$ElapsedTime = time() - $ScriptStartTime;
print "After gaugeqc_qc_latlon.pl, elapsed time=", $ElapsedTime, "\n";

system("$ENV{USHgauge}/gaugeqc_pcp_r2l.pl $ARGV[0]");
$ElapsedTime = time() - $ScriptStartTime;
print "After gaugeqc_pcp_r2l.pl, elapsed time=", $ElapsedTime, "\n";

system("$ENV{USHgauge}/gaugeqc_daily_sum.pl $ARGV[0]");
$ElapsedTime = time() - $ScriptStartTime;
print "After gaugeqc_daily_sum.pl, elapsed time=", $ElapsedTime, "\n";

system("$ENV{DATA}/pcp_qc_gz.scr");
$ElapsedTime = time() - $ScriptStartTime;
print "After pcp_qc_gz.scr, elapsed time=", $ElapsedTime, "\n";

#system("/home/mab/collande/pcp_qc/temp6/qc_precip_pre.pl");
#system("/home/mab/collande/pcp_qc/temp6/qc_precip.pl $ARGV[0]");
#system("/home/mab/collande/pcp_qc/temp6/qc_latlon.pl $ARGV[0]");
#system("/home/mab/collande/pcp_qc/temp6/pcp_r2l.pl $ARGV[0]");
#system("/data/mab/PVstrm/pcp_qc/pcp_qc_gz.scr");
