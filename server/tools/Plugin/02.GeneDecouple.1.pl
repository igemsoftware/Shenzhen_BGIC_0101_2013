#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Data::Dumper;

my ($species,$gene_order,$gene_flank_len,$geneset_dir,$fa_file,$gff_file,$help);
GetOptions(
	'species:s'=>			\$species,
	'gene_order:s'=>		\$gene_order,
	'extendlen:i'=>			\$gene_flank_len,
	'geneset_dir:s'=>		\$geneset_dir,
	'help'=>				\$help
);
$gene_flank_len||=100;
my (%sequence,%AnnoInfo,@GeneOrder);
my (%Order,%frag,%aa_table);
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

open ORDER, "$gene_order" or die("fail open $gene_order\n");
while(<ORDER>)
{
	my @Ord = split /\s+/, $_;
	$Order{$Ord[0]} = '+'; #### TODO, the strand can be recorded here.
}
close ORDER;
&Init_aa_code(\%codon_table,\%aa_table);
&ReadFasta($fa_file,\%sequence);
&ReadGff($gff_file,\%AnnoInfo);
#print Dumper(\%AnnoInfo);
&Extract_gene_fragment($fa_file, \%AnnoInfo, \%Order, \%frag, $gene_flank_len);
#print Dumper(\%frag);
&FindOverlap(\%AnnoInfo);
#&OverlapFinding(\%AnnoInfo,\%Order);


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
	my $Anninfo=shift;
	my $mark=0;
	foreach my $CHR(keys %$Anninfo)
	{
		my ($prev_gene_start,$prev_gene_end,$prev_gene_strand,$prev_gene)=('','','','');
		foreach my $GENE(sort {$AnnoInfo{$CHR}{$a}{mRNA} <=> $AnnoInfo{$CHR}{$b}{mRNA}}keys %{$AnnoInfo{$CHR}})
		{
#			print "$CHR\n"; 
#			print Dumper(\%{$AnnoInfo{$CHR}{$GENE}{mRNA}});
			my $current_gene=$GENE;
			my $current_gene_start=$AnnoInfo{$CHR}{$GENE}{mRNA}[0];
			my $current_gene_end=$AnnoInfo{$CHR}{$GENE}{mRNA}[1];
			my $current_gene_strand=$AnnoInfo{$CHR}{$GENE}{mRNA}[2];
#### init
			if($mark==0 && $prev_gene_start eq '' && $prev_gene_end eq '' && $prev_gene_strand eq '')
			{
				$prev_gene=$GENE;
				$prev_gene_start=$current_gene_start;
				$prev_gene_end=$current_gene_end;
				$prev_gene_strand=$current_gene_strand;
				$mark=1;
			}
#### current gene compares with previous gene
			elsif($mark==1 && $prev_gene_start ne '' && $prev_gene_end ne '' && $prev_gene_strand ne '')
			{
				if($current_gene_start>=$prev_gene_start && $current_gene_start<=$prev_gene_end)
				{
#### decouple
#					print "$current_gene,$current_gene_start,$current_gene_end,$current_gene_strand,$prev_gene,$prev_gene_start,$prev_gene_end,$prev_gene_strand\n";exit;
					&Decouple($CHR,$current_gene,$current_gene_start,$current_gene_end,$current_gene_strand,$prev_gene,$prev_gene_start,$prev_gene_end,$prev_gene_strand);
				}
#### current gene stored as previouse gene
				$prev_gene=$GENE;
				$prev_gene_start=$current_gene_start;
				$prev_gene_end=$current_gene_end;
				$prev_gene_strand=$current_gene_strand;
			}
		}
		$mark=0;
		($prev_gene_start,$prev_gene_end,$prev_gene_strand)=('','','');
	}
}
=head2 Decouple

#Function:decouple 2 overlap genes,synonymous substitution the site 
#Input:overlap gene1,overlap gene2

=cut

sub Decouple
{
	my $chrmsme=shift;

	my $overlap_gene1=shift;
	my $g1_start=shift;
	my $g1_end=shift;
	my $g1_direct=shift;

	my $overlap_gene2=shift;
	my $g2_start=shift;
	my $g2_end=shift;
	my $g2_direct=shift;

	my $replace_site;
	my $g1_seq=&ExtractSequnece($chrmsme,$g1_start,$g1_end,$g1_direct,\%sequence);
	my $g2_seq=&ExtractSequnece()
#	print "$g1_start\t$g1_end\t$g2_start\t$g2_end-----\n";exit;
	if($g1_start<$g2_start && $g1_end>$g2_end)# gene1 cover gene2 fully
	{
		if($g2_direct eq '+')
		{
			$replace_site=$g2_start-$g1_start+1;
			Codon_Substitution($chrmsme,$overlap_gene1,$replace_site);
		}
		else
		{
			$replace_site=$g1_end-$g2_end+1;
			Codon_Substitution($chrmsme,$overlap_gene1,$replace_site);
		}
	}
	elsif($g1_start>$g2_start && $g1_end<$g2_end)# gene2 cover gene1 fully
	{
		if($g1_direct eq '+')
		{
			$replace_site=$g1_start-$g2_start+1;
			Codon_Substitution($chrmsme,$overlap_gene2,$replace_site);
		}
		else
		{
			$replace_site=$g2_end-$g1_end+1;
			Codon_Substitution($chrmsme,$overlap_gene2,$replace_site);
		}
	}
	elsif($g1_end>$g2_end)
	{
#		print "-----\n";exit;
		if($g1_direct eq '+' && $g2_direct eq '-')
		{
#### syn subs gene1
			$replace_site=$g2_end-$g1_start+1;
			Codon_Substitution($chrmsme,$overlap_gene1,$replace_site);
#### syn subs gene2
			$replace_site=$g2_start-$g1_start+1;
			Codon_Substitution($chrmsme,$overlap_gene2,$replace_site);
		}
	}
}


sub Codon_Substitution
{
	my $ch=shift;
	my $gene=shift;
	my $start_postion=shift;
	my $phase_site=$start_postion%3;
	my ($codon,$syn_codon,$random_element);

	for(my $i=0;$i<@{$AnnoInfo{$ch}{$gene}{CDS}};$i++)
	{
		my $cds_start=1;
		my $cds_end=$AnnoInfo{$ch}{$gene}{CDS}[0][1]-$AnnoInfo{$ch}{$gene}{CDS}[0][0]+1;
### subs site is in the CDS region
		if($start_postion>=$cds_start && $start_postion<=$cds_end);
		my $phase_site=$start_postion%3;
		my ($codon,$syn_codon,$random_element);
		if($phase_site==0)
		{
			$codon=substr($info{$gene}{gene}[4],$start_postion-3,3);
		}
		elsif($phase_site==1)
		{
			$codon=substr($info{$gene}{gene}[4],$start_postion-1,3);
		}
		elsif($phase_site==2)
		{
			$codon=substr($info{$gene}{gene}[4],$start_postion-2,3);
		}
	}
	$random_element = int(rand @{$Codon{$codon_table{$codon}}});
	$syn_codon=$Codon{$codon_table{$codon}}[$random_element];
	until($syn_codon ne $codon)
	{
		$random_element = int(rand @{$Codon{$codon_table{$codon}}});
		$syn_codon=$Codon{$codon_table{$codon}}[$random_element];
	}

	my $len=length($info{$gene}{gene}[4]);
	my $before_codon=substr($info{$gene}{gene}[4],0,$start_postion-1);
	my $after_codon=substr($info{$gene}{gene}[4],$start_postion+2,$len-($start_postion+2)+1);
	$info{$gene}{gene}[4]=$before_codon."$syn_codon"."$after_codon";
#   print "$before_codon\t$codon\t$after_codon\n";
#   print "$before_codon\t$syn_codon\t$after_codon\n";
#   print "$info{$gene}{gene}[4]\n";exit;
}

=head2 ReadGff

#Function:Read the genome annotation file (.gff3) and store 
#Input:Gff3 file
#Output:3D hash: Chromosome_ID->gene_ID->feature->position

=cut
sub ReadGff
{
	my $Gff_file=shift;
	my $Info=shift;
	my $order=shift;
	open GFF,"$Gff_file" || die ("fail open $Gff_file\n");
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
#	print Dumper($Info);exit;
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
open IN, "<$gene_list_file" or die("Can't read file:$gene_list_file\n");
while(my $line=<IN>){
	my @info = split /\s+/, $line;
	$gene_list{$info[0]} = '+'; #### TODO, the strand can be recorded here.
}
close IN;
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
=head2 Extract_gene_fragment

	Info:Split the gene into 4 dimensional hash by per base
	Input:fasta_file,anno_hash,up/down_stream_extend_length
	Output:4 dimensional hash 

=cut
sub Extract_gene_fragment{
	my ($seq_file, $gene_info_p, $extract_list_p, $frag_p, $flank_len) = @_;

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
#		next if(!defined $gene_info_p->{$chr_id});
		my $seq = (split /\n/,$line,2)[1];
		$seq=~s/\s//g;
		my $seq_len = length $seq;

#print Dumper(\%{$gene_info_p->{$chr_id}});
		foreach my $geneid (keys %{$gene_info_p->{$chr_id}}) {
			next if(!defined $extract_list_p->{$geneid});
			my $genep = $gene_info_p->{$chr_id}{$geneid};
			my $fp = \%{$frag_p->{$geneid}};

			my ($gene_st, $gene_ed);
			if($genep->{'mRNA'}[2] eq '+'){
				$genep->{'5UTR'} = $genep->{'mRNA'}[0] - $flank_len < 1 ? $genep->{'mRNA'}[0] - 1 : $flank_len if(!defined $genep->{'5UTR'});
				$genep->{'3UTR'} = $genep->{'mRNA'}[1] + $flank_len > $seq_len ? $seq_len - $genep->{'mRNA'}[1] : $flank_len if(!defined $genep->{'3UTR'});
				$gene_st = $genep->{'mRNA'}[0] - $genep->{'5UTR'};
				$gene_ed = $genep->{'mRNA'}[1] + $genep->{'3UTR'};
			}else{
				$genep->{'5UTR'} = $genep->{'mRNA'}[1] + $flank_len > $seq_len ? $seq_len - $genep->{'mRNA'}[1] : $flank_len if(!defined $genep->{'5UTR'});
				$genep->{'3UTR'} = $genep->{'mRNA'}[0] - $flank_len < 1 ? $genep->{'mRNA'}[0] - 1 : $flank_len if(!defined $genep->{'3UTR'});
				$gene_st = $genep->{'mRNA'}[0] - $genep->{'3UTR'};
				$gene_ed = $genep->{'mRNA'}[1] + $genep->{'5UTR'};
			}
			$fp->{'seq'} = substr($seq, $gene_st, $gene_ed - $gene_st + 1);
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

########### Create positional annotated information
			map { $fp->{'pos'}{$_}{'type'} = '5UTR' } $fp->{'anno'}{'5UTR'}[0][0]..$fp->{'anno'}{'5UTR'}[0][1] ;
			map { $fp->{'pos'}{$_}{'type'} = '3UTR' } $fp->{'anno'}{'3UTR'}[0][0]..$fp->{'anno'}{'3UTR'}[0][1] ;
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

	Info:
	Input:
	Output: 

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

