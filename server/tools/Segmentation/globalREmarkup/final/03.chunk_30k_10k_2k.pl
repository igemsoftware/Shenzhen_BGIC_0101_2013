#!/usr/bin/perl 
#==============================================================================#
#-------------------------------help-info-start--------------------------------#

=head1 Name

    03.chunk_30k_10k_2k.pl --> Script for segmentating 30k fragments into about 10k fragments and adding gibson or goldengate adaptor for the final assembly

=head1 Usage

    perl  03.chunk_30k_10k_2k.pl [options] [input file]

    -help        print this help to screen
    -re      *   path to restriction enzyme site storage file 
    -fa      *   path to fasta output of 01.chunk_wh_30k.pl
    -mk     *   path to markup output of 02.globalREmarkup.pl
    -ot     *   path to outfile (default: (-mk).chunk

=head1 Example

    perl  03.chunk_30k_10k_2k.pl -h
    perl  03.chunk_30k_10k_2k.pl -re standard_and_IIB -fa sce_chr01.fa_0.chunk30k -mk sce_chr01.fa_0.chunk30k.markup -ot sce_chr01.fa_0.chunk30k.markup.chunk

=head1 Version

    Verion	:  2.0
    Created	:  09/14/2013 05:55:22 PM 
    Updated	:  --
    LastMod	:  --

=head1 Contact

    Author	:  Jianhui Gong
    E-mail	:  gongjianhui@genomics.cn
    iGEM-team	:  Shenzhen_BGIC_0101

=cut
#-------------------------------help-info-end--------------------------------#
#============================================================================#

use lib '/ifs1/ST/SYNBIO/USER/wangyun/Bin/lib';
use RNA;
use AnnealTemp qw /Tm/;
use Getopt::Long;

GetOptions(
  "help"  =>\$Need_help,
  #'gff=s'=>\$gff,
  'mk=s'  =>\$mk,
  're=s'  =>\$re,
  'fa=s'  =>\$fa,
  'ot=s'  =>\$out,
);

die `pod2text $0` if ($Need_help
    || !$mk
    || !$re
    || !$fa
);

#============================================================================#
#                              Global Variable                               #
#============================================================================#

$out||=$fa."chunk";
open MK,'<',$mk;
open RE,'<',$re;
open FA,'<',$fa;
open SG,'>',$out;

<FA>;
while(<FA>){
	chomp;
	$sequence.=$_;
}

$falength=length $sequence;

$chunkmin||=1800;
$chunkmax||=2200;
$chunknum||=5;
$overlap||=40;
$chunk=($chunkmin+$chunkmax)/2;

$tmmax||=70;
$tmmin||=66;

$exoenzy||="T5";
$retype2k||="IIP";
$enzytemp2k||="37";

$retype10k||="IIA&IIB";

#============================================================================#
#                               Main process                                 #
#============================================================================#
print STDERR "---Program\t$0\tstarts --> ".localtime()."\n";

################################################### read RE information
while(<RE>){
	chomp;
	@info=split/\t/;
	if($retype2k eq "IIP" && $retype10k eq "IIA&IIB"){
		if($info[1]=~/\((\d+)\/(\d+)\)(\w+)\((\d+)\/(\d+)\)/){#this enzyme is IIB type
			#$IIB{$info[0]}=$info[1];
			#$re2price10k{$info[0]}=$info[12];
			
		}
		elsif($info[1]=~/(\w+)\((\d+)\/(\d+)\)/){#this enzyme is IIA type
			#$IIA{$info[0]}=$info[1];
			$re2price10k{$info[0]}=$info[12];
			$re2site10k{$info[0]}=$1;
			$gap1=$2;$gap2=$3;
			$re2gap10k{$info[0]}=$gap1+$gap2;# re2gap10k is distance between match site and original seq
			#print $info[0],"\t",$1,"\n";
		}
		else{	
			if($exoenzy eq "T5"){	
				$info[1]=~/(\w*)\^(\w*)/;
		    $match1=$1,$match2=$2;
		    if(length $match1<= length $match2){# this IIP is for T5exo
		     	if($info[2]==$enzytemp2k){
	          $re2price2k{$info[0]}=$info[12];
	          $re2tail{$info[0]}=$match1; 
	          $re2site{$info[0]}=$match1.$match2;
	          #print $info[0],"\t",$re2tail{$info[0]},"\n";  #notation
	        }
	      }
	    }
	  }
  }
}

################################################### read the result of RE map
while(<MK>){
	chomp;
	@info=split/\s+/;
	push @re2loci,$info[0]."-".$info[1]."-".$info[2];
	#print @re2loci,"\n";
}

################################################### 
$process="2k";
$point=0;
#=head
$s=$point+1;$e=$point+$chunkmax;
@re2=&findRE($s,$e);
$re2=$re2[0];

#print "$s\t$e\t$re2\n";

$result2k="*\t";
$win1=1;

######################################
while($e<=$falength){
	$execnum=1;
	
	
  $s=$point+$chunkmin-$overlap;$e=$point+$chunkmin-$overlap+$chunkmax;
	@re1=&findRE($s,$e);
	$re1=$re1[0];
  #print "$re1\t",$re2tail{$re1},"\t$re2\t",$re2tail{$re2},"\n";
  $refirst=$re2tail{$re1};
	$refirst=~tr/ATCGRYMKSWHDBV/TAGCYRKMWSDHVB/;
	$map=$refirst.("." x ($overlap- length($re2tail{$re2})- length($re2tail{$re1}))).$re2tail{$re2};
	#print "$map\n";
	$step=0;
	@matchout=&match($chunk+$point-40,$map,$step);#real point
	$point=$matchout[0];
	$tmout=$matchout[1];
	$win2=$point+40-1;
  #print "$re1\t$re2\t",substr($sequence,$point-1,1),"\t",substr($sequence,$win2-1,1),"\t$map\t$tmout\n";
	$result2k=$result2k."$re2\t$win1\t$win2\t".($win2-$win1+1)."\n$re1\t";

	$win1=$point;	
	$re2=$re1;
	$point+=40;

  	
  
  $execnum++;
}
$result2k=$result2k."*\t$win1\t$falength\t".($falength-$win1+1);
#=cut


$process="10k";######################################
#s10k is the start site for search 10k enzyme site
@result2k=split/\n/,$result2k;


for($i=1;$i<=scalar(@result2k);$i++){
  $line=$result2k[$i-1];
	@info=split/\s+/,$line;
	if(int($i%5)==1){
		$s10k=$info[2];
		$e10k=(split/\s+/,$result2k[$i+4-1])[3];
		#print $s10k,"\t",$e10k,"\n";
	}

	@re10k=&findRE($s10k,$e10k);
	$re10k=$re10k[0];
	if($i==1){#SEQ+2k done
		print SG $line,"\t",substr($sequence,$info[2]-1,$info[3]-$info[2]+1-length$re2tail{$info[0]}),$re2site{$info[0]},"\n";
	}
	elsif($i==scalar(@result2k)){#2k+SEQ done
		print SG $line,"\t",$re2site{$info[0]},substr($sequence,$info[2]-1+length$re2tail{$info[0]},$info[3]-$info[2]+1-length$re2tail{$info[0]}),"\n";
	}
	elsif(int($i%5)==1){#10k+SEQ+2k done
		$examp=$re2site10k{$re10k};#10k
	  $examp=~tr/RYMKSWHDBVN/ACAGGAAGGGA/;
	  @linesplit=split/\s+/,$line;
		print SG $re10k,"\t",$linesplit[1],"\t",$linesplit[2],"\t",$linesplit[3],"\t",$linesplit[4],"\t",$examp,substr($sequence,$info[2]-1+($overlap-$re2gap10k{$re10k}),$info[3]-$info[2]+1-length$re2tail{$info[0]}-($overlap-$re2gap10k{$re10k})),$re2site{$info[0]},"\n";
	}
	elsif(int($i%5)==0){#2k+SEQ+10k done
		$revtra=$re2site10k{$re10k};#10k
	  $revtra=~tr/RYMKSWHDBVN/ACAGGAAGGGA/;
	  $revtra=~tr/ATCG/TAGC/;
	  $revtra=reverse $revtra;
	  @linesplit=split/\s+/,$line;
		print SG $linesplit[0],"\t",$re10k,"\t",$linesplit[2],"\t",$linesplit[3],"\t",$linesplit[4],"\t",$re2site{$info[0]},substr($sequence,$info[2]-1+length$re2tail{$info[0]},$info[3]-$info[2]+1-length$re2tail{$info[0]}),$revtra,"\n";
	}
	else{#2k+SEQ+2k done
		print SG $line,"\t",$re2site{$info[0]},substr($sequence,$info[2]-1+length$re2tail{$info[0]},$info[3]-$info[2]+1-2*length$re2tail{$info[0]}),$re2site{$info[0]},$re2site{$info[0]},"\n";
	}
}

#============================================================================#
#                               Subroutines                                  #
#============================================================================#

sub findRE{
	undef %reclass;
	($start,$end)=@_;
  foreach $tmp(@re2loci){
  	#print $tmp,"\n";
	  ($re_name,$relocif,$relocir)=(split/\-/,$tmp)[0,1,2];
    if($relocif>=$start && $relocir <= $end  ){
      $reclass{$re_name}=$re_name;
    }
  }
  if($process eq "2k"){
    %re2priced=%re2price2k;
  }
  if($process eq "10k"){
    %re2priced=%re2price10k;
  }
  foreach $tmp2 (keys %reclass){
  	if($re2priced{$tmp2}){
	  	delete $re2priced{$tmp2};
	  }
  }
  @key =sort {$re2priced{$a} <=> $re2priced{$b}} keys %re2priced;
  #foreach(@key){
  #	print $_,"\n";
  #}
  return @key;
}

sub match{
	($m1,$m2,$m3)=@_;#m1=start site -1,m2=letters,m3=step number
	#$fixplace=$m1;
	#print "$m1\t$m2\t$m3\n";
  $segmentf=substr($sequence,$m1+$m3,$overlap);
  $segmentr=substr($sequence,$m1-1-$m3,$overlap);
  #print "$segmentf\t$segmentr\n";
  #$segmentf="C";$segmentr="G";
  #print $segmentf,$segmentr;
  #if(($m1+$m3)>($fixplace+200) || ($m1-1-$m3)<($fixplace- 200)){
  #	$re1=$re1[1];
  #	$m3=0;
	#  $map=$re2tail{$re1}.("." x ($overlap-length($re2tail{$re2})- length($re2tail{$re1}))).$re2tail{$re2};
  #	&match($chunk+$point-40,$map,$m3);
  #	print "no match\n";
  #}    
  $tmf=&Tm($segmentf);
  $tmr=&Tm($segmentr);
  if($tmf>$tmmin && $tmf<$tmmax && $segmentf=~$m2){
  	#print "yes\n";
	  $point=$m1+$m3;
	  #print &Tm($segmentf),"\n";
	  return $point+1,$tmf;
  }
  elsif($tmr>$tmmin && $tmr<$tmmax && $segmentr=~$m2){
	  $point=$m1-1-$m3;
	  #print &Tm($segmentr),"\n";
	  return $point+1,$tmr;
  }
  else{
  	$m3++;
  	&match($m1,$m2,$m3);
  }
}

$process="10k";######################################
=head
for($i=1;$i<$falength;$i+=10000){
	print $i,"\t",$i+10000,"\t";
@key=&findRE($i,$i+10000);
foreach(@key){
	print $_,"\t";
}
print "\n";
}
=cut

print STDERR "---Program\t$0\tends  --> ".localtime()."\n";