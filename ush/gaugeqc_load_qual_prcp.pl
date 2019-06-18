#!/usr/bin/perl
#############################################
# Script to create input files of Gauge QC Processing
#############################################

$in_shef="rfc24.input";

#############################################
# Get Lat/Lon of Each Station
#############################################
$DICTgauge=$ENV{'DICTgauge'};
$shef_table="$DICTgauge/shef.tbl";

%lat=();
%lon=();
open(SHF,$shef_table);
while (<SHF>)
{
     chop;
     $id=substr($_,0,16);
#     $id=substr($_,0,10);
     $id=~s/\s+//g;

     $lt=substr($_,56,4);
#     $lt=substr($_,10,5);
     $lt=~s/\s+//g;
     $lt=$lt/100;

     $ln=substr($_,61,6);
#     $ln=substr($_,16,6);
     $ln=~s/\s+//g;
     $ln=$ln/-100;

     $lat{$id}=$lt;
     $lon{$id}=$ln;
}
close SHF;

#################################################
# Initialize variables
#################################################
($s,$m,$h,$mm,$mn, $curyr,$w,$yd,$isd) = gmtime(time);  # get system time
$curyr +=1900 ;           # number of years since 1900, hope 100 for yr 2000
$numrec = 0 ;             # initialize counters for records processed
$duprec = 0 ;
$updrec = 0 ;

%array = ();
%amount = ();

open(SHEF,$in_shef);
while (<SHEF>)
{ 
    chop;

    #################################################
    # Increment count to track how many reports read
    #################################################
    $numrec++ ;

    #################################################
    # Read one line of input file
    #################################################
#yl    ($id,$yr,$mn,$dy,$hr,$mi,$p1,$p2,$dur,$tc,$sc,$ec,$j1,$val,$qual,$rv,$org) = split(" ",$_);
    ($yr,$mn,$dy,$hr,$mi,$id,$p1,$p2,$dur,$tc,$sc,$ec,$j1,$val,$qual,$rv,$org) = split(" ",$_);

    #################################################
    # Create Obs date in form yyyymmdd 
    # Create Obs time in form hhmm
    #################################################
    if ($yr > $curyr)
    {
         $yr = $curyr;
    }
    $obsdate = ($yr*10000) + ($mn*100) + $dy;

    $obstime = $hr * 100 + $mi;

    $elemcod = $p1.$p2;

    #################################################
    # Attempt to Add to List 
    # If it is duplicate set err flag to begin dup elim
    #################################################
    $stndate="${obsdate}_${id}";
    if($array{$stndate} eq "")
    {
        $array{$stndate} = "$obsdate,$id,$obstime,$elemcod,$val,$rv,$dur,$tc,$sc,$ec,$org,0,$qual";
        $amount{$stndate} = "$val";
#        print "$obsdate,$id,$obstime,$elemcod,$val,$rv,$dur,$tc,$sc,$ec,$org,'0',$qual\n";
        $err=0;
    }
    else
    {
        $err=1;
#        print "$obsdate,$id,$obstime,$elemcod,$val,$rv,$dur,$tc,$sc,$ec,$org,'1',$qual\n";
    }

    #################################################
    # Begin Dup Elim decisions
    #################################################
    if ( $err == 1 )
    {  
        #################################################
        # Load previous ob with matching station and date into temp array dup
        #################################################
        @dups = (split(/\,/,$array{$stndate}));
        $duprec++ ;

# What dups look like:
#  Line in rfc24.input:
#  2019  6  5 12  0 ABTT2    P P 2001 R Z Z -1.00     0.730 Z 1 FWR      0
#
#  dups columns 0-11:
#          20190605,ABTT2,1200,PP,0.730,1,2001,R,Z,Z,FWR,0
#  col #:     0      1      2   3   5   5  6   7 8 9 10 11
#
        #################################################
        # If obstime and previous obs time match update with current if not already updated  
        #################################################
        if ($obstime == $dups[2] )
        {
#             if ($rv == 1 && $dups[11] != 1)  # update using revised reports
# Based on Sid Katz email of 2019/6/10, select report with the highest value 
# if report time is same.  So the logic below is: when reading in a new report
# with the same valid time as an existing report already read into the arrays, 
# use the new report IF the new report is a revised report, AND if either the
# existing report is not a revised report (dups[4]=0) or if the new report
# has a higher value than the existing report.  
#
# 2019/6/14: it appears that the original code is incorrect to consider dups[11]
#   as the 'rv' (flag: '1' means revised).  It read in the 'rv' from 
#   rfc24.input, but then when the values are placed in $array{$stndate}, 
#   in addition to the original 'rv' (on column 5 - column numbers start with
#   0 - there is an additional rv-like code in column 11, and this second rv
#   (in column 11) is initialized with a value of '0' when $array{$stndate} is
#   initially assumed (i.e. values for this station-id/time is read read in),
#   and subsequent 'rv' values read in from rfc24.input are compared to this
#   "column 11" rv.  Essentially it is assuming that the first time an entry
#   for  $stndate is read, its rv should be assigned to zero (overriding the 
#   rv code in input rfc24 data) for the purpose of determining whether it's 
#   more valid than subsequent values read in (Jeff Ator, 2019/06/07: 
#   "individual reports are often externally bundled into collectives, so we 
#   have no way to control what order they arrive at our doorstep".  For
#   example, on 5 June 2019 there are two entries of 24h accumulation valid
#   at 12Z for ABTT2:
#     2019  6  5 12  0 ABTT2    P P 2001 R Z Z -1.00     0.730 Z 1 FWR      0
#     2019  6  5 12  0 ABTT2    P P 2001 R Z Z -1.00     0.000 Z 1 FWR      0
#
#   In this case the 'rv' in the input above are '1' for both entries, and 
#   and the first entry with pcp=0.730" should be the correct one (compared
#   Stage IV 24h totals on this location), but the gaugeqc code assumed a 
#   'column 11 rv' to 0 based solely on the entry being the first one read in
#   for ABTT2 at 12:00Z for 20190605.  So I'm now comparing the input rv (in
#   the new line being read in to 'column 4 rv' in $array{$stndate}/dups.  
#
             if ($rv == 1 && ( $dups[5] != 1 || $val > $dups[4]))
             {
                 $array{$stndate} = "$obsdate,$id,$obstime,$elemcod,$val,1,$dur,$tc,$sc,$ec,$org,1,$qual";
                 $amount{$stndate} = "$val";
                 $updrec++;
             }
        }
        #################################################
        # Otherwise, update with report closest to 1200 UTC  
        #################################################
        else
        {
             if ( $obstime < 1200)
             {
                 $obsdif = 1160 - $obstime;
             }
             else
             {
                 $obsdif = $obstime - 1200;
             }

             if ( $dups[2] < 1200)
             {
                 $curdif = 1160 - $dups[2];
             }
             else
             {
                 $curdif = $dups[2] - 1200;
             }

             if ( $obsdif < $curdif )
             {
# YL 2019/5/29: in the original code, a new record that has an obs time closer
#   to 12:00Z would replace a previous record (with obs time further away from 
#      12:00Z only if the new value is greater than the old value and
#      that the old 'rv' column is not '1'.  Neither makes sense.  For the 
#      first condition, 
#      the obsdif and curdif are absolute values (it would've made some sense
#      if we're checking that the new record's obs time is later than the 
#      existing record's obs time).  
# e.g. Dell's
#   /gpfs/dell1/nco/ops/dcom/prod/shef_pefiles/20190520.pe
# has
#
#  2019  5 20  0  0 MQT      P P 2001 R Z Z -1.00     2.250 Z 1 MQT      0
#  2019  5 20  0  0 MQT      P P 2001 R Z Z -1.00     2.250 Z 1 APX      0
#  2019  5 20  0  0 MQT      P P 2001 R Z Z -1.00     2.250 Z 1 MQT      0
#  2019  5 20  4  0 MQT      P P 2001 R Z Z -1.00     2.460 Z 0          0
#  2019  5 20 12  0 MQT      P P 2001 R Z Z -1.00     2.980 Z 0          0
#  2019  5 20 12  0 MQT      P P 2001 R Z Z -1.00     2.980 Z 1 MQT      0
#  2019  5 20 12  0 MQT      P P 2001 R Z Z -1.00     2.980 Z 1 MQT      0
#  2019  5 20 12  0 MQT      P P 2001 R Z Z -1.00     2.980 Z 1 APX      0
#  2019  5 20 12  0 MQT      P P 2001 R Z Z -1.00     2.980 Z 1 MQT      0
#  2019  5 20 12  0 MQT      P P 2001 R Z Z -1.00     2.980 Z 1 MQT      0
#  2019  5 20 12  0 MQT      P P 2001 R Z Z -1.00     2.980 Z 0 MSR      0
#
# Using the existing logic, the later reports valid at 12:00 will not replace
# the earlier report valid at 0000Z, solely due to the former having rv=1
#  (the digit after '2.980 Z'.
#                 if ($val > $dups[4] && $dups[11] != 1)
#                 {
                       $array{$stndate} = "$obsdate,$id,$obstime,$elemcod,$val,1,$dur,$tc,$sc,$ec,$org,1,$qual";
                       $amount{$stndate} = "$val";
                       $updrec++;
#                 }
             }
        }
    }
}

close SHEF;

#################################################
# Print Reports
#################################################

print " 24-hr precip reports ending 12Z on $ARGV[0]\n";

foreach $key (sort {$amount{$b} <=> $amount{$a}} keys %amount)
{
   @obs = (split(/\,/,$array{$key}));

   if ($obs[12]=~/Z|M|S|V|N/ && $lat{$obs[1]} ne "" && $obs[0] eq "$ARGV[0]")
   {
      printf "%6.2f %7.2f %6.2f %-9s %4s %4s\n",$lat{$obs[1]},$lon{$obs[1]},$obs[4],$obs[1],$obs[2];
   }
}

#printf "Reports=%5d, duplicates=%4d, updates=%4d ended %s\n",$numrec,$duprec,$updrec,$stp;
