#!/usr/bin/perl 
#==============================================================================#
#-------------------------------help-info-start--------------------------------#

=head1 Name

    02.globalREmarkup.pl --> Script for searching the exited restriction enzyme site along the chromosome

=head1 Usage

    perl  02.globalREmarkup.pl [options] [input file]

    --help       print this help to screen
    -re      *   path to restriction enzyme site storage file 
    -fa      *   path to fasta output of 01.chunk_wh_30k.pl
    -ct      *   path to codontable file of the organism
    -ot      *   name of outfile (default: (-fa)_*.markup

=head1 Example

    perl  02.globalREmarkup.pl -h
    perl  02.globalREmarkup.pl -re standard_and_IIB -fa sce_chr01.fa_0.chunk30k -ct Standard.ct -ot sce_chr01.fa_0.chunk30k.markup

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
use Getopt::Long;
use Cwd;

GetOptions(
  "help"   =>\$Need_help,
  #'gff=s' =>\$gff,  # for the version 2 - potential enzyme site searching
  'fa=s'   =>\$fa,
  're=s'   =>\$re,
  'ct=s'   =>\$codontable,
  'ot=s'   =>\$mkout,
);

die `pod2text $0` if ($Need_help
    || !$fa
    || !$re
    || !$codontable
);


#============================================================================#
#                              Global Variable                               #
#============================================================================#

#open GFF,'<',$gff;
open FA,'<',$fa;
open RE,'<',$re;
open CODONTABLE,'<',$codontable;


$cwd =getcwd;
#$in=$cwd."/01.chunk_wh_30k";

$out=$cwd."/02.globalREmarkup";
if(!(-e $out)){
	mkdir($out);
}
$fa=(split/\//,$fa)[1];
$mkout||=$out."/".$fa.".markup";
open MK,'>',$mkout;

#construct maxbase hash
$mixbase{"R"}="(A|G)";
$mixbase{"Y"}="(C|T)";
$mixbase{"M"}="(A|C)";
$mixbase{"K"}="(G|T)";
$mixbase{"S"}="(G|C)";
$mixbase{"W"}="(A|T)";
$mixbase{"H"}="(A|T|C)";
$mixbase{"B"}="(G|T|C)";
$mixbase{"V"}="(G|A|C)";
$mixbase{"D"}="(G|A|T)";
$mixbase{"N"}="(A|T|G|C)";
#construct maxbase hash

#============================================================================#
#                               Main process                                 #
#============================================================================#
print STDERR "---Program\t$0\tstarts --> ".localtime()."\n";

while(<CODONTABLE>){
	chomp;
	if(/^#/){
		next;
	}
	else{
	  @info=split/\s+/;
	  $info[0]=~tr/{|}//;
    $codontable{$info[0]}=$info[1];
  }
}
	
while(<RE>){
	chomp;
	if(/^#/){
		next;
	}
	else{
		@info=split/\t/;
		#print $info[0],"\n";
		if($info[1]=~/\((\d+)\/(\d+)\)(\w+)\((\d+)\/(\d+)\)/){#this enzyme is IIB type
			#print $info[0],"\t",$3,"\tIIB\n";
			$IIB_match{$info[0]}=$3;
			$re{$info[0]}=$3;
			$IIB_cutsite{$info[0]}=$1."-".$2."-".$3."-".$4;
		}
		elsif($info[1]=~/(\w+)\((.+)\/(.+)\)/){#this enzyme is IIA type
			#print $info[0],"\t",$1,"\tIIA\n";
			$IIA_match{$info[0]}=$1;
			$re{$info[0]}=$1;
			$IIA_cutsite{$info[0]}=$2."-".$3;
		}
		else{# the others are IIP type
		
		$info[1]=~/(\w*)\^(\w*)/;
		#print $info[0],"\n";
		$match1=$1,$match2=$2;
		if(length $match1<= length $match2){# this IIP is for T5exo
			$IIP_T5_match{$info[0]}=$match1.$match2;
			$re{$info[0]}=$match1.$match2;
			#print $info[0],"\t",$match1.$match2,"\tIIPT5\n";
			if(length $match1==0){
			  $IIP_T5_remained{$info[0]}="N";
			}
			else{
				$IIP_T5_remained{$info[0]}=$match1;# but pay attention, the opposite is $match=~tr/AS/TW/;
			}
		}
		if(length $match1>= length $match2){#this IIP is for T3exo
			$IIP_T3_match{$info[0]}=$match1.$match2;
			$re{$info[0]}=$match1.$match2;
			#print $info[0],"\t",$match1.$match2,"\tIIPT3\n";
			if(length $match2==0){
			  $IIP_T3_remained{$info[0]}="N";
			}
			else{
				$IIP_T3_remained{$info[0]}=$match2;# but pay attention, the opposite is $match=~tr/AS/TW/;
			}
		}
    $re_temp{$info[0]}=$info[2];
    $re_price{$info[0]}=$info[12];
  }
	}
}

while(<FA>){
	if(/^>/){
		next;
	}
	else{
	  chomp;
	  $sequence.=$_;
	}
}


#============================================================================#
#                               Subroutines                                  #
#============================================================================#
#1.find exit restriction enzyme site
sub mix2simple{
	$mix=$_[0];
  foreach(keys%mixbase){
  	$mix=~s/$_/$mixbase{$_}/g;
  }
  return $mix;
}

foreach(keys %re){
  $simple=&mix2simple($re{$_});
  $relength=length $re{$_};
  for($i=0;$i<length $sequence;$i++){
	  $segmentation=substr($sequence,$i,$relength);
	  if($segmentation=~/$simple/i){
		  print MK $_,"\t",$i+1,"\t",$i+$relength,"\t",$re{$_},"\t",$segmentation,"\n";
	  }
  }
}
foreach(keys %IIA_match){
  $simple=&mix2simple($IIA_match{$_});
  $simple=~tr/ATCG/TAGC/;
  $simple=reverse $simple;
  $relength=length $IIA_match{$_};
  for($i=0;$i<length $sequence;$i++){
	  $segmentation=substr($sequence,$i,$relength);
	  if(((length $segmentation) ==(length $IIA_match{$_})) && ($segmentation=~/$simple/i)){
		  print MK $_,"\t",$i+1,"\t",$i+$relength,"\t",$re{$_},"\t",$segmentation,"\n";
	  }
  }
}

#2.find potent restriction enzyme site

#sub nuleo2pro{
#	$nuleo=$_;
#}

#while(<GFF>){
#	chomp;
#	@info=split/\s+/;
#	if($info[2] eq "CDS"){
#		$info[8]=~/Name=(.+)_CDS;/;
#		$name=$1;
#		print $name,"\n";
#		$cds{$name."=".$info[3]."-".$info[4]}=$info[3]."-".$info[4];
#	}
#}

print STDERR "---Program\t$0\tends  --> ".localtime()."\n";
