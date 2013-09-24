#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Data::Dumper;

my ($delete_list,$neo_chr_fa,$neo_chr_gff,$slim_fa,$slim_gff,$help);
GetOptions(
	"delete_list:s"=>		\$delete_list,
	"neochr_fa:s"=>			\$neo_chr_fa,
	"neochr_gff:s"=>        \$neo_chr_gff,
	"slim_fa:s"=>			\$slim_fa,
	"slim_gff:s"=>			\$slim_gff,
	"help"=>                \$help
);
if(!$neo_chr_fa || !$neo_chr_gff || !$delete_list)
{
	print "perl $0 --delete=\"gene1,gene2\" --neochr_gff <final.chr> --neochr_fa <final.fa> --slim_fa <slim.fa> --slim_gff <slim.gff>\n";
	exit;
}

my (%AnnoInfo,@gene_order,%sequence,%frag);

ReadFasta($neo_chr_fa, \%sequence);
Read_Gff($neo_chr_gff, $delete_list, \%AnnoInfo, \%sequence, \@gene_order);
#print Dumper(\%AnnoInfo);exit;
Slim_Chr(\@gene_order, \%AnnoInfo, $slim_fa, $slim_gff);

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
	my $Delete=shift;
	my $Info=shift;
	my $Seq=shift;
	my $Gene_order=shift;

	my @Del=split /,/,$Delete;
	my %Del_gene;
	foreach my $g(@Del)
	{
		$Del_gene{$g}=1;
	}

	my ($five_UTR_end,$three_UTR_st,$three_UTR_end,$mRNA_st,$mRNA_end,$CDS_st,$CDS_end,$gene_st,$gene_end,$seq,$left_tel_st,$left_tel_end,$right_tel_st,$right_tel_end,$centr_st,$centr_end,$ars_st,$ars_end,$loxp_len);
	open GFF,"$Gff" || die "fail open $Gff";
	while(my $line = <GFF>)
	{
		my @info = split /\s+/, $line;
		my ($tmp, $gene_id) = $info[8]=~/^(ID|Parent)=([^;]+);?/;

#		$Gene_hash->{$gene_id}=$info[6];
#### Reverse if start > end
		@info[3,4] = @info[4,3] if($info[3] > $info[4]);
#		next if($info[3] >= $range_st && $info[4] <= $range_end && ($info[2] ne 'left_telomere' && $info[2] ne 'right_telomere' && $info[2] ne 'centromere' && $info[2] ne 'ARS'));
		next if(exists $Del_gene{$gene_id});
#		print $info[2];exit;
		if($info[2] eq 'left_telomere')
		{
#			print "$info[2]\n";exit;
			$left_tel_st = $info[3];
			$seq = ExtractSequnece($info[0], $info[3], $info[4], $info[6], $Seq);
			$left_tel_end = length $seq;
			$Info->{$info[0]}{'left_telomere'}{'info'} = [$gene_id,1,$left_tel_end,$info[6]];
			$Info->{$info[0]}{'left_telomere'}{'seq'} = $seq;
		}
		elsif($info[2] eq 'mRNA')
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
			$five_UTR_end = $info[4] - $gene_st + 1;
			@{$Info->{$info[0]}{$gene_id}{'5UTR'}} = [1,$five_UTR_end,$info[6]];  #### TODO, should we convert the origin gff to BGI style
		}
		elsif($info[2] eq 'three_prime_UTR_intron' || $info[2] eq"3'-UTR" || $info[2] eq '3UTR' )
		{
			$three_UTR_st = $info[3] - $gene_st + 1;
			@{$Info->{$info[0]}{$gene_id}{'3UTR'}} = [$three_UTR_st,$gene_end,$info[6]];
		}
		elsif($info[2] eq 'gene')
		{
			$gene_st = $info[3];
			$seq = ExtractSequnece($info[0], $info[3], $info[4], $info[6], $Seq);
			$gene_end = length $seq;
			$Info->{$info[0]}{$gene_id}{'gene'} = [1,$gene_end,$info[6]];
			$Info->{$info[0]}{$gene_id}{'seq'} = $seq;
		}
		elsif($info[2] eq 'right_telomere')
		{
			$right_tel_st = $info[3];
			$seq = ExtractSequnece($info[0], $info[3], $info[4], $info[6], $Seq);
			$right_tel_end = length $seq;
			$Info->{$info[0]}{'right_telomere'}{'info'} = [$gene_id,1,$right_tel_end,$info[6]];
			$Info->{$info[0]}{'right_telomere'}{'seq'} = $seq;
		}
		elsif($info[2] eq 'centromere')
		{
			$centr_st = $info[3];
			$seq = ExtractSequnece($info[0], $info[3], $info[4], $info[6], $Seq);
			$centr_end = length $seq;
			$Info->{$info[0]}{'centromere'}{'info'} = [$gene_id,1,$centr_end,$info[6]];
			$Info->{$info[0]}{'centromere'}{'seq'} = $seq;
		}
		elsif($info[2] eq 'ARS')
		{
			$ars_st = $info[3];
			$seq = ExtractSequnece($info[0], $info[3], $info[4], $info[6], $Seq);
			$ars_end = length $seq;
			$Info->{$info[0]}{'ars'}{'info'} = [$gene_id,1,$ars_end,$info[6]];
			$Info->{$info[0]}{'ars'}{'seq'} = $seq;
		}
		elsif($info[2] eq 'loxp')
		{
			$loxp_len = $info[4] - $info[3] + 1;
			$Info->{$info[0]}{'loxPsym'}{'len'} = $loxp_len;
			$Info->{$info[0]}{'loxPsym'}{'info'} = [$gene_id,$info[6]];
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


sub Slim_Chr
{
	my $Gen_Ord = shift;
	my $Annotation = shift;
	my $Slim_fa = shift;
	my $Slim_gff = shift;

	my ($accum_len, $count) = (0,0);
	my $gene_seq;
	open NEOGFF,">$Slim_gff" or die "can't open $Slim_gff";
	open NEOFA,">$Slim_fa" or die "can't open $Slim_fa";
	print NEOFA ">NeoChr\n";

	my $fp = $Annotation->{'NeoChr'};
#### Add left telomere
	$gene_seq .= $fp->{'left_telomere'}{'seq'};
	my $left_telomere_name = $fp->{'left_telomere'}{'info'}[0];
	my $left_telomere_len = $fp->{'left_telomere'}{'info'}[2];
	my $left_telomere_direct = $fp->{'left_telomere'}{'info'}[3];
#	push @{$fp->{'left_telomere'}},[1,$left_telomere_len,'+'];
	$accum_len += $left_telomere_len;
	print NEOGFF "NeoChr\tGenovo\tleft_telomere\t1\t$left_telomere_len\t.\t$left_telomere_direct\t.\tID=$left_telomere_name;\n";
#### generate new gff & fa
	my $half = int(scalar(@$Gen_Ord)/2);
#   print $half,"\n";exit;
	foreach my $Gene (@$Gen_Ord)
	{
#### output gene anntotaion info
		$count++;
		$gene_seq .= $fp->{$Gene}{'seq'};
		my $gene_len = length $fp->{$Gene}{'seq'};
		my $gene_start = $accum_len + 1;
		my $gene_end = $accum_len + $gene_len;
		my $gene_direct = $fp->{$Gene}{'gene'}[2];
		print NEOGFF "NeoChr\tGenovo\tgene\t$gene_start\t$gene_end\t.\t$gene_direct\t.\tID=$Gene;\n";
#### output 5UTR annotation info
		my $five_UTR_start = $accum_len + $fp->{$Gene}{'5UTR'}[0][0];
		my $five_UTR_end = $accum_len + $fp->{$Gene}{'5UTR'}[0][1];
		print NEOGFF "NeoChr\tGenovo\t5UTR\t$five_UTR_start\t$five_UTR_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
#### output mRNA annotation info
		my $mRNA_start = $accum_len + $fp->{$Gene}{'CDS'}[0][0];
		my $mRNA_end = $accum_len + $fp->{$Gene}{'CDS'}[-1][1];
		print NEOGFF "NeoChr\tGenovo\tmRNA\t$mRNA_start\t$mRNA_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
#### output gene CDS info
		for(my $i=0;$i<@{$fp->{$Gene}{'CDS'}};$i++)
		{
			my $CDS_st = $accum_len + $fp->{$Gene}{'CDS'}[$i][0];
			my $CDS_end = $accum_len + $fp->{$Gene}{'CDS'}[$i][1];
			print NEOGFF "NeoChr\tGenovo\tCDS\t$CDS_st\t$CDS_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
		}
#### output LoxP and 3'-UTR info
		my $three_UTR_start = $accum_len + $fp->{$Gene}{'3UTR'}[0][0];
		my $three_UTR_end = $accum_len + $fp->{$Gene}{'3UTR'}[0][1];
		my $loxp_st = $three_UTR_start + 3;
		my $loxp_end = $loxp_st + $fp->{'loxPsym'}{'len'};
		my $loxp_name = $fp->{'loxPsym'}{'info'}[0];
		my $loxp_direct = $fp->{'loxPsym'}{'info'}[1];
		print NEOGFF "NeoChr\tGenovo\tloxp\t$loxp_st\t$loxp_end\t.\t$loxp_direct\t.\tID=$loxp_name;Parent=$Gene;\n";
		$accum_len += $gene_len;
#### output ARS
		if($count == $half-1)
		{
			my $ars_len = $fp->{'ars'}{'info'}[2];
			my $ars_st = $accum_len + 1;
			my $ars_end = $accum_len + $ars_len;
			my $ars_name = $fp->{'ars'}{'info'}[3];
			$gene_seq .= $fp->{'ars'}{'seq'};
			$accum_len += $ars_len;
			print NEOGFF "NeoChr\tGenovo\tARS\t$ars_st\t$ars_end\t.\t.\t.\tID=$ars_name;\n";
		}
#### output the centromere
		if($count == $half)
		{
			my $centromere_len = $fp->{'centromere'}{'info'}[2];
			my $centromere_st = $accum_len + 1;
			my $centromere_end = $accum_len + $centromere_len;
			my $centromere_name = $fp->{'centromere'}{'info'}[0];
			my $centromere_direct = $fp->{'centromere'}{'info'}[3];
			$gene_seq .= $fp->{'centromere'}{'seq'};
			print NEOGFF "NeoChr\tGenovo\tcentromere\t$centromere_st\t$centromere_end\t.\t$centromere_end\t.\tID=$centromere_name;\n";
			$accum_len += $centromere_len;
		}
	}
#### add right telomere
	$gene_seq .= $fp->{'right_telomere'}{'seq'};
	my $right_telomere_len = $fp->{'right_telomere'}{'info'}[2];
	my $right_telomere_st = $accum_len + 1;
	my $right_telomere_end = $accum_len + $right_telomere_len;
	my $right_telomere_name = $fp->{'right_telomere'}{'info'}[0];
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
