#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my ($species,$pathway,$pathdir,$help);
GetOptions(
	'species:s'=>			\$species,
	'pathway:s'=>			\$pathway,
	'pathdir:s'=>			\$pathdir,
	'help'=>				\$help
);
if(!$species || !$pathway ||!$pathdir)
{
	print "perl $0 --species [species latin name] --pathway [path way] --pathdir [../pathway]\n";
	exit;
}
my (%gene);
my $keg_file="$pathdir/$species.keg";
GetGene($pathway,\%gene);

=head2 GetGene

  Info:  Extract the gene ID from the species.kegg file
  Input: species name,pathway name
  Output:gene ID(hash)

=cut

sub GetGene
{
	my $Pathway=shift;
	my $Gene=shift;
	my $mark=0;
	open PATHWAY,"$keg_file" or die "fail open $keg_file\n";
	while(<PATHWAY>)
	{
		chomp;
		next if($_=~/^[AB#!%]/);
		if($_=~/^C\s+\d+\s+(\S+)\s+/ && $mark==0)
		{
			if($Pathway=~/$1/)
			{
				$mark=1;	
			}
		}
		elsif($_=~/^D\s+(\S+)\s+\S+/ && $mark==1)
		{
			my $gene=$1;
			print $gene,"\n";
			$Gene->{$gene}=1;
		}
		elsif($_=~/^C\s+\d+\s+(\S+)/ && $mark==1)
		{
			last;
		}
	}
	close PATHWAY;
}

