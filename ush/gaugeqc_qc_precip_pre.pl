#!/usr/bin/perl

use Date::Calc qw(Today_and_Now Add_Delta_DHMS);
use strict;

my (%count,%lat,%lon,%precip,%tcount);
my (@in,@inf,@lat,@lon,@mo,@obt,@out,@poss,@today,@typ,@yestday);
my ($amt,$count,$counter,$ct,$cx,$damt,$dcphadsI,$dcpnwsli,$dcpusa);
my ($debug,$dec,$dupval,$eq,$f,$hadsInwsli,$hadsIusa,$hr,$i,$id,$in);
my ($inf,$j,$k,$lat,$lax,$lenh,$lon,$lox,$mday,$miss,$mo,$ms,$name);
my ($nwsliusa,$nul,$nulx,$out,$poss,$recd,$sgnn,$sgnt,$t,$tl);
my ($today,$tx,$typ,$val,$x,$yestday,$yr,$ze);

$debug = 0;

if ($debug) { print "setloop\n"; }        #set loop counter to user-input value
$mday = -1;
for ($counter=$mday; $counter<0; $counter++) {
    if ($debug) { print "init\n"; }
    &init($counter);          #initialize variables/constants
    if ($debug) { print "write_scr\n"; }
    &write_scr;               #write gzip script
    if ($debug) { print "read_nwsli\n"; }
    &read_nwsli;              #read NWSLI station list
    if ($debug) { print "read_dcp\n"; }
    &read_dcp;                #read dcp station list
    if ($debug) { print "read_hads\n"; }
    &read_hads;               #read hads hourly data file
    if ($debug) { print "read_usa\n"; }
    &read_usa;                #read usa daily data file
    if ($debug) { print "open_file\n"; }
    &open_file;               #open processed files and diagnostic output files
    if ($debug) { print "load_lalo\n"; }
    &load_lalo;               #initialize latitude/longitude station locations
    if ($debug) { print "proc_hads\n"; }
    &proc_hads;               #process hads hourly data
    if ($debug) { print "proc_usa\n"; }
    &proc_usa;                #process usa daily data file
    if ($debug) { print "count_src\n"; }
    &count_src;               #generate descriptive comparison file
    if ($debug) { print "write_precip\n"; }
    &write_precip;            #write output files
    if ($debug) { print "cleanup\n"; }
    &cleanup;                 #close files and exit
}

sub init {
    @out = %precip = ();
    $nulx = '0' x 96;
    @typ = qw(dcp hadsI nwsli usa);
    @poss = qw(0001 0010 0100 1000 0011 0101 0110 0111 1001 1010 1011 1100 1101 1110 1111);
    $count = $miss = $poss = 0;
    @mo = qw(nul Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    $dcphadsI = $dcpnwsli = $dcpusa = $hadsInwsli = $hadsIusa = $nwsliusa = 0;
    if (! $ARGV[0]) {
	@today = Today_and_Now(1);
	@today = Add_Delta_DHMS(@today,-1,0,0,0);
    } else {
	@today = $ARGV[0] =~ /(....)(..)(..)/;
	push @today, (0,0,0);
        @today = Add_Delta_DHMS(@today,-1,0,0,0);
    }
    $today = sprintf("%4.4d%2.2d%2.2d",$today[0],$today[1],$today[2]);
    print "Processing: $today\n";
    $mo = $mo[$today[1]];
    $yr = sprintf("%2.2d",($today[0] - 2000));
    @yestday = Add_Delta_DHMS(@today,-1,0,0,0);
    $yestday = sprintf("%4.4d%2.2d%2.2d",$yestday[0],$yestday[1],$yestday[2]);

    system("cp $ENV{COMOUT}/hrly.prcp.day.$today $ENV{DATA}/hrly.prcp.day.$today");
    
    open (OUT,">$ENV{DATA}/${today}.nwsli");
    open (DUP,">$ENV{DATA}/${today}.duplicate");
    open (CT,">$ENV{DATA}/${today}.count");
}

sub write_scr {
    open(GZIP,">$ENV{DATA}/pcp_qc_gz.scr");
    print GZIP "#!/bin/ksh -x\n";
    print GZIP "cd $ENV{DATA}\n";
#yl copy over $today.NWSLI file just so it'll be archived as in GSD setup:
    print GZIP "cp $ENV{COMOUT}/${today}.NWSLI .\n";
#yl
    print GZIP "tar -cvf z${today}.tar ${today}*\n";
    print GZIP "cp ${today}.eval* $ENV{COMOUT}/.\n";
    print GZIP "cp ${today}.good* $ENV{COMOUT}/.\n";
    print GZIP "cp ${today}.precip $ENV{COMOUT}/.\n";
    print GZIP "cp ${today}.eval $ENV{COMOUT}/current.eval\n";
    print GZIP "cp ${today}.good $ENV{COMOUT}/current.good\n";
    print GZIP "cp ${today}.evalH $ENV{COMOUT}/current.evalH\n";
    print GZIP "cp ${today}.goodH $ENV{COMOUT}/current.goodH\n";
    print GZIP "cp ${today}_day.neigh $ENV{COMOUT}/.\n";
    print GZIP "cp ${today}_hour.neigh $ENV{COMOUT}/.\n";
#yl Use 'gzip -f' instead of 'gzip' so the job will overwrite any existing
#yl z${today}.tar.gz without waiting for user confirmation.  If we need to 
#yl make a re-run the old z${today}.tar.gz file might have been copied over
#yl from the 40-day rotating archive.
#yl print GZIP "gzip $ENV{DATA}/z${today}.tar\n";
    print GZIP "gzip -f z${today}.tar\n";
    print GZIP "cp z${today}.tar.gz $ENV{COMOUT}/.\n";
    close GZIP;
    chmod 0777, "$ENV{DATA}/pcp_qc_gz.scr";
}

sub read_nwsli {
    my @nwsli = `ls -1 $ENV{COMIN}/*.NWSLI`;
    @nwsli = reverse sort @nwsli;
    my $nwsli = $nwsli[0];
    open (INF,"${nwsli}" || die "cannot open NWSLI file\n");
    $ct = 0;
    print CT "NWSLI\n";
    if ($debug) { print "NWSLI $nwsli\n"; }

    while (<INF>) {
	$inf = $_;
	@inf = split /\s+/, $inf;
	if (! $inf[0]) {
	    shift @inf;
	}
	$lenh = @inf;
	$id = $inf[1];
	$name = $inf[2];
    
	$lat = $inf[$lenh-2];  
	$lon = $inf[$lenh-1];
	if ($lat =~ /\d+/ && $lon =~ /\d+/) {   
	    $out = sprintf ("%8s %8.5f %9.5f %s",$id,$lat,$lon,$name);
	} else {
	    $out = undef;
	}
	$eq = 0;
	if (! $eq && $out) {
	    push @out, $out;
	    $ct++;
	}
    }
    @out = sort @out;
    $tx = '000000000';
    foreach $j (@out) {
	if ($j eq $tx) {
	    $tx = $j;
	    print DUP "NWSLI: $j\n";
	    next;
	} else {
	    print OUT "$j\n";
	    $tx = $j;
	}
    }
    print CT "$ct\n";

    close INF;
    close OUT;
}

sub read_dcp {
    open (INF,"$ENV{DCOMgauge}/all_dcp_defs.txt" || die "cannot open dcp file\n");
    open (OUT,">$ENV{DATA}/${today}.dcp");

    $ct = 0;
    @out = ();
    print CT "all_dcp\n";
    if ($debug) { print "all_dcp\n"; }
    
    while (<INF>) {
	$inf = $_;
	@inf = split /\|/, $inf;
	
	$id = $inf[1];
	$name = $inf[9];
	$lax = $inf[5];
	$lox = $inf[6];
	splice(@inf,1,1);
	splice(@inf,4,2);
	splice(@inf,6,1);
	
	@lat = split /\s/, $lax;
	@lon = split /\s/, $lox;
	
	if ($lat[0] != 0) {
	    $sgnt = $lat[0] / abs($lat[0]);
	}
	if ($lon[0] != 0) {
	    $sgnn = $lon[0] / abs($lon[0]);
	}
	$lat = $sgnt * (abs($lat[0]) + $lat[1]/60 + $lat[2]/3600);   
	$lon = $sgnn * (abs($lon[0]) + $lon[1]/60 + $lon[2]/3600);   

	$out = sprintf ("%8s %8.5f %9.5f %s",$id,$lat,$lon,$name);
	$eq = 0;
	if ($lat == 0 && $lon == 0) {
	    $eq = 1;
	}
	if (! $eq) {
	    push @out, $out;
	    $ct++;
	}
    }
    @out = sort @out;
    $tx = '000000000';
    foreach $j (@out) {
	if ($j eq $tx) {
	    $tx = $j;
	    print DUP "dcp: $j\n";
	    next;
	} else {
	    print OUT "$j\n";
	    $tx = $j;
	}
    }
    print CT "$ct\n";

    close INF;
    close OUT;
}

sub read_hads {
    @out = ();
    open (INF,"$ENV{COMIN}/hrly.prcp.day.$yestday" || die "cannot open hadsI file\n");
    open (OUT,">$ENV{DATA}/${today}12.hadsI");

    print CT "hadsI\n";
    if ($debug) { print "hadsI\n"; }

    $ct = 0;
    while (<INF>) {
	$inf = $_;
	@inf = split /\s+/, $inf;
	if (! $inf[0]) {
	    shift @inf;
	}
	$ct++;
	$lenh = @inf;
	@obt = Add_Delta_DHMS($inf[0],$inf[1],$inf[2],$inf[3],$inf[4],0,0,0,30,0);
	$id = $inf[5];
	$hr = 'h' . $obt[3];
	$amt = int($inf[13]*100);
	if ($amt > 9999) {
	    print "Amount exceeds threshold\n$inf\n";
	    $amt = 9999;
	}
	if ($obt[3] >= 12 && $obt[2] == substr($yestday,6,2)) {
	    $dupval = 0;
	    if (!defined $precip{$id}{$hr}) {
		$precip{$id}{$hr} = $amt;
		if ($amt != 9999) {
		    $precip{$id}{total} += $amt;
		}
	    } elsif ($amt == $precip{$id}{$hr}) {
		$dupval = 1;
	    } else {
		if ($precip{$id}{$hr} != 9999) {
		    if ($precip{$id}{$hr} != 0) {
			$precip{$id}{count}--;
			$precip{$id}{total} -= $precip{$id}{$hr};
		    } else {
			$precip{$id}{zero}--;
		    }
		}
		$amt = 9999;
		$precip{$id}{$hr} = $amt;
	    }
	    if (!$dupval) {
		if ($amt != 9999) {
		    if ($amt != 0) {
			$precip{$id}{count}++;
		    } else {
			$precip{$id}{zero}++;
		    }
		}
	    }
	}
    }
    close INF;

# today's hrly.prcp.day.* file would be in COMOUT instead of COMIN (this matters
# during the testing stage when COMOUT is separated from COMIN
    open (INF,"$ENV{COMOUT}/hrly.prcp.day.$today" || die "cannot open hadsI file\n");
    while (<INF>) {
	$inf = $_;
	@inf = split /\s+/, $inf;
	if (! $inf[0]) {
	    shift @inf;
	}
	$ct++;
	$lenh = @inf;
	@obt = Add_Delta_DHMS($inf[0],$inf[1],$inf[2],$inf[3],$inf[4],0,0,0,30,0);
	$id = $inf[5];
	$hr = 'h' . $obt[3];
	$amt = int($inf[13]*100);
	if ($amt > 9999) {
	    print "Amount exceeds threshold\n$inf\n";
	    $amt = 9999;
	}
	if ($obt[3] < 12 || ($obt[3] == 23  && $obt[2] == substr($yestday,6,2))) {
	    $dupval = 0;
	    if (!defined $precip{$id}{$hr}) {
		$precip{$id}{$hr} = $amt;
		if ($amt != 9999) {
		    $precip{$id}{total} += $amt;
		}
	    } elsif ($amt == $precip{$id}{$hr}) {
		$dupval = 1;
	    } else {
		if ($precip{$id}{$hr} != 9999) {
		    if ($precip{$id}{$hr} != 0) {
			$precip{$id}{count}--;
			$precip{$id}{total} -= $precip{$id}{$hr};
		    } else {
			$precip{$id}{zero}--;
		    }
		}
		$amt = 9999;
		$precip{$id}{$hr} = $amt;
	    }
	    if (!$dupval) {
		if ($amt != 9999) {
		    if ($amt != 0) {
			$precip{$id}{count}++;
		    } else {
			$precip{$id}{zero}++;
		    }
		}
	    }
	}
    }
    foreach $i (keys %precip) {
	if (!defined $precip{$i}{count}) {
	    $precip{$i}{count} = 0;
	}
	if (!defined $precip{$i}{zero}) {
	    $precip{$i}{zero} = 0;
	}
	$out = sprintf("%8.8s ",$i);
	for ($j=12;$j<24;$j++) {
	    $hr = 'h' . $j;
	    if (!defined $precip{$i}{$hr} || $precip{$i}{$hr} == 9999) {
		$dec = 9999;
		$precip{$i}{miss}++;
	    } else {
		$dec = sprintf("%4.4d",$precip{$i}{$hr});
	    }
	    $out .= "$dec";
	}
	for ($j=0;$j<12;$j++) {
	    $hr = 'h' . $j;
	    if (!defined $precip{$i}{$hr} || $precip{$i}{$hr} == 9999) {
		$dec = 9999;
		$precip{$i}{miss}++;
	    } else {
		$dec = sprintf("%4.4d",$precip{$i}{$hr});
	    }
	    $out .= "$dec";
	}
	if ($precip{$i}{total} > 9999) {
	    $tl = 'D9999';
	} else {
	    $tl = sprintf("D%4.4d",$precip{$i}{total});
	}
	if (!defined $precip{$i}{miss}) {
	    $precip{$i}{miss} = 0;
	}
	$out .= "$tl";
	$cx = sprintf("C%2.2d",$precip{$i}{count});
	$out .= "$cx";
	$ze = sprintf("Z%2.2d",$precip{$i}{zero});
	$out .= "$ze";
	$ms = sprintf("M%2.2d",$precip{$i}{miss});
	$out .= "$ms";
	push @out, $out;
    }
    @out = sort @out;
    $tx = '000000000';
    foreach $j (@out) {
	if ($j eq $tx) {
	    $tx = $j;
	    next;
	} else {
	    print OUT "$j\n";
	    $tx = $j;
	}
    }
    $ct = @out;
    print CT "$ct\n";
    
    close INF;
    close OUT;
}

sub read_usa {
    @out = ();
# Reading from COMOUT because ush/gaugeqc_load_qual_prcp.pl produces 
# usa-dlyprcp-${today} earlier and placed it there.  
    print "$ENV{COMOUT}/usa-dlyprcp-${today}\n";
    open (INF,"$ENV{COMOUT}/usa-dlyprcp-${today}" || die "cannot open hadsusa file\n");
    open (OUT,">$ENV{DATA}/${today}.hadsusa");
    open (USF,">$ENV{DATA}/${today}.badobt");
    
    print CT "hads-usa\n";
    if ($debug) { print "hads-usa\n"; }
    $ct = 0;
    $nul = <INF>;
    while (<INF>) {
	$inf = $_;
	@inf = split /\s+/, $inf;
	if (! $inf[0]) {
	    shift @inf;
	}
	$lenh = @inf;
	$id = $inf[3];
	if ($id eq '' || ($inf[4] < 1000 || $inf[4] > 1400)) {
            $inf = substr($_,0,length($_)-1);
            print USF "$inf\n";
	}
	$ct++;
	
	$lat = $inf[0];   
	$lon = -$inf[1];
	$amt = $inf[2]*100;
	$damt = sprintf("%4.0f",$amt);
	$damt =~ s/ /0/g;
	$recd = $nulx . 'D' . $damt . 'U24Z99M99';
	
	$out = sprintf ("%8s %8.5f %10.5f %s",$id,$lat,$lon,$recd);
	$eq = 0;
	if (! $eq) {
	    push @out, $out;
	}
    }
    close USF;

    @out = sort @out;
    $tx = '000000000';
    foreach $j (@out) {
	if ($j eq $tx) {
	    $tx = $j;
	    print DUP "usa: $j\n";
	    next;
	} else {
	    print OUT "$j\n";
	    $tx = $j;
	}
    }
    print CT "$ct\n";
}

sub cleanup {
    close ERF;
    close INF;
    close OUT;
    close DUP;
    close CT;
    close PCP;
}

sub open_file {
    close CT;
    close DUP;
    close INF;
    close OUT;
    open(OUT,">$ENV{DATA}/${today}.comp");
    open(STAT,">$ENV{DATA}/${today}.stat");
    open(PCP,">$ENV{DATA}/${today}.precip");
    open(DIA,">$ENV{DATA}/${today}.diag");
    open(ERF,">$ENV{DATA}/${today}.error");
}

sub load_lalo {
    open(INP,"$ENV{DATA}/${today}.nwsli");
    while (<INP>) {
	$in = substr($_,0,length($_)-1);
	@in = split /\s+/, $in;
	if ($in[0] eq '') {
	    shift @in;
	}
	$id = $in[0];
	$id =~ s/\s//g;
	$lat = $in[1];
	$lon = $in[2];
	$precip{$id}{nwsli} = 1;
	$precip{$id}{latn} = $lat;
	$precip{$id}{lonn} = $lon;
	$lat{ $id } = $lat;
	$lon{ $id } = $lon;
    }
    close INP;

    open(INP,"$ENV{DATA}/${today}.dcp");
    while (<INP>) {
	$in = substr($_,0,length($_)-1);
	@in = split /\s+/, $in;
	if ($in[0] eq '') {
	    shift @in;
	}
	$id = $in[0];
	$id =~ s/\s//g;
	$lat = $in[1];
	$lon = $in[2];
	$precip{$id}{dcp} = 1;
	$precip{$id}{latd} = $lat;
	$precip{$id}{lond} = $lon;
	if (! $lat{ $id }) {
	    $lat{ $id } = $lat;
	    $lon{ $id } = $lon;
	}
    }
    close INP;
}
sub proc_hads {
    open(INP,"$ENV{DATA}/${today}12.hadsI");
    while (<INP>) {
	$in = substr($_,0,length($_)-1);
	@in = split /\s+/, $in;
	if ($in[0] eq '') {
	    shift @in;
	}
	$id = $in[0];
	$id =~ s/\s//g;
	if (!$lat{$id}) {
	    print DIA "station $id not found in master lists: no lat/lon\n";
	}
	$amt = substr($in,82,3)/100;
	$amt =~ s/\s//g;
	$precip{$id}{hadsI} = $in[1];
	$precip{$id}{total} = $amt;
	
    }
    close INP;
}

sub proc_usa {
    open(INP,"$ENV{DATA}/${today}.hadsusa");
    while (<INP>) {
	$in = substr($_,0,length($_)-1);
	@in = split /\s+/, $in;
	if ($in[0] eq '') {
	    shift @in;
	}
	$id = $in[0];
	$id =~ s/\s//g;
	if (!$lat{$id}) {
	    print DIA "station $id not found in master lists: source lat/lon used\n";
	    $lat{$id} = $in[1];
	    $lon{$id} = $in[2];
	}
	$precip{$id}{hadsusa} = $in[3];
    }
    close INP;
}

sub count_src {
    @out = %count = %tcount = ();
    foreach $t (@poss) {
	$count{$t} = 0;
    }
    foreach $i (keys %precip) {
	push @out, $i;
    }
    @out = sort @out;
    $count{total} = 0;
    foreach $i (@out) {
	$count{total}++;
	$k = '';
	foreach $j (keys %{$precip{$i}}) {
	    $k .= "$j ";
	}
	$val = 0;
	if ($k =~ 'dcp ') {
	    $out = 'dcp ';
	    $val += 1000;
	    $tcount{dcp}++;
	} else {
	    $out = '    ';
	}
	if ($k =~ 'hadsI ') {
	    $out .= 'hadsI ';
	    $val += 100;
	    $tcount{hadsI}++;
	} else {
	    $out .= '      ';
	}
	if ($k =~ 'nwsli') {
	    $out .= 'nwsli ';
	    $val += 10;
	    $tcount{nwsli}++;
	} else {
	    $out .= '      ';
	}
	if ($k =~ 'hadsusa') {
	    $out .= 'usa';
	    $val += 1;
	    $tcount{usa}++;
	} else {
	    $out .= '     ';
	}
	$val = sprintf("%4.4d",$val);
	$count{$val}++;
	if (substr($val,0,2) == 11) {
	    $dcphadsI++;
	}
	if (substr($val,0,1) == 1 && substr($val,2,1) == 1) {
	    $dcpnwsli++;
	}
	if (substr($val,0,1) == 1 && substr($val,3,1) == 1) {
	    $dcpusa++;
	}
	if (substr($val,1,1) == 1 && substr($val,2,1) == 1) {
	    $hadsInwsli++;
	}
	if (substr($val,1,1) == 1 && substr($val,3,1) == 1) {
	    $hadsIusa++;
	}
	if (substr($val,2,2) == 11) {
	    $nwsliusa++;
	}
	
	printf OUT ("%8s %s\n",$i,$out);

    }
    print STAT "Record count by file\n\n";
    foreach $j (keys %tcount) {
	printf STAT ("%5.5d %s\n",$tcount{$j},$j);
    }
    print STAT "\nFile Intercomparison\n\n";
    foreach $t (@poss) {
	$typ = undef;
	$x = $t;
	for ($f=0;$f<4;$f++) {
	    if (substr($x,$f,1) eq '1') {
		if (defined $typ) {
		    $typ .= " + $typ[$f]";
		} else {
		    $typ = $typ[$f];
		}
	    }
	}
	$typ .= ' only';
	if ($count{$t} != 0) {
	    printf STAT ("%5d %s\n",$count{$t},$typ);
	}
    }
    
    print STAT "total count: $count{total}\n\n";
    print STAT "File Pair comparison\n\n";
    printf STAT ("%5.5d %s\n",$dcphadsI,'common: dcp hadsI');
    printf STAT ("%5.5d %s\n",$dcpnwsli,'common: dcp nwsli');
    printf STAT ("%5.5d %s\n",$dcpusa,'common: dcp usa');
    printf STAT ("%5.5d %s\n",$hadsInwsli,'common: hadsI nwsli');
    printf STAT ("%5.5d %s\n",$hadsIusa,'common: hadsI usa');
    printf STAT ("%5.5d %s\n",$nwsliusa,'common: nwsli usa');
    close INP;
    close OUT;
    close STAT;
}

sub write_precip {
    @out = ();
    foreach $i (keys %precip) {
	push @out, $i;
    }
    @out = sort @out;
    foreach $i (@out) {
	$k = '';
	foreach $j (keys %{$precip{$i}}) {
	    $k .= "$j ";
	}
	if ($k =~ /hadsI/) {
	    if (!defined $lat{$i}) {
		$lat{$i} = 99;
		$lon{$i} = -999;
	    }
	    printf PCP ("%8s %9.5f %10.5f %s\n",$i,$lat{$i},$lon{$i},$precip{$i}{hadsI});
	}
	if ($k =~ /hadsusa/) {
	    if (!defined $lat{$i}) {
		$lat{$i} = 99;
		$lon{$i} = -999;
	    }
	    printf PCP ("%8s %9.5f %10.5f %s\n",$i,$lat{$i},$lon{$i},$precip{$i}{hadsusa});
	}
	if ($k =~ /nwsli/ && $k =~ /dcp/ && $k =~ /hadsI/) {
	    $poss+=2;
	    $precip{$i}{latd} = int((($precip{$i}{latd}) * 1000) + 0.5) / 1000;
	    $precip{$i}{lond} = int((($precip{$i}{lond}) * 1000) + 0.5) / 1000;
	    $precip{$i}{latn} = int((($precip{$i}{latn}) * 1000) + 0.5) / 1000;
	    $precip{$i}{lonn} = int((($precip{$i}{lonn}) * 1000) + 0.5) / 1000;
	    if ($precip{$i}{latd} != $precip{$i}{latn}) {
		$miss++;
		print ERF "lat mismatch: $i $precip{$i}{latd} $precip{$i}{lond} | $precip{$i}{latn} $precip{$i}{lonn}\n";
	    } elsif ($precip{$i}{lond} != $precip{$i}{lonn}) {
		$miss++;
		print ERF "lon mismatch: $i $precip{$i}{latd} $precip{$i}{lond} | $precip{$i}{latn} $precip{$i}{lonn}\n";
	    }
	}
    }
    print ERF "\nLocation errors: $miss of $poss\n";
}

