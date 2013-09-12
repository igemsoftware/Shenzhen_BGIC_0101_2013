#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Data::Dumper;

my ($species,$gene_order,$genome,$gff,$cds,$geneset_dir,$help);
GetOptions(
	"species:s"=>			\$species,
	"gene_order:s"=>		\$gene_order,
	"genome:s"=>			\$genome,
	"gff:s"=>				\$gff,
	"cds:s"=>				\$cds,
	"geneset_dir:s"=>		\$geneset_dir,
	"help"=>				\$help
);
my (%sequence,%AnnoInfo,@GeneOrder);
my (%Order);
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
&ReadFasta(\%sequence);
#&Read_Gff(\%AnnoInfo,\%Order);
&ReadGff(\%AnnoInfo);
foreach my $CHR(keys %AnnoInfo)
{
#	print "$CHR\n";
#	print Dumper(\%{$AnnoInfo{$CHR}});exit;
	foreach my $GENE(sort {$AnnoInfo{$CHR}{$a}{mRNA} <=> $AnnoInfo{$CHR}{$b}{mRNA}}keys %{$AnnoInfo{$CHR}})
	{
		print "$CHR\t$GENE\t$AnnoInfo{$CHR}{$GENE}{mRNA}[0]\t$AnnoInfo{$CHR}{$GENE}{mRNA}[1]\n";
	}
}
&OverlapFinding(\%AnnoInfo,\%Order);

=head2 ReadFasta

	Function:Read the genome fasta file and store sequence 
	Input:Genome fasta file
	Output:Chromosome_ID -> sequence(hash)

=cut
sub ReadFasta
{
	my $Fa=shift;
	open FASTA,"$geneset_dir/$species.fa" or die ("fail open $geneset_dir/$species.fa\n");
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


=head2 ExtractSequnece

	Function:Extract the sequence according to the 
	Input:chr,start site,ending site,strand
	Output:chr->sequence(hash)

=cut
sub ExtractSequnece
{
	my $chr_id=shift;
	my $start_site=shift;
	my $end_site=shift;
	my $Strand=shift;
	my $Fa=shift;
	my $Sequence;
	$Sequence=substr($Fa->{$chr_id},$start_site-1,$end_site-$start_site+1);
	if($Strand eq '-')
	{
		$Sequence=reverse($Sequence);
		$Sequence=~tr/ATCGatcg/TAGCtagc/;
	}
	return $Sequence;
}

=head2 FindOverlap

	Function:Detect the overlap genes
	Input:Gff hash,gene order in each chr
	Output:decoupled gff file(data structure)

=cut
sub FindOverlap
{
	my $ifo=shift;
	my $ord=shift;
	my $begin=0;
	foreach my $Chr(keys %$ord)
	{
		for(my $i=$begin;$i<@{$ord->{$Chr}}-1;$i++)
		{
			my $init_gene=$ord->{$Chr}[$i];
			my $init_direction=$ifo->{$init_gene}{mRNA}[1];
			my $init_start=$ifo->{$init_gene}{mRNA}[2];
			my $init_end=$ifo->{$init_gene}{mRNA}[3];

			my $current_gene=$ord->{$Chr}[$i+1];
			my $current_direction=$ifo->{$current_gene}{mRNA}[1];
			my $current_start=$ifo->{$current_gene}{mRNA}[2];
			my $current_end=$ifo->{$current_gene}{mRNA}[3];
			if($current_start<$init_end && $current_start>$init_start)
			{
				Decouple($init_gene,$current_gene,$current_direction,$current_start,$current_end,$init_direction,$init_start,$init_end);
			}
		}
	}
}

=head2 OverlapFinding

	Function:Detect the overlap genes
	Input:species name,gff file,genome fasta file
	Output:decoupled gff file(data structure)

=cut
sub OverlapFinding
{
	my $Species=shift;
	my $Gene_order=shift;
	my %gene;
	open ORDER,"$Gene_order" or die "can't open $Gene_order";
	while(<ORDER>)
	{
		chomp;
		$gene{$_}=1;
	}
	close ORDER;

	open GFF,"$geneset_dir/$Species.gff" or die "can't open $geneset_dir/$Species.gff";
	while(<GFF>)
	{
		chomp;
		my @array=split /\s+/;
		next if(($array[2] ne 'CDS') &&  ($array[2] ne 'mRNA'));
		$array[8]=~/=([^;]+)/;
		if(exists $gene{$1})
		{
			print $_,"\n";
		}
	}
	close GFF;
}
sub ReadGff 
{
	my $Info=shift;
	my $order=shift;
	open GFF,"$geneset_dir/$species.gff" || die ("fail open $geneset_dir/$species.gff\n");
	while(my $line=<GFF>)
	{
		my @info = split /\s+/, $line;
		my ($tmp, $gene_id) = $info[8]=~/^(ID|Parent)=([^;]+);?/;

		@info[3,4] = @info[4,3] if($info[3] > $info[4]);  #### Reverse if start > end
		if($info[2] eq 'mRNA')
		{
			@{$Info->{$info[0]}{$gene_id}{'mRNA'}} = @info[3,4,6]; #### Start, end, strand
		}elsif($info[2] eq 'CDS')
		{
			push @{$Info->{$info[0]}{$gene_id}{'CDS'}}, [@info[3,4]];
		}elsif($info[2] eq 'five_prime_UTR_intron' || $info[2] eq '5\'-UTR'){
			$Info->{$info[0]}{$gene_id}{'5UTR'} = 0;  #### TODO, should we convert the origin gff to BGI style
		}
	}
	close GFF;

	return 1;
}
 #=head2 Read_Gff

#Function:Read the genome annotation file (.gff3) and store 
#Input:Gff3 file
#Output:Chromosome_ID -> sequence(hash)

=cut
sub Read_Gff
{
	my $Info=shift;
	my $order=shift;
	open GFF,"$geneset_dir/$species.gff" || die ("fail open $geneset_dir/$species.gff\n");
	while(<GFF>)
	{
		chomp;
		my @aa=split /\s+/;
		next if($aa[2] eq 'chromosome');
		$aa[8]=~/[ID|parent]=([^;]+)/;
		my $gene_id=$1;
		my ($chr,$source,$feature,$start,$end,$score,$strand,$frame)=($aa[0],$aa[1],$aa[2],$aa[3],$aa[4],$aa[5],$aa[6],$aa[7]);
		($start,$end)=($end,$start) if($start>$end);
		my $gene_seq=ExtractSequnece($chr,$start,$end,$strand,\%fa);
		push @{$Info->{$gene_id}{$feature}},($chr,$strand,$start,$end,$gene_seq);
		if($feature eq 'mRNA' && !exists $record{$chr."$gene_id"})
		{
			push @{$order{$chr}},$gene_id;
			$record{$chr."$gene_id"}=1;
		}
	}
	close GFF;
}
