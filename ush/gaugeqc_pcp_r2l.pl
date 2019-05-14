#!/usr/bin/perl

use Date::Calc qw(Today Add_Delta_Days);

@ftyp = qw(eval evalH evalU good goodH goodU);

if (! $ARGV[0]) {
    @today = Today();
    @today = Add_Delta_Days(@today,-1);
} else {
    @today = $ARGV[0] =~ /(....)(..)(..)/;
    @today = Add_Delta_Days(@today,-1);
}
$date = sprintf("%4d%2.2d%2.2d",$today[0],$today[1],$today[2]);

foreach $i (@ftyp) {
    $fnam = "$ENV{DATA}/$date\.$i";
    open(INP,"$fnam");
    open(OUT,">$ENV{DATA}/transfm.txt");
    $nul = <INP>;
    $nul = substr($nul,0,length($nul)-1);
    print OUT "$nul\n";
    while (<INP>) {
	$in = substr($_,0,length($_)-1);
	$sta = substr($in,0,8);
	($rt) = $sta =~ /(\w+)/;
	$lenrt = 8- length($rt);
	$lf = $rt . ' ' x $lenrt;
	substr($in,0,8) = $lf;
	print OUT "$in\n";
    }
    close INP;
    close OUT;
    system("cp $ENV{DATA}/transfm.txt $fnam");
}
unlink "$ENV{DATA}/transfm.txt";






