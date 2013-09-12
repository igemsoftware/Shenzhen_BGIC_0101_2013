#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my ($speices,$telomere,$centromere,$replication,$gene_order,$gene_sequence,$random,$help);
GetOptions(
	"telomere:s" =>			\$telomere,
	"centromere:s"=>		\$centromere,
	"replicate_origin:s"=>	\$replication,
	"gene_order:s"=>		\$gene_order,
	"gene_sequence:s"=>		\$gene_sequence,
	"help"=>				\$help
);
my (%sequence);
StoreSequence($gene_order,$gene_sequence,%sequence);
NeoChromosome($telomere,$centromere,$replication,$gene_order,%sequence);
NeoGff();

## Init gene sequece hash
##
sub StoreSequence
{
	my $gene_list=shift;
	my $gene_fasta=shift;
	my $seq=shift;
	open LIST,"$gene_list" or die $!;
	while(<LIST>)
	{
		chomp;
		next if($_=~/^part/);
		$seq->{$_}=1;
	}
	close LIST;
	
	open FASTA,"$gene_fasta" or die $!;
	$/=">";
	<FASTA>;
	while(<FASTA>)
	{
		chomp;
		my $gene_id=(split /\n/,$_,2)[0];
		$gene_id=(split /\s+/,$gene_id)[0];
		my $gene_seq=(split /\n/,$_,2)[1];
		$seq->{$gene_id}=$gene_seq if(exists $seq->{$gene_id});
	}
	$/="\n";
	close FASTA;
}

## New chromosome construction
## New chromosome struction:
## telomere+gene+ARS+gene+centromere+gene+ARS+gene+telomere
sub NeoChromosome
{
	my $tel=shift;
	my $cent=shift;
	my $rep=shift;
	my $genord=shift;
	my $genseq=shift;
## Join the 1st telomere
	my $chr.=$tel;
	open LIST,"$genord" or die $!;
	while(<LIST>)
	{
		chomp;
		if($_=~/^part/ && )
	}
}
