#!/usr/bin/perl 
#==============================================================================#
#-------------------------------help-info-start--------------------------------#

=head1 Name

    01.whole2mega.pl --> Script for segmentating a whole chromosome into about 30k fragments(megachunks) and adding homologous overlap, markers, telomeres for the final assembly

=head1 Usage

    perl  01.whole2mega.pl [options] [input file]

    --help       print this help to screen
    -gff     *   path to gff file 
    -fa      *   path to fasta file
    -ol      *   length of overlap between 30k chunks
    -ck      *   length of 30 chunks
    -m1      *   path to gff file of marker1 (default:LEU2)
    -m2      *   path to gff file of marker2 (default:URA3)
    -m3      *   path to gff file of marker3 (default:HIS3)
    -m4      *   path to gff file of marker4 (default:TRP1)
    -ot      *   path of the directory of outfile (default: cwd/01.whole2mega)

=head1 Example

    perl  01.whole2mega.pl -h
    perl  01.whole2mega.pl -gff sce_chrI.gff -fa sce_chr01.fa -ol 1000 -ck 30000 -m1 LEU2 -m2 URA3 -m3 HIS3 -m4 TRP1 -ot 01.whole2mega
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

use warnings;
use strict;
use Getopt::Long;
use File::Basename;
use Cwd;
use JSON;
use Data::Dumper;

my($Need_help,$gff,$fa,$ol30k,$chunk30k,$m1,$m2,$m3,$m4,$out);
GetOptions(
  "help"  =>\$Need_help,
  'gff=s' =>\$gff,
  'fa=s'  =>\$fa,
  'ol=i'=>\$ol30k,
  'ck=i'=>\$chunk30k,
  'm1=s'  =>\$m1,
  'm2=s'  =>\$m2,
  'm3=s' =>\$m3,
  'm4=s' =>\$m4,
  'ot=s'  =>\$out,
);

die `pod2text $0` if ($Need_help
    || !$gff
    || !$fa
);

#============================================================================#
#                              Global Variable                               #
#============================================================================#
open GFF,'<',$gff;
open FA,'<',$fa;

open M1,'<',$m1;
open M2,'<',$m2;
open M3,'<',$m3;
open M4,'<',$m4;

my $tl="server/config/features/UTC_left.feat";
my $tr="server/config/features/UTC_right.feat";

open TL,'<',$tl;
open TR,'<',$tr;
my ($switch,$marker_1,$marker_2,$marker_3,$marker_4,$telL,$telR);
while(<M1>){
	chomp;
	if(/>/){
		$switch="yes";
	}
	if($switch && $switch eq "yes"){
		$marker_1.=$_;
	}
}
undef $switch;
while(<M2>){
	chomp;
	if(/>/){
		$switch="yes";
	}
  if($switch && $switch eq "yes"){
		$marker_2.=$_;
	}
}
undef $switch;
while(<M3>){
	chomp;
	if(/>/){
		$switch="yes";
	}
  if($switch && $switch eq "yes"){
		$marker_3.=$_;
	}
}
undef $switch;
while(<M4>){
	chomp;
	if(/>/){
		$switch="yes";
	}
  if($switch && $switch eq "yes"){
		$marker_4.=$_;
	}
}
while(<TL>){
	chomp;
	if(/^sequence/){
		/sequence = (\w+)/;
		$telL=$1;
	}
}
while(<TR>){
	chomp;
	if(/^sequence/){
		/sequence = (\w+)/;
		$telR=$1;
	}
}

$ol30k||=1000; #overlap between 30k fragments
$chunk30k||=30000; #the size of chunk30k

#============================================================================#
#                               Main process                                 #
#============================================================================#
print STDERR "---Program\t$0\tstarts --> ".localtime()."\n";

my (@inf,%loc,$allseq);
while(<GFF>){
	chomp;
	@inf=split/\s+/;
	if($inf[2] eq "centromere"){
		$loc{"CEN_L"}=$inf[3];
	}
	if($inf[2] eq "ARS"){
		$loc{"ARS_R"}=$inf[4];
	}
}

while(<FA>){
	chomp;
	if(/>/){
	}
	else{
	  $allseq.=$_;
	}
}

my(%loc30k,%loc30k_seq,$start,$end,%loc30k_struc);

my $loc30_num=0;
$loc30k{$loc30_num}=int(($loc{"CEN_L"}+$loc{"ARS_R"})/2-$chunk30k/2)."-".int(($loc{"CEN_L"}+$loc{"ARS_R"})/2+$chunk30k/2);
my $core=substr($allseq,int(($loc{"CEN_L"}+$loc{"ARS_R"})/2-$chunk30k/2)-1,int(($loc{"CEN_L"}+$loc{"ARS_R"})/2+$chunk30k/2)-int(($loc{"CEN_L"}+$loc{"ARS_R"})/2-$chunk30k/2)+1);
$loc30k_seq{"0"}=$telL.$marker_4.$core.$marker_3.$telR;

$start=1;$end=$start+(length$telL)-1;
$loc30k_struc{"0"}="left_telomere\t$start\t$end\n";
$start=$end+1;$end=$start+(length$marker_4)-1;
$loc30k_struc{"0"}.="HIS3\t$start\t$end\n";
$start=$end+1;$end=$start+(length$core)-1;
$loc30k_struc{"0"}.="Part of chromosome\t$start\t$end\n";
$start=$end+1;$end=$start+(length$marker_3)-1;
$loc30k_struc{"0"}.="TRP1\t$start\t$end\n";
$start=$end+1;$end=$start+(length$telR)-1;
$loc30k_struc{"0"}.="right_telomere\t$start\t$end\n";

my $chunk30k_L_num=int(((split/-/,$loc30k{"0"})[0]-1)/($chunk30k-$ol30k)+0.5);
my $chunk30k_R_num=int(((length$allseq)-(split/-/,$loc30k{"0"})[1])/($chunk30k-$ol30k)+0.5);

my $chunk30k_L_len=int(((split/-/,$loc30k{"0"})[0]-1)/$chunk30k_L_num);
my $chunk30k_R_len=int(((length$allseq)-(split/-/,$loc30k{"0"})[1])/$chunk30k_R_num);

my($i,$marker);
for($i=-1;$i>=(-$chunk30k_L_num);$i--){
  if($i!=(-$chunk30k_L_num)){
	  if($i%2==1){
      $marker=$marker_1;
	  }
	  else{
      $marker=$marker_2;
	  }
	  $loc30k{$i}=((split/-/,$loc30k{$i+1})[0]-($chunk30k_L_len))."-".((split/-/,$loc30k{$i+1})[0]-1+$ol30k);
	  $core=substr($allseq,((split/-/,$loc30k{$i+1})[0]-($chunk30k_L_len))-1,((split/-/,$loc30k{$i+1})[0]-1+$ol30k)-((split/-/,$loc30k{$i+1})[0]-($chunk30k_L_len-$ol30k))+1);
	  $loc30k_seq{$i}=$telL.$marker.$core;
	  {
	  	$start=1;$end=$start+(length$telL)-1;
      $loc30k_struc{$i}="left_telomere\t$start\t$end\n";
      $start=$end+1;$end=$start+(length$marker)-1;
      if($marker eq $marker_1){
        $loc30k_struc{$i}.="LEU2\t$start\t$end\n";
      }
      else{
        $loc30k_struc{$i}.="URA3\t$start\t$end\n";
      }
      $start=$end+1;$end=$start+(length$core)-1;
      $loc30k_struc{$i}.="Part of chromosome\t$start\t$end\n";
    }
  }
  else{
	  if($i%2==1){
      $marker=$marker_1;
	  }
	  else{
      $marker=$marker_2;
	  }
	  $loc30k{$i}="1"."-".((split/-/,$loc30k{$i+1})[0]-1+$ol30k);
	  $core=substr($allseq,0,((split/-/,$loc30k{$i+1})[0]-1+$ol30k)-0+1);
	  $loc30k_seq{$i}=$telL.$marker.$core; 
	  {
	  	$start=1;$end=$start+(length$telL)-1;
      $loc30k_struc{$i}="left_telomere\t$start\t$end\n";
      $start=$end+1;$end=$start+(length$marker)-1;
      if($marker eq $marker_1){
        $loc30k_struc{$i}.="LEU2\t$start\t$end\n";
      }
      else{
        $loc30k_struc{$i}.="URA3\t$start\t$end\n";
      }
      $start=$end+1;$end=$start+(length$core)-1;
      $loc30k_struc{$i}.="Part of chromosome\t$start\t$end\n";
    }
	}
}

for($i=1;$i<=$chunk30k_R_num;$i++){
	if($i!=$chunk30k_R_num){
	  if($i%2==1){
      $marker=$marker_1;
	  }
	  else{
      $marker=$marker_2;
	  }
	  $loc30k{$i}=((split/-/,$loc30k{$i-1})[1]+1-$ol30k)."-".((split/-/,$loc30k{$i-1})[1]+($chunk30k_R_len));
	  $core=substr($allseq,((split/-/,$loc30k{$i-1})[1]+1-$ol30k)-1,((split/-/,$loc30k{$i-1})[1]+($chunk30k_R_len))-((split/-/,$loc30k{$i-1})[1]+1-$ol30k)+1);
	  $loc30k_seq{$i}=$core.$marker.$telR;
	  {
      $start=1;$end=$start+(length$core)-1;
      $loc30k_struc{$i}.="Part of chromosome\t$start\t$end\n";
      $start=$end+1;$end=$start+(length$marker_3)-1;
      if($marker eq $marker_1){
        $loc30k_struc{$i}.="LEU2\t$start\t$end\n";
      }
      else{
      	$loc30k_struc{$i}.="URA3\t$start\t$end\n";
      }
      $start=$end+1;$end=$start+(length$telR)-1;
      $loc30k_struc{$i}.="right_telomere\t$start\t$end\n";
    }
  }
  else{
	  if($i%2==1){
      $marker=$marker_1;
	  }
	  else{
      $marker=$marker_2;
	  }
	  $loc30k{$i}=((split/-/,$loc30k{$i-1})[1]+1-$ol30k)."-".length $allseq;
	  $core=substr($allseq,((split/-/,$loc30k{$i-1})[1]+1-$ol30k)-1,(length $allseq)-((split/-/,$loc30k{$i-1})[1]+1-$ol30k)+1);
	  $loc30k_seq{$i}=$core.$marker.$telR;
	  {
      $start=1;$end=$start+(length$core)-1;
      $loc30k_struc{$i}.="Part of chromosome\t$start\t$end\n";
      $start=$end+1;$end=$start+(length$marker_3)-1;
      if($marker eq $marker_1){
        $loc30k_struc{$i}.="LEU2\t$start\t$end\n";
      }
      else{
      	$loc30k_struc{$i}.="URA3\t$start\t$end\n";
      }
      $start=$end+1;$end=$start+(length$telR)-1;
      $loc30k_struc{$i}.="right_telomere\t$start\t$end\n";
    }
  }
}
my $outdiv;
my $cwd =getcwd;
$out||=$cwd."/01.whole2mega";

if(!(-e $out)){
	mkdir($out);
}

my @suffixlist = qw(.fa .fasta);
my ($name,$path,$suffix) = fileparse($fa,@suffixlist);


my $state="$out/$name.whole2mega.state";
open ST,'>',$state;

my @stateinfo;
for($i=(-$chunk30k_L_num);$i<=$chunk30k_R_num;$i++){
	$outdiv=$out."/$name"."_".$i.".mega";
	open OUT,'>',$outdiv;
	print ST $outdiv,"\t",$loc30k{$i},"\n";
	print ST $loc30k_struc{$i},"\n";
	push @stateinfo,$outdiv."\t".(split/-/,$loc30k{$i})[0]."\t".(split/-/,$loc30k{$i})[1]."\n".$loc30k_struc{$i};
	print  OUT ">$outdiv\t",$loc30k{$i},"\n";
	$start=0;
	while($start <(length $loc30k_seq{$i})){
	  print OUT substr($loc30k_seq{$i},$start,100),"\n";
	  $start+=100;
	}
}

#print @stateinfo;
my(@statebk,%state,$tmp1,$tmp2,$tmp3,$tmp4,$tmp5,$tmp6);

foreach(@stateinfo){
	@statebk=split/\n/,$_;
	$tmp1=(split/\t/,$statebk[0])[0];
	$tmp2=(split/\t/,$statebk[0])[1];
	$tmp3=(split/\t/,$statebk[0])[2];
	$state{pre}{ID}{$tmp1}={
		  Start_in_chromosome => $tmp2,
		  End_in_chromosome => $tmp3
	};
  #print Dumper $state;
	for($i=1;$i<scalar@statebk;$i++){
		$tmp4=(split/\t/,$statebk[$i])[0];
	  $tmp5=(split/\t/,$statebk[$i])[1];
	  $tmp6=(split/\t/,$statebk[$i])[2];
	  $state{pre}{ID}{$tmp1}{Feature}{$tmp4}={
		    Start_in_Segment => $tmp5,
		    End_in_Segment => $tmp6
		}
	}
}
#print Dumper $state{pre};
my $json="$out/$name".".json";
open JSON,'>',$json;
print JSON to_json($state{pre});		

print STDERR "---Program\t$0\tends  --> ".localtime()."\n";
