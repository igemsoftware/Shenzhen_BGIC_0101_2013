#!/bin/env perl -w
use strict;
use Getopt::Long;
#use File::Basename;
use Data::Dumper;
sub usage{
    print STDERR <<USAGE;
    ################################################
            Version 1.0 by Wing-L   2013.05.29

      Usage: $0 <fa_file> >STDOUT

    ################################################
USAGE
    exit;
}

my ($step);
my ($crispr_kmer_lib, $species_name );
my ($enzyme_file);
my ($gene_gff_file, $gene_list_file, $gene_flank_len);
my ($crispr_design_number);
my ($codon_optimize_file, $optimize_gene_list, $optimize_all_gene);
my ($deleteintron);
my ($output_fasta, $output_gff);

GetOptions(
  "kmerlib=s"=>\$crispr_kmer_lib,
  "species=s"=>\$species_name,
  "step=i"=>\$step,
  "enzymelib=s"=>\$enzyme_file,
  "genegff=s"=>\$gene_gff_file,
  "genelist=s"=>\$gene_list_file,
  "flanklen=i"=>\$gene_flank_len,
  "crisprnum=i"=>\$crispr_design_number,
  "codonoptimize=s"=>\$codon_optimize_file,
  "optimizegenelist=s"=>\$optimize_gene_list,
  "optizeallgene"=>\$optimize_all_gene,
  "deleteintron"=>\$deleteintron,
  "outfasta=s"=>\$output_fasta,
  "outgff=s"=>\$output_gff,
#   ""=>\,
);

&usage if(@ARGV !=1);
my ($fa_file)=@ARGV;

############# global variable
my $data_path = `pwd`;
chomp $data_path;



$species_name ||= 'yeast';
$crispr_kmer_lib ||= "$species_name.kmer12.lib";
$gene_flank_len ||= 600;
$crispr_design_number ||= 2;
$step ||= 234;


my %base_list = (
    'M' => '[AC]',
    'R' => '[AG]',
    'W' => '[AT]',
    'S' => '[CG]',
    'Y' => '[CT]',
    'K' => '[GT]',
    'V' => '[ACG]',
    'H' => '[ACT]',
    'D' => '[AGT]',
    'B' => '[CGT]',
    'N' => '[ACGT]',
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

my %int_base = (
    0 => 'A',
    1 => 'C',
    2 => 'G',
    3 => 'T',
);

my %cds_code = (
    'GCA' => 'A', 'GCC' => 'A', 'GCG' => 'A', 'GCT' => 'A',                               # Alanine
    'TGC' => 'C', 'TGT' => 'C',                                                           # Cysteine
    'GAC' => 'D', 'GAT' => 'D',                                                           # Aspartic Acid
    'GAA' => 'E', 'GAG' => 'E',                                                           # Glutamic Acid
    'TTC' => 'F', 'TTT' => 'F',                                                           # Phenylalanine
    'GGA' => 'G', 'GGC' => 'G', 'GGG' => 'G', 'GGT' => 'G',                               # Glycine
    'CAC' => 'H', 'CAT' => 'H',                                                           # Histidine
    'ATA' => 'I', 'ATC' => 'I', 'ATT' => 'I',                                             # Isoleucine
    'AAA' => 'K', 'AAG' => 'K',                                                           # Lysine
    'CTA' => 'L', 'CTC' => 'L', 'CTG' => 'L', 'CTT' => 'L', 'TTA' => 'L', 'TTG' => 'L',   # Leucine
    'ATG' => 'M',                                                                         # Methionine
    'AAC' => 'N', 'AAT' => 'N',                                                           # Asparagine
    'CCA' => 'P', 'CCC' => 'P', 'CCG' => 'P', 'CCT' => 'P',                               # Proline
    'CAA' => 'Q', 'CAG' => 'Q',                                                           # Glutamine
    'CGA' => 'R', 'CGC' => 'R', 'CGG' => 'R', 'CGT' => 'R', 'AGA' => 'R', 'AGG' => 'R',   # Arginine
    'TCA' => 'S', 'TCC' => 'S', 'TCG' => 'S', 'TCT' => 'S', 'AGC' => 'S', 'AGT' => 'S',   # Serine
    'ACA' => 'T', 'ACC' => 'T', 'ACG' => 'T', 'ACT' => 'T',                               # Threonine
    'GTA' => 'V', 'GTC' => 'V', 'GTG' => 'V', 'GTT' => 'V',                               # Valine
    'TGG' => 'W',                                                                         # Tryptophan
    'TAC' => 'Y', 'TAT' => 'Y',                                                           # Tyrosine
    'TAA' => 'U', 'TAG' => 'U', 'TGA' => 'U'                                              # Stop
);

my %aa_code;
my %syn_code;
my %kmer_lib;
my %gene_list;
my %gene_info;
my %frag;
my %crispr_lib;
my %codon_score;

############################  BEGIN MAIN  ############################

&Init_aa_code(\%cds_code, \%aa_code);
&Init_syn_code(\%cds_code, \%syn_code);
&Init_optimize_syn_code($codon_optimize_file, \%codon_score) if($codon_optimize_file);


if($step=~/1/){
    ########## Create a library of kmer12, or read kmer from library
    &Constructe_kmer_library($fa_file, $crispr_kmer_lib, 12) unless(-e $crispr_kmer_lib); ### this version only build kmer12 library
    &Init_kmer_library($crispr_kmer_lib, \%kmer_lib);
}

if($step=~/2/){
    ########## Constructe gene fragment

    ##### Read gene list
    open IN, "<$gene_list_file" or die("Can't read file:$gene_list_file\n");
    my $gene_count = 1;
    while(my $line=<IN>){
        my @info = split /\s+/, $line;
        $gene_list{$info[0]}{'strand'} = defined $info[1] ? $info[1] : '+';
        $gene_list{$info[0]}{'order'} = $gene_count;
        $gene_count++;
    }
    close IN;

    ##### Read gff file
    &Read_gene_gff($gene_gff_file, \%gene_info);

    ##### Create data structure
    #$seq_file, $gene_info_p, $extract_list_p, $frag_p, $flank_len
    &Extract_gene_fragment($fa_file, \%gene_info, \%gene_list, \%frag, $gene_flank_len);
    # print Dumper(\%frag);
}

if($step=~/3/){
    ########## Search and modify CRISPR site
    foreach my $gene (keys %frag) {
        my $fin_design_number = &Design_crispr_seq($gene, \%frag, \%kmer_lib, $crispr_design_number, \%crispr_lib);
        print "$gene\t$fin_design_number\n";
    }
}

$| = 1;
my @enzyme_regexp;
my %exist_enzyme;
my $regexp;
######## delete enzyme
if($step=~/4/){
    open ENZ, "<$enzyme_file" or die("Can't read file:$enzyme_file\n");
    while(my $line=<ENZ>){
        next if($line=~/^#/);
        my @info = split /\s+/, $line;
        #### EcoRI  GAATTC
        $info[2]=~s/[^ACGTMRWSYKVHDBN]//g;
        
        ####### Supplier  Restriction Endonucleases  Recognition Site  3' base Size(U) Price(RMB)  RMB/U  Incubation Temperature(?)  Buffer  purchased
        ####### eg. NEB     BamHI   G/GATCC G       5000    219     0.04    37      3+BSA   1
        &Create_enzyme_regexp($info[1], $info[2], \%base_list, \%exist_enzyme, \@enzyme_regexp);

        # my $recom_enzyme = &Reverse_complement($info[1], \%complement_base);
        # &Create_enzyme_regexp($info[0], $recom_enzyme, \%base_list, \%exist_enzyme, \@enzyme_regexp);
    }
    close ENZ;

    ####### initialize the regular expression
    $regexp = join '|', @enzyme_regexp;
    $regexp = qr/$regexp/i;

    foreach my $e (keys %gene_list) {
        my @change_result;
        my $all_is_changed = 1;
        foreach my $cds (@{$frag{$e}{'anno'}{'CDS'}}) {
            #$gene_id, $frag_p, $regexp_p, $exist_enzyme_p, $start_pos, $end_pos, $test_only
            $all_is_changed = 0 if (&Find_enzyme_and_substitute($e, \%frag, \$regexp, \%exist_enzyme, $cds->[0], $cds->[1]) != 1);
        }
        if($all_is_changed == 0){
            print STDERR "delete enzyme fail, $e:\n";
        }
    }
}


######## Create new enzyme of RFC32
if($step=~/5/){
    my %change_method;
    &Init_enzyme_design_library($enzyme_file, \%change_method);
    foreach my $e (keys %gene_list) {
        foreach my $cds (@{$frag{$e}{'anno'}{'CDS'}}) {
            &Create_new_enzyme_site_exon($e, \%frag, $cds->[0], $cds->[1], 'EcoRI', \%change_method);
        }
        # print "$e\n";print Dumper($frag{$e}{'anno'});exit;
    }
}


if($step=~/6/){
    my @opt_gene_list;
    if(defined $optimize_gene_list){
        open IN, "<$optimize_gene_list" or die("Can't read file:$optimize_gene_list\n");
        while(my $line=<IN>){
            my @info = split /\s+/, $line;
            push @opt_gene_list, $info[0];
        }
        close IN;
    }else{
        @opt_gene_list = keys %gene_list;
    }
    &Optimize_selected_gene(\@opt_gene_list, \%frag, \%codon_score);
}

if($step=~/7/){
    foreach my $g (keys %gene_list) {
        foreach my $cds (@{$frag{$g}{'anno'}{'CDS'}}) {
            &Break_tandem_base($g, \%frag, $cds->[0], $cds->[1], 5);
        }
    }
}

&Create_fasta_and_gff(\%gene_list, \%frag, $output_fasta, $output_gff);

############################   END  MAIN  ############################

########################################################################################################
##################################      Sub function for crispr      ##################################
########################################################################################################
#############################
#
#     Constructe_uniq_seq_library
#
#  description
#
#############################
sub Constructe_kmer_library {
    my ($input_fa, $output_lib, $kmer_len) = @_;
    my %kmer_list;

    open OUT, ">", "$output_lib" or die("Can't write file:$output_lib\n");
    
    if($input_fa=~/\.gz$/){
        open FA, "gzip -dc $input_fa |" or die("Can't read file with gzip:$input_fa\n");
    }else {
        open FA, "<$input_fa" or die("Can't read file:$input_fa\n");
    }
    $/='>';<FA>;$/="\n";
    while(my $line=<FA>){
        $/='>';
        my $seq=<FA>;
        chomp $seq;
        $/="\n";
        $seq=~s/\s//g;
        for my $i (0..(length $seq) - $kmer_len) {
            $kmer_list{substr ($seq, $i, $kmer_len)}++;
        }
    }
    close FA;

    foreach my $e (keys %kmer_list) {
        print OUT $e."\n" if($kmer_list{$e} == 1);
    }

    close OUT;
}

#############################
#
#     Init_library
#
#  description
#
#############################
sub Init_kmer_library {
    my ($input_lib, $kmer_hash_p) = @_;
    if($input_lib=~/\.gz$/){
        open IN, "gzip -dc $input_lib |" or die("Can't read file with gzip:$input_lib\n");
    }else {
        open IN, "<$input_lib" or die("Can't read file:$input_lib\n");
    }
    while(my $line=<IN>){
        chomp $line;
        $kmer_hash_p->{$line} = 1;
    }
    close IN;
    return 1;
}

#############################
#
#     Design_crispr_seq
#
#  description
#
#############################
sub Design_crispr_seq {
    ###### [0]id of gene  [1]ref of %frag  [2]ref of 12-mer library  [3]number want to design  [4]empty %hash for record the crispr site
    my ($gene_id, $frag_p, $kmer_lib_p, $design_number, $crispr_lib_p ) = @_;

    my $fp = $frag_p->{$gene_id};
    my $fin_number = 0;
    foreach my $e (@{$fp->{'anno'}{'CDS'}}) { ### loop every cds to find crispr site
        my $cds_seq = substr($fp->{'seq'}, $e->[0] - 1, $e->[1] - $e->[0] + 1); ## get the cds sequence of selected
        ######### crispr structure:  G NNNNNNN NNNNNNNNNNNN NGG
        #########                             {     12     }
        #########        this 12 bp should be uniq in target genome
        #########  So use regexp to search the basic structure, then check whether uniq of 12bp sequence by 12-mer library.
        #########  steply tried a synonymous substitution in selected locus.
        #########  Finally, modify the gene sequence, record crispr site, mark the change in data structure
        while($cds_seq=~/G.{20}GG/ig){
            my $crispr_st = $-[0];
            my $crispr_seq = $&;
            my $uniq_seq = substr ($crispr_seq, 8, 12); ## the first uniq base is 8 in crispr sequence

            ####### Check uniq in origin genome
            next if(!defined $kmer_lib_p->{$uniq_seq}); ## library record all uniq sequence, undefined means the sequence is not uniq

            ####### Change one base to disable cutting
            ####### loop all bases in uniq sequence
            SUBSTITUTE:for my $i (8..19) {
                my $this_pos = $e->[0] + $crispr_st + $i; ## acutally pos, use $this_pos - 1 for substitution
                my $this_code = $fp->{'pos'}{$this_pos}{'code'};
                my $this_shift = $fp->{'pos'}{$this_pos}{'shift'};

                ####### next if this code can not be changed.
                ####### if the codon of selected locus has a synonymous type, it should exist in %syn_code
                next if($fp->{'pos'}{$this_pos}{'immutable'} or !defined $syn_code{$this_code} or !defined $syn_code{$this_code}{$this_shift});
                ####### Test every change unitl no conflict with other crispr uniq sequence
                foreach my $cb (@{$syn_code{$this_code}{$this_shift}}) {
                    my $syn_seq = $crispr_seq;
                    substr($syn_seq, $i, 1) = $cb;
                    ###### Test in crispr hash, if the new sequence is uniq in target genome, delete it. 
                    if(!defined $crispr_lib_p->{$syn_seq}){
                        delete $kmer_lib_p->{substr($syn_seq, 8, 12)} if(defined $kmer_lib_p->{substr($syn_seq, 8, 12)});
                        $fin_number++; ## Cheer~! we find a probable site of crispr

                        ######## @crispr:  start_pos, crispr_seq, uniq_seq_start, uniq_seq,  modify_pos , changed_base
                        push @{$fp->{'anno'}{'crispr'}}, [$crispr_st + $e->[0], $crispr_seq, $i + 1, $syn_seq, $this_pos, $cb];
                        @{$crispr_lib_p->{$syn_seq}} = ($gene_id, $crispr_st, $i + 1, $crispr_seq, $syn_seq); ## another record

                        &Substitute_frag_base($gene_id, $this_pos, $cb, $frag_p);
                        &Lock_position($gene_id, $frag_p, $e->[0] + $crispr_st, $e->[0] + $crispr_st + 22);

                        # $fp->{'pos'}{$this_pos}{'change'} = substr($fp->{'seq'}, $this_pos - 1, 1); ## recode the ORIGIN base
                        # substr($fp->{'seq'}, $this_pos - 1, 1) = $cb; ## modify synthestic gene to advoid cutting
                        # map { $fp->{'pos'}{$this_pos}{'immutable'} = 1 } ($e->[0] + $crispr_st)..($e->[0] + $crispr_st + 22) ; ## set all crispr site to immutable
                        return $fin_number if($fin_number >= $design_number); ## reutun the crispr number if match requirement
                        last SUBSTITUTE;
                    }
                }
            }
        }
    }
    return $fin_number; ## return fin_number anyway...
}


##############################################################################################################
##################################      Sub function for gene fragment      ##################################
##############################################################################################################
#############################
#
#     Read_gene_gff
#
#  description
#
#############################
sub Read_gene_gff {
    my ($gff_file, $gene_info_p) = @_;

    ######## Example
    # chr2    SGD     gene    45645   46370   .       +       .       ID=YBL092W;
    # chr2    SGD     CDS     45978   46370   .       +       0       Parent=YBL092W;
    # chr2    SGD     five_prime_UTR_intron   45645   45977   .       +       .       Parent=YBL092W;
    # chr2    SGD     mRNA    45645   46370   .       +       .       ID=YBL092W;

    open IN, "<$gff_file" or die("Can't read file:$gff_file\n");
    while(my $line=<IN>){
        my @info = split /\s+/, $line;
        my ($tmp, $gene_id) = $info[8]=~/^(ID|Parent)=([^;]+);?/;

        @info[3,4] = @info[4,3] if($info[3] > $info[4]);  #### Reverse if start > end
        if($info[2] eq 'mRNA'){
            @{$gene_info_p->{$info[0]}{$gene_id}{'mRNA'}} = @info[3,4,6]; #### Start, end, strand
        }elsif($info[2] eq 'CDS'){
            push @{$gene_info_p->{$info[0]}{$gene_id}{'CDS'}}, [@info[3,4]];
        }elsif($info[2] eq 'five_prime_UTR_intron'){
            $gene_info_p->{$info[0]}{$gene_id}{'5UTR'} = 0;  #### TODO, should we convert the origin gff to BGI style
        }
    }
    close IN;

    return 1;
}

#############################
#
#     Extract_gene_fragment
#
#  description
#  Depend: %cds_code, %aa_code
#
#############################
sub Extract_gene_fragment {
    my ($seq_file, $gene_info_p, $extract_list_p, $frag_p, $flank_len) = @_;

    if($seq_file=~/\.gz$/){
        open FA, "gzip -dc $seq_file |" or die("Can't read file with gzip:$seq_file\n");
    }else {
        open FA, "<$seq_file" or die("Can't read file:$seq_file\n");
    }
    $/='>';<FA>;$/="\n";
    while(my $line=<FA>){
        my ($chr_id) = $line=~/^(\S+)/;
        $/='>';
        my $seq = <FA>;
        chomp $seq;
        $/="\n";
        next if(!defined $gene_info_p->{$chr_id});
        $seq=~s/\s//g;
        my $seq_len = length $seq;

        foreach my $gene_id (keys %{$gene_info_p->{$chr_id}}) {
            next if(!defined $extract_list_p->{$gene_id});
            my $genep = $gene_info_p->{$chr_id}{$gene_id};
            my $fp = \%{$frag_p->{$gene_id}};

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

            $fp->{'seq'} = substr($seq, $gene_st - 1, $gene_ed - $gene_st + 1);
            $fp->{'strand'} = $genep->{'mRNA'}[2];
            $fp->{'len'} = length $fp->{'seq'};

            push @{$fp->{'anno'}{'5UTR'}}, [1, $genep->{'5UTR'}];
            push @{$fp->{'anno'}{'3UTR'}}, [ $fp->{'len'} - $genep->{'3UTR'} + 1, $fp->{'len'}];
            &Reverse_complement(\$fp->{'seq'}) if($fp->{'strand'} eq '-');
            
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
            # map { $fp->{'pos'}{$_}{'type'} = '5UTR' } $fp->{'anno'}{'5UTR'}[0][0]..$fp->{'anno'}{'5UTR'}[0][1] ;
            # map { $fp->{'pos'}{$_}{'type'} = '3UTR' } $fp->{'anno'}{'3UTR'}[0][0]..$fp->{'anno'}{'3UTR'}[0][1] ;

            if(defined $deleteintron and @{$fp->{'anno'}{'CDS'}} > 1){
                my $cds_len = 0;
                my $intron_ed;
                foreach my $cds (reverse @{$fp->{'anno'}{'CDS'}}) {
                    if(!defined $intron_ed){
                        ####### Record and skip the last exon
                        $intron_ed = $cds->[0] - 1;
                        $cds_len += $cds->[1] - $cds->[0] + 1;
                        next;
                    }else{
                        my $intron_st = $cds->[1] + 1;
                        substr ($fp->{'seq'}, $intron_st - 1, $intron_ed - $intron_st + 1) = '';
                        $cds_len += $cds->[1] - $cds->[0] + 1;
                        $intron_ed = $cds->[0] - 1;
                    }
                }
                my $cds_st = $fp->{'anno'}{'CDS'}[0][0];
                my $cds_ed = $cds_st + $cds_len - 1;
                @{$fp->{'anno'}{'CDS'}} = ([$cds_st, $cds_ed]);
            }

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
                            $fp->{'pos'}{$code_pos[$k]}{'aa'} = $cds_code{$this_code};
                            $fp->{'pos'}{$code_pos[$k]}{'shift'} = $k;
                        }
                        $this_code = '';
                        @code_pos = ();
                    }
                }
            }
        }
    }
    close FA;
}


##############################################################################################################
##################################      Sub function for create enzyme      ##################################
##############################################################################################################
#############################
#
#     Init_enzyme_design_library
#
#  description
#
#############################
sub Init_enzyme_design_library {
    my ($input_enzyme_file, $change_method_p) = @_;
    if(1){
        open IN, "<$input_enzyme_file" or die("Can't read file:$input_enzyme_file\n");
        while(my $line=<IN>){
            my @info = split /\s+/, $line;
            #### EcoRI  GAATTC
            $info[2]=~s/[^ACGTMRWSYKVHDBN]//g;

            my $enzyme_len = length $info[2];
            my $min_len = $enzyme_len + ($enzyme_len % 3);
            my $max_len = $min_len + 3;
            push @{$change_method_p->{$info[1]}{'len'}}, ($min_len, $max_len);

            ##### in 3 frame
            for my $i (0..2) {
                ####### eg CTGCAG:  CTG|CAG  NCT|GCA|GNN  NNC|TGC|AGN
                my $tail_number = 3 - (($enzyme_len + $i) % 3);
                $tail_number = 0 if($tail_number == 3);
                my $new_seq = ('N' x $i).$info[2].('N' x $tail_number);
                my %design_enzyme;
                &Init_exist_enzyme($new_seq, $info[1], 0, \%base_list, \%design_enzyme);

                foreach my $e (keys %design_enzyme) {
                    my $this_aa = '';
                    for (my $k = 0; $k + 2<= (length $e) - 1; $k+=3) {
                        $this_aa.= $cds_code{substr($e, $k, 3)};
                    }
                    # print "$this_aa\t$info[0]\t$info[1]\t$new_seq\t$e\t$i\n";
                    &Init_syn_codon_from_aa('', $this_aa, $i, $info[2], $info[1], $change_method_p);
                }
            }
        }
        close IN;
    }
}

#############################
#
#     Init_syn_codon_from_aa
#
#  Depend: %aa_code
#
#############################
sub Init_syn_codon_from_aa {
    my ($codon_seq, $aa_seq, $shift_pos, $enzyme_seq, $enzyme_name, $change_method_p) = @_;

    if($aa_seq){
        my @all_codon = @{$aa_code{substr($aa_seq, 0, 1)}};
        substr ($aa_seq, 0, 1) = '';
        foreach my $codon_base (@all_codon) {
            my $new_codon = $codon_seq.$codon_base;
            &Init_syn_codon_from_aa($new_codon, $aa_seq, $shift_pos, $enzyme_seq, $enzyme_name, $change_method_p);
        }
    }else{
        return 1 if(defined $change_method_p->{$enzyme_name} and defined $change_method_p->{$enzyme_name}{$codon_seq});
        my $end_pos = (length $enzyme_seq) - 1 + $shift_pos;
        # print "$codon_seq\t|$aa_seq|\t$shift_pos\t$end_pos\t$enzyme_seq\t$enzyme_name\n";
        for my $i ($shift_pos..$end_pos) {
            my $enzyme_base = substr ($enzyme_seq, $i - $shift_pos, 1);
            if(substr ($codon_seq, $i, 1) ne $enzyme_base){
                push @{$change_method_p->{$enzyme_name}{$codon_seq}}, [$i, $enzyme_base];
            }
        }
        push @{$change_method_p->{$enzyme_name}{$codon_seq}}, [$shift_pos, $enzyme_seq];
        return 1;
    }
}

#############################
#
#     Create_new_enzyme_site
#
#  
#
#############################
sub Create_new_enzyme_site_exon {
    my ($gene_id, $frag_p, $start, $end, $enzyme_name, $change_method_p) = @_;
    my $fp = $frag_p->{$gene_id};
    my $cm = $change_method_p->{$enzyme_name};

    # my $change_seq = substr ($fp->{'seq'}, $start + 1, $end - $start + 1);
    for (my $i = $start - 1; $i <= $end; $i++) {
        DIF_LEN:foreach my $e (@{$cm->{'len'}}) {
            next if($i + 1 + $e > $end);
            my $this_seq = substr($fp->{'seq'}, $i, $e);
            next if(!defined $cm->{$this_seq});

            ####### Check the position can be changed.
            foreach my $j (@{$cm->{$this_seq}}) {
                last if(length $j->[1] != 1);
                if( &Substitute_frag_base($gene_id, $i+$j->[0]+1, $j->[1], $frag_p, 'test') != 1){
                    next DIF_LEN;
                }
            }
            foreach my $j (@{$cm->{$this_seq}}) {
                last if(length $j->[1] != 1);
                &Substitute_frag_base($gene_id, $i+$j->[0]+1, $j->[1], $frag_p);
            }

            ####### Add the enzyme site to anno
            my $act_pos = $cm->{$this_seq}[-1][0] + $i + 1;
            $fp->{'anno'}{'add_enzyme'}{$enzyme_name}{$act_pos} = [$enzyme_name, $cm->{$this_seq}[-1][1], $act_pos, length($cm->{$this_seq}[-1][1])];

            return 1;
        }
    }
    return 0;
}

##############################################################################################################
###############################      Sub function for codon optimization      ################################
##############################################################################################################
#############################
#
#     Break_tandem_base
#
#  description
#
#############################
sub Break_tandem_base {
    my ($gene_id, $frag_p, $start_pos, $end_pos, $min_len) = @_;
    my $fp = $frag_p->{$gene_id};
    my $target_seq = substr ($fp->{'seq'}, $start_pos - 1, $end_pos - $start_pos + 1);
    $min_len -= 1;

    my $tandem_regexp = qr/([ACGT])\1{$min_len,}/i;
    while($target_seq=~/$tandem_regexp/g){
        my $match_seq = $&;
        my $match_start = $start_pos + $-[0];
        my $match_end = $match_start + (length $match_seq) - 1;
        my $change_start = $fp->{'pos'}{$match_start}{'shift'} == 1 ? $match_start + 1 : $match_start + 2;

        while($change_start <= $match_end){
            my $this_shift = $fp->{'pos'}{$change_start}{'shift'};
            my $this_code = $fp->{'pos'}{$change_start}{'code'};
            my $change_done = 0;

            if (defined $syn_code{$this_code}{$this_shift}){
                
                foreach my $s (@{$syn_code{$this_code}{$this_shift}}) {
                    if(&Substitute_frag_base($gene_id, $change_start, $s, $frag_p) == 1){
                        $change_done = 1;
                        push @{$fp->{'anno'}{'break_tandem'}}, [$match_start, $match_end, $match_seq, $change_start, $s];
                        last;
                    }
                }
            }
            if($change_done == 1){
                $change_start += 3;
            }else{
                $change_start++;
            }
        }
    }
}

#############################
#
#     Init_optimize_syn_code
#
#  Depend: %syn_code %cds_code
#
#############################
sub Init_optimize_syn_code {
    my ($opt_file, $codon_score_p) = @_;
    my %aa_score;
    open IN, "<$opt_file" or die("Can't read file:$opt_file\n");
    while(my $line=<IN>){
        my @info = split /\s+/, $line;
        next if(!defined $info[2]);
        my $this_aa = $cds_code{$info[1]};
        push @{$aa_score{$this_aa}}, [@info[1,2]];
    }
    close IN;

    foreach my $aa (keys %aa_score) {
        @{$aa_score{$aa}} = sort {$b->[1] <=> $a->[1]} @{$aa_score{$aa}};

        ########  max: 2  middle: 1   min: 0
        $codon_score_p->{$aa_score{$aa}[0][0]} = 2;
        $codon_score_p->{$aa_score{$aa}[-1][0]} = 0 if(@{$aa_score{$aa}} > 1);
        map { $codon_score_p->{$aa_score{$aa}[$_][0]} = 1 } (1..($#{$aa_score{$aa}} - 1)) if(@{$aa_score{$aa}} > 2);
    }

    sub Syn_code_sort {
        my ($score_p, $codon, $shift, $new_base) = @_;
        substr ($codon, $shift, 1) = $new_base;
        return $score_p->{$codon};
    }

    foreach my $code (keys %syn_code) {
        foreach my $pos (keys %{$syn_code{$code}}) {
            @{$syn_code{$code}{$pos}} = sort { &Syn_code_sort($codon_score_p, $code, $pos, $b) <=> &Syn_code_sort($codon_score_p, $code, $pos, $a) or $a cmp $b } @{$syn_code{$code}{$pos}};
        }
    }
}


#############################
#
#     Optimize_selected_gene
#
#  Depend: %syn_code $regexp
#
#############################
sub Optimize_selected_gene {
    my ($gene_list_p, $frag_p, $codon_score_p ) = @_;

    ########### Each gene
    foreach my $g (@{$gene_list_p}) {
        my $fp = $frag_p->{$g};

        ########### Each CDS
        foreach my $cds (@{$fp->{'anno'}{'CDS'}}) {
            for (my $i = $cds->[0]; $i <= $cds->[1]; $i++) {
                my $this_codon = $fp->{'pos'}{$i}{'code'};
                my $this_shift = $fp->{'pos'}{$i}{'shift'};

                ########### if the score is max, jump to next codon
                if($codon_score_p->{$this_codon} == 2){
                    $i += 2 - $this_shift;
                    next;
                }
                ########### next if NO syn solution
                next unless(defined $syn_code{$this_codon} and defined $syn_code{$this_codon}{$this_shift});
                my $first_base = $syn_code{$this_codon}{$this_shift}[0];
                my $first_syn = $this_codon;
                substr ($first_syn, $this_shift, 1) = $first_base;

                ########### If the first syn will be better
                if($codon_score_p->{$first_syn} > $codon_score_p->{$this_codon}){
                    if(&Test_new_enzyme_site($g, $frag_p, $regexp, [[$i, $first_base]]) == 1){
                        &Substitute_frag_base($g, $i, $first_base, $frag_p, 'mutable');
                    }
                }
            }
        }
    }
    return 1;
}

##############################################################################################################
#################################      Sub function for link chromosome      #################################
##############################################################################################################
#############################
#
#     Reverse_fragment
#
#  description
#
#############################
sub Reverse_fragment {
    my ($gene_id, $frag_p) = @_;
    my $fp = $frag_p->{$gene_id};
    my %new_fp;

    ####### strand and length
    $new_fp{'len'} = $fp->{'len'};
    $new_fp{'strand'} = $fp->{'strand'} eq '+' ? '-' : '+';
    ####### pos
    foreach my $p (keys %{$fp->{'pos'}}) {
        my $new_pos = $fp->{'len'} - $p + 1;
        &Reverse_complement(\$fp->{'pos'}{$p}{'code'});
        &Reverse_complement(\$fp->{'pos'}{$p}{'change'}) if(defined $fp->{'pos'}{$p}{'change'});

        $new_fp{'pos'}{$new_pos} = $fp->{'pos'}{$p};

    }

    ####### anno
    ## 1, UTR and CDS
    foreach my $e ('5UTR', '3UTR', 'CDS') {
        foreach my $p (@{$fp->{'anno'}{$e}}) {
            my $new_st = $fp->{'len'} - $p->[1] + 1;
            my $new_ed = $fp->{'len'} - $p->[0] + 1;
            push @{$new_fp{'anno'}{$e}}, [$new_st, $new_ed];
        }
        @{$new_fp{'anno'}{$e}} = sort {$a->[0] <=> $b->[0]} @{$new_fp{'anno'}{$e}};
    }
    ## 2, CRISPR
    foreach my $e (@{$fp->{'anno'}{'crispr'}}) {
        $e->[0] = $fp->{'len'} - $e->[0] + 1;
        &Reverse_complement(\$e->[1]);
        $e->[2] = (length $e->[1]) - $e->[2] + 1;
        &Reverse_complement(\$e->[3]);
        $e->[4] = $fp->{'len'} - $e->[4] + 1;
        &Reverse_complement(\$e->[5]);
        push @{$new_fp{'anno'}{'crispr'}}, $e;
    }

    ## 3, enzyme
    foreach my $e ('add_enzyme', 'ori_enzyme') {
        foreach my $n (keys %{$fp->{'anno'}{$e}}) {
            foreach my $p (keys %{$fp->{'anno'}{$e}{$n}}) {
                my $new_pos = $fp->{'len'} - $p + 1;
                my $pp = $fp->{'anno'}{$e}{$n}{$p};
                &Reverse_complement(\$pp->[1]);
                $pp->[2] = $fp->{'len'} - $p + 1;
                $new_fp{'anno'}{$e}{$n}{$new_pos} = $pp;
            }
        }
    }
    ## 4, break_tandem
    foreach my $e (@{$fp->{'anno'}{'break_tandem'}}) {
        $e->[0] = $fp->{'len'} - $e->[0] + 1;
        $e->[1] = $fp->{'len'} - $e->[1] + 1;
        &Reverse_complement(\$e->[2]);
        $e->[3] = $fp->{'len'} - $e->[3] + 1;
        &Reverse_complement(\$e->[4]);
        push @{$new_fp{'anno'}{'break_tandem'}}, $e;
    }

    ## 5, seq
    &Reverse_complement(\$fp->{'seq'});
    $new_fp{'seq'} = $fp->{'seq'};

    delete $frag_p->{$gene_id};
    return \%new_fp;
}

#############################
#
#     Create_fasta_and_gff
#
#  description
#
#############################
sub Create_fasta_and_gff {
    my ($gene_list_p, $frag_p, $output_fasta_file, $output_gff_file) = @_;

    my $chr_name = 'new_chr';
    my $anno_tag = 'Genovo';

    open FA, ">", "$output_fasta_file" or die("Can't write file:$output_fasta_file\n");
    open GFF, ">", "$output_gff_file" or die("Can't write file:$output_gff_file\n");

    print FA ">$chr_name\n";
    
    my $gene_start = 0;
    foreach my $gid (sort { $gene_list_p->{$a}{'order'} <=> $gene_list_p->{$b}{'order'}} keys %{$gene_list_p}) {

        if($gene_list_p->{$gid}{'strand'} eq '-'){
            $frag_p->{$gid} = &Reverse_fragment($gid, $frag_p);
        }
        my $tg = $gene_list_p->{$gid};
        my $fp = $frag_p->{$gid};
        my $this_strand = $tg->{'strand'};
        my $this_len = $fp->{'len'};
        print FA $fp->{'seq'};

        ###### Create annotation gff
        ## 5UTR, 3UTR, CDS
        foreach my $e ('5UTR', 'CDS', '3UTR') {
            if($e eq 'CDS'){
                my $cds_st = $fp->{'anno'}{$e}[0][0];
                my $cds_ed = $fp->{'anno'}{$e}[-1][1];
                print GFF "$chr_name\t$anno_tag\tmRNA\t$cds_st\t$cds_ed\t.\t$this_strand\t.\tID=$gid;\n";
            }
            foreach my $p (@{$fp->{'anno'}{$e}}) {
                my $new_st = $p->[0] + $gene_start;
                my $new_ed = $p->[1] + $gene_start;
                my $this_shift = '.';
                if($e eq 'CDS'){
                    $this_shift = $this_strand eq '+' ? 2 - $fp->{'pos'}{$p->[1]}{'shift'} : 2 - $fp->{'pos'}{$p->[0]}{'shift'};
                }
                print GFF "$chr_name\t$anno_tag\t$e\t$new_st\t$new_ed\t.\t$this_strand\t.\t$this_shift\tParent=$gid;\n";
            }
        }

        ## CRISPR
        foreach my $crispr (@{$fp->{'anno'}{'crispr'}}) {
            my $crispr_st = $crispr->[0];
            my $crispr_ed = $crispr->[0] + (length $crispr->[1]) - 1;
            if($this_strand eq '-'){
                ($crispr_st, $crispr_ed) = ($crispr_st - (length $crispr->[1]) + 1, $crispr_st);
            }
            print GFF "$chr_name\t$anno_tag\tCRISPR\t$crispr_st\t$crispr_ed\t.\t$this_strand\t.\tParent=$gid;Seq=$crispr->[1],$crispr->[3];Change=$crispr->[4]:$crispr->[5];\n";
        }

        ## enzyme
        foreach my $e ('add_enzyme', 'ori_enzyme') {
            foreach my $n (keys %{$fp->{'anno'}{$e}}) {
                foreach my $p (keys %{$fp->{'anno'}{$e}{$n}}) {
                    my $pp = $fp->{'anno'}{$e}{$n}{$p};
                    my $enzyme_st = $p;
                    my $enzyme_ed = $p + (length $pp->[1]) - 1;
                    if($this_strand eq '-'){
                        ($enzyme_st, $enzyme_ed) = ($enzyme_st - (length $pp->[1]) + 1, $enzyme_st);
                    }
                    print GFF "$chr_name\t$anno_tag\t$e\t$enzyme_st\t$enzyme_ed\t.\t$this_strand\t.\tParent=$gid;Seq=$pp->[1];Name=$pp->[0];\n";
                }
            }
        }

        ## Tandem Break
        my @tmp;
        my $tandem_st;
        my $tandem_ed;
        my $tandem_seq;
        foreach my $e (@{$fp->{'anno'}{'break_tandem'}}) {
            if(!defined $tandem_st){
                $tandem_st = $e->[0];
                $tandem_ed = $e->[1];
                $tandem_seq = $e->[2];
            }
            if($e->[0] ne $tandem_st){
                ($tandem_st, $tandem_ed) = ($tandem_ed, $tandem_st) if($this_strand eq '-');
                print GFF "$chr_name\t$anno_tag\ttandemBreak\t$tandem_st\t$tandem_ed\t.\t$this_strand\t.\tParent=$gid;Seq=$tandem_seq;Change=".(join ',', @tmp).";\n";
                @tmp = ();
                $tandem_st = $e->[0];
                $tandem_ed = $e->[1];
                $tandem_seq = $e->[2];
            }
            push @tmp, "$e->[3]:$e->[4]";
        }
        if(@tmp){
            ($tandem_st, $tandem_ed) = ($tandem_ed, $tandem_st) if($this_strand eq '-');
            print GFF "$chr_name\t$anno_tag\ttandemBreak\t$tandem_st\t$tandem_ed\t.\t$this_strand\t.\tParent=$gid;Seq=$tandem_seq;Change=".(join ',', @tmp).";\n";
        }
    }

    print FA "\n";
    close GFF;
    close FA;
}

##############################################################################################################
##################################      Sub function for common method      ##################################
##############################################################################################################
#############################
#
#     Substitute_frag_base
#
#  Depend: %syn_code $regexp
#
#############################
sub Substitute_frag_base {
    my ($gene_id, $pos, $new_base, $frag_p, $change_option) = @_;

    ######### change_option can be 'test': just check this position can be canged. 'mutable': this position can still change by other method.
    $change_option ||= '';

    ######### !!!! Here, we do NOT check the change is synonymous. !!!!
    ######### -1 means format error, the length of base > 1, or not exist such pos in gene, or new base equal origin base.
    return -1 if(length $new_base != 1 or !defined $frag_p->{$gene_id}{'pos'}{$pos} or substr($frag_p->{$gene_id}{'seq'}, $pos - 1, 1) eq $new_base);
    my $pp = $frag_p->{$gene_id}{'pos'}{$pos};

    ######### check whether the change is synonymous
    ######### -2 means nonsynonymous.
    return -2 if($pp->{'type'} eq 'CDS' and !defined $syn_code{$pp->{'code'}}{$pp->{'shift'}});

    ######### 0 means this position can NOT be changed.
    return 0 if($pp->{'immutable'});

    ######### if just test, return 1 for changeable, but do nothing.
    if(!$change_option or $change_option eq 'mutable'){
        $pp->{'immutable'} = 1 if($change_option ne '');

        ########## Record the origin base if no record before. (must be not record for V1)
        $pp->{'change'} = substr($frag_p->{$gene_id}{'seq'}, $pos - 1, 1) if(!defined $pp->{'change'});

        ########## change the codon if the pos is in CDS.
        substr ($pp->{'code'}, $pp->{'shift'}, 1) = $new_base if($pp->{'type'} eq 'CDS');

        ########## modify the sequence of gene.
        substr ($frag_p->{$gene_id}{'seq'}, $pos - 1, 1) = $new_base;
    }
    return 1;
}


#############################
#
#     Find_enzyme_and_substitute
#
#  description
#
#############################
sub Find_enzyme_and_substitute {
    my ($gene_id, $frag_p, $regexp_p, $exist_enzyme_p, $start_pos, $end_pos, $test_only) = @_;

    my $fp = $frag_p->{$gene_id};
    my $all_changeable = 1;
    

    while(1){
        my $enzyme_change_count = 0;
        my $target_seq = substr ($fp->{'seq'}, $start_pos - 1, $end_pos - $start_pos + 1);


        while ($target_seq=~/${$regexp_p}/g) {
            my $match_seq = $&;
            my $match_start = $start_pos + $-[0];
            my $match_end = $match_start + (length $match_seq) - 1;
            my $match_enzyme = $exist_enzyme_p->{$match_seq};
            my $match_length = length $&;
            my $change_done = 0;
            next if(defined $fp->{'anno'}{'ori_enzyme'}{$match_enzyme} and defined $fp->{'anno'}{'ori_enzyme'}{$match_enzyme}{$match_start});
            # print "$gene_id\t$match_enzyme\t$match_seq\t$match_start\n";

            if(!defined $test_only){
                CHANGE_ENZYME:for my $i ($match_start..$match_end) {
                    my $this_shift = $fp->{'pos'}{$i}{'shift'};
                    my $this_code = $fp->{'pos'}{$i}{'code'};

                    ####### next if this pos no synonymous.
                    next if(!defined $syn_code{$this_code}{$this_shift});

                    my $substitute_result = 0;
                    foreach my $e (@{$syn_code{$this_code}{$this_shift}}) {
                        if(&Test_new_enzyme_site($gene_id, $frag_p, $regexp_p, [[$i, $e]])){
                            $substitute_result = &Substitute_frag_base($gene_id, $i, $e, $frag_p, 'mutable');

                            ####### successfully change if return is 1.
                            if($substitute_result == 1){
                                $change_done = 1;
                                $enzyme_change_count++;
                                last CHANGE_ENZYME;
                            }
                        }

                    }
                }
            }
            ######### if this enzyme can NOT be deleted. record the infomation
            if($change_done == 0){
                $all_changeable = 0;
                $fp->{'anno'}{'ori_enzyme'}{$match_enzyme}{$match_start} = [$match_enzyme, $match_seq, $match_start, $match_length];
                # push @{$result_p}, [$match_start, $match_enzyme, $match_seq];
            }
        }
        last if($enzyme_change_count == 0);
    }
    return $all_changeable;
}

#############################
#
#     Test_new_enzyme_site
#
#  description
#
#############################
sub Test_new_enzyme_site {
    my ($gene_id, $frag_p, $regexp_p, $change_list_p) = @_;
    my $flank = 8;
    @{$change_list_p} = sort { $a->[0] <=> $b->[0] } @{$change_list_p} if(@{$change_list_p} > 1);
    my $start_pos = $change_list_p->[0][0] - $flank < 0 ? 0 : $change_list_p->[0][0] - $flank;
    my $end_pos = $change_list_p->[-1][0] + $flank > $frag_p->{$gene_id}{'len'} ? $frag_p->{$gene_id}{'len'} : $change_list_p->[-1][0] + $flank;

    my $ori_seq = substr ($frag_p->{$gene_id}{'seq'}, $start_pos - 1, $end_pos - $start_pos + 1);



    my $ori_match = '';
    while ($ori_seq=~/${regexp_p}/g) {
        $ori_match .= $-[0];
    }

    map { substr ($ori_seq, $_->[0] - $start_pos, 1)= $_->[1] } @{$change_list_p} ;
    my $new_match = '';
    while ($ori_seq=~/${regexp_p}/g) {
        $new_match .= $-[0];
    }

    if($ori_match eq $new_match){
        return 1;
    }else{
        return 0;
    }

}

#############################
#
#     Find_enzyme
#
#  description
#
#############################
sub Find_enzyme {
    my ($seq_p, $regexp_p, $start, $length) = @_;
    if(substr(${$seq_p}, $start, $length)=~/${$regexp_p}/){
        my $match_start = $start + $-[0];
        my $match_enzyme = $&;
        my $match_length = length $&;
        return ($match_enzyme, $match_start, $match_length);
    }else{
        return ('');
    }
}

#############################
#
#     Create_enzyme_regexp
#
#  description
#
#############################
sub Create_enzyme_regexp {
    my ($enzyme_name, $ori_enzyme_seq, $base_list_p, $exist_enzyme_p, $enzyme_regexp_p) = @_;

    &Init_exist_enzyme($ori_enzyme_seq, $enzyme_name, 0, $base_list_p, $exist_enzyme_p);

    my $reg_seq = $ori_enzyme_seq;
    #### convert continuous N to 'N{number}' format
    #### eg:   CACNNNNNNTCC --> CACN{5}TCC
    $reg_seq=~s/N+/"N{".(length $&)."}"/ie;

    for (my $i = 0; $i < length $reg_seq; $i++) {
        substr($reg_seq, $i, 1) = $base_list{substr($reg_seq, $i, 1)} if(defined $base_list{substr($reg_seq, $i, 1)});
    }

    push @{$enzyme_regexp_p}, $reg_seq;

    return 1;
}


#############################
#
#     Substitute_enzyme_exon
#
#  description
#
#############################
sub Substitute_enzyme_exon {
    my ($match_enzyme, $exist_enzyme_p, $base_list_p, $cds_code_p, $aa_code_p, $exon_st_pos ) = @_;

    for (my $i = $exon_st_pos; $i + 3 <= length $match_enzyme; $i+=3) {
        my $this_code = substr($match_enzyme, $i, 3);
        my $this_aa = $cds_code_p->{$this_code};
        if(@{$aa_code_p->{$this_aa}} > 1){
            foreach my $e (@{$aa_code_p->{$this_aa}}) {
                next if($e eq $this_code);
                my $new_seq = $match_enzyme;
                substr($new_seq, $i, 3) = $e;
                return $new_seq if(!defined $exist_enzyme_p->{$new_seq});
            }
        }
    }
    print STDERR "Can not find substitute method in $match_enzyme\n";
    return $match_enzyme;
}

#############################
#
#     Init_exist_enzyme
#
#  recursively create all type 
#  of exist enzymes.
#
#############################
sub Init_exist_enzyme {
    my ($enzyme_seq, $enzyme_name, $start_pos, $base_list_p, $exist_enzyme_p, ) = @_;
    my $end_pos = (length $enzyme_seq) - 1;
    for my $i ($start_pos..$end_pos) {
        my $base_q = substr($enzyme_seq, $i, 1);
        if(defined $base_list_p->{$base_q} ){

            ######### split middle AGCT to an array
            ######### eg: [ACG] --> ('A', 'C', 'G')
            my @base_arr = (split '', ($base_list_p->{$base_q}))[1..(length $base_list_p->{$base_q}) - 2];
            foreach my $e (@base_arr) {
                my $new_seq = $enzyme_seq;
                substr ($new_seq, $i, 1) = $e;
                &Init_exist_enzyme($new_seq, $enzyme_name, $i, $base_list_p, $exist_enzyme_p);
            }
            return 1;
        }
    }
    $exist_enzyme_p->{$enzyme_seq} = $enzyme_name;
}

###########################################
#
#     Reverse_complement
#
#  Reverse and complement the geiven sequencing.
#
#  Type:   Shared method.
#  Depend: %complement_base
#
###########################################
sub Reverse_complement {
    my ($ori_seq_p) = @_;

    ####### TODO, Here can be optimized by tr/// method.
    ${$ori_seq_p} = reverse ${$ori_seq_p};
    ${$ori_seq_p} =~tr/ACGTMRWSYKVHDB/TGCAKYWSRMBDHV/;
    return 1;
    # for my $i (0..(length $ori_seq) - 1) {
    #     substr ($ori_seq, $i, 1) = $complement_base{substr ($ori_seq, $i, 1)};
    # }
    # return reverse $ori_seq;
}

#############################
#
#     Init_aa_code
#
#  description
#
#############################
sub Init_aa_code {
    my ($cds_code_p, $aa_code_p) = @_;
    foreach my $e (sort keys %{$cds_code_p}) {
        push @{$aa_code_p->{$cds_code_p->{$e}}}, $e;
    }
}

#############################
#
#     Init_syn_code
#
#  description
#
#############################
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

#############################
#
#     Lock_position
#
#  description
#
#############################
sub Lock_position {
    my ($gene_id, $frag_p, $start_pos, $end_pos) = @_;
    foreach my $e ($start_pos..$end_pos) {
        $frag_p->{$gene_id}{'pos'}{$e}{'immutable'} = 1;
    }
    return 1;
}

=Problem
    line 589: Not test another enzyme created by test function.
    line 753: If an enzyme can not be changed, another is overlap with it, it can not be detected.
    line 818: Test function only test equal, can not use in Create enzyme.

=cut

################## God's in his heaven, All's right with the world. ##################