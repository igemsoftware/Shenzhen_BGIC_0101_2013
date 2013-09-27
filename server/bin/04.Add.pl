#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Data::Dumper;

my ($loxp,$ARS,$left_telomere,$right_telomere,$centromere,$chr,$gff,$neo_chr_fa,$neo_chr_gff,$help);
GetOptions(
		"loxp:s"=>				\$loxp,
		"ars:s"=>				\$ARS,
		"left_telomere:s" =>	\$left_telomere,
		"right_telomere:s" =>	\$right_telomere,
		"centromere:s"=>		\$centromere,
		"chr_seq:s"=>			\$chr,
		"chr_gff:s"=>			\$gff,
		"neochr_seq:s"=>		\$neo_chr_fa,
		"neochr_gff:s"=>		\$neo_chr_gff,
		"help"=>				\$help
);
if(!$chr || !$gff)
{
	print "perl $0 --loxp <loxPsym.feat> --left_telomere <left_telomere.feat> --right_telomere <right_telomere.feat> --centromere <centromere.feat> --chr_seq <decoupled.fa> --chr_gff <decoupled.gff> --neochr_gff <final.chr> --neochr_seq <final.fa>\n";
	exit;
}

my %codon_table= (
		"GCT" => "A","GCC" => "A","GCA" => "A","GCG" => "A",
		"CGT" => "R","CGC" => "R","CGA" => "R","CGG" => "R","AGA" => "R","AGG" => "R",
		"AAT" => "N","AAC" => "N",
		"GAT" => "D","GAC" => "D",
		"TGT" => "C","TGC" => "C",
		"CAA" => "Q","CAG" => "Q",
		"GAA" => "E","GAG" => "E",
		"GGT" => "G","GGC" => "G","GGA" => "G","GGG" => "G",
		"CAT" => "H","CAC" => "H",
		"ATT" => "I","ATC" => "I","ATA" => "I",
		"TTA" => "L","TTG" => "L","CTA" => "L","CTC" => "L","CTG" => "L","CTT" => "L",
		"AAA" => "K","AAG" => "K",
		"ATG" => "M",
		"TTT" => "F","TTC" => "F",
		"CCT" => "P","CCC" => "P","CCA" => "P","CCG" => "P",
		"TCT" => "S","AGC" => "S","AGT" => "S","TCC" => "S","TCA" => "S","TCG" => "S",
		"ACT" => "T","ACC" => "T","ACA" => "T","ACG" => "T",
		"TGG" => "W",
		"TAT" => "Y","TAC" => "Y",
		"GTT" => "V","GTC" => "V","GTA" => "V","GTG" => "V",
		"TAA" => "U","TAG" => "U","TGA" => "U",
);

my %complement_base = (
		'A' => 'T',
		'C' => 'G',
		'G' => 'C',
		'T' => 'A',
		'M' => 'K',
		'R' => 'Y',
		'W' => 'W',
		'S' => 'S',
		'Y' => 'R',
		'K' => 'M',
		'V' => 'B',
		'H' => 'D',
		'D' => 'H',
		'B' => 'V',
		'N' => 'N',
		);

my (%AnnoInfo,%gene_order,@gene_order,%sequence,%frag);
my (%Loxp, %Left_telo, %Right_telo, %ARS, %Centr_mere);

Read_Feature($loxp, \%Loxp);
#print Dumper(%Loxp);exit;
Read_Feature($left_telomere, \%Left_telo);
#print Dumper(%Left_telo);exit;
Read_Feature($right_telomere, \%Right_telo);
#print Dumper(%Right_telo);exit;
Read_Feature($ARS, \%ARS);
#print Dumper(%ARS);exit;
Read_Feature($centromere, \%Centr_mere);
#print Dumper(%Centr_mere);exit;

ReadFasta($chr, \%sequence);

Read_Gff($gff, \%AnnoInfo, \%sequence, \%gene_order, \@gene_order);
#print Dumper(\%AnnoInfo);exit;
#print Dumper(\%gene_order);exit;
Add_LoxP(\@gene_order, \%AnnoInfo, \%Loxp) if(defined $loxp);
#print Dumper(\%AnnoInfo);exit;
NeoChr(\@gene_order, \%AnnoInfo, \%Loxp, \%Left_telo, \%Right_telo, \%Centr_mere, \%ARS);
#print Dumper(\%AnnoInfo);exit;

=head2 Read_Feature

    Function:Read the feature file
	Input:feature file
	Output:feature_type -> (sequence,seq_len) (hash)

=cut
sub Read_Feature
{
	my ($feat_file, $feat) = @_;
	open FEAT,"$feat_file" or die $!;
	my ($name, $type, $seq, $len);
	while(<FEAT>)
	{
		chomp;
		if($_ =~ /name\s+?=\s+?(\S+)/)
		{
			$name = $1;
		}
		elsif($_ =~ /type\s+?=\s+?(\S+)/)
		{
			$type = $1;
			$feat->{$type}{'name'} = $name;
		}
		elsif($_ =~ /sequence\s+?=\s+?(\S+)/)
		{
			$seq = $1;
			$len = length $seq;
			$feat->{$type}{'seq'} = $seq;	
			$feat->{$type}{'length'} = $len;	
		}
	}
	close FEAT;
}
=head2 ReadFasta

    Function:Read the genome fasta file and store sequence
	Input:Genome fasta file
	Output:Chromosome_ID -> sequence(hash)

=cut
sub ReadFasta
{
	my $Fa_file=shift;
	my $Fa=shift;
	open FASTA,"$Fa_file" or die ("fail open $Fa_file\n");
	$/='>';
	<FASTA>;
	while(<FASTA>)
	{
		chomp;
		my $id=(split /\s+/,$_,2)[0];
		my $sequence=(split /\n/,$_,2)[1];
		$sequence=~s/\s+//g;
		$sequence=uc($sequence);
		$Fa->{$id}=$sequence;
	}
	$/="\n";
	close FASTA;
}



sub Read_Gff
{
	my $Gff=shift;
	my $Info=shift;
	my $Seq=shift;
	my $Gene_hash=shift;
	my $Gene_order=shift;

	my ($five_UTR_start,$five_UTR_end,$three_UTR_st,$three_UTR_end,$mRNA_st,$mRNA_end,$CDS_st,$CDS_end,$gene_st,$gene_end,$seq,$decouple_site);
	open GFF,"$Gff" || die "fail open $Gff";
	while(my $line = <GFF>)
	{
		my @info = split /\s+/, $line;
		my ($tmp, $gene_id) = $info[8]=~/^(ID|Parent)=([^;]+);?/;

		$Gene_hash->{$gene_id}=$info[6];
#### Reverse if start > end
		@info[3,4] = @info[4,3] if($info[3] > $info[4]);
		if($info[2] eq 'mRNA')
		{
#### Start, end, strand
			$mRNA_st = $info[3] - $gene_st + 1;
			$mRNA_end = $info[4] - $gene_st + 1;
			@{$Info->{$info[0]}{$gene_id}{'mRNA'}} = [$mRNA_st,$mRNA_end,$info[6]];
			push @$Gene_order, $gene_id;
		}
		elsif($info[2] eq 'CDS')
		{
			$CDS_st = $info[3] - $gene_st + 1;
			$CDS_end = $info[4] - $gene_st + 1;
			push @{$Info->{$info[0]}{$gene_id}{'CDS'}}, [$CDS_st,$CDS_end,$info[6]];
		}
		elsif($info[2] eq 'five_prime_UTR_intron' || $info[2] eq "5'-UTR" || $info[2] eq '5UTR')
		{
			$five_UTR_start = $info[3] - $gene_st + 1;
			$five_UTR_end = $info[4] - $gene_st + 1;
			@{$Info->{$info[0]}{$gene_id}{'5UTR'}} = ($info[6] eq '+' ?  [1,$five_UTR_end,$info[6]] : [$five_UTR_start,$five_UTR_end,$info[6]]);  #### TODO, should we convert the origin gff to BGI style
		}
		elsif($info[2] eq 'three_prime_UTR_intron' || $info[2] eq"3'-UTR" || $info[2] eq '3UTR' )
		{
			$three_UTR_st = $info[3] - $gene_st + 1;
			$three_UTR_end = $info[4] - $gene_st + 1;
			@{$Info->{$info[0]}{$gene_id}{'3UTR'}} = ($info[6] eq '+' ? [$three_UTR_st,$three_UTR_end,$info[6]] : [1,$three_UTR_end,$info[6]]);
		}
		elsif($info[2] eq 'gene')
		{
			$gene_st = $info[3];
			$seq = ExtractSequnece($info[0], $info[3], $info[4], $info[6], $Seq);
			$gene_end = length $seq;
			$Info->{$info[0]}{$gene_id}{'gene'} = [1,$gene_end,$info[6]];
			$Info->{$info[0]}{$gene_id}{'seq'} = $seq;
			$info[8] =~/display=([^;]+);?/;
			my $function = $1;
			$Info->{$info[0]}{$gene_id}{'function'} = $function;

		}
		elsif($info[2] eq 'decouple')
		{
#			print "$gene_id\t$info[3]\t$gene_st\n";exit;
			$decouple_site = $info[3] - $gene_st;
			$Info->{$info[0]}{$gene_id}{'decouple'} = $decouple_site;
		}
	}
	close GFF;
}

=head2 ExtractSequnece

	Function:Extract the sequence according to the
	Input:chr,start site,ending site,strand
	Output:chr->sequence(hash)

=cut
sub ExtractSequnece
{
	my $chrid=shift;
	my $start_site=shift;
	my $end_site=shift;
	my $Strand=shift;
	my $Fa=shift;
	my $Sequence;
	$Sequence=substr($Fa->{$chrid},$start_site-1,$end_site-$start_site+1);
	if($Strand eq '-')
	{
		$Sequence=reverse($Sequence);
		$Sequence=~tr/ATCGatcgMRWSYKVHDBN/TAGCtagcKYWSRMBDHVN/;
	}
	return $Sequence;
}

sub Add_LoxP
{
	my $Gen_Ord = shift;
	my $Annotation = shift;
	my $Loxpsym = shift;
	my $loxp_seq = $Loxpsym->{'loxPsym'}{'seq'};
	my $loxp_len = $Loxpsym->{'loxPsym'}{'length'};

	my ($new_3UTR_seq,$new_3UTR_len,$loxp_st,$loxp_end,$new_seq);
	my ($cds_end,$gene_seq,$before_3UTR_seq,$three_utr_st,$three_utr_end,$three_utr_len,$three_utr_seq,$before_loxp,$after_loxp,$gene_direct,$gene_end);
	foreach my $Gene(@$Gen_Ord)
	{
		my $gp = $Annotation->{'NeoChr'}{$Gene};
		$gene_direct = $gp->{'gene'}[2];
		if($gene_direct eq '+')
		{
##### get the sequence before the 3UTR
			$cds_end = $gp->{'CDS'}[-1][1];
			$gene_seq = $gp->{'seq'};
			$before_3UTR_seq = substr($gene_seq,0,$cds_end);
##### get the 3UTR sequence
			$three_utr_st = $gp->{'3UTR'}[0][0];
			$three_utr_end = $gp->{'3UTR'}[0][1];
			$three_utr_len = $three_utr_end - $three_utr_st + 1;
			$three_utr_seq = substr($gene_seq,$three_utr_st-1,$three_utr_len);
			$before_loxp = substr($three_utr_seq,0,3);
			$after_loxp = substr($three_utr_seq,3,$three_utr_len-3);

			$new_3UTR_seq = $before_loxp."$loxp_seq"."$after_loxp";
			$new_3UTR_len = length $new_3UTR_seq;

			$gp->{'seq'} = $before_3UTR_seq."$new_3UTR_seq";
			$gp->{'3UTR'}[0][1] = $three_utr_st + $new_3UTR_len - 1;
			$gp->{'gene'}[1] += $loxp_len;
		}else
		{
			$gene_seq = $gp->{'seq'};
			$gene_end = $gp->{'gene'}[1];
			$before_loxp = substr($gene_seq,0,97);
			$after_loxp = substr($gene_seq,97,$gene_end - 97);

			$new_seq = $before_loxp."$loxp_seq"."$after_loxp";
			$gp->{'seq'} = $new_seq;
			$gp->{'3UTR'}[0][1] += $loxp_len;
			$gp->{'mRNA'}[0][0] += $loxp_len;
			$gp->{'mRNA'}[0][1] += $loxp_len;
			$gp->{'5UTR'}[0][0] += $loxp_len;
			$gp->{'5UTR'}[0][1] += $loxp_len;
			$gp->{'gene'}[1] += $loxp_len;
			for(my $i=0;$i<@{$gp->{'CDS'}};$i++)
			{
				$gp->{'CDS'}[$i][0] += $loxp_len;
				$gp->{'CDS'}[$i][1] += $loxp_len;
			}
		}
#		$loxp_st = $three_utr_st + 3;
#		$loxp_end = $loxp_st + $loxp_len - 1;
#		push @{$Annotation->{'NeoChr'}{$Gene}{'3UTR'}{'loxp'}},[$loxp_st,$loxp_end,$gene_direct];
	}
}

sub NeoChr
{
	my $Gen_Ord = shift;
	my $Annotation = shift;
	my $LoxP = shift;
	my $Left_telom = shift;
	my $Right_telom = shift;
	my $Centro_mere = shift;
	my $Ars = shift;

	my ($accum_len, $count) = (0,0);
	my $gene_seq;
	open NEOGFF,">$neo_chr_gff" or die "can't open $neo_chr_gff";
	open NEOFA,">$neo_chr_fa" or die "can't open $neo_chr_fa";
	print NEOFA ">NeoChr\n";

	my $fp = $Annotation->{'NeoChr'};
#### Add left telomere
	$gene_seq .= $Left_telom->{'telomere'}{'seq'};
	my $left_telomere_len = $Left_telom->{'telomere'}{'length'};
	my $left_telomere_name = $Left_telom->{'telomere'}{'name'};
	push @{$fp->{'left_telomere'}},[1,$left_telomere_len,'+'];
	$accum_len += $left_telomere_len;
	print NEOGFF "NeoChr\tGenovo\tleft_telomere\t1\t$left_telomere_len\t.\t+\t.\tID=$left_telomere_name;\n";
#### generate new gff & fa
	my $half = int(scalar(@$Gen_Ord)/2);
#	print $half,"\n";exit;
	foreach my $Gene (@$Gen_Ord)
	{
#### output gene anntotaion info
		$count++;
		$gene_seq .= $fp->{$Gene}{'seq'};
		my $gene_len = length $fp->{$Gene}{'seq'};
		my $gene_start = $accum_len + 1;
		my $gene_end = $accum_len + $gene_len;
#	print Dumper($fp->{$Gene}{'gene'});
		my $gene_direct = $fp->{$Gene}{'gene'}[2];
		my $gene_func = $fp->{$Gene}{'function'};
		print NEOGFF "NeoChr\tGenovo\tgene\t$gene_start\t$gene_end\t.\t$gene_direct\t.\tID=$Gene;display=$gene_func;\n";
		my $five_UTR_start = $accum_len + $fp->{$Gene}{'5UTR'}[0][0];
		my $five_UTR_end = $accum_len + $fp->{$Gene}{'5UTR'}[0][1];

		my $mRNA_start = $accum_len + $fp->{$Gene}{'CDS'}[0][0];
		my $mRNA_end = $accum_len + $fp->{$Gene}{'CDS'}[-1][1];

		my $three_UTR_start = $accum_len + $fp->{$Gene}{'3UTR'}[0][0];
		my $three_UTR_end = $accum_len + $fp->{$Gene}{'3UTR'}[0][1];

		my $loxp_st = $three_UTR_start + 3;
		my $loxp_end = $loxp_st + $LoxP->{'loxPsym'}{'length'};
		my $loxp_name = $LoxP->{'loxPsym'}{'name'};
		
		my $decple_site;
		if($gene_direct eq '+')
		{
#### output 5UTR annotation info
			print NEOGFF "NeoChr\tGenovo\t5UTR\t$five_UTR_start\t$five_UTR_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
#### output mRNA annotation info
			print NEOGFF "NeoChr\tGenovo\tmRNA\t$mRNA_start\t$mRNA_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
#### output gene CDS info
			for(my $i=0;$i<@{$fp->{$Gene}{'CDS'}};$i++)
			{
				my $CDS_st = $accum_len + $fp->{$Gene}{'CDS'}[$i][0];
				my $CDS_end = $accum_len + $fp->{$Gene}{'CDS'}[$i][1];
				print NEOGFF "NeoChr\tGenovo\tCDS\t$CDS_st\t$CDS_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
			}
#### output decouple site
			if(exists $fp->{$Gene}{'decouple'})
			{
				$decple_site = $accum_len + $fp->{$Gene}{'decouple'};
				print NEOGFF "NeoChr\tGenovo\tdecouple\t$decple_site\t$decple_site\t.\t.\t.\tParent=$Gene;\n";
			}
#### output LoxP and 3'-UTR info
			print NEOGFF "NeoChr\tGenovo\t3UTR\t$three_UTR_start\t$three_UTR_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
			print NEOGFF "NeoChr\tGenovo\tloxp\t$loxp_st\t$loxp_end\t.\t$gene_direct\t.\tID=$loxp_name;Parent=$Gene;\n";
		}
		else
		{
#### output LoxP and 3'-UTR info
			print NEOGFF "NeoChr\tGenovo\t3UTR\t$three_UTR_start\t$three_UTR_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
			print NEOGFF "NeoChr\tGenovo\tloxp\t$loxp_st\t$loxp_end\t.\t$gene_direct\t.\tID=$loxp_name;Parent=$Gene;\n";
#### output mRNA annotation info
			print NEOGFF "NeoChr\tGenovo\tmRNA\t$mRNA_start\t$mRNA_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
#### output gene CDS info
#			my $element_num = scalar(@{$fp->{$Gene}{'CDS'}});
			for(my $i=0;$i<@{$fp->{$Gene}{'CDS'}};$i++)
			{
				my $CDS_st = $accum_len + $fp->{$Gene}{'CDS'}[$i][0];
				my $CDS_end = $accum_len + $fp->{$Gene}{'CDS'}[$i][1];
				print NEOGFF "NeoChr\tGenovo\tCDS\t$CDS_st\t$CDS_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
			}
#### output decouple site
			if(exists $fp->{$Gene}{'decouple'})
			{
				$decple_site = $accum_len + $fp->{$Gene}{'decouple'};
				print NEOGFF "NeoChr\tGenovo\tdecouple\t$decple_site\t$decple_site\t.\t.\t.\tParent=$Gene;\n";
			}
#### output 5UTR annotation info
			print NEOGFF "NeoChr\tGenovo\t5UTR\t$five_UTR_start\t$five_UTR_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
		}
		$accum_len += $gene_len;
#### output ARS
		if($count == $half-1)
		{
			my $ars_len = $Ars->{'ARS'}{'length'};
			my $ars_st = $accum_len + 1;
			my $ars_end = $accum_len + $ars_len;
			my $ars_name = $Ars->{'ARS'}{'name'};
			$gene_seq .= $Ars->{'ARS'}{'seq'};
			$accum_len += $ars_len;
			print NEOGFF "NeoChr\tGenovo\tARS\t$ars_st\t$ars_end\t.\t.\t.\tID=$ars_name;\n";
		}
#### output the centromere
		if($count == $half)
		{
			my $centromere_len = $Centro_mere->{'centromere'}{'length'};
			my $centromere_st = $accum_len + 1;
			my $centromere_end = $accum_len + $centromere_len;
			my $centromere_name = $Centro_mere->{'centromere'}{'name'};
			$gene_seq .= $Centro_mere->{'centromere'}{'seq'};
			print NEOGFF "NeoChr\tGenovo\tcentromere\t$centromere_st\t$centromere_end\t.\t+\t.\tID=$centromere_name;\n";
			$accum_len += $centromere_len;
		}
	}
#### add right telomere
	$gene_seq .= $Right_telom->{'telomere'}{'seq'};
	my $right_telomere_len = $Right_telom->{'telomere'}{'length'};
	my $right_telomere_st = $accum_len + 1;
	my $right_telomere_end = $accum_len + $right_telomere_len;
	my $right_telomere_name = $Right_telom->{'telomere'}{'name'};
	$accum_len += $right_telomere_len;
	print NEOGFF "NeoChr\tGenovo\tright_telomere\t$right_telomere_st\t$right_telomere_end\t.\t+\t.\tID=$right_telomere_name;\n";
#### format the fasta file, 60bp each line
	for (my $k=0; $k<length $gene_seq; $k+=100)
	{
		my $part=substr($gene_seq,$k,100);
		print NEOFA "$part\n";
	}
}
close NEOGFF;
close NEOFA;
