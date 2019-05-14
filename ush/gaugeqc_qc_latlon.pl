#!/usr/bin/perl

use Date::Calc qw(Today_and_Now Add_Delta_Days Add_Delta_DHMS);

$nulx = '0' x 96;
#$debug = $ARGV[0];
@distrib = ();
@mo = qw(nul Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
if (! $ARGV[0]) {
    @today = Today();
    @today = Add_Delta_Days(@today,-1);
} else {
    @today = $ARGV[0] =~ /(....)(..)(..)/;
    @today = Add_Delta_Days(@today,-1);
}
#@today = Today_and_Now(1);
#@today = Add_Delta_DHMS(@today,-1,0,0,0);
$today = sprintf("%4.4d%2.2d%2.2d",$today[0],$today[1],$today[2]);

my $pi = 3.141592654;
my $dg2rd = $pi / 180;
my $rd2dg = 180 / $pi;
for ($i=0;$i<=200;$i++) {
    $distrib[$i] = 0;
}

open(PCP,"$ENV{DATA}/${today}.error");
open(OUT,">$ENV{DATA}/${today}.latlon");
while (<PCP>) {
    $in = substr($_,0,length($_)-1);
    @in = split /\s+/, $in;
    if ($in[0] eq 'Location') {
	last;
    }
    $id = $in[2];

    $dclat = $in[3]*$dg2rd;
    $nwlat = $in[6]*$dg2rd;
    $dclon = $in[4]*$dg2rd;
    $nwlon = $in[7]*$dg2rd;

    if ((1-(cos($dclat)*cos($nwlat)*cos($nwlon-$dclon))-(sin($nwlat)*sin($dclat))) >= .00000001) {
	$ddist=9002.18*sqrt((1-(cos($dclat)*cos($nwlat)*cos($nwlon-$dclon))-(sin($nwlat)*sin($dclat))));
    } else {
	$ddist = 0;
    }
    if ((1-(cos($dclat)*cos($nwlat)*cos($nwlon-$nwlon))-(sin($nwlat)*sin($dclat))) >= .00000001) {
	$tdist=9002.18*sqrt((1-(cos($dclat)*cos($nwlat)*cos($nwlon-$nwlon))-(sin($nwlat)*sin($dclat))));
    } else {
	$tdist = 0;
    }
    if ((1-(cos($nwlat)*cos($nwlat)*cos($nwlon-$dclon))-(sin($nwlat)*sin($nwlat))) >= .00000001) {
	$ndist=9002.18*sqrt((1-(cos($nwlat)*cos($nwlat)*cos($nwlon-$dclon))-(sin($nwlat)*sin($nwlat))));
    } else {
	$ndist = 0;
    }
    $distrib = int(($ddist + 0.5) / 10);
    if ($distrib < 200) {
	$distrib[$distrib]++;
    } else {
#	print "$in\n";
	$distrib[200]++;
    }
    printf OUT ("%5s %s %12.7f %s %12.7f %s %12.7f\n",$id,'dist = ',$ddist,' dlat = ',$tdist,' dlon = ',$ndist);
}
close PCP;

for($i=0;$i<200;$i++) {
    $jj = ($i+1)*10;
    $j = $i*10;
    if ($distrib[$i] != 0) {
	printf OUT ("%4d %s %4d %s %5d\n",$j,'-',$jj,' km: ',$distrib[$i]);
    }
}
printf OUT ("%s %5d\n",'     > 2000  km: ',$distrib[200]);

close OUT;

