#!/usr/bin/perl -w

use Date::Calc qw(Today Add_Delta_Days);

# initialize failure type counter

@count = ();
for ($c=0; $c<15; $c++) {
    $count[$c] = 0;
}

# Get QC date (today - 1) or user-input

if (!$ARGV[0]) {
   @today = Today();
} else {
    @today = $ARGV[0] =~ /(....)(..)(..)/;
}
@vdat = Add_Delta_Days(@today,-1);
$fnam = sprintf("%4.4d%2.2d%2.2d",$vdat[0],$vdat[1],$vdat[2]);

# Populate failure reason array

@flags = ('nul','nul','Unidentified station location',
	  '< 3 hourly reports in one day','Hourly observation > 4.00"',
	  'Consecutive observations >= 2"','Daily sum > 12.00"',
	  '>=2 daily sums >= 5.00"','Monthly sum >= 20.00"',
	  'Monthly sum > 2 * climate sum','Excessive missing obs for day',
	  '>= 35 missing obs for month','Stuck gage (repeated value)',
	  'Failed daily stn neighbor check','Failed hourly stn neighbor check');

# Get observation counts

open(DSP,"$ENV{DATA}/${fnam}.disp");
$nul = <DSP>;
$nul = <DSP>;
$rec = <DSP>;
($goodH,$evalH) = $rec =~ /goodH = (\d*)\s+failH = (\d*)\s+.*$/;
close DSP;

# Accumulate failure types

open(EVL,"$ENV{DATA}/$fnam.evalH");
$nul = <EVL>;
while (<EVL>) {
    @rec = split /\s+/;
    if ($rec[0] eq '') { 
	$nul = shift @rec; 
    }
    if (substr($rec[3],1,1) == 2) {
	$count[2]++;
    }
    for ($c=2; $c<14; $c++) {
	if (substr($rec[3],$c,1) == 1) {
	    $count[$c+1]++;
	}
    }
}
close EVL;

# Write output file

open(SUM,">$ENV{DATA}/$fnam.summary");

print SUM "Stats for 24h ending 12Z $fnam\n";
print SUM "Number of good gauges:      $goodH\n";
print SUM "Number of flagged gauges:   $evalH\n";
print SUM "\n";
print SUM "Reasons for flagging (overlap likely):\n"; 
for ($i=2; $i<15; $i++) {
    if ($i != 9 && $i != 11) {
	printf SUM ("%34s%4d\n",$flags[$i],$count[$i]);
    }
}
close SUM;
exit;
