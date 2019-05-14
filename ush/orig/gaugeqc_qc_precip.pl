#!/usr/bin/perl

use strict;
use Date::Calc qw(Today_and_Now Add_Delta_DHMS);

my (%climate,%nwsli,%precip,%quad);
my (@anomdy,@anomdysta,@anomhr,@anomhrsta,@br,@cldate,@consec);
my (@begpd,@cft,@compass,@curdt,@current,@daysta);
my (@diff,@dirs,@endpd,@eparams,@eval,@files,@good,@in,@inf);
my (@neifail,@neipass,@noneigh,@norep,@notvalid,@obs,@oneob,@params);
my (@pcp,@stop,@stuck,@stuckhr,@stucksta,@today,@usafail,@usapass,@valid);
my (@type);
my ($adj,$ax,$amt,$anomdy,$anomdylist,$anomhrlist,$anomhr,$anommo);
my ($b,$cct,$chk,$consec,$cou,$count,$ct);
my ($dayct,$debug,$dec,$diff,$dstat);
my ($dsum,$dt,$dx,$dy,$eval,$evx,$fail,$failsum,$fct,$files,$found,$ftoday);
my ($gzfn,$hr,$i,$id,$id8,$in,$inf,$j,$k,$m,$mfv,$mfvz,$monms,$nwsli);
my ($mo_precip,$n,$nrat,$nul,$out,$outf,$p,$rt);
my ($poss,$ratio,$rec,$samt,$shr,$stuck,$stucklen,$stucklist,$tcnt);
my ($tmsg,$tsum,$tzer,$today,$valid,$value,$yes,$z,$zh);

$debug = 1;

if ($debug) { print "init\n"; }              #initialize variables/constants
&init;
if ($debug) {print "loadclim\n"; }           # load COOP station climatology
&loadclim;
if ($debug) {print "getstnlist\n"; }         # load station information
&getstnlist;
if ($debug) {print "readrec\n"; }            # read precip data
&readrec;
if ($debug) {print "set_type\n"; }           # set station type (daily/hourly)
&set_type;
if ($debug) {print "evaluate\n"; }           # QC precip data against criteria (through yesterday)
&eval;
if ($debug) {print "mark_val\n"; }           # fill daily and hourly station arrays
&mark_val;
if ($debug) {print "check_day_neighbor\n"; } # neighbor-check daily stations
&ck_dneigh;
#&ck_dneigh_sp;                              # spatial consideration
if ($debug) {print "check_hr_neighbor\n"; }  # neighbor-check hourly stations
&ck_neigh;
#&ck_neigh_sp;                               # spatial consideration
if ($debug) {print "check_today\n"; }        # add today's evaluation
&eval_today;
if ($debug) {print "writefile\n"; }          # write output files
&writefile;
#if ($debug) {print "sumanom\n"; }           # compile statistic information
#&sumanom;
if ($debug) {print "cleanup\n"; }            # close files
&cleanup;

exit;

sub init {
    $dstat = 0;
    %precip = %nwsli = ();
    $stucklist = $anomhrlist = $anomdylist = '';
    @stucksta = @anomhrsta = @anomdysta = ();
    @params = qw(dayct dayg1 hours);
    @eparams = qw(recnon reczer recmis recstu dayct dayg1 hours anomhr anomdy stuck miss);

#    @compass = qw(348 11 33 56 78 101 123 146 168 191 213 236 258 281 303 326 348); # 16-pt compass
#    @dirs = qw(N__ NNE NE_ ENE E__ ESE SE_ SSE S__ SSW SW_ WSW W__ WNW NW_ NNW);    # 16-pt
#    @compass = qw(337 22 67 112 157 202 247 292 337);                               # 8-pt compass
#    @dirs = qw(N__ NE_ E__ SE_ S__ SW_ W__ NW_);                                    # 8-pt
    @compass = qw(315 45 135 225 315);                                                # 4-pt compass
    @dirs = qw(N__ E__ S__ W__);                                                    # 4-pt

    for ($i=0; $i<24; $i++) {
	$hr = ($i+12) - ((int($i/12))*24);
	$shr = "h" . sprintf("%2.2d",$hr);
	push @params, $shr;
    }
    push @params, ('a0000','a0001','a0002','a0003','a0004','a0005','a0009','a0010','a0020','a0030','a0040','a0050',
		   'a0100','a0200','a0300','miss','max','daymax','mosum');
    if (!$ARGV[0]) {
        @today = Today_and_Now(1);
    } else {
	@today = $ARGV[0] =~ /(....)(..)(..)/;
	push @today, (0,0,0);
    }
    @begpd = Add_Delta_DHMS(@today,-31,0,0,0);
    @curdt = @begpd;
    @endpd = Add_Delta_DHMS(@today,-1,0,0,0);

    $today = sprintf("%4.4d%2.2d%2.2d",$endpd[0],$endpd[1],$endpd[2]);
#
# thresholds for evaluation
#
    $anomhr = 4.00;  # maximum hourly amount
    $anomdy = 12.00; # maximum daily amount
    $anommo = 20.00; # maximum monthly amount
    $dayct = 3;      # minimum daily records for 30 days
    $monms = 35;     # maximum number of missing values for month
    $adj = 0.00;     # precip amount adjustment to zero
    $nrat = 0.500;   # ratio needed to pass neighbor check

    &gzfile;
    $files = @files;
}

sub gzfile {
    for ($ax=0; $ax<30; $ax++) {
        @curdt = Add_Delta_DHMS(@curdt,1,0,0,0);
	$today = sprintf("%4.4d%2.2d%2.2d",$curdt[0],$curdt[1],$curdt[2]);
	$dt = substr($today,4,4);
	$gzfn = "z$today.tar.gz";
	if ((!-e "$today.eval" || !-e "$today.good" || !-e "$today.precip") && $ax != 29) {
	    if (-e "$ENV{COMIN}/z$today.tar.gz") {
                system("cp $ENV{COMIN}/z$today.tar.gz $ENV{DATA}/.");
		system("gunzip -v $ENV{DATA}/$gzfn");
		system("tar -xvf $ENV{DATA}/z$today.tar $today.eval");
		system("tar -xvf $ENV{DATA}/z$today.tar $today.good");
		system("tar -xvf $ENV{DATA}/z$today.tar $today.evalH");
		system("tar -xvf $ENV{DATA}/z$today.tar $today.goodH");
		system("tar -xvf $ENV{DATA}/z$today.tar $today.precip");
		system("tar -xvf $ENV{DATA}/z$today.tar $today.evalU");
		system("tar -xvf $ENV{DATA}/z$today.tar $today.goodU");
		system("gzip -v $ENV{DATA}/z$today.tar");
	    }
	}
        if (-e "$ENV{DATA}/$today.precip") {
	    push @files, "$today.precip";
	}
        if (-e "$ENV{DATA}/$today.eval") {
	    push @eval, "$today.eval";
	}
        if (-e "$ENV{DATA}/$today.good") {
	    push @eval, "$today.good";
	}
    }
}

sub eval_today {
    foreach $j (sort keys %precip) {
	if ($precip{$j}{eval}) {
	    $in = $precip{$j}{eval};
            $failsum = 0;
	    if (substr($in,2,1) == 1 || substr($in,9,1) == 1 || substr($in,10,1) == 1) {
		$precip{$j}{insuf}++;
		$precip{$j}{failct}++;
	    }
	    if (substr($in,3,1) == 1 || substr($in,4,1) == 1) {
		$precip{$j}{failhr}++;
		$precip{$j}{failct}++;
	    }
	    if (substr($in,5,1) == 1 || substr($in,6,1) == 1) {
		$precip{$j}{faildy}++;
		$precip{$j}{failct}++;
	    }
	    if (substr($in,7,1) == 1 || substr($in,8,1) == 1) {
		$precip{$j}{failmo}++;
		$precip{$j}{failct}++;
	    }
	    if (substr($in,11,1) == 1) {
		$precip{$j}{failgage}++;
		$precip{$j}{failct}++;
	    }
	    if (substr($in,12,1) == 1 || substr($in,13,1) == 1) {
		$precip{$j}{failneigh}++;
		$precip{$j}{failct}++;
	    }
	}

        $failsum = $precip{$j}{failhr} + $precip{$j}{faildy} +
                $precip{$j}{failmo} + $precip{$j}{failgage};
        if ($failsum) {
            substr($in,0,1) = 1;
        }

	$fct = sprintf("%2.2d%2.2d%2.2d%2.2d%2.2d%2.2d",$precip{$j}{insuf},
		       $precip{$j}{failhr},$precip{$j}{faildy},$precip{$j}{failmo},
		       $precip{$j}{failgage},$precip{$j}{failneigh});
	$precip{$j}{eval} = $in . $fct;
    }
}

sub mark_val {
    @good = @daysta = ();
    my @cft = ();
    foreach $i (sort keys %precip) {
	if ($precip{$i}{day}) {
	    $precip{$i}{valid} = 1;
	    push @daysta, $i;
	}
	if ($precip{$i}{hour}) {
	    push @good, $i;
	}
	if ($precip{$i}{day} && !$precip{$i}{hour}) {
	    $cft[0]++;
	    substr($precip{$i}{eval},12,1) = '8';
	} elsif (!$precip{$i}{day} && $precip{$i}{hour}) {
	    $cft[1]++;
	} elsif ($precip{$i}{day} && $precip{$i}{hour}) {
	    $cft[2]++;
	} else {
	    $cft[3]++;
	}
    }
    $i = @good;
    $j = @daysta;
    if ($debug) { print "day:$cft[0] hour:$cft[1] both:$cft[2] good_hrly:$i daily:$j\n" };
}

sub set_type {
    open(INP,"$ENV{DATA}/${today}.precip");
    while (<INP>) {
	$in = substr($_,0,length($_)-1);
	@in = split /\s+/, $in;
	if ($in[0] eq '') {
	    shift @in;
	}
	$id = $in[0];
	$id =~ s/\s//g;
	$precip{$id}{lat} = $in[1];
	$precip{$id}{lon} = $in[2];
	$precip{$id}{hdist} = 999999;
	$precip{$id}{hneigh} = 'ZZZZZZZZ';
	$precip{$id}{ddist} = 999999;
	$precip{$id}{dneigh} = 'ZZZZZZZZ';
	if ($in =~ /U24Z99/) {
	    $precip{$id}{day} = 1;
	} else {
	    $precip{$id}{hour} = 1;
	}
    }
    close INP;
}

sub ck_neigh {
    my ($nei,$nct,$nvals,$e,$nlen,$ntest,$ct,$ii,$rat);
    my (@nei,@neival,@yeanay,@nnn);
    my @neighbor = `ls -1 $ENV{DATA}/*hour.neigh`;
    @neighbor = reverse sort @neighbor;
    $neighbor[0] =~ /^\/[\w\/]*\/(\d*)\_.*/;
    my @elementsinstring = split (/\//, $neighbor[0]);
    print "chk_neigh-1; elements in string=@elementsinstring\n";
    my $nelements=scalar(@elementsinstring);
    print "chk_neigh-2; number of elements in string=$nelements\n";
    my $NEIFILE=$elementsinstring[$nelements-1];
    print "chk_neigh-3; NEI=$ENV{DATA}/$NEIFILE\n";
    open(NEI,"$ENV{DATA}/$NEIFILE");
    while (<NEI>) {
	$nei = substr($_,0,length($_)-1);
	$nei =~ s/\://;
	@nei = split /\s+/, $nei;
	$nct = 0;
	if (!defined $precip{$nei[0]}{sum}) {
	    next;
	}
	$nvals = sprintf("%8.8s\#%5.2f ",$nei[0],$precip{$nei[0]}{sum});
        for ($e=1; $e<50; $e++) {
	    $nei[$e] =~ /(\w+)\[(\d\d\d\d)(\w\w\w)\]/;
	    @br = ($1,$2,$3);
	    if (!defined $br[0] || !defined $precip{$br[0]}{dsum}) {
		next;
	    }
	    if ($precip{$br[0]}{sum} >= 0 && substr($precip{$br[0]}{eval},12,1) eq '0') {
	        $nvals .= sprintf("%8.8s\#%2.2s\_%4.4d\#%5.2f ",$br[0],$br[2],$br[1],$precip{$br[0]}{sum});
		$nct++;
                if ($nct == 8) {
		    last;
		}
	    }
	}
        $nvals =~ s/\# /\#0/g;
        $precip{$nei[0]}{neigh} = $nvals;
    }
    close NEI;
    foreach $j (sort keys %precip) {
	if (!$precip{$j}{eval}) {
	    next;
	}
	@eval = split /\_/, $precip{$j}{eval};
	$eval = $eval[0];
	@yeanay = (0,0);
	$ct = $rat = 0;
        if ($precip{$j}{neigh}) {
	    @neival = split /\s+/, $precip{$j}{neigh};
	    if ($neival[0] eq '') {
		$nul = shift @neival;
	    }
	    $nlen = @neival;
	    @nnn = split /\#/, $neival[0];
            if ($nnn[1]-$adj <= 0) {
		$ntest = 0;
	    } else {
		$ntest = 1;
	    }
	    for ($ii=1; $ii<$nlen; $ii++) {
		@nnn = split /\#/, $neival[$ii];
                if ($nnn[2]-$adj <= 0) {
		    $yeanay[0]++;
		    $ct++;
		} else {
		    $yeanay[1]++;
		    $ct++;
		}
	    }
            if ($ct < 8) {
		$eval += 9;
	    } else {
		if ($ntest == 0) {
		    $rat = $yeanay[0] / $ct;
		} else {
		    $rat = $yeanay[1] / $ct;
		}
	    }
            if ($ct >= 8) {
                if ($rat < $nrat) {
		    $eval += 1;
		    substr($eval,0,1) = '1';
		    if ($precip{$j}{hour}) {
			push @neifail, $precip{$j}{neigh};
		    }
		} else {
		    if ($precip{$j}{hour}) {
			push @neipass, $precip{$j}{neigh};
		    }
		}
	    }
	} else {
	    if ($precip{$j}{hour}) {
		$eval += 9;
	    } else { 
		$eval += 8;
	    }
	}
	$precip{$j}{eval} = $eval . '_' . $eval[1];
    }
}

sub ck_neigh_sp {
    my ($nei,$nct,$nvals,$e,$nlen,$ntest,$ct,$ii,$rat);
    my (@nei,@neival,@yeanay,@nnn);
    my @neighbor = `ls -1 $ENV{DATA}/*hour.neigh`;
    @neighbor = reverse sort @neighbor;
    $neighbor[0] =~ /^\/[\w\/]*\/(\d*)\_.*/;
    $ftoday = $1;
    open(NEI,"$ENV{DATA}/${ftoday}_hour.neigh");
    while (<NEI>) {
	%quad = ();
	$nei = substr($_,0,length($_)-1);
	$nei =~ s/\://;
	@nei = split /\s+/, $nei;
	$nct = 0;
	if (!defined $precip{$nei[0]}{sum}) {
	    next;
	}
	$nvals = sprintf("%8.8s\#%5.2f ",$nei[0],$precip{$nei[0]}{sum});
        for ($e=1; $e<50; $e++) {
	    $nei[$e] =~ /(\w+)\[(\d\d\d\d)(\w\w\w)\]/;
	    @br = ($1,$2,$3);
	    if (!defined $br[0] || !defined $precip{$br[0]}{dsum}) {
		next;
	    }
	    if ($precip{$br[0]}{sum} >= 0 && substr($precip{$br[0]}{eval},0,1) eq '2' && $quad{$br[2]}<2) {
		$quad{$br[2]}++;
		$nvals .= sprintf("%8.8s\#%2.2s\_%4.4d\#%5.2f ",$br[0],$br[2],$br[1],$precip{$br[0]}{sum});
		$nct++;
                if ($nct == 8) {
		    last;
		}
	    }
	}
	if ($nct < 8) {
	    for ($e=1; $e<50; $e++) {
		$nei[$e] =~ /(\w+)\[(\d\d\d\d)(\w\w\w)\]/;
		@br = ($1,$2,$3);
		if (!defined $br[0] || !defined $precip{$br[0]}{dsum}) {
		    next;
		}
		if ($precip{$br[0]}{sum} >= 0 && substr($precip{$br[0]}{eval},0,1) eq '2' && $nvals !~ $br[0]) {
		    $nvals .= sprintf("%8.8s\#%2.2s\_%4.4d\#%5.2f ",$br[0],$br[2],$br[1],$precip{$br[0]}{sum});
		    $nct++;
		    if ($nct == 8) {
			last;
		    }
		}
	    }
	}
        $nvals =~ s/\# /\#0/g;
        $precip{$nei[0]}{neigh} = $nvals;
    }
    close NEI;
    foreach $j (sort keys %precip) {
	if (!$precip{$j}{eval} || !$precip{$j}{neigh}) {
	    next;
	}
	@eval = split /\_/, $precip{$j}{eval};
	$eval = $eval[0];
	@yeanay = (0,0);
	$ct = $rat = 0;
        if ($precip{$j}{neigh}) {
	    @neival = split /\s+/, $precip{$j}{neigh};
	    if ($neival[0] eq '') {
		$nul = shift @neival;
	    }
	    $nlen = @neival;
	    @nnn = split /\#/, $neival[0];
            if ($nnn[1]-$adj <= 0) {
		$ntest = 0;
	    } else {
		$ntest = 1;
	    }
	    for ($ii=1; $ii<$nlen; $ii++) {
		@nnn = split /\#/, $neival[$ii];
                if ($nnn[2]-$adj <= 0) {
		    $yeanay[0]++;
		    $ct++;
		} else {
		    $yeanay[1]++;
		    $ct++;
		}
	    }
            if ($ct < 8) {
		$eval += 9;
	    } else {
		if ($ntest == 0) {
		    $rat = $yeanay[0] / $ct;
		} else {
		    $rat = $yeanay[1] / $ct;
		}
	    }
            if ($ct >= 8) {
                if ($rat < $nrat) {
		    $eval += 1;
		    substr($eval,0,1) = '1';
		    if ($precip{$j}{hour}) {
			push @neifail, $precip{$j}{neigh};
		    }
		} else {
		    if ($precip{$j}{hour}) {
			push @neipass, $precip{$j}{neigh};
		    }
		}
	    }
	} else {
	    $eval += 9;
	}
	$precip{$j}{eval} = $eval . '_' . $eval[1];
    }
}

sub ck_dneigh {
    open(KL,">$ENV{DATA}/yoneigh.out");
    my ($nei,$nct,$nvals,$e,$nlen,$ntest,$ct,$ii,$rat);
    my (@nei,@neival,@yeanay,@nnn);
    $z = 0;
    $cct = 1;
    @stop = (0,0,0);
    @type = (0,0,0,0);
    while ($cct > 0 && $stop[0] != -1) {
        @valid = @usapass = @usafail = ();
	$z++;
        if ($z > 20) { $stop[0] = -1; }
        if ($debug && $z > 1) { print "cct=$cct\n"; }
	if ($z > 1) {
            $stop[2] = $stop[1];
            $stop[1] = $cct;
            if ($stop[1] == $stop[2]) {
                $stop[0] = -1;
            }
            $cct = 0;
	    foreach $p (sort keys %precip) {
		if ($z == 2) {
		    $precip{$p}{eusa} = $precip{$p}{temp};
		    delete $precip{$p}{temp};
		} elsif ($z > 2) {
                    if (defined $precip{$p}{temp}) {
			if ($precip{$p}{temp} != $precip{$p}{eusa}) {
			    $precip{$p}{swap}++;
			    $precip{$p}{eusa} = $precip{$p}{temp};
			}
		    }
		    delete $precip{$p}{temp};
		}
	    }
	}
        if ($debug && $z > 1) { 
	    print "Pass $z\n";
	    print "Good: zero:$type[0] nonz:$type[1]  Fail: zero:$type[2] nonz:$type[3]\n";
	}
        @type = (0,0,0,0);
	my @neighbor = `ls -1 $ENV{DATA}/*day.neigh`;
	@neighbor = reverse sort @neighbor;
	$neighbor[0] =~ /^\/[\w\/]*\/(\d*)\_.*/;
#yl     $ftoday = $1;
        my @elementsinstring = split (/\//, $neighbor[0]);
        my $nelements=scalar(@elementsinstring);
        my $NEIFILE=$elementsinstring[$nelements-1];
        open(NEI,"$ENV{DATA}/$NEIFILE");
#yl     open(NEI,"$ENV{DATA}/${ftoday}_day.neigh");
	while (<NEI>) {
	    $nei = substr($_,0,length($_)-1);
	    $nei =~ s/\://;
	    @nei = split /\s+/, $nei;
	    if (!defined $precip{$nei[0]}{dsum}) {
		next;
	    }
	    $nct = 0;
	    $nvals = sprintf("%8.8s\#%5.2f ",$nei[0],$precip{$nei[0]}{dsum});
            for ($e=1; $e<50; $e++) {
		$nei[$e] =~ /(\w+)\[(\d\d\d\d)(\w\w\w)\]/;
		@br = ($1,$2,$3);
                if (!defined $br[0] || !defined $precip{$br[0]}{dsum}) {
                    next;
                }
                if ($precip{$br[0]}{dsum} >= 0 && ($z == 1 || $precip{$br[0]}{eusa} != -1 && $z > 1)) {
		    $nvals .= sprintf("%8.8s\#%2.2s\_%4.4d\#%5.2f ",$br[0],$br[2],$br[1],$precip{$br[0]}{dsum});
		    $nct++;
                    if ($nct == 8) {
			last;
		    }
		}
	    }
	    $nvals =~ s/\# /\#0/g;
	    $precip{$nei[0]}{neigh} = $nvals;
	}
	close NEI;
	foreach $j (sort keys %precip) {
	    if (!$precip{$j}{eval}) {
		next;
	    }
	    @yeanay = (0,0);
	    $ct = $rat = 0;
	    if ($precip{$j}{neigh}) {
		@neival = split /\s+/, $precip{$j}{neigh};
		if ($neival[0] eq '') {
		    $nul = shift @neival;
		}
		$nlen = @neival;
		@nnn = split /\#/, $neival[0];
                if ($nnn[1]-$adj <= 0) {
		    $ntest = 0;
		} else {
		    $ntest = 1;
		}
		for ($ii=1; $ii<$nlen; $ii++) {
		    @nnn = split /\#/, $neival[$ii];
                    if ($nnn[2]-$adj <= 0) {
			$yeanay[0]++;
			$ct++;
		    } else {
			$yeanay[1]++;
			$ct++;
		    }
		}
                if ($ct >= 8) {
		    if ($ntest == 0) {
			$rat = $yeanay[0] / $ct;
		    } else {
			$rat = $yeanay[1] / $ct;
		    }
                    if ($rat >= $nrat) {
			push @valid, $j;
			push @usapass, $precip{$j}{neigh};
                        if ($precip{$j}{dsum} > 0) {
                            $type[1]++;
                        } else {
                            $type[0]++;
                        }

			if ($z>1 && (defined $precip{$j}{eusa} && $precip{$j}{eusa} != 0)) {
			    $cct++;
			}
			$precip{$j}{temp} = 0;
			substr($precip{$j}{eval},12,1) = 0;
		    } else {
			push @usafail, $precip{$j}{neigh};
                        if ($precip{$j}{dsum} > 0) {
                            $type[3]++;
                        } else {
                            $type[2]++;
                        }
			if ($z>1 && (defined $precip{$j}{eusa} && $precip{$j}{eusa} != -1)) {
			    $cct++;
			}
			$precip{$j}{temp} = -1;
			substr($precip{$j}{eval},12,1) = 1;
		    }
                } else {
                    push @valid, $j;
                    push @usapass, $precip{$j}{neigh};
		    if ($precip{$j}{dsum} > 0) {
			$type[1]++;
		    } else {
			$type[0]++;
		    }
		    substr($precip{$j}{eval},12,1) = 9;
                }
	    } else {
		if ($precip{$j}{day}) {
		    substr($precip{$j}{eval},12,1) = 9;
		} else {
		    substr($precip{$j}{eval},12,1) = 8;
		}
	    }
	    substr($precip{$j}{eval},0,1) = 2;
	    if (substr($precip{$j}{eval},1,1) == 2) {
		substr($precip{$j}{eval},0,1) = 1;
	    }
	    if (substr($precip{$j}{eval},2,1) != 0) {
		substr($precip{$j}{eval},0,1) = 1;
	    }
	    for ($b=3; $b<14; $b++) {
		if (substr($precip{$j}{eval},$b,1) == 1) {
		    substr($precip{$j}{eval},0,1) = 1;
		}
	    }
	    delete $precip{$j}{neigh};
	}
    }
    close KL;
}

sub ck_dneigh_sp {
    open(KL,">$ENV{DATA}/yoneigh.out");
    my ($nei,$nct,$nvals,$e,$nlen,$ntest,$ct,$ii,$rat);
    my (@nei,@neival,@yeanay,@nnn);
    $z = 0;
    $cct = 1;
    @stop = (0,0,0);
    @type = (0,0,0,0);
    while ($cct > 0 && $stop[0] != -1) {
        @valid = @usapass = @usafail = ();
	$z++;
        if ($debug) { print "cct=$cct\n"; }
	if ($z > 1) {
            $stop[2] = $stop[1];
            $stop[1] = $cct;
            if ($stop[1] == $stop[2]) {
                $stop[0] = -1;
            }
            $cct = 0;
	    foreach $p (sort keys %precip) {
		if ($z == 2) {
		    $precip{$p}{eusa} = $precip{$p}{temp};
		    delete $precip{$p}{temp};
		} elsif ($z > 2) {
                    if (defined $precip{$p}{temp}) {
			if ($precip{$p}{temp} != $precip{$p}{eusa}) {
			    $precip{$p}{swap}++;
			    $precip{$p}{eusa} = $precip{$p}{temp};
			}
		    }
		    delete $precip{$p}{temp};
		}
	    }
	}
        if ($debug) { 
	    print "Pass $z\n";
	    print "Good: zero:$type[0] nonz:$type[1]  Fail: zero:$type[2] nonz:$type[3]\n";
	}
        @type = (0,0,0,0);
	my @neighbor = `ls -1 $ENV{DATA}/*day.neigh`;
	@neighbor = reverse sort @neighbor;
	$neighbor[0] =~ /^\/[\w\/]*\/(\d*)\_.*/;
	$ftoday = $1;
        open(NEI,"$ENV{DATA}/${ftoday}_day.neigh");
	while (<NEI>) {
	    %quad = ();
	    $nei = substr($_,0,length($_)-1);
	    $nei =~ s/\://;
	    @nei = split /\s+/, $nei;
	    if (!defined $precip{$nei[0]}{dsum}) {
		next;
	    }
	    $nct = 0;
	    $nvals = sprintf("%8.8s\#%5.2f ",$nei[0],$precip{$nei[0]}{dsum});
            for ($e=1; $e<50; $e++) {
		$nei[$e] =~ /(\w+)\[(\d\d\d\d)(\w\w\w)\]/;
		@br = ($1,$2,$3);
                if (!defined $br[0] || !defined $precip{$br[0]}{dsum}) {
                    next;
                }
                if ($precip{$br[0]}{dsum} >= 0 && ($z == 1 || $precip{$br[0]}{eusa} != -1 && $z > 1) && $quad{$br[2]}<2) {
		    $quad{$br[2]}++;
		    $nvals .= sprintf("%8.8s\#%2.2s\_%4.4d\#%5.2f ",$br[0],$br[2],$br[1],$precip{$br[0]}{dsum});
		    $nct++;
                    if ($nct == 8) {
			last;
		    }
		}
	    }
	    if ($nct < 8) {
		for ($e=1; $e<50; $e++) {
		    $nei[$e] =~ /(\w+)\[(\d\d\d\d)(\w\w\w)\]/;
		    @br = ($1,$2,$3);
		    if (!defined $br[0] || !defined $precip{$br[0]}{dsum}) {
			next;
		    }
		    if ($precip{$br[0]}{dsum} >= 0 && ($z == 1 || $precip{$br[0]}{eusa} != -1 && $z > 1)) {
			$quad{$br[2]}++;
			$nvals .= sprintf("%8.8s\#%2.2s\_%4.4d\#%5.2f ",$br[0],$br[2],$br[1],$precip{$br[0]}{dsum});
			$nct++;
			if ($nct == 8) {
			    last;
			}
		    }
		}
	    }
	    $nvals =~ s/\# /\#0/g;
	    $precip{$nei[0]}{neigh} = $nvals;
	}
	close NEI;
	foreach $j (sort keys %precip) {
            if ($j =~ /CNNO1|LIVT2|LOZ|MRFO1|WSHT2/ && $precip{$j}{neigh} ne '') {
                print KL "$precip{$j}{neigh} pass$z\n";
            }
	    if (!$precip{$j}{eval}) {
		next;
	    }
	    @yeanay = (0,0);
	    $ct = $rat = 0;
	    if ($precip{$j}{neigh}) {
		@neival = split /\s+/, $precip{$j}{neigh};
		if ($neival[0] eq '') {
		    $nul = shift @neival;
		}
		$nlen = @neival;
		@nnn = split /\#/, $neival[0];
                if ($nnn[1]-$adj <= 0) {
		    $ntest = 0;
		} else {
		    $ntest = 1;
		}
		for ($ii=1; $ii<$nlen; $ii++) {
		    @nnn = split /\#/, $neival[$ii];
                    if ($nnn[2]-$adj <= 0) {
			$yeanay[0]++;
			$ct++;
		    } else {
			$yeanay[1]++;
			$ct++;
		    }
		}
                if ($ct >= 8) {
		    if ($ntest == 0) {
			$rat = $yeanay[0] / $ct;
		    } else {
			$rat = $yeanay[1] / $ct;
		    }
                    if ($rat >= $nrat) {
			push @valid, $j;
			push @usapass, $precip{$j}{neigh};
                        if ($precip{$j}{dsum} > 0) {
                            $type[1]++;
                        } else {
                            $type[0]++;
                        }

			if ($z>1 && (defined $precip{$j}{eusa} && $precip{$j}{eusa} != 0)) {
			    $cct++;
			}
			$precip{$j}{temp} = 0;
			substr($precip{$j}{eval},12,1) = 0;
		    } else {
			push @usafail, $precip{$j}{neigh};
                        if ($precip{$j}{dsum} > 0) {
                            $type[3]++;
                        } else {
                            $type[2]++;
                        }
			if ($z>1 && (defined $precip{$j}{eusa} && $precip{$j}{eusa} != -1)) {
			    $cct++;
			}
			$precip{$j}{temp} = -1;
			substr($precip{$j}{eval},12,1) = 1;
		    }
                } else {
                    push @valid, $j;
                    push @usapass, $precip{$j}{neigh};
		    if ($precip{$j}{dsum} > 0) {
			$type[1]++;
		    } else {
			$type[0]++;
		    }
		    substr($precip{$j}{eval},12,1) = 9;
                }
	    }
	    delete $precip{$j}{neigh};
	}
    }
    close KL;
}

sub loadclim {
    @cldate = ();
    %climate = ();

    $cldate[1] = substr($today,6,2) / 30;
    $cldate[0] = 1 - ($cldate[1]);
    $cldate[3] = substr($today,4,2);
    $cldate[2] = $cldate[3] - 1;
    if (!$cldate[2]) {
	$cldate[2] = 12;
    }
    open(CLI,"$ENV{FIXgauge}/gaugeqc_normals.dat");
    while (<CLI>) {
	$in = substr($_,0,length($_)-1);
	@in = split /\s+/, $in;
	@pcp = split /\|/,$in[3];
	$mo_precip = int(($cldate[0] * $pcp[$cldate[2]-1]) + ($cldate[1] * $pcp[$cldate[3]-1])+.5) / 100;
	$climate{$in[0]} = $mo_precip;
    }
    close CLI;
}

sub getstnlist {
    my ($id,@in,$in);
    my @nwsli = `ls -1 $ENV{COMOUT}/*.NWSLI`;
    @nwsli = reverse sort @nwsli;
    foreach $rt (@nwsli) {
	my $fty = `ls -lsa $rt`;
	my @fty = split /\s/,$fty;
	if ($fty[0] != 0) {
	    $nwsli = substr($nwsli[0],0,length($nwsli[0])-1);
	    last;
	}
    }
    open(INP,"$nwsli");

    while (<INP>) {
	$in = substr($_,0,length($_)-1);
	@in = split /\s+/, $in;
	if ($in[0] eq '') {
	    shift @in;
	}
        $id = $in[1];
	$id =~ s/\s//g;
	$nwsli{ $id } = 1;
	$precip{$id}{nwsli} = 1;
	$precip{$id}{daymax} = '99999999';
	$precip{$id}{mosum} = 0;
	$precip{$id}{anomclim} = ' -999';
    }
    close INP;

    open(INP,"$ENV{COMOUT}/all_dcp_defs.txt");

    while (<INP>) {
	$in = substr($_,0,length($_)-1);
	@in = split /\|/, $in;
	if ($in[0] eq '') {
	    shift @in;
	}
	$id = $in[1];
	$id =~ s/\s//g;
	$precip{$id}{dcp} = 1;
	if (!$nwsli{ $id }) {
	    $nwsli{ $id } = 1;
	    $precip{$id}{daymax} = '99999999';
	    $precip{$id}{mosum} = 0;
	    $precip{$id}{anomclim} = ' -999';
	}
    }
    close INP;

    open(INP,"$ENV{FIXgauge}/gaugeqc_correlate.dat");
    while (<INP>) {
	$in = substr($_,0,length($_)-1);
	@in = split /\s+/, $in;
	if ($precip{$in[0]}) {
	    if ($in[6] <= 50) {
		$precip{$in[0]}{climo} = $climate{$in[1]};
	    } else {
		$precip{$in[0]}{climo} = 0;
	    }
	}
    }
    close INP;
}

sub eval {
    foreach $j (sort keys %precip) {
	$eval = $fail = 0;
	if (!$precip{$j}{current}) {
	    next;
	}
	if ($precip{$j}{dayct} > 0) {
	    $precip{$j}{msgmn} = $precip{$j}{miss} / $precip{$j}{dayct};
	} else {
	    $precip{$j}{msgmn} = -999;
	}
# station location
	if (!$precip{$j}{src}) {
	    $eval += 1000000000000;
	} elsif ($precip{$j}{src} eq 'MSG') {
	    $eval += 2000000000000;
	    $fail += 1;
	} elsif ($precip{$j}{src} eq 'SRC') {
	    $eval += 3000000000000;
	}
# daily report count
# bad observation time (usa file)
        if ($precip{$j}{badobt}) {
           $eval += 200000000000;
           $fail += 1;
	} elsif ($precip{$j}{dayct} < $dayct) { 
	    $eval += 100000000000;
	    $fail += 1;
	}
# anomalous hourly observation
	if ($precip{$j}{current}[4]) {
	    $eval += 10000000000;
	    $fail += 1;
	}
# consecutive hrly obs 3" or greater
	if ($precip{$j}{current}[7]) {
	    $eval += 1000000000;
	    $fail += 1;
	}
# anomalous daily sum
	if ($precip{$j}{current}[5]) {
	    $eval += 100000000;
	    $fail += 1;
	}
# excessive count, days with sum over 5"
	if ($precip{$j}{dayg5} >= 2) {
	    $eval += 10000000;
	    $fail += 1;
	}
# anomalous (high) monthly sum
	if ($files >= 28 && $precip{$j}{mosum} >= 10) {
	    $eval += 0000000;
	    $fail += 0;
	}
# extreme monthly sum wrt climatology
	if ($precip{$j}{anomclim} >= 2 && $precip{$j}{climo} >= 3) {
	    $eval += 000000;
	    $fail += 0;
	}
# missing obs (current day)
	if ($precip{$j}{hour}) {
	    if ($precip{$j}{msgmn} > 2) {
		if ($precip{$j}{current}[2] >= 4) {
		    $eval += 10000;
		    $fail += 1;
		}
	    } elsif ($precip{$j}{msgmn} != -999) {
		if ($precip{$j}{current}[2] >= 5) {
		    $eval += 10000;
		    $fail += 1;
		}
	    }
	}
# missing obs (30 day)
	if ($files >= 28 && $precip{$j}{miss} >= $monms && $precip{$j}{miss} != 99) {
	    $eval += 0000;
	    $fail += 0;
	}
# stuck gage (1) - Repeated value
	if ($precip{$j}{current}[6]) {
	    $eval += 100;
	    $fail += 1;
	}
# set evaluation variable
	if ($fail) {
	    $eval += 10000000000000;
	} else {
	    $eval += 20000000000000;
	}
	$precip{$j}{eval} = $eval;
    }
}

sub setid {
    if ($nwsli{$_[0]}) {
	$id = $_[0];
	$valid = 1;
    } elsif ($_[1] != 99.00000) {
	$id = $_[0];
	$valid = 2;
    } else {
	$id = $_[0];
	$valid = 0;
    }
    return ($id,$valid);
}

sub procob {
    @obs = ();
    if ($in =~ /U24Z99/) {
	$precip{$id}{sum} = $_[1]/100;
        $precip{$id}{dsum} = $precip{$id}{sum};
	$precip{$id}{mosum} += ($_[1]/100);
	if (!$precip{$id}{hour}) {
	    if ($_[1] > 0) {
		$precip{$id}{dayg1}++;
# save date (non-zero value)
		$precip{$id}{recnon} = $_[0];
	    } else {
# save date (zero value)
		$precip{$id}{reczer} = $_[0];
	    }
	}
	$precip{$id}{obs} = -1;
    } else {
	if ($count) {
	    my $flag = 0;
# for each hour, decode observation
	    for ($i=0;$i<24;$i++) {
		$j = $i*4+30;
		$dec = substr($in,$j,4);
		$amt = $dec / 100;
		$hr = ($i+12) - ((int($i/12))*24);
		$shr = "h" . sprintf("%2.2d",$hr);
		push @obs, $dec;
# nonzero observation
		if ($amt > 0.00 && $amt != 99.99) {
# check for new maximum value
		    if ($amt > $precip{$id}{max}) {
			$precip{$id}{max} = $amt;
			$precip{$id}{daymax} = $_[0];
		    }
# check for anomalous precipitation amount; save record if criteria exceeded
		    if ($amt >= $anomhr && !$flag) {
			$amt = sprintf("%5.2f",$amt);
			push @anomhr, "$in $amt $_[0]";
			$precip{$id}{anomhr}++;
			if ($_[0] eq $today) {
			    $current[4] = 1;
			}
			if ($anomhrlist !~ $id) {
			    $anomhrlist .= "${id}|";
			    push @anomhrsta, $id;
			}
			$flag++;
		    }
# bin observation
		    if ($amt <= 0.05) {
			$samt = "a$dec";
		    } elsif ($amt > 0.05 && $amt < 0.1) {
			$samt = "a0009";
		    } elsif ($amt >= 0.1 && $amt < 0.2) {
			$samt = "a0010";
		    } elsif ($amt >= 0.2 && $amt < 0.3) {
			$samt = "a0020";
		    } elsif ($amt >= 0.3 && $amt < 0.4) {
			$samt = "a0030";
		    } elsif ($amt >= 0.4 && $amt < 0.5) {
			$samt = "a0040";
		    } elsif ($amt >= 0.5 && $amt < 1) {
			$samt = "a0050";
		    } elsif ($amt >= 1 && $amt < 2) {
			$samt = "a0100";
		    } elsif ($amt >= 2 && $amt < 3) {
			$samt = "a0200";
		    } elsif ($amt >= 3) {
			$samt = "a0300";
		    }
# increment obs count for hour
		    $precip{$id}{$shr}++;
# increment count for amount bin
		    $precip{$id}{$samt}++;
# add amount to day/month sums
		    $precip{$id}{sum} += $amt;
		    $precip{$id}{mosum} += $amt;
# increment non-zero precip hour count
		    $precip{$id}{hours}++;
# compute components useful for statistical computation
		    $precip{$id}{x2} += ($amt*$amt);
		    $precip{$id}{x4} += ($amt**4);
# increment zero ob count
		} elsif ($amt == 0) {
		    $precip{$id}{a0000}++;
		    $precip{$id}{sum} += 0;
		} else {
# increment missing ob count
		    $precip{$id}{miss}++;
		    $precip{$id}{recmis} = $_[0];
		}
	    }
	} else {
# add 24 (zero hours) to zero count
	    $precip{$id}{a0000} += 24;
	    $precip{$id}{sum} = 0;
# save date
	}
	if ($precip{$id}{sum} == 0) {
	    $precip{$id}{reczer} = $_[0];
	} else {
# increment count of days with 1+ hours of nonzero precipitation
	    $precip{$id}{dayg1}++;
	    $precip{$id}{recnon} = $_[0];
	}
    }
# compute number of obs for day (nonzero, zero, missing)
    if ($precip{$id}{obs} && $precip{$id}{obs} != -1) {
	$precip{$id}{obs} = substr($in,132,2) + substr($in,135,2) + substr($in,138,2);
    }
# check for repetitive values
	$yes = 0;
    $stuck = 1;
    $chk = '0000|';
    @stuckhr = @consec = ();
    for ($i=0; $i<24; $i++) {
	if ($yes) {
	    last;
	}
	if (defined $obs[0] && $chk !~ $obs[$i] && $obs[$i] != 9999) {
	    $chk .= "$obs[$i]|";
	    $stuck = 1;
	    @stuckhr = ();
	    push @stuckhr, $i;
	    for ($k=$i+1; $k<24; $k++) {
		if ($obs[$i] eq $obs[$k]) {
		    $stuck++;
		    push @stuckhr, $k;
		}
	    }
	    if ($stuck >=3) {
		$stucklen = @stuckhr;
		@diff = ();
		$consec = 0;
		for ($m=0; $m<=($stucklen-2); $m++) {
		    $diff = $stuckhr[$m+1] - $stuckhr[$m];
		    $diff[$diff]++;
		    if ($diff == 1) {
			$consec++;
		    } else {
			if ($consec) {
			    push @consec, $consec;
			}
			$consec = 0;
		    }
		}
		if ($consec) {
		    push @consec, $consec;
		}
#		print "Obs: $i $obs[$i]\n";
		if ($obs[$i] < 20) {
		    if ($diff[1] > 8) {
			foreach $zh (@consec) {
			    if ($zh > 8) {
				$yes = 1;
			    }
			}
		    }
		} else {
		    if ($diff[1] > 3) {
			foreach $zh (@consec) {
			    if ($zh > 3) {
				$yes = 1;
			    }
			}
		    }
		}
		for ($n=2; $n<24; $n++) {
		    if ($obs[$i] >= 20) {
			if ($diff[$n] > 3) {
			    $yes = 1;
			}
		    }
		}
	    }
	}
    }
    if ($yes) {
	push @stuck, "$in $_[0]";
	$precip{$id}{recstu} = $_[0];
	$precip{$id}{stuck}++;
	if ($_[0] eq $today) {
	    $current[6] = 1;
	}
	if ($stucklist !~ $id) {
	    $stucklist .= "${id}|";
	    push @stucksta, $id;
	}
    }
# check for consecutive >= 2.00 inches
    for ($i=0; $i<23; $i++) {
	if ($obs[$i] != 9999 && $obs[$i+1] != 9999 &&
	    $obs[$i] >= 300 && $obs[$i+1] >= 300) {
	    $precip{$id}{hrg3}++;
	    if ($_[0] eq $today) {
		$current[7] = 1;
	    }
	    last;
	}
    }

    if ($precip{$id}{sum} > $anomdy) {
	$precip{$id}{sum} = sprintf("%6.2f",$precip{$id}{sum});
	push @anomdy, "$in $precip{$id}{sum} $_[0]";
	$precip{$id}{anomdy}++;
	if ($anomdylist !~ $id) {
	    $anomdylist .= "${id}|";
	    push @anomdysta, $id;
	}
	if ($_[0] eq $today) {
	    $current[5] = 1;
	}
    }
    if ($precip{$id}{sum} >= 5) {
	$precip{$id}{dayg5}++;
    }
    $dec = substr($in,127,4);
    $value = $dec / 100;
    $count = substr($in,132,2);
    if ($precip{$id}{climo}) {
	$ratio = $precip{$id}{mosum} / $precip{$id}{climo};
	if ($ratio >= 10) {
	    $precip{$id}{anomclim} = 9.999;
	} else {
	    $precip{$id}{anomclim} = sprintf("%5.3f",$ratio);
	}
    } else {
	$precip{$id}{anomclim} = ' -999';
    }
}

sub readrec {
    foreach $i (@files) {
	$dx = substr($i,4,4);
	$dy = substr($i,0,8);
	foreach $k (sort keys %precip) {
	    $precip{$k}{sum} = $precip{$k}{dsum} = undef;
	}
	if ($debug) { print "$dy\n"; }
        open(INP,"$ENV{DATA}/$i") || die "cannot find file ${i}\n";
	while (<INP>) {
	    $in = substr($_,0,length($_)-1);
	    if ($in !~ /U24Z99M99/) {
		$in =~ s/U24Z99/U24Z99M99/;
	    }
	    @in = split /\s+/, $in;
	    if ($in[0] eq '') {
		shift @in;
	    }
	    $id8 = $in[0];
	    $id8 =~ s/\s//g;
	    ($id,$valid) = &setid($id8,$in[1]);
	    if (!$precip{$id}{src}) {
		$precip{$id}{src} = 0;
	    }
	    if (!$valid) {
		$found = 0;
		foreach $k (@notvalid) {
		    if ($k eq $id) {
			$found = 1;
		    }
		}
		if (! $found) {
		    push @notvalid, $id;
		}
		$precip{$id}{src} = 'MSG';
	    } elsif ($valid == 2) {
		$precip{$id}{src} = 'SRC';
	    }
	    if ($dy eq $today) {
		@current = ();
		$tsum = substr($in,127,4) / 100;
		$tcnt = substr($in,132,2);
		$tzer = substr($in,135,2);
		if ($tzer == 99) {
		    $tzer = 0;
		}
		$tmsg = substr($in,138,2);
		if ($tmsg == 99) {
		    $tmsg = 0;
		}
		if ($in !~ /U24Z/) {
		    push @current, ($tsum,$tcnt,$tmsg,$tzer);
		} else {
		    push @current, ($tsum,99,99,99);
		}
	    }
# initialize max value
	    if (! $precip{$id}{max}) {
		$precip{$id}{max} = '0.00';
		$precip{$id}{daymax} = '99999999';
	    }
# skip daily record if hourly record available
	    if ($precip{$id}{date} && $precip{$id}{date} eq $dy) {
		if ($precip{$id}{date} eq $today) {
		    $precip{$id}{dsum} = substr($in,127,4) / 100;
		}
		next;
# use daily record
	    } elsif ($in =~ /.U24Z99/) {
		$count = 24;
		$dsum = substr($in,127,4);
		$precip{$id}{dsum} = substr($in,127,4) / 100;
		$precip{$id}{date} = $dy;
# decode number of nonzero hourly entries
	    } else {
		$count = substr($in,132,2);
		$dsum = substr($in,127,4);
#		$precip{$id}{sum} = substr($in,127,4) / 100;
		$precip{$id}{date} = $dy;
	    }
# increment observation count
	    $precip{$id}{dayct}++;
	    &procob($dy,$dsum);
	    if ($dy eq $today) {
		$precip{$id}{current} = [ @current ];
	    }
	}
	close INP;
    }
    open(USF,"${today}.badobt");
    while (<USF>) {
	$inf = $_;
	@inf = split /\s+/, $inf;
	if (! $inf[0]) {
	    shift @inf;
	}
	$id = $inf[3];
	$precip{$id}{badobt} = 1;
    }
    close USF;
    foreach $j (@eval) {
	open(EAX,"$j");
	$nul = <EAX>;
	while (<EAX>) {
	    $in = substr($_,0,length($_)-1);
	    @in = split /\s+/, $in;
	    if (! $in[0]) {
		$nul = shift @in;
	    }
	    if (substr($in[1],2,1) == 1 || substr($in[1],9,1) == 1 || substr($in[1],10,1) == 1) {
		$precip{$in[0]}{insuf}++;
		$precip{$in[0]}{failct}++;
	    }
	    if (substr($in[1],3,1) == 1 || substr($in[1],4,1) == 1) {
		$precip{$in[0]}{failhr}++;
		$precip{$in[0]}{failct}++;
	    }
	    if (substr($in[1],5,1) == 1 || substr($in[1],6,1) == 1) {
		$precip{$in[0]}{faildy}++;
		$precip{$in[0]}{failct}++;
	    }
	    if (substr($in[1],7,1) == 1 || substr($in[1],8,1) == 1) {
		$precip{$in[0]}{failmo}++;
		$precip{$in[0]}{failct}++;
	    }
	    if (substr($in[1],11,1) == 1) {
		$precip{$in[0]}{failgage}++;
		$precip{$in[0]}{failct}++;
	    }
	    if (substr($in[1],12,1) == 1 || substr($in[1],13,1) == 1) {
		$precip{$in[0]}{failneigh}++;
		$precip{$in[0]}{failct}++;
	    }
	}
	close EAX;
    }
}

sub cleanup {
    close OUT;
    close ANL;
    close FTN;
    close MFV;
}

sub descstat {
    if ($precip{$j}{hours}) {
	$precip{$j}{kurt} = $precip{$j}{sek} = '0.00';
	$precip{$j}{skew} = $precip{$j}{ses} = '0.00';
	$precip{$j}{mean} = $precip{$j}{sum} / $precip{$j}{hours};
	if ($precip{$j}{hours}>1) {
	    $poss = (($precip{$j}{hours} * $precip{$j}{x2}) - $precip{$j}{sum}**2) / ($precip{$j}{hours}*
		    ($precip{$j}{hours}-1));
	    if (abs($poss) < .00001) {
		$poss = 0;
	    } else {
		$precip{$j}{sdev} = sqrt($poss);
	    }
#		if ($precip{$j}{sdev} != 0) {
	    $precip{$j}{kurt} = $precip{$j}{x4} / ($precip{$j}{hours}*($precip{$j}{sdev})**4);
	    $precip{$j}{sek} = 2 * sqrt(24 / $precip{$j}{hours});
	    $precip{$j}{kurt} = sprintf("%6.2f",$precip{$j}{kurt});
	    $precip{$j}{sek} = sprintf("%6.2f",$precip{$j}{sek});
	    $precip{$j}{skew} = $precip{$j}{x3} / ($precip{$j}{hours}*($precip{$j}{sdev})**3);
	    $precip{$j}{ses} = 2 * sqrt(6 / $precip{$j}{hours});
	    $precip{$j}{skew} = sprintf("%6.2f",$precip{$j}{skew});
	    $precip{$j}{ses} = sprintf("%6.2f",$precip{$j}{ses});
	}
    }
}

sub writefile {
    my %data;
    my (@disp,@src);
    my ($DYhr,$DY,$hr,$count,$flag);

# save list of stations which did not report at all
    foreach $k (keys %nwsli) {
	if (!$precip{$k}{dayct}) {
	    push @norep, $k;
	}
    }
    open(OUT,">$ENV{DATA}/${today}.proc");
    open(ANL,">$ENV{DATA}/${today}.anl");
    open(MFV,">$ENV{DATA}/${today}.mfv");
    open(BDH,">$ENV{DATA}/${today}.evalH");
    open(BDA,">$ENV{DATA}/${today}.eval");
    open(BDU,">$ENV{DATA}/${today}.evalU");
    print BDH "${today}.evalH\n";
    print BDA "${today}.eval\n";
    print BDU "${today}.evalU\n";
    open(GDA,">$ENV{DATA}/${today}.good");
    open(GDH,">$ENV{DATA}/${today}.goodH");
    open(GDU,">$ENV{DATA}/${today}.goodU");
    print GDH "${today}.goodH\n";
    print GDA "${today}.good\n";
    print GDU "${today}.goodU\n";
# generate header
    foreach $k (@params) {
	$out .= $k;
	$outf .= $k;
	if ($k ne 'mosum') {
	    $out .= ',';
	    $outf .= ' ';
	}
    }
    print OUT "$out\n";
    $out = $outf = $evx = '';
    $cou = 0;
# loop through alphabetical list of stations
    foreach $j (sort keys %precip) {
	$cou++;
# format output fields
	$precip{$j}{daymax} = sprintf("%8.8d",$precip{$j}{daymax});
	$out = $outf = sprintf("%8.8s,",$j);
	$evx = sprintf("%8.8s ",$j);
	if ($precip{$j}{eval} !~ '_') {
	    $precip{$j}{eval} .= '_999999999999';
	}
	if ($precip{$j}{mosum}) {
	    $precip{$j}{mosum} = sprintf("%5.2f",$precip{$j}{mosum});
	} else {
	    $precip{$j}{mosum} = ' 0.00';
	}
	$precip{$j}{max} = sprintf("%5.2f",$precip{$j}{max});
# compute descriptive statistics
	if ($dstat) {
	    &descstat;
	}
# construct output record (comma delimited)
	foreach $i (@params) {
	    if ($precip{$j}{$i}) {
		$out .= "$precip{$j}{$i}";
	    } else {
		$out .= "0";
	    }
	    if ($i ne 'mosum') {
		$out .= ",";
	    }
	}
	foreach $k (@eparams) {
	    if ($k =~ /rec/) {
		if ($precip{$j}{$k}) {
		    $precip{$j}{$k} = sprintf("%8.8s",$precip{$j}{$k});
		} else {
		    $precip{$j}{$k} = '99999999';
		}
	    } else {
		if ($precip{$j}{$k}) {
		    $precip{$j}{$k} = sprintf("%3.3d",$precip{$j}{$k});
		} else {
		    $precip{$j}{$k} = '000';
		}
	    }
	    $evx .= "$precip{$j}{$k} ";
	}
	if ($precip{$j}{climo}) {
	    $evx .= "$precip{$j}{anomclim} ";
	} else {
	    $evx .= " -999 ";
	}
	if ($precip{$j}{hrg3}) {
	    $evx .= "YES ";
	} else {
	    $evx .= " NO ";
	}
	if ($precip{$j}{dayg5}) {
	    $evx .= "YES ";
	} else {
	    $evx .= " NO ";
	}
	if ($precip{$j}{src}) {
	    $evx .= "$precip{$j}{src}";
	}
	print MFV "$evx\n";
	if ($precip{$j}{dayct} == 0) {
	    next;
	} elsif ($precip{$j}{dayct} == 1 && $precip{$j}{mosum} == 0) {
	    push @oneob, $j;
	} else {
	    print OUT "$out\n";
	}
	if (substr($precip{$j}{eval},0,1) == 1) {
	    printf BDA ("%8.8s %27s\n",$j,$precip{$j}{eval});
	    if ($precip{$j}{hour}) {
		printf BDH ("%8.8s %6.2f %7.2f %27s\n",$j,$precip{$j}{lat},$precip{$j}{lon},$precip{$j}{eval});
	    }
	    if ($precip{$j}{day}) {
		printf BDU ("%8.8s %6.2f %7.2f %27s\n",$j,$precip{$j}{lat},$precip{$j}{lon},$precip{$j}{eval});
	    }
	} elsif (substr($precip{$j}{eval},0,1) == 2) {
		printf GDA ("%8.8s %27s\n",$j,$precip{$j}{eval});
	    if ($precip{$j}{hour}) {
		printf GDH ("%8.8s %6.2f %7.2f %27s\n",$j,$precip{$j}{lat},$precip{$j}{lon},$precip{$j}{eval});
	    }
	    if ($precip{$j}{day}) {
		printf GDU ("%8.8s %6.2f %7.2f %27s\n",$j,$precip{$j}{lat},$precip{$j}{lon},$precip{$j}{eval});
	    }
	    push @good, $j;
	}
    }
    close BDA; close BDH; close BDU; close GDA; close GDH; close GDU;
    open(FTN,">$ENV{DATA}/${today}.procf");
    $outf = 'id ';
# generate header
    foreach $k (@params) {
	$outf .= $k;
	if ($k ne 'mosum') {
	    $outf .= ' ';
	}
    }
    print FTN "$outf\n";
    $outf = '';
# loop through alphabetical list of stations
    foreach $j (sort keys %precip) {
	if ($precip{$j}{dayct} == 0) {
	    next;
	}
# format output fields
	$precip{$j}{daymax} = sprintf("%4.4d",$precip{$j}{daymax});
	$outf = sprintf("%8.8s ",$j);
	if ($precip{$j}{mosum}) {
	    $precip{$j}{mosum} = sprintf("%5.2f",$precip{$j}{mosum});
	} else {
	    $precip{$j}{mosum} = ' 0.00';
	}
	$precip{$j}{max} = sprintf("%5.2f",$precip{$j}{max});
# construct output record (column)
	foreach $i (@params) {
	    if ($i !~ /max/ && $i !~ /mosum/) {
		if ($precip{$j}{$i}) {
		    $outf .= sprintf("%3.3s",$precip{$j}{$i});
		} else {
		    $outf .= "  0";
		}
	    } elsif ($i =~ /daymax/) {
		if ($precip{$j}{$i}) {
		    $outf .= sprintf("%4.4d",$precip{$j}{$i});
		} else {
		    $outf .= "9999";
		}
	    } else {
		if ($precip{$j}{$i}) {
		    $outf .= sprintf("%5.2f",$precip{$j}{$i});
		} else {
		    $outf .= " 0.00";
		}
	    }
	    if ($i ne 'mosum') {
		$outf .= " ";
	    }
	}
	if ($precip{$j}{dayct} == 0) {
	    next;
	} else {
	    print FTN "$outf\n";
	}
    }
    close FTN;
    $mfv = @notvalid;
    print ANL "\nStations in data file not found in NWSLI/DCP lists ($mfv):\n\n";
    $ct = 0;
    $rec = '0';
    foreach $i (sort @notvalid) {
	if ($i ne $rec) {
	    $ct++;
	    if ($ct % 10 == 0) {
		printf ANL ("%8.8s\n",$i);
	    } else {
		printf ANL ("%8.8s",$i);
	    }
	    $rec = $i;
	}
    }
    print ANL "\n";

    $mfv = @norep;
#    print ANL "\nStations which did not report during past 30 days ($mfv):\n\n";
    $ct = 0;
#    foreach $i (sort @norep) {
#	$ct++;
#	if ($ct % 10 == 0) {
#	    printf ANL ("%8.8s\n",$i);
#	} else {
#	    printf ANL ("%8.8s",$i);
#	}
#    }
#    print ANL "\n";
    $mfv = @oneob;
    print ANL "\nStations reporting only once (zero precip) during past 30 days ($mfv):\n\n";
    $ct = 0;
    foreach $i (sort @oneob) {
	$ct++;
	if ($ct % 10 == 0) {
	    printf ANL ("%8.8s\n",$i);
	} else {
	    printf ANL ("%8.8s",$i);
	}
    }
    print ANL "\n";
    $mfv = @anomhr;
    $mfvz = @anomhrsta;
    print ANL "\nStations reporting anomalously high hourly observations during past 30 days (sta=$mfvz rec=$mfv):\n\n";
    foreach $i (sort @anomhr) {
	print ANL "$i\n";
    }
    print ANL "\n";
    $mfv = @anomdy;
    $mfvz = @anomdysta;
    print ANL "\nStations reporting anomalously high daily sums during past 30 days (sta=$mfvz rec=$mfv):\n\n";
    foreach $i (sort @anomdy) {
	print ANL "$i\n";
    }
    print ANL "\n";
    $mfv = @stucksta;
    $mfvz = @stuck;
    print ANL "\nStations with potentially stuck gauges (sta=$mfv rec=$mfvz):\n\n";
    foreach $i (sort @stuck) {
	print ANL "$i\n";
    }
    print ANL "\n";
    $mfv = @neifail;
    print ANL "\nStations which failed neighbor check (rec=$mfv):\n\n";
    foreach $i (sort @neifail) {
	print ANL "$i\n";
    }
    print ANL "\n";
    $mfv = @neipass;
    print ANL "\nStations which passed neighbor check (rec=$mfv):\n\n";
    foreach $i (sort @neipass) {
	print ANL "$i\n";
    }
    print ANL "\n";
    $mfv = @noneigh;
    print ANL "\nStations with insufficient number of valid neighbors (rec=$mfv):\n\n";
    foreach $i (sort @noneigh) {
	print ANL "$i\n";
    }
    print ANL "\n";
    $mfv = @usafail;
    print ANL "\n\*Daily\* stations which failed neighbor check (rec=$mfv):\n\n";
    foreach $i (sort @usafail) {
	print ANL "$i\n";
    }
    print ANL "\n";
    $mfv = @usapass;
    print ANL "\n\*Daily\* stations which passed neighbor check (rec=$mfv):\n\n";
    foreach $i (sort @usapass) {
	print ANL "$i\n";
    }
    print ANL "\n";
    print ANL "\n\*Daily\* stations which changed status:\n\n";
    foreach $i (sort keys %precip) {
	if ($precip{$i}{swap} > 1) {
	    printf ANL ("%8.8s Changed %2.2d times\n",$i,$precip{$i}{swap});
	}
    }
    close ANL;

# write station disposition file

    %data = @disp = ();
    @src = qw(goodH goodU failH failU);
    $DYhr = $DY = $hr = $count = 0;

    open(DIS,">$ENV{DATA}/${today}.disp");
    open(INP,"$ENV{DATA}/${today}.precip");
    while (<INP>) {
	$in = substr($_,0,length($_)-1);
	@in = split /\s+/,$in;
	if ($in[0] eq '') {
	    $nul = shift @in;
	}
	$data{$in[0]}{mfv} = 1;
	if ($in =~ /U24Z99/) {
	    $data{$in[0]}{day} = 1;
	} else {
	    $data{$in[0]}{hour} = 1;
	}
	$count++;
    }
    close INP;
    open(INP,"$ENV{DATA}/${today}.goodH");
    $nul = <INP>;
    while (<INP>) {
	$in = substr($_,0,length($_)-1);
	@in = split /\s+/,$in;
	if ($in[0] eq '') {
	    $nul = shift @in;
	}
	$data{$in[0]}{goodH} = 1;
	$data{$in[0]}{code} = $in[3];
	$disp[0]++;
    }
    close INP;
    open(INP,"$ENV{DATA}/${today}.evalH");
    $nul = <INP>;
    while (<INP>) {
	$in = substr($_,0,length($_)-1);
	@in = split /\s+/,$in;
	if ($in[0] eq '') {
	    $nul = shift @in;
	}
	$data{$in[0]}{failH} = 1;
	$data{$in[0]}{code} = $in[3];
	$disp[1]++;
    }
    open(INP,"$ENV{DATA}/${today}.goodU");
    $nul = <INP>;
    while (<INP>) {
	$in = substr($_,0,length($_)-1);
	@in = split /\s+/,$in;
	if ($in[0] eq '') {
	    $nul = shift @in;
	}
	$data{$in[0]}{goodU} = 1;
	$data{$in[0]}{code} = $in[3];
	$disp[2]++;
    }
    close INP;
    open(INP,"$ENV{DATA}/${today}.evalU");
    $nul = <INP>;
    while (<INP>) {
	$in = substr($_,0,length($_)-1);
	@in = split /\s+/,$in;
	if ($in[0] eq '') {
	    $nul = shift @in;
	}
	$data{$in[0]}{failU} .= 1;
	$data{$in[0]}{code} = $in[3];
	$disp[3]++;
    }
    
    foreach $i (sort keys %data) {
	if ($data{$i}{day} && $data{$i}{hour}) {
	    $DYhr++;
	} elsif ($data{$i}{day}) {
	    $DY++;
	} elsif ($data{$i}{hour}) {
	    $hr++;
	}
    }
    print DIS "${today}.disp\n";
    print DIS "Records = $count   DYhr = $DYhr   DY = $DY   hr = $hr\n";
    print DIS "goodH = $disp[0]   failH = $disp[1]   goodU = $disp[2]   failU = $disp[3]\n\n";
    foreach $i (sort keys %data) {
	if ($data{$i}{day} && $data{$i}{hour}) {
	    $out = "DYhr ";
	} elsif ($data{$i}{day}) {
	    $out = "DY   ";
	} elsif ($data{$i}{hour}) {
	    $out = "  hr ";
	}
	$out .= sprintf("%8s ",$i);
	$flag = 0;
	foreach $j (@src) {
	    if ($data{$i}{$j}) {
		$out .= "$j ";
		$flag = 1;
	    } else {
		$out .= '      ';
	    }
	}
	if (($out =~ /goodH/ && $out =~ /failH/) || ($out =~ /goodU/ && $out =~ /failU/)) {
	    $out .= ' *** Error ***';
	}
	if (!$flag) {
	    $out = '************************';
	}
	$out .= " $data{$i}{code}";
	print DIS "$out\n";
    }
    close DIS;
}

