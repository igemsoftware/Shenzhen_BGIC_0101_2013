#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use FindBin qw($Bin);
use lib $Bin;
use lib "$Bin/lib";
#use Math::Combinatorics;
use Data::Dumper;

my ($species,$gene_order,$gene_upstream_len,$gene_downstream_len,$geneset_dir,$fa_file,$gff_file,$neo_chr_fa,$neo_chr_gff,$list_format,$help);
my (@Ord,@tmp); 
GetOptions(
	'species:s'=>			\$species,
	'gene_order:s'=>		\$gene_order,
	'upstream_extend:i'=>	\$gene_upstream_len,
	'downstream_extend:i'=>	\$gene_downstream_len,
	'neo_chr_gff:s'=>		\$neo_chr_gff,
	'neo_chr_fa:s'=>		\$neo_chr_fa,
	'geneset_dir:s'=>		\$geneset_dir,
	'list_format:s'=>		\$list_format,
	'help'=>				\$help
);

$gene_upstream_len ||= 600;
$gene_downstream_len ||= 100;
if ($help || !$species ||!$gene_order ||!$geneset_dir ||!$neo_chr_gff ||!$neo_chr_fa)
{
	print STDERR "perl GeneDecouple.pl --species <species_name> --gene_order <gene_order_list> --geneset_dir <../gene_set> --upstream_extend <600> --downstream_extend <100> --neo_chr_gff <neochr.gff> --neo_chr_fa <neochr.fa>\n";
	exit;
}

#print $gene_order,"\n";exit;
my (%sequence,%AnnoInfo,@GeneOrder);
my (%Order,%frag,%aa_table,%syn_aa_base);
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

$gff_file="$geneset_dir/$species.gff";
$fa_file="$geneset_dir/$species.fa";

if($list_format eq 'string')
{
	@tmp = split /,/,$gene_order;
	foreach my $tmp(@tmp)
	{
		@Ord = split /\s+/,$tmp;
		$Order{$Ord[0]} = $Ord[1];
		push @GeneOrder,$Ord[0];
	}
}
elsif($list_format eq 'file')
{
	open ORDER, "$gene_order" or die("fail open $gene_order\n");
	while(<ORDER>)
	{
		@Ord = split /\s+/, $_;
		$Order{$Ord[0]} = $Ord[1];
		push @GeneOrder,$Ord[0];
	}
	close ORDER;
}

Init_aa_code(\%codon_table, \%aa_table);
Init_syn_code(\%codon_table, \%syn_aa_base);
#print Dumper(\%syn_aa_base);exit;
ReadFasta($fa_file, \%sequence);
ReadGff($gff_file, \%AnnoInfo);
#print Dumper(\%AnnoInfo);exit;
Extract_gene_fragment($fa_file, \%AnnoInfo, \%Order, \%frag, $gene_upstream_len,$gene_downstream_len);
#print Dumper(\%frag);exit;
FindOverlap(\%AnnoInfo);
Neo_Gff_Fasta(\@GeneOrder,\%frag,\%Order);

=head2 Init_aa_code

	Function:Init aa code 
	Input:codon table(hash)
	Output:aa->@(codon1,codon2)

=cut
sub Init_aa_code
{
	my ($cds_code_p, $aa_code_p) = @_;
	foreach my $e (sort keys %{$cds_code_p})
	{
		push @{$aa_code_p->{$cds_code_p->{$e}}}, $e;
	}
}

=head2 Init_syn_code

	Function:Init syn code 
	Input:codon table(hash)
	Output:syn->(codon)->(phase)

=cut
sub Init_syn_code {
	my ($cds_code_p, $syn_code_p) = @_;

	foreach my $code (keys %{$cds_code_p}) {
		for my $i (0..2) {
			foreach my $e (qw(A C G T)) {
				my $new_code = $code;
				substr($new_code, $i, 1) = $e;
				next if($new_code eq $code);
				push @{$syn_code_p->{$code}{$i}}, $e if($cds_code_p->{$code} eq $cds_code_p->{$new_code});
			}
		}
	}
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
=head2 ReadGff

	Function:Read the genome annotation file (.gff3) and store 
	Input:Gff3 file
	Output:3D hash: Chromosome_ID->gene_ID->feature->position

=cut
sub ReadGff
{
	my $Gff_file=shift;
	my $Info=shift;
	open GFF,"$Gff_file" || die ("fail open $Gff_file\n");
	while(my $line=<GFF>)
	{
		my @info = split /\s+/, $line;
		my ($tmp, $gene_id) = $info[8]=~/^(ID|Parent)=([^;]+);?/;

		next if(!exists $Order{$gene_id});
#### Reverse if start > end
		@info[3,4] = @info[4,3] if($info[3] > $info[4]);
		if($info[2] eq 'mRNA')
		{
			@{$Info->{$info[0]}{$gene_id}{'mRNA'}} = @info[3,4,6]; #### Start, end, strand
		}elsif($info[2] eq 'CDS')
		{
			push @{$Info->{$info[0]}{$gene_id}{'CDS'}}, [@info[3,4,7]];
		}
		elsif($info[2] eq 'five_prime_UTR_intron' || $info[2] eq "5'-UTR" || $info[2] eq '5UTR')
		{
			$Info->{$info[0]}{$gene_id}{'5UTR'} = 0;  #### TODO, should we convert the origin gff to BGI style
		}
	}
	close GFF;
#	print Dumper($Info);exit;
	return 1;
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
	my $Mark=0;
	my $SEQ;
	my @Decouple;
#	print Dumper(\%AnnoInfo);exit;
	foreach my $CHR(keys %AnnoInfo)
	{
		my ($init_gene,$init_gene_start,$init_gene_end,$init_gene_strand)=('','','','');
		foreach my $GENE(sort {$AnnoInfo{$CHR}{$a}{'mRNA'}[0] <=> $AnnoInfo{$CHR}{$b}{'mRNA'}[0]} keys %{$AnnoInfo{$CHR}})
		{
			my $current_gene = $GENE;
			my $current_gene_start = $AnnoInfo{$CHR}{$GENE}{'mRNA'}[0];
			my $current_gene_end = $AnnoInfo{$CHR}{$GENE}{'mRNA'}[1];
			my $current_gene_strand = $AnnoInfo{$CHR}{$GENE}{'mRNA'}[2];

			if($Mark==0 && $init_gene_start eq '' && $init_gene_end eq '' && $init_gene_strand eq '')
			{
#### store the first gene when in a new overlap gene finding
				$init_gene = $GENE;
				$init_gene_start = $current_gene_start;
				$init_gene_end = $current_gene_end;
				$init_gene_strand = $current_gene_strand;
				
				$Mark=1;
				push @Decouple,$init_gene;
			}
			elsif($Mark==1 && $init_gene_start ne '' && $init_gene_end ne '' && $init_gene_strand ne '')
			{
#### current gene has overlap with the init gene and both in the gene order list
				if($current_gene_start <= $init_gene_end)
				{
					push @Decouple,$current_gene;
				}
#### current gene has no overlap with the init and both in the gene order list
				elsif($current_gene_start>$init_gene_end)
				{
#### @decouple > 1 and excute decouple sub routine
					if(@Decouple > 1)
					{
						Decouple($CHR,\@Decouple,\%frag);
					}
#### @decouple < 2 
					$init_gene = $GENE;
					$init_gene_start = $current_gene_start;
					$init_gene_end = $current_gene_end;
					$init_gene_strand = $current_gene_strand;
					@Decouple = ();
					push @Decouple,$init_gene;
				}
			}
		}
		if(@Decouple > 1)
		{
			Decouple($CHR,\@Decouple,\%frag);
		}
		@Decouple = ();
		$Mark=0;
	}
}
=head2 Decouple

	Function:decouple 2 overlap genes,synonymous substitution the site 
	Input:chr_id,@decouple,%frag

=cut

sub Decouple
{
	my $chrmsme=shift;
	my $Decple=shift;
	my $frag_p=shift;

#	print Dumper($Decple);
#### list the combine of @Decouple array
	my @combine=Combine($Decple);
	for(my $i=0;$i<@combine;$i++)
	{
#		print "$combine[$i][0]\t$combine[$i][1]\n";
		my $gene1=$combine[$i][0];
		my $g1_start=$AnnoInfo{$chrmsme}{$gene1}{'mRNA'}[0];
		my $g1_end=$AnnoInfo{$chrmsme}{$gene1}{'mRNA'}[1];
		my $g1_direct=$AnnoInfo{$chrmsme}{$gene1}{'mRNA'}[2];

		my $gene2=$combine[$i][1];
		my $g2_start=$AnnoInfo{$chrmsme}{$gene2}{'mRNA'}[0];
		my $g2_end=$AnnoInfo{$chrmsme}{$gene2}{'mRNA'}[1];
		my $g2_direct=$AnnoInfo{$chrmsme}{$gene2}{'mRNA'}[2];

		my ($replace_site,$replace_base,$check);
		my $g1_seq=$frag_p->{$gene1}{'seq'};
		my $g2_seq=$frag_p->{$gene2}{'seq'};
#		print "$g1_seq\n$g2_seq\n";exit;
##### gene1 cover gene2 fully,only syn subs gene1
		if($g1_end>$g2_end)
		{
#			print "++++++$gene1\t$g1_start\t$g1_end\t$gene2\t$g2_start\t$g2_end\n";
			if($g2_direct eq '+')
			{
				$replace_site=$g2_start-$g1_start+$frag_p->{$gene1}{'anno'}{'5UTR'}[0][1];
				$replace_base=substr($g1_seq,$replace_site,1);
				$check=Synsubstitution_Check($gene1,$replace_site+1,\%frag,\%syn_aa_base);
			}
			else
			{
				$replace_site=$g1_end-$g2_end+$frag_p->{$gene1}{'anno'}{'5UTR'}[0][1];
				$replace_base=substr($g1_seq,$replace_site,1);
				$check=Synsubstitution_Check($gene1,$replace_site+1,\%frag,\%syn_aa_base);
			}
		}
#### gene1 partly cover gene2
		elsif($g1_end<=$g2_end)
		{
			if($g1_direct eq '-' && $g2_direct eq '+')
			{
#### syn subs gene1
				$replace_site=$g1_end - $g2_start + $frag_p->{$gene1}{'anno'}{'5UTR'}[0][1];
				$replace_base=substr($g1_seq,$replace_site,1);
				$check=Synsubstitution_Check($gene1,$replace_site+1,\%frag,\%syn_aa_base);
#				$check == 0 ? print "$gene1 and $gene2 can not decouple in the $replace_site\n" : print "$gene1 and $gene2 decoulpe successed in the $replace_site\n";
#### syn subs gene2
				$replace_site=$g1_end-$g2_start+$frag_p->{$gene2}{'anno'}{'5UTR'}[0][1];
				$replace_base=substr($g2_seq,$replace_site,1);
				$check=Synsubstitution_Check($gene2,$replace_site+1,\%frag,\%syn_aa_base);
			}
			elsif($g1_direct eq '+' && $g2_direct eq '+')
			{
#### syn subs gene1
				$replace_site=$g2_start-$g1_start+$frag_p->{$gene1}{'anno'}{'5UTR'}[0][1];
				$replace_base=substr($g1_seq,$replace_site,1);
				$check=Synsubstitution_Check($gene1,$replace_site+1,\%frag,\%syn_aa_base);
			}
			elsif($g1_direct eq '-' && $g2_direct eq '-')
			{
#### syn subs gene2
				$replace_site=$g2_end - $g1_end + $frag_p->{$gene2}{'anno'}{'5UTR'}[0][1];
				my $g2_len = length $g2_seq;
				$replace_base=substr($g2_seq,$replace_site,1);
				$check=Synsubstitution_Check($gene2,$replace_site+1,\%frag,\%syn_aa_base);
			}
		}
#		$check == 0 ? print "$gene1 and $gene2 can not decouple in the $replace_site\n" : print "$gene1 and $gene2 decoulpe successed in the $replace_site\n";
	}

}
=head2
	
	Info:output combinations of 2 according the array.
	Input:Decouple array.
	Output:new array of Combine of 2.

=cut

sub Combine
{
	my $Decouple_array = shift;
	my @Combine;
#	print Dumper(@$Decouple_array);exit;
	for(my $i = 0;$i <= @$Decouple_array;$i++)
	{
		my $element1 = shift @$Decouple_array;
		foreach(@$Decouple_array){
			my $element2 = $_;
			push @Combine,[$element1,$element2];
		}
	}
	return @Combine;
}


=head2 Synsubstitution_Check

	Info:check whether the site is can be decoupled
	Input:gene_id,site,frag(hash),syn_aa(hash)
	Output:0(can not be decoupled) or 1(decouple successed)

=cut

sub Synsubstitution_Check
{
	my ($geneid, $site, $frag_p, $syn_aa) = @_;
	return 0 if($frag_p->{$geneid}{'pos'}{$site}{'type'} =~ 'UTR');
	my $code = $frag_p->{$geneid}{'pos'}{$site}{'code'};
	my $phase = $frag_p->{$geneid}{'pos'}{$site}{'shift'};
	if(exists $syn_aa->{$code}{$phase} && @{$syn_aa->{$code}{$phase}} > 0)
	{
		Substitute_frag_base($geneid, $site, $syn_aa->{$code}{$phase}[0], \%frag);
	}
	else
	{
		return 0;
	}
	return 1;
}

=head2 Extract_gene_fragment

Info:Split the gene into 4 dimensional hash by per base
Input:fasta_file,anno_hash,up/down_stream_extend_length
Output:4 dimensional hash 

=cut
sub Substitute_frag_base
{
	my ($gene_id, $pos, $new_base, $frag_p, $test_only) = @_;

######### -1 means format error, the length of base > 1, or not exist such pos in gene.
	return -1 if(length $new_base != 1 or !defined $frag_p->{$gene_id}{'pos'}{$pos});
	my $fp = $frag_p->{$gene_id};
	my $pp = $frag_p->{$gene_id}{'pos'}{$pos};
######### 0 means this position can NOT be changed.
	return 0 if($pp->{'immutable'});

######### if just test, return 1 for changeable, but do nothing.
	if(!defined $test_only){
######### TODO, in some condition, this position should be changeable.
		$pp->{'immutable'} = 1; 

########## Record the origin base if no record before. (must be not record for V1)
		$pp->{'change'} = substr($fp->{'seq'}, $pos - 1, 1) if(!defined $pp->{'change'});

########## change the codon if the pos is in CDS.
		substr ($pp->{'code'}, $pp->{'shift'}, 1) = $new_base if($pp->{'type'} eq 'CDS');

########## modify the sequence of gene.
		substr ($frag_p->{$gene_id}{'seq'}, $pos - 1, 1) = $new_base;
	}
	return 1;
}

=head2 Extract_gene_fragment

	Info:Split the gene into 4 dimensional hash by per base
	Input:fasta_file,anno_hash,up/down_stream_extend_length
	Output:4 dimensional hash 

=cut
sub Extract_gene_fragment{
	my ($seq_file, $gene_info_p, $extract_list_p, $frag_p, $upstream_len, $downstream_len) = @_;

	if($seq_file=~/\.gz$/){
		open FA, "gzip -dc $seq_file |" or die("Can't read file with gzip:$seq_file\n");
	}else {
		open FA, "<$seq_file" or die("Can't read file:$seq_file\n");
	}
	$/='>';<FA>;
	while(my $line=<FA>)
	{
		chomp $line;
		my $chr_id=(split /\s+/,$line,2)[0];
		next if(!defined $gene_info_p->{$chr_id});
		my $seq = (split /\n/,$line,2)[1];
		$seq=~s/\s//g;
		my $seq_len = length $seq;

		foreach my $geneid (keys %{$gene_info_p->{$chr_id}})
		{
			next if(!defined $extract_list_p->{$geneid});
			my $genep = $gene_info_p->{$chr_id}{$geneid};
			my $fp = \%{$frag_p->{$geneid}};

			my ($gene_st, $gene_ed);
			if($genep->{'mRNA'}[2] eq '+'){
				$genep->{'5UTR'} = $genep->{'mRNA'}[0] - $upstream_len < 1 ? $genep->{'mRNA'}[0] - 1 : $upstream_len if(!defined $genep->{'5UTR'});
				$genep->{'3UTR'} = $genep->{'mRNA'}[1] + $downstream_len > $seq_len ? $seq_len - $genep->{'mRNA'}[1] : $downstream_len if(!defined $genep->{'3UTR'});
				$gene_st = $genep->{'mRNA'}[0] - $genep->{'5UTR'};
				$gene_ed = $genep->{'mRNA'}[1] + $genep->{'3UTR'};
			}else{
				$genep->{'5UTR'} = $genep->{'mRNA'}[1] + $upstream_len > $seq_len ? $seq_len - $genep->{'mRNA'}[1] : $upstream_len if(!defined $genep->{'5UTR'});
				$genep->{'3UTR'} = $genep->{'mRNA'}[0] - $downstream_len < 1 ? $genep->{'mRNA'}[0] - 1 : $downstream_len if(!defined $genep->{'3UTR'});
				$gene_st = $genep->{'mRNA'}[0] - $genep->{'3UTR'};
				$gene_ed = $genep->{'mRNA'}[1] + $genep->{'5UTR'};
			}
			$fp->{'seq'} = substr($seq, $gene_st - 1, $gene_ed - $gene_st + 1);
			$fp->{'strand'} = $genep->{'mRNA'}[2];
			$fp->{'len'} = length $fp->{'seq'};
			$fp->{'chr'} = $chr_id;
			push @{$fp->{'anno'}{'5UTR'}}, [1, $genep->{'5UTR'}];
			push @{$fp->{'anno'}{'3UTR'}}, [ $fp->{'len'} - $genep->{'3UTR'} + 1, $fp->{'len'}];
			$fp->{'seq'} = &Reverse_complement($fp->{'seq'}) if($fp->{'strand'} eq '-');
			foreach my $e (@{$genep->{'CDS'}}) {
				my @cds_pos = ($e->[0] - $gene_st + 1, $e->[1] - $gene_st + 1);

				if($fp->{'strand'} eq '-'){
					@cds_pos = ($gene_ed - $e->[1] + 1, $gene_ed - $e->[0] + 1);
				}
				push @{$fp->{'anno'}{'CDS'}}, \@cds_pos;
			}
			$fp->{'strand'} = '+';
			@{$fp->{'anno'}{'CDS'}} = sort { $a->[0] <=> $b->[0] } @{$fp->{'anno'}{'CDS'}};

#### Create positional annotated information
			map { $fp->{'pos'}{$_}{'type'} = '5UTR' } $fp->{'anno'}{'5UTR'}[0][0]..$fp->{'anno'}{'5UTR'}[0][1];
			map { $fp->{'pos'}{$_}{'type'} = '3UTR' } $fp->{'anno'}{'3UTR'}[0][0]..$fp->{'anno'}{'3UTR'}[0][1];
#### annotate CDS
			my $this_code = '';
			my @code_pos;
			foreach my $cds (@{$fp->{'anno'}{'CDS'}}) {
				for my $j ($cds->[0]..$cds->[1]) {

					$this_code.= substr($fp->{'seq'}, $j - 1, 1);
					push @code_pos, $j;
					if(@code_pos == 3){
						foreach my $k (0..$#code_pos) {
							$fp->{'pos'}{$code_pos[$k]}{'type'} = 'CDS';
							$fp->{'pos'}{$code_pos[$k]}{'code'} = $this_code;
							$fp->{'pos'}{$code_pos[$k]}{'aa'} = $codon_table{$this_code};
							$fp->{'pos'}{$code_pos[$k]}{'shift'} = $k;
						}
						$this_code = '';
						@code_pos = ();
					}
				}
			}
		}
	}
	$/="\n";
	close FA;
}

=head2 Reverse_complement

Info:complement reverse all base
Input:fasta_seq
Output: reverese complement fasta_seq

=cut
sub Reverse_complement
{
	my ($ori_seq) = @_;
####### TODO, Here can be optimized by tr/// method.
	for my $i (0..(length $ori_seq) - 1) {
		substr ($ori_seq, $i, 1) = $complement_base{substr ($ori_seq, $i, 1)};
	}
	return reverse $ori_seq;
}

=head2 NewGff

Info:generate the new chr gff according the gene order and frag(hash)
Input:gene_order(array),frag(hash)
Output:gff file

=cut
sub Neo_Gff_Fasta
{
	my ($GeneOrder, $frag_p, $Ord) = @_;
	my $accum_len = 0;
	my $gene_seq;

	open NEOGFF,">$neo_chr_gff" or die "can't open $neo_chr_gff";
	open NEOFA,">$neo_chr_fa" or die "can't open $neo_chr_fa";
	print NEOFA ">NeoChr\n";

	foreach my $Gene (@$GeneOrder)
	{
		my $fp=$frag_p->{$Gene};
		my $gene_direct = $Ord->{$Gene};
		if($gene_direct eq '+')
		{
			$gene_seq .= $fp->{'seq'};
		}else
		{
			my $reverse_seq = Reverse_complement($fp->{'seq'});
			$gene_seq .= $reverse_seq;
		}
		my $gene_len=$fp->{'len'};
		my $gene_start=$accum_len+1;
		my $gene_end=$accum_len+$gene_len;

		my $five_UTR_end=$accum_len+$fp->{'anno'}{'5UTR'}[0][1];
		my $three_UTR_start=$accum_len+$fp->{'anno'}{'3UTR'}[0][0];
		my $three_UTR_end=$accum_len+$fp->{'anno'}{'3UTR'}[0][1];

		my $mRNA_start=$accum_len+$fp->{'anno'}{'CDS'}[0][0];
		my $mRNA_end=$accum_len+$fp->{'anno'}{'CDS'}[-1][1];

#		chr1    SGD     gene    335     649     .       +       .       ID=YAL069W;Name=YAL069W;
#### output gene annotation info
		print NEOGFF "NeoChr\tGenovo\tgene\t$gene_start\t$gene_end\t.\t$gene_direct\t.\tID=$Gene;\n";
#### output gene 5'-UTR info
		print NEOGFF "NeoChr\tGenovo\t5UTR\t$gene_start\t$five_UTR_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
#### output gene mRNA info
		print NEOGFF "NeoChr\tGenovo\tmRNA\t$mRNA_start\t$mRNA_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
#### output gene CDS info
		for(my $i=0;$i<@{$fp->{'anno'}{'CDS'}};$i++)
		{
			my $CDS_st=$accum_len+$fp->{'anno'}{'CDS'}[$i][0];
			my $CDS_end=$accum_len+$fp->{'anno'}{'CDS'}[$i][1];
			print NEOGFF"NeoChr\tGenovo\tCDS\t$CDS_st\t$CDS_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
		}
#### output gene 3'-UTR info
		print NEOGFF "NeoChr\tGenovo\t3UTR\t$three_UTR_start\t$three_UTR_end\t.\t$gene_direct\t.\tParent=$Gene;\n";
		$accum_len+=$fp->{'len'};
	}
	for (my $k=0; $k<length $gene_seq; $k+=100)
	{
		my $part=substr($gene_seq,$k,100);
		print NEOFA "$part\n";
	}
	close NEOFA;
	close NEOGFF;
}
