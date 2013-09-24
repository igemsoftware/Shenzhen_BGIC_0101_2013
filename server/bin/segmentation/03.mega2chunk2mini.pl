#!/usr/bin/perl 
#==============================================================================#
#-------------------------------help-info-start--------------------------------#

=head1 Name

    03.mega2chunk2mini.pl --> Script for segmentating 30k fragments into about 10k fragments and following 2k fragments, adding gibson or goldengate adaptor for the final assembly

=head1 Usage

    perl  03.mega2chunk2mini.pl [options] [input file]

    -help        print this help to screen
    -re      *   path to restriction enzyme site storage file 
    -sg      *   path to fasta output of 01.whole2mega.pl
    -ps      *   path to parse output of 02.globalREmarkup.pl
    -a2      *   2k to 10k assembly strategy
    -a10     *   10k to 30k assembly strategy
    -ckmax2  *   the maximum length of minichunks 
    -ckmin2  *   the minimum length of minichunks
    -cknum   *   the number of minichunks in a chunk 
    -ol2     *   the length of overlap
    -tmax2   *   the maximum melting temperature of the overlap of minichunks
    -tmin2   *   the minimum melting temperature of the overlap of minichunks
    -fe2     *   the minimum free energy of the overlap of minichunks
    -ex2     *   the type of exonuclease used for minichunks
    -lo2     *   the minimum distance between minichunks overlap and loxpsym
    -en2     *   the type of enzyme flanking minichunks
    -et2     *   the temperature of enzyme used in minichunks digestion
    -ep2     *   the maximum unit price of enzyme used in minichunks digestion
    -en10    *   the type of enzyme flanking chunks
    -et10    *   the temperature of enzyme used in chunks digestion
    -ot      *   path of the directory of outfile (default: cwd/03.mega2chunk2mini)

=head1 Example

    perl  03.mega2chunk2mini.pl -h
    perl  03.mega2chunk2mini.pl -re standard_and_IIB -sg sce_chrI.mega_0 -ps sce_chrI.mega_0.parse -ot 03.mega2chunk2mini

=head1 Version

    Verion	:  3.0
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

#use warnings;
use strict;
use Cwd;
use lib '/ifs1/ST/SYNBIO/USER/wangyun/Bin/lib';
use RNA;
use AnnealTemp qw /Tm/;
use File::Basename;
use Getopt::Long;

my($Need_help,$mk,$re,$fa,$a2,$a10,$chunkmax,$chunkmin,$chunknum,$overlap,$tmmax,$tmmin,$minener,$exoenzy,$dislox,$retype2k,$enzytemp2k,$enzyprize2k,$retype10k,$enzytemp10k,$out);

GetOptions(
  "help"  =>\$Need_help,
  #'gff=s'=>\$gff,
  'ps=s'  =>\$mk,
  're=s'  =>\$re,
  'sg=s'  =>\$fa,
  'a2=s'  =>\$a2,
  'a10=s'  =>\$a10,
  'ck2max=i'  =>\$chunkmax,
  'ck2min=i'  =>\$chunkmin,
  'cknum=i'  =>\$chunknum,
  'ol2=i'  =>\$overlap,
  'tmax2=i'  =>\$tmmax,
  'tmin2=i'  =>\$tmmin,
  'fe2=i'  =>\$minener,
  'ex2=s'  =>\$exoenzy,
  'lo2=i'  =>\$dislox,
  'en2=s'  =>\$retype2k,
  'et2=i'  =>\$enzytemp2k,
  'ep2=i'  =>\$enzyprize2k,
  'en10=s'  =>\$retype10k,
  'et10=i'  =>\$enzytemp10k,
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

my $cwd =getcwd;
$out||=$cwd."/03.mega2chunk2mini";
if(!(-e $out)){
	mkdir($out);
}
my @suffixlist = qw(.parse );
my ($name,$path,$suffix) = fileparse($mk,@suffixlist);
my $miout=$out."/$name".".mini";

open MK,'<',$mk;
open RE,'<',$re;
open FA,'<',$fa;
open SG,'>',$miout;

my $sequence;
<FA>;
while(<FA>){
	chomp;
	$sequence.=$_;
}

my $falength=length $sequence;

$chunkmin||=1800;
$chunkmax||=2200;
$overlap||=40;
my $chunk=($chunkmin+$chunkmax)/2;
$chunknum||=5;
$tmmax||=70;
$tmmin||=66;

$exoenzy||="T5";
$retype2k||="IIP";
$enzytemp2k||="37";

$retype10k||="IIB";
$enzytemp10k||="37";

#============================================================================#
#                               Main process                                 #
#============================================================================#
print STDERR "---Program\t$0\tstarts --> ".localtime()."\n";

################################################### read RE information

my(@info,%re2price10k,%re2site10k,$gap1,$gap2,%re2gap10k,$match1,$match2,%re2price2k,%re2tail,%re2site);
while(<RE>){
	chomp;
	@info=split/\t/;
	if($retype2k eq "IIP"){
		if($info[1]=~/\((\d+)\/(\d+)\)(\w+)\((\d+)\/(\d+)\)/ && $retype10k eq "IIB"){#this enzyme is IIB type
			$re2price10k{$info[0]}=$info[12];
			$re2site10k{$info[0]}=$1;
			
		}
		elsif($info[1]=~/^(\w+)\((\d+)\/(\d+)\)/ && $retype10k eq "IIA"){#this enzyme is IIA type
			$re2price10k{$info[0]}=$info[12];
			$re2site10k{$info[0]}=$1;
			$gap1=$2;$gap2=$3;
		  $re2gap10k{$info[0]}=$gap1+$gap2;# re2gap10k is distance between match site and original seq
		}
		elsif($info[1]=~/\(/){
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
	        }
	      }
	    }
	  }
  }
}

################################################### read the result of RE map

my@re2loci;
while(<MK>){
	chomp;
	@info=split/\s+/;
	push @re2loci,$info[0]."-".$info[1]."-".$info[2];
}

################################################### 
my $process="2k";
my $point=0;

my $s=$point+1;
my $e=$point+$chunkmax;
my @re2=&findRE($s,$e);
my $re2=$re2[0];


my $result2k="*\t";
my $win1=1;
my $i=1;

######################################

my(@re1,$re1,$refirst,$map,$step,@matchout,$tmout,$win2);
while($e<=$falength){
  $s=$point+$chunkmin-$overlap;$e=$point+$chunkmin-$overlap+$chunkmax;
	@re1=&findRE($s,$e);
	$re1=$re1[0];
  $refirst=$re2tail{$re1};
	$refirst=~tr/ATCGRYMKSWHDBV/TAGCYRKMWSDHVB/;
	$map=$refirst.("." x ($overlap- length($re2tail{$re2})- length($re2tail{$re1}))).$re2tail{$re2};
	$step=0;
	@matchout=&match($chunk+$point-40,$map,$step);#real point
	$point=$matchout[0];
	$tmout=$matchout[1];
	$win2=$point+40-1;
	$result2k=$result2k."$re2\t$win1\t$win2\t".($win2-$win1+1)."\t$tmout\n$re1\t";
	$win1=$point;	
	$re2=$re1;
	$point+=40;
}
$result2k=$result2k."*\t$win1\t$falength\t".($falength-$win1+1);
my @result2k=split/\n/,$result2k;
my $line;
undef $result2k;
for($i=1;$i<=scalar(@result2k);$i++){
  $line=$result2k[$i-1];
  @info=split/\s+/,$line;
  if($i%5==1){
  	$result2k.="*\t".$info[1]."\t".$info[2]."\t".$info[3]."\t".$info[4]."\t".$info[5]."\n";
  }
  elsif($i%5==0 || $i==scalar(@result2k)){
  	$result2k.=$info[0]."\t*\t".$info[2]."\t".$info[3]."\t".$info[4]."\t".$info[5]."\n";
  }
  else{
  	$result2k.=$line."\n";
  }
}


my $out2k="$out/$name".".2kstate";
open OUT2k,'>',$out2k;
print OUT2k $result2k;
my $out10k="$out/$name".".10kstate";
open OUT10k,'>',$out10k;


$process="10k";######################################
#s10k is the start site for search 10k enzyme site
  
my($s10k,$e10k,@re10k,$re10k,$examp,@linesplit,$revtra,@en10k);
for($i=1;$i<=scalar(@result2k);$i++){
  $line=$result2k[$i-1];
	@info=split/\s+/,$line;
	if(int($i%5)==1){
		$s10k=$info[2];
		if((split/\s+/,$result2k[$i+5-1])[3]){
		  $e10k=(split/\s+/,$result2k[$i+5-1])[3];
		}
		else{
		  $e10k=$falength;
	  }
	}

	@re10k=&findRE($s10k,$e10k);
	$re10k=$re10k[0];
  #print "$s10k\t$e10k\t@re10k\n";	
	
	if($i==1){#SEQ+2k done
		print SG ">",$line,"\n",substr($sequence,$info[2]-1,$info[3]-$info[2]+1-length($re2tail{$info[0]})),$re2site{$info[1]},"\n\n";
    push @en10k,"*";
	}
	elsif($i==scalar(@result2k)){#2k+SEQ done
		print SG ">",$line,"\n",$re2site{$info[0]},substr($sequence,$info[2]-1+length$re2tail{$info[0]},$info[3]-$info[2]+1-length$re2tail{$info[0]});
    push @en10k,"*";
	}
	elsif(int($i%5)==1){#10k+SEQ+2k done
		$examp=$re2site10k{$re10k};#10k
	  $examp=~tr/RYMKSWHDBVN/ACAGGAAGGGA/;
	  @linesplit=split/\s+/,$line;
		print SG ">",$re10k,"\t",$linesplit[1],"\t",$linesplit[2],"\t",$linesplit[3],"\t",$linesplit[4],"\t",$linesplit[5],"\n",$examp,substr($sequence,$info[2]-1+($overlap-$re2gap10k{$re10k}),$info[3]-$info[2]+1-length$re2tail{$info[0]}-($overlap-$re2gap10k{$re10k})),$re2site{$info[0]},"\n\n";
    push @en10k,$re10k;
	}
	elsif(int($i%5)==0){#2k+SEQ+10k done
		$revtra=$re2site10k{$re10k};#10k
	  $revtra=~tr/RYMKSWHDBVN/ACAGGAAGGGA/;
	  $revtra=~tr/ATCG/TAGC/;
	  $revtra=reverse $revtra;
	  @linesplit=split/\s+/,$line;
		print SG ">",$linesplit[0],"\t",$re10k,"\t",$linesplit[2],"\t",$linesplit[3],"\t",$linesplit[4],"\n",$re2site{$info[0]},substr($sequence,$info[2]-1+length$re2tail{$info[0]},$info[3]-$info[2]+1-length$re2tail{$info[0]}),$revtra,"\n\n";
    push @en10k,$re10k;
	}
	else{#2k+SEQ+2k done
		print SG ">",$line,"\n",$re2site{$info[0]},substr($sequence,$info[2]-1+length$re2tail{$info[0]},$info[3]-$info[2]+1-2*length$re2tail{$info[0]}),$re2site{$info[0]},$re2site{$info[0]},"\n\n";
	}
}

my (@tmp,$start10k);
for($i=1;$i<=scalar(@result2k);$i++){
	if($i%5==1){
		print OUT10k shift@en10k,"\t",shift@en10k,"\t";
		@tmp=split/\t/,$result2k[$i-1];
		print OUT10k $tmp[2],"\t";
		$start10k=$tmp[2];
	}
	elsif($i%5==0){
		@tmp=split/\t/,$result2k[$i-1];
		print OUT10k $tmp[3],"\t",$tmp[3]-$start10k+1,"\n";
	}
}
print OUT10k $falength,"\t",$falength-$start10k+1,"\n";
#============================================================================#
#                               Subroutines                                  #
#============================================================================#

my(%reclass,$start,$end,$tmp,$re_name,$relocif,$relocir,%re2priced,$tmp2,@key);
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
  return @key;
}

my($m1,$m2,$m3,$segmentf,$segmentr,$tmf,$tmr);
sub match{
	($m1,$m2,$m3)=@_;#m1=start site -1,m2=letters,m3=step number
  $segmentf=substr($sequence,$m1+$m3,$overlap);
  $segmentr=substr($sequence,$m1-1-$m3,$overlap);   
  $tmf=&Tm($segmentf);
  $tmr=&Tm($segmentr);
  if($tmf>$tmmin && $tmf<$tmmax && $segmentf=~$m2){
	  $point=$m1+$m3;
	  return $point+1,$tmf;
  }
  elsif($tmr>$tmmin && $tmr<$tmmax && $segmentr=~$m2){
	  $point=$m1-1-$m3;
	  return $point+1,$tmr;
  }
  else{
    if($m3>=($chunkmax-$chunk)){
	  $point=$m1-1-$m3;
	  return $point+1,$tmr;
    }
    else{
  	$m3++;
  	&match($m1,$m2,$m3);
    }
  }
}

my ($printseq,$printseqout);
sub printseq{
	$printseq=@_;
	print @_;
	undef $printseqout;
	for($i=0;$i<length $printseq;$i=$i+60){
		$printseqout.=substr($printseq,$i,60)."\n";
	}
	return $printseqout;
}


print STDERR "---Program\t$0\tends  --> ".localtime()."\n";