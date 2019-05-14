#!/usr/bin/perl

use Date::Calc qw(Add_Delta_Days);

my @ref;
my %ref;

open(REF,"$ENV{PARMFILE}");
while (<REF>) {
    @ref = split /\s+/;
    $ref{$ref[0]} = $ref[1];
}
close REF;

@today = $ARGV[0] =~ /(....)(..)(..)/;
@curdt = Add_Delta_Days(@today,-33);

for ($i=0; $i<33; $i++) {
    @date1 = Add_Delta_Days(@curdt,$i);
    $today = sprintf("%4.4d%2.2d%2.2d",$date1[0],$date1[1],$date1[2]);

    print "$ref{srcloc}/gaugeqc_precip_qc.pl $today\n";
    system("$ref{srcloc}/gaugeqc_precip_qc.pl $today");
}
