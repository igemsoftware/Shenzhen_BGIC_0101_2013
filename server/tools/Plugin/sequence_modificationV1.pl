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
my ($crisprp_kmer_lib, $species_name );
my ($enzyme_file);
my ($gene_gff_file, $gene_list_file, $gene_flank_len);

GetOptions(
  "kmerlib=s"=>\$crisprp_kmer_lib,
  "species=s"=>\$species_name,
  "step=i"=>\$step,
  "enzymelib=s"=>\$enzyme_file,
  "genegff=s"=>\$gene_gff_file,
  "genelist=s"=>\$gene_list_file,
  "flanklen=i"=>\$gene_flank_len,
#  ""=>\,
#  ""=>\,
);

&usage if(@ARGV !=1);
my ($fa_file)=@ARGV;

############# global variable




$species_name ||= 'yeast';
$crisprp_kmer_lib ||= "$species_name.kmer12.lib";
$gene_flank_len ||= 100;
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
my %kmer_lib;
my %gene_list;
my %gene_info;
my %frag;

############################  BEGIN MAIN  ############################

&Init_aa_code(\%cds_code, \%aa_code);


if($step=~/1/){
    ########## Create a library of kmer12, or read kmer from library
    &Constructe_kmer_library($fa_file, $crisprp_kmer_lib, 12) unless(-e $crisprp_kmer_lib); ### this version only build kmer12 library
    &Init_kmer_library($crisprp_kmer_lib, \%kmer_lib);
}

if($step=~/2/){
    ########## Constructe gene fragment

    ##### Read gene list
    open IN, "<$gene_list_file" or die("Can't read file:$gene_list_file\n");
    while(my $line=<IN>){
        my @info = split /\s+/, $line;
        $gene_list{$info[0]} = '+'; #### TODO, the strand can be recorded here.
    }
    close IN;

    ##### Read gff file
    &Read_gene_gff($gene_gff_file, \%gene_info);
#   print Dumper(\%gene_info);exit;

    ##### Create data structure
    #$seq_file, $gene_info_p, $extract_list_p, $frag_p, $flank_len
    &Extract_gene_fragment($fa_file, \%gene_info, \%gene_list, \%frag, $gene_flank_len);
    print Dumper(\%frag);
    # exit;
}

if($step=~/3/){
    ########## Search and modify CRISPR site

    exit;
}

my @enzyme_regexp;
my %exist_enzyme;
open ENZ, "<$enzyme_file" or die("Can't read file:$enzyme_file\n");
while(my $line=<ENZ>){
    # next if($. == 1);
    my @info = split /\s+/, $line;
    #### EcoRI  GAATTC
    $info[1]=~s/[^ACGTMRWSYKVHDBN]//g;
    
    &Create_enzyme_regexp($info[0], $info[1], \%base_list, \%exist_enzyme, \@enzyme_regexp);

    # my $recom_enzyme = &Reverse_complement($info[1], \%complement_base);
    # &Create_enzyme_regexp($info[0], $recom_enzyme, \%base_list, \%exist_enzyme, \@enzyme_regexp);

}
close ENZ;

####### initialize the regular expression
my $regexp = join '|', @enzyme_regexp;
$regexp = qr/$regexp/i;


if($fa_file=~/\.gz$/){
    open FA, "gzip -dc $fa_file |" or die("Can't read file with gzip:$fa_file\n");
}else {
    open FA, "<$fa_file" or die("Can't read file:$fa_file\n");
}
$/='>';<FA>;$/="\n";
while(my $line=<FA>){
    my ($id)=$line=~/^(\S+)/;
    $/='>';
    my $seq=<FA>;
    $/="\n";
    $seq=~s/\s//g;

    my ($match_seq, $match_start, $match_length);
    $match_start = 0;
    my $seq_len = length $seq;
    my $cycle = 0;
    ($match_seq, $match_start, $match_length) = &Find_enzyme(\$seq, \$regexp, $match_start, $seq_len);
    while($match_seq ne ''){
        my $new_seq = &Substitute_enzyme_regular($match_seq, \%exist_enzyme, \%base_list, 0);
        substr($seq, $match_start, $match_length) = $new_seq;
        
        print STDERR "$id\t$cycle\t$match_start\t$match_length\t$match_seq\t$new_seq\n";$cycle+=1;

        my $new_len = $seq_len - $match_start - 1;
        last if($new_len < 1);
        ($match_seq, $match_start, $match_length) = &Find_enzyme(\$seq, \$regexp, $match_start - 10, $new_len); ### fix it to the max length of enzyme

    }
    print ">$id\n$seq\n";
}
close FA;
############################   END  MAIN  ############################

########################################################################################################
##################################      Sub function for CRISPRP      ##################################
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
#     Design_crisprp_seq
#
#  description
#
#############################
sub Design_crisprp_seq {
    my ($gene_id, $frag_p, $kmer_lib_p, $design_number ) = @_;

    my $fp = $frag_p->{$gene_id};
    my $fin_number = 0;
    foreach my $e (@{$fp->{'anno'}{'CDS'}}) {
        my $cds_seq = substr($fp->{'seq'}, $e->[0] + 1, $e->[1] - $e->[0] + 1);
        while($cds_seq=~/G.{20}GG/ig){
            my $crisprp_st = $-[0];
            my $uniq_seq = substr ($&, 8, 12);
            next if(!defined $kmer_lib_p->{$uniq_seq});
        }
        my $ind_st = $e->[0];
    }
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

        foreach my $gene_id (%{$gene_info_p->{$chr_id}}) {
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

            $fp->{'seq'} = substr($seq, $gene_st, $gene_ed - $gene_st + 1);
            $fp->{'strand'} = $genep->{'mRNA'}[2];
            $fp->{'len'} = length $fp->{'seq'};
#### add info
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



###############  sub  ###############
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
#     Substitute_enzyme
#
#  description
#
#############################
sub Substitute_enzyme_regular {
    my ($match_enzyme, $exist_enzyme_p, $base_list_p, $change_start, $change_end) = @_;
    my $enzyme_name = $exist_enzyme_p->{$match_enzyme};
    $change_start ||= 0;
    $change_end ||= (length $match_enzyme) - 1;
    my $new_seq = $match_enzyme;
    for my $i ($change_start..$change_end) {
        # print "$match_enzyme\t".(substr($new_seq, $i, 1))."\n" if(substr($new_seq, $i, 1) !~/[ACGT]/);
        next if(defined $base_list_p->{substr($new_seq, $i, 1)});
        foreach my $e (qw(A C G T)) {
            substr($new_seq, $i, 1) = $e;
            return $new_seq if(!defined $exist_enzyme_p->{$new_seq});
        }
    }
    print STDERR "Can not find substitute method in $match_enzyme\n";
    return $match_enzyme;
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
    my ($ori_seq) = @_;

    ####### TODO, Here can be optimized by tr/// method.
    for my $i (0..(length $ori_seq) - 1) {
        substr ($ori_seq, $i, 1) = $complement_base{substr ($ori_seq, $i, 1)};
    }
    return reverse $ori_seq;
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



################## God's in his heaven, All's right with the world. ##################
