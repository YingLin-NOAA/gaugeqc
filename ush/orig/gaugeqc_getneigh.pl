#!/usr/bin/perl

use strict;
use Date::Calc qw(Today_and_Now Add_Delta_DHMS);

my (%nwsli,%precip,%ref);
my (@begpd,@compass,@curdt,@dirs);
my (@dneigh,@endpd,@files,@hneigh,@in,@inf,@lat,@lon,@nbg,@neigh);
my (@today,@valid);
my ($adj,$ax,$alat,$alon,$amt,$anomdy,$anomdylist,$anomhrlist,$anomhr,$anommo);
my ($bx,$blat,$blon,$cct,$chk,$cou,$count,$counterrlist,$ct,$dayct,$dayms);
my ($ddist,$debug,$dec,$dg2rd,$diff,$dir,$dirs,$dstat,$dsum,$dt,$dx,$dy,$eval);
my ($evx,$fail,$fct,$files,$found,$gzfn,$hex,$hr,$i,$id,$id5,$id8,$idist,$in);
my ($inf,$j,$k,$lat,$lax,$lenh,$lon,$lox,$m,$mfv,$mfvz,$monms,$mo_precip,$n);
my ($neict,$nrat,$nul,$obs,$out,$outf,$p,$poss,$q,$ratio);
my ($rd2dg,$rec,$samt,$sgnn,$sgnt,$shr,$stuck,$stucklen,$stucklist,$tcnt);
my ($tdir,$tmsg,$tsum,$tzer,$today,$valid,$xdis,$ydis,$value,$u,$yes,$z);

$debug = 0;

print "init\n";
&init;
#print "getstnlist\n";
#&getstnlist;
print "readrec\n";
&readrec;
print "get_hr_neighbor\n";
&get_neigh;
print "cleanup\n";
&cleanup;

exit;

# subroutine to initialize variables

sub init {

# initialize file location variables

    $dstat = 0;
    %precip = %nwsli = ();
#    @compass = qw(348 11 33 56 78 101 123 146 168 191 213 236 258 281 303 326 348); # 16-pt compass
#    @compass = qw(337 22 67 112 157 202 247 292 337);                               # 8-pt compass
    @compass = qw(315 45 135 225 315);                                              # 4-pt compass
#    @dirs = qw(N__ NNE NE_ ENE E__ ESE SE_ SSE S__ SSW SW_ WSW W__ WNW NW_ NNW);    # 16-pt
#    @dirs = qw(N__ NE_ E__ SE_ S__ SW_ W__ NW_);                                    # 8-pt
    @dirs = qw(N__ E__ S__ W__);                                                    # 4-pt
    $dirs = @dirs;
    
    if (!$ARGV[0]) {
        @today = Today_and_Now(1);
    } else {
	@today = $ARGV[0] =~ /(....)(..)(..)/;
	push @today, (0,0,0);
    }

# initialize begin and end dates

    @begpd = Add_Delta_DHMS(@today,-31,0,0,0);
    @curdt = @begpd;
    @endpd = Add_Delta_DHMS(@today,-1,0,0,0);

    $today = sprintf("%4.4d%2.2d%2.2d",$endpd[0],$endpd[1],$endpd[2]);

# run subroutine to generate gzip script

    &gzfile;

    $files = @files;
}

# subroutine to generate gzip script used after processing

sub gzfile {
    for ($ax=0; $ax<30; $ax++) {
        @curdt = Add_Delta_DHMS(@curdt,1,0,0,0);
	$today = sprintf("%4.4d%2.2d%2.2d",$curdt[0],$curdt[1],$curdt[2]);
	$dt = substr($today,4,4);
	$gzfn = "z$today.tar.gz";
	if ((!-e "$ENV{DATA}/$today.eval" || !-e "$ENV{DATA}/$today.good" || !-e "$ENV{DATA}/$today.precip" || !-e "$ENV{DATA}/z$today.tar.gz")) {
            if ( -e "$ENV{COMIN}/z$today.tar.gz" ) {
              system("cp $ENV{COMIN}/z$today.tar.gz $ENV{DATA}/.");
	    }
            if ( -e "$ENV{DATA}/z$today.tar.gz" ) {
		system("gunzip -v $ENV{DATA}/$gzfn");
		system("tar -xvf $ENV{DATA}/z$today.tar $today.precip");
		system("gzip -v $ENV{DATA}/z$today.tar");
	    }
	}
        if (-e "$ENV{DATA}/$today.precip") {
	    push @files, "$today.precip";
	}
    }
}

# subroutine to generate list of nearest neighbors for all stations from
# which obervations have been received in the last 45 days

sub get_neigh {

    $ct = 0;
    $dg2rd = (3.141592654/180);
    $rd2dg = (180/3.141592654);
    open(DAY,">$ENV{DATA}/${today}_day.neigh");
    open(HR,">$ENV{DATA}/${today}_hour.neigh");
    @valid = sort keys %precip;
    foreach $j (sort keys %precip) {
	$ct++;
	@neigh = @hneigh = @dneigh = ();
	$id = $j;
	if ($ct % 100 == 0) {
	    print "$ct $id\n";
	}

# skip stations without location information

	if (!$precip{$id}{lat}) {
	    next;
	}
	foreach $i (@valid) {
	    if ($i ne $id) {

# do not compute distance between stations when latitude or longitude
# difference exceeds 1 degree

		if (abs($precip{$id}{lat} - $precip{$i}{lat}) > 1 ||
		    abs($precip{$id}{lon} - $precip{$i}{lon}) > 1) {
		    next;
		}

# convert latitude and longitude to radians

		$alat = $precip{$id}{lat}*$dg2rd;
		$blat = $precip{$i}{lat}*$dg2rd;
		$alon = $precip{$id}{lon}*$dg2rd;
		$blon = $precip{$i}{lon}*$dg2rd;

# compute distance between stations

		if ((1-(cos($alat)*cos($blat)*cos($blon-$alon))-(sin($blat)*sin($alat))) >= .00000001) {
		    $ddist=9002.18*sqrt((1-(cos($alat)*cos($blat)*cos($blon-$alon))-(sin($blat)*sin($alat))));
		} else {
		    $ddist = 999999;
		}

# determine azimuth from target station to neighbor station

		$xdis = ($blon-$alon);
		$ydis = ($blat-$alat);
		$tdir = atan2($ydis,$xdis)*$rd2dg;
		if ($ydis == 0) {
		    $tdir = $tdir + 90;
		} elsif ($xdis >= 0 && $ydis > 0) {
		    $tdir = 90 - $tdir;
		} elsif ($xdis < 0 && $ydis > 0) {
		    $tdir = 450 - $tdir;
		} else {
		    $tdir = 90 + abs($tdir);
		}

# determine compass direction from azimuth

		if ($tdir >= $compass[0] || $tdir <= $compass[1]) {
		    $dir = $dirs[0];
		} else {
		    for ($k=1; $k<($dirs-1); $k++) {
			if ($tdir >= $compass[$k] && $tdir < $compass[$k+1]) {
			    $dir = $dirs[$k];
			}
		    }
		}

# append daily and/or hourly neighbor array with distance and direction 
# information

		$dx = "$ddist $i $dir";
		if ($ddist != 999999) {
		    if ($precip{$j}{day} && $precip{$i}{day}) {
			push @dneigh, $dx;
		    }
		    if ($precip{$j}{hour} && $precip{$i}{day}) {
			push @hneigh, $dx;
		    }
		}
	    }
	}

# sort daily neighbors by distance and limit number to 51

	@neigh = sort { $a <=> $b } @dneigh;
	$neict = @neigh;
	if ($neict > 51) {
	    $neict = 51;
	}

# write list to file if adequate number of neighbors are found

	if ($neict >= 8) {
	    print DAY "$id: ";
	    for ($q=0; $q<$neict-2; $q++) {
		if ($neigh[$q]) {
		    @nbg = split /\s+/, $neigh[$q];
		    $idist = int($nbg[0]+0.5);
		    printf DAY ("%s\[%4.4d%3.3s\] ",$nbg[1],$idist,$nbg[2]);
		}
	    }
	    @nbg = split /\s+/, $neigh[$neict-1];
            printf DAY ("%s\[%4.4d%3.3s\]\n",$nbg[1],$idist,$nbg[2]);
	}

# sort hourly neighbors by distance and limit number to 51

	@neigh = sort { $a <=> $b } @hneigh;
	$neict = @neigh;
	if ($neict > 51) {
	    $neict = 51;
	}

# write list to file if adequate number of neighbors are found

	if ($neict >= 8) {
	    print HR "$id: ";
	    for ($q=0; $q<$neict-2; $q++) {
		if ($neigh[$q]) {
		    @nbg = split /\s+/, $neigh[$q];
		    $idist = int($nbg[0]+0.5);
		    printf HR ("%s\[%4.4d%3.3s\] ",$nbg[1],$idist,$nbg[2]);
		}
	    }
	    @nbg = split /\s+/, $neigh[$neict-1];
            printf HR ("%s\[%4.4d%3.3s\]\n",$nbg[1],$idist,$nbg[2]);
	}
    }
    close DAY;
    close HR;

}

# subroutine to retrieve latest NWSLI and dcp station lists and load array with
# location information

sub getstnlist {
    my ($id,@inf,$inf);
    my @nwsli = `ls -1 $ENV{COMOUT}/*.NWSLI`;
    @nwsli = reverse sort @nwsli;
    my $nwsli = substr($nwsli[0],0,length($nwsli[0])-1);
    open(INF,"$nwsli");

    while (<INF>) {
	$inf = $_;
	@inf = split /\s+/, $inf;
	if (! $inf[0]) {
	    shift @inf;
	}
	$lenh = @inf;
	$id = $inf[1];
	$id =~ s/\s//g;
    
#	$lat = $inf[$lenh-2];  
#	$lon = $inf[$lenh-1];   
	$nwsli{$id} = 1;
#	$precip{$id}{lat} = $lat;
#	$precip{$id}{lon} = $lon;
    }
    close INF;

    open(INF,"$ENV{DCOMgauge}/all_dcp_defs.txt");

    while (<INF>) {
	$inf = substr($_,0,length($_)-1);
	@inf = split /\|/, $inf;
	if ($inf[0] eq '') {
	    shift @inf;
	}
	
	$id = $inf[1];
	$id =~ s/\s//g;

	if (!$nwsli{ $id }) {
	    $nwsli{ $id } = 1;
	}
    }
    close INF;

}

# subroutine to validate station ID ** may be removed **

sub setid {
    $id5 = substr($_[0],0,5);
    if ($nwsli{$_[0]}) {
	$id = $_[0];
	$valid = 1;
#    } elsif ($nwsli{$id5}) {
#	$id = $id5;
#	$valid = 1;
    } elsif ($_[1] != 99.99999) {
	$id = $_[0];
	$valid = 2;
    } else {
	$id = $_[0];
	$valid = 0;
    }
    return ($id,$valid);
}

# subroutine to read data file and tag stations by type (daily/hourly)

sub readrec {
    foreach $i (@files) {
	$dx = substr($i,4,4);
	$dy = substr($i,0,8);
	print "$dy\n";
        open(INP,"$ENV{DATA}/$i") || die "cannot find file ${i}\n";
	while (<INP>) {
	    $in = substr($_,0,length($_)-1);
	    @in = split /\s+/, $in;
	    if ($in[0] eq '') {
		shift @in;
	    }
	    $id8 = $in[0];
	    $id8 =~ s/\s//g;
	    ($id,$valid) = &setid($id8,$in[1]);
	    if ($in =~ /U24Z99/) {
		$precip{$id}{day} = 1;
	    } else {
		$precip{$id}{hour} = 1;
	    }
	    if ($valid == 2) {
		$precip{$id}{lat} = $in[1];
		$precip{$id}{lon} = $in[2];
		$precip{$id}{src} = 'SRC';
		$precip{$id}{day} = 1;
	    }
	}
    }
}

sub cleanup {
    foreach $i (@files) {
#	system("rm -f $ENV{DATA}/$i");
    }
    unlink "$ENV{DATA}/${today}.tmp";
}

