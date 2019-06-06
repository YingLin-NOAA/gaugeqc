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
#        print "$obsdate,$id,$obstime,$elemcod,$val,$rv,$dur,$tc,$sc,$ec,$org,'0',$qual\n";
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

        #################################################
        # If obstime and previous obs time match update with current if not already updated  
        #################################################
        if ($obstime == $dups[2] )
        {
             if ($rv == 1 && $dups[11] != 1)  # update using revised reports
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
