#!/bin/env perl -w
use strict;
use Getopt::Long;
#use File::Basename;
sub usage{
    print STDERR <<USAGE;
    ################################################
            Version 0.2.2 by Yuxiang Li   2013.09.26

      Usage: $0 [option] >STDOUT

      BASIC:
      -inputfa        <str> : Input fasta file of Genovo sequence.
      -inputgff       <str> : Input gff file of chromosome annotation.
      -outputfa       <str> : Output fasta file of new chromosome.
      -outputgff      <str> : Output gff file of new chromosome.

      OPTIONS:
      1. CRISPR design:
      -crisprnum      <int> : Number of CRISPR site to design in a gene.
      -database       <str> : Genome fasta file of selected species.

      2. Delete enzyme:
      -delenzymelist  <str> : A file of enzyme structure to be deleted.
      -biobrickstrand <opt> : Use biobrickstrand to delete enzyme.

      3. Add enzyme:
      -addenzymelist   <str>: A file of enzyme structure to be add.
      -addenzymeconfig <\@str>: A group of config for create enzyme.
                                See 'format' section for more detailed.

      4. codon optimization:
      -codonoptimize  <str> : A file of codon priority of selected species.
      -optimizegenelist <str> : Only genes in this list will be optimized.
      -optizeallgene  <opt> : Optimize all genes in gff. [coverd by -optimizegenelist]

      5. repeat smash:
      -repeatsmash    <int> : tandem Repeat bases longer than this value will be smash.

      OTHER:
      -detail  <opt> : Show all changed in new gff. [none]
      -verbose <opt> : Show detailed information while running. [none]
      -help    <opt> : Show this help.

      FORMAT:

      -delenzymelist & -addenzymelist:
      #company name    site   3'-base Size   Price   RMB/U  Incubation_Temperature  Buffer
      NEB     BamHI   G/GATCC G       5000    219     0.04    37      3+BSA
      NEB     EcoRI   G/AATTC G       5000    219     0.04    37      EcoRI
      NEB     HindIII A/AGCTT A       5000    219     0.04    37      2

      -addenzymeconfig:
      #gene_id,start_pos,end_pos,enzyme_to_add
      YAL054C,824,2965,BamHI
      :: The start_pos and the end_pos should located in CDS.

      -optimizegenelist:
      YAL054C,YAL038W,YBR019C,YBR145W,YBR196C,YBR221C,YCL040W,YCR012W

    ################################################
USAGE
    exit;
}

my ($input_fa_file, $input_gff_file);
my ($crispr_design_number, $species_database);
my ($remove_enzyme_file, $remove_biobrick_enzyme);
my ($add_enzyme_file, @add_enzyme_config);
my ($repeat_smash_len);
my ($codon_optimize_file, $optimize_gene_list, $optimize_all_gene);
my ($show_detail_in_gff);
my ($output_fa_file, $output_gff_file);
my ($verbose, $help);

GetOptions(
  "inputfa=s"=>\$input_fa_file,
  "inputgff=s"=>\$input_gff_file,

  "crisprnum=i"=>\$crispr_design_number,
  "database=s"=>\$species_database,

  "delenzymelist=s"=>\$remove_enzyme_file,
  "biobrickstrand"=>\$remove_biobrick_enzyme,
  "addenzymelist=s"=>\$add_enzyme_file,
  "addenzymeconfig=s{1,}"=>\@add_enzyme_config,

  "repeatsmash=s"=>\$repeat_smash_len,

  
  "codonoptimize=s"=>\$codon_optimize_file,
  "optimizegenelist=s"=>\$optimize_gene_list,
  "optizeallgene"=>\$optimize_all_gene,

  "outputfa=s"=>\$output_fa_file,
  "outputgff=s"=>\$output_gff_file,

  "detail"=>\$show_detail_in_gff,
  "verbose"=>\$verbose,
  "help"=>\$help,
#   ""=>\,
);


&usage unless($input_fa_file and $input_gff_file and $output_fa_file and $output_gff_file);
&usage if($help);

############# global variable
$| = 1;
my $data_path = `pwd`;
chomp $data_path;

my @biobrick_enzyme = (['EcoRI','GAATTC'], ['XbaI','TCTAGA'], ['SpeI','ACTAGT'], ['PstI','CTGCAG'], ['NotI','GCGGCCGC']);

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

my %exist_enzyme;
my @enzyme_regexp;
my $remove_regexp;


my %frag;
my @fragment_order;

my %gene_list;
my %crispr_lib;
my %codon_score;

############################  BEGIN MAIN  ############################

&Init_aa_code(\%cds_code, \%aa_code);
&Init_syn_code(\%cds_code, \%syn_code);
&Init_optimize_syn_code($codon_optimize_file, \%codon_score) if($codon_optimize_file);
&Constructe_data_structure($input_gff_file, $input_fa_file, \%frag, \@fragment_order);
print "[STEP] Read fasta and gff finished.\n" if($verbose);

if($remove_enzyme_file){
    open ENZ, "<$remove_enzyme_file" or die("Can't read file:$remove_enzyme_file\n");
    while(my $line=<ENZ>){
        next if($line=~/^#/);
        my @info = split /\s+/, $line;
        #### EcoRI  GAATTC
        $info[2]=~s/[^ACGTMRWSYKVHDBN]//g;
        
        ####### Supplier  Restriction Endonucleases  Recognition Site  3' base Size(U) Price(RMB)  RMB/U  Incubation Temperature(?)  Buffer  purchased
        ####### eg. NEB     BamHI   G/GATCC G       5000    219     0.04    37      3+BSA   1
        &Create_enzyme_regexp($info[1], $info[2], \%base_list, \%exist_enzyme, \@enzyme_regexp);
    }
    close ENZ;

    ####### initialize the regular expression
    $remove_regexp = join '|', @enzyme_regexp;
    $remove_regexp = qr/$remove_regexp/i;
}

if($remove_biobrick_enzyme){
    foreach my $e (@biobrick_enzyme) {
        &Create_enzyme_regexp($e->[0], $e->[1], \%base_list, \%exist_enzyme, \@enzyme_regexp);
    }
    $remove_regexp = join '|', @enzyme_regexp;
    $remove_regexp = qr/$remove_regexp/i;
}

print "[STEP] Initialization finished.\n" if($verbose);

if($crispr_design_number and $species_database){
    my $crispr_design_tmp_fa = "$data_path/crispr_design_query.fa";
    &Search_crispr_candidate_site(\%frag, $species_database, $crispr_design_number, $crispr_design_tmp_fa);
    print "[STEP] Design CRISPR site finished.\n" if($verbose);
}

if($remove_regexp){
    foreach my $gene (keys %{$frag{'gene'}}) {
        my $is_all_remove = 1;
        foreach my $cds (@{$frag{'gene'}{$gene}{'anno'}{'CDS'}}) {
            $is_all_remove = 0  if(&Find_enzyme_and_substitute($gene, \%frag, \$remove_regexp, \%exist_enzyme, $cds->[0], $cds->[1]) != 1);
        }
        print "[Delete Enzyme] Can not remove all enzyme in $gene, recorded in new gff.\n" if($is_all_remove != 1 and $verbose);
    }
    print "[STEP] Remove enzyme site finished.\n" if($verbose);
}

######## Create new enzyme of RFC32
if($add_enzyme_file and @add_enzyme_config){
    my %change_method;
    &Init_enzyme_design_library($add_enzyme_file, \%change_method);

    ###### config:   gene_id,start,end,enzyme
    ###### example:  YAL054C,824,2965,EcoRI  YAL038W,4166,5668,EcoRI
    foreach my $block (@add_enzyme_config) {
        my @add_list = split /,/, $block;
        &Create_new_enzyme_site_exon($add_list[0], \%frag, $add_list[1], $add_list[2], $add_list[3], \%change_method);
    }
    print "[STEP] Add enzyme site finished.\n" if($verbose);
}

if($codon_optimize_file and ($optimize_gene_list or $optimize_all_gene)){
    my @opt_gene_list;
    if($optimize_gene_list){
        @opt_gene_list = split /,/, $optimize_gene_list;
    }else{
        @opt_gene_list = keys %{$frag{'gene'}};
    }
    &Optimize_selected_gene(\@opt_gene_list, \%frag, \%codon_score);
    print "[STEP] Codon optimization finished.\n" if($verbose);
}

if($repeat_smash_len){
    foreach my $g (keys %{$frag{'gene'}}) {
        &Break_tandem_base($g, \%frag, $repeat_smash_len);
    }
    print "[STEP] Repeat-smash finished.\n" if($verbose);
}

if($codon_optimize_file){
    &Ranking_optimize_gene(\%frag, \%codon_score);
    print "[STEP] Ranking optimization finished.\n" if($verbose);
}

&Create_fasta_and_gff(\@fragment_order, \%frag, $output_fa_file, $output_gff_file);
print "[STEP] Create new chromosome fasta and gff finished\n[STEP] All Finished!\n" if($verbose);

############################   END  MAIN  ############################

########################################################################################################
##################################      Sub function for crispr      ##################################
########################################################################################################


#############################
#
#     Search_crispr_candidate_site
#
#  description
#
#############################
sub Search_crispr_candidate_site {
    ###### [0]id of gene  [1]ref of %frag  [2]ref of 12-mer library  [3]number want to design  [4]empty %hash for record the crispr site
    my ($frag_p, $database_file, $design_number, $tmp_fa ) = @_;

    my $blastn = `which blastn`;
    chomp $blastn;

    ##### make database
    if(!-e "$database_file.nsq"){
        my $makedb = `which makeblastdb`;
        chomp $makedb;
        `$makedb -in $database_file -dbtype nucl -parse_seqids`;
    }

    my %criseq;
    my %genecri;

    open FA, ">", "$tmp_fa" or die("Can't write file:$tmp_fa\n");
    my $cri_id = "cirspr000001";

    foreach my $gene_id (keys %{$frag_p->{'gene'}}) {
        my $fp = $frag_p->{'gene'}{$gene_id};

        foreach my $e (@{$fp->{'anno'}{'CDS'}}) { ### loop every cds to find crispr site
            my $cds_seq = substr($frag_p->{'seq'}, $e->[0] - 1, $e->[1] - $e->[0] + 1); ## get the cds sequence of selected
            ######### crispr structure:  G NNNNNNN NNNNNNNNNNNN NGG
            #########                             {     12     }
            #########        this 12 bp should be uniq in target genome
            #########  So use regexp to search the basic structure, then check whether uniq of 12bp sequence by 12-mer library.
            #########  steply tried a synonymous substitution in selected locus.
            #########  Finally, modify the gene sequence, record crispr site, mark the change in data structure

            my $cds_len = length $cds_seq;
            while(1){
                $cds_seq=~/G.{20}GG/ig;
                my $crispr_st = $-[0];
                my $crispr_seq = $&;
                last if(!defined pos($cds_seq) or pos($cds_seq) >= $cds_len);
                my $uniq_seq = substr ($crispr_seq, 8, 12); ## the first uniq base is 8 in crispr sequence

                @{$criseq{$cri_id}} = ($gene_id, $crispr_st + $e->[0], $crispr_seq, $uniq_seq);
                $genecri{$gene_id}{$cri_id} =  $criseq{$cri_id};
                print FA ">$cri_id\n$uniq_seq\n";
                $cri_id++;

                pos($cds_seq) = $-[0] + 1;
            }
        }
    }
    close FA;

    my $blast_result = `$blastn -task blastn-short -query $tmp_fa -db $database_file -outfmt 6 |awk '\$4==12' | cut -f 1 |uniq -u `;
    my %crispr_lib;
    my %fin_number;
    map { $criseq{$_}[4] = 1; } split /\n/, $blast_result ;

    foreach my $gene_id (keys %genecri) {
        my $fp = $frag_p->{'gene'}{$gene_id};
        map { delete $genecri{$gene_id}{$_} if(!defined $genecri{$gene_id}{$_}[4]) } (keys %{$genecri{$gene_id}}) ;
        my @crispr_id = sort {$genecri{$gene_id}{$a}[1]<=>$genecri{$gene_id}{$b}[1]} keys %{$genecri{$gene_id}};
        my $last_end = 0;
        SUBSTITUTE:foreach my $id (@crispr_id) {
            next if(defined $crispr_lib{$criseq{$id}[3]});
            next if($criseq{$id}[1] < $last_end);
            $crispr_lib{$criseq{$id}[3]} = $criseq{$id}[0];
            for my $i (0..11) {
                my $this_pos = $criseq{$id}[1] + 8 + $i;
                my $this_code = $fp->{'pos'}{$this_pos}{'code'};
                my $this_shift = $fp->{'pos'}{$this_pos}{'shift'};
                next if(defined $fp->{'pos'}{$this_pos}{'immutable'} or !defined $syn_code{$this_code} or !defined $syn_code{$this_code}{$this_shift});
                foreach my $cb (@{$syn_code{$this_code}{$this_shift}}) {
                    my $syn_seq = $criseq{$id}[3];
                    substr($syn_seq, $i, 1) = $cb;

                    next if(defined $crispr_lib{$syn_seq});
                    if(&Substitute_frag_base($gene_id, $this_pos, $cb, $frag_p) == 1){
                        $fin_number{$gene_id}++;
                        push @{$fp->{'anno'}{'crispr'}}, [$criseq{$id}[1], $criseq{$id}[1] + 22, '+', "Parent=$gene_id;CRISPR_seq=$criseq{$id}[2];sub_seq=$criseq{$id}[3];change_pos=$this_pos;change_base=$cb;"];
                        &Lock_position($gene_id, $frag_p, $criseq{$id}[1], $criseq{$id}[1] + 22);
                        $last_end = $criseq{$id}[1] + 22;
                        last SUBSTITUTE if($fin_number{$gene_id} >= $design_number);
                    }
                }
            }
        }
    }

    foreach my $gene (sort keys %{$frag_p->{'gene'}}) {
        $fin_number{$gene} ||= 0;
        print "[CRISPR] Design $fin_number{$gene} CRISPR site(s) in $gene.\n" if($verbose);
    }
}


##############################################################################################################
##################################      Sub function for gene fragment      ##################################
##############################################################################################################
#############################
#
#     Constructe_data_structure
#
#  Depence : %cds_code
#
#############################
sub Constructe_data_structure {
    my ($gff_file, $seq_file, $frag_p, $element_list_p) = @_;

    if($seq_file=~/\.gz$/){
        open FA, "gzip -dc $seq_file |" or die("Can't read file with gzip:$seq_file\n");
    }else {
        open FA, "<$seq_file" or die("Can't read file:$seq_file\n");
    }
    $/='>';<FA>;$/="\n";
    while(my $line=<FA>){
        ($frag_p->{'name'}) = $line=~/^(\S+)/;
        $/='>';
        $frag_p->{'seq'}=<FA>;
        chomp $frag_p->{'seq'};
        $/="\n";
        $frag_p->{'seq'}=~s/\s//g;
        $frag_p->{'len'} = length $frag_p->{'seq'};
        last;
    }
    close FA;

    open IN, "<$gff_file" or die("Can't read file:$gff_file\n");
    while(my $line=<IN>){
        my @info = split /\s+/, $line;
        @info[3,4] = @info[4,3] if($info[3] > $info[4]);  #### Reverse if start > end
        my $this_id = '';

        # NeoChr  Genovo  ARS     63819   64806   .       .       .       ID=chromosome_I_ARS108;
        # NeoChr  Genovo  gene    64807   67190   .       +       .       ID=YKR097W;
        # NeoChr  Genovo  5UTR    64807   65406   .       +       .       Parent=YKR097W;
        # NeoChr  Genovo  mRNA    65407   67056   .       +       .       Parent=YKR097W;
        # NeoChr  Genovo  CDS     65407   67056   .       +       .       Parent=YKR097W;
        # NeoChr  Genovo  loxp    67060   67094   .       +       .       ID=site_specific_recombination_target_region;Parent=YKR097W;
        # NeoChr  Genovo  3UTR    67057   67190   .       +       .       Parent=YKR097W;

        if($info[2]=~/centromere|ARS|left_telomere|right_telomere/){
            ####### elements beside gene
            ($this_id) = $info[8]=~/ID=([^;]+);?/;
            ####### frag -->  type --> element_id = @information
            @{$frag_p->{$info[2]}{$this_id}} = @info[3,4,6,8];
            push @{$element_list_p}, [$info[2], $this_id, $info[6]];
        }elsif($info[2]=~/gene|mRNA|3UTR|5UTR/){
            ####### gene element
            my $tmp;
            ($tmp, $this_id) = $info[8]=~/(ID|Parent)=([^;]+);?/;
            ####### frag -->  gene --> gene_id --> type = @information
            @{$frag_p->{'gene'}{$this_id}{$info[2]}} = @info[3,4,6,8];
            push @{$element_list_p}, [$info[2], $this_id, $info[6]] if($info[2] eq 'gene');
        }else{
            ####### CDS, loxp and decouple, etc.....
            ####### frag -->  gene --> gene_id --> anno --> type --> @each of element = @information
            ($this_id) = $info[8]=~/Parent=([^;]+);?/;
            push @{$frag_p->{'gene'}{$this_id}{'anno'}{$info[2]}}, [@info[3,4,6,8]];
        }
    }
    close IN;

    foreach my $gene (keys %{$frag_p->{'gene'}}) {
        my $fp = $frag_p->{'gene'}{$gene};

        ####### Reverse sequence
        &Reverse_gene($gene, $frag_p) if($fp->{'gene'}[2] eq '-');

        ####### CDS annotate
        my $this_code = '';
        my @code_pos;
        foreach my $cds (@{$fp->{'anno'}{'CDS'}}) {

            for my $j ($cds->[0]..$cds->[1]) {
                $this_code .= substr($frag_p->{'seq'}, $j - 1, 1);
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

        ####### lock inportant site
        foreach my $e (qw(decouple)) {
            next unless(defined $fp->{'anno'}{$e});
            foreach my $j (@{$fp->{'anno'}{$e}}) {
                &Lock_position($gene, $frag_p, $j->[0], $j->[1]);
            }
        }
    }
}

#############################
#
#     Reverse_gene
#
#  description
#
#############################
sub Reverse_gene {
    my ($gene_id, $frag_p) = @_;
    my $fp = $frag_p->{'gene'}{$gene_id};
    my %new_gene;

    my $gene_st = $fp->{'gene'}[0];
    my $gene_ed = $fp->{'gene'}[1];
    my $new_strand = $fp->{'gene'}[2] eq '+' ? '-' : '+';
    $fp->{'gene'}[2] = $new_strand;
    
    foreach my $element ('mRNA', '5UTR', '3UTR') {
        my $new_st = $gene_ed - $fp->{$element}[1] + $gene_st;
        my $new_ed = $gene_ed - $fp->{$element}[0] + $gene_st;
        $fp->{$element}[0] = $new_st;
        $fp->{$element}[1] = $new_ed;
        $fp->{$element}[2] = $new_strand;
    }

    foreach my $element (keys %{$fp->{'anno'}}) {
        foreach my $e (@{$fp->{'anno'}{$element}}) {
            my $new_st = $gene_ed - $e->[1] + $gene_st;
            my $new_ed = $gene_ed - $e->[0] + $gene_st;
            $e->[0] = $new_st;
            $e->[1] = $new_ed;
            $e->[2] = $new_strand;
        }
    }
    substr ($frag_p->{'seq'}, $gene_st - 1, $gene_ed - $gene_st + 1) = &Reverse_complement(substr ($frag_p->{'seq'}, $gene_st - 1, $gene_ed - $gene_st + 1));
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
            next if($info[0]=~/^#/);
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
    my $fp = $frag_p->{'gene'}{$gene_id};
    my $cm = $change_method_p->{$enzyme_name};

    # my $change_seq = substr ($fp->{'seq'}, $start + 1, $end - $start + 1);
    for (my $i = $start - 1; $i <= $end; $i++) {
        DIF_LEN:foreach my $e (@{$cm->{'len'}}) {
            next if($i + 1 + $e > $end);
            my $this_seq = substr($frag_p->{'seq'}, $i, $e);
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
            my $enzyme_st = $cm->{$this_seq}[-1][0] + $i + 1;
            my $enzyme_ed = length($cm->{$this_seq}[-1][1]) + $enzyme_st - 1;
            push @{$fp->{'anno'}{'enzyme'}}, [$enzyme_st, $enzyme_ed, '+', "Parent=$gene_id;name=$enzyme_name;enzyme_seq=$cm->{$this_seq}[-1][1];status=add;"];
            print "[Add Enzyme] successfully add $enzyme_name enzyme in $gene_id, position $enzyme_st.\n" if($verbose);

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
    my ($gene_id, $frag_p, $min_len) = @_;
    my $fp = $frag_p->{'gene'}{$gene_id};
    
    $min_len -= 1;

    my $match_number = 0;
    my $change_number = 0;

    my $tandem_regexp = qr/([ACGT])\1{$min_len,}/i;
    
    foreach my $e (@{$fp->{'anno'}{'CDS'}}) {

        my $target_seq = substr ($frag_p->{'seq'}, $e->[0] - 1, $e->[1] - $e->[0] + 1);
        while($target_seq=~/$tandem_regexp/g){
            my $match_seq = $&;
            my $match_start = $e->[0] + $-[0];
            my $match_end = $match_start + (length $match_seq) - 1;
            my $have_a_change = 0;
            $match_number++;
            my $change_start = $fp->{'pos'}{$match_start}{'shift'} == 1 ? $match_start + 1 : $match_start + 2;


            while($change_start <= $match_end){
                my $this_shift = $fp->{'pos'}{$change_start}{'shift'};
                my $this_code = $fp->{'pos'}{$change_start}{'code'};
                my $change_done = 0;

                if (defined $syn_code{$this_code}{$this_shift}){

                    foreach my $s (@{$syn_code{$this_code}{$this_shift}}) {
                        if(&Test_new_enzyme_site($gene_id, $frag_p, \$remove_regexp, [[$change_start, $s]]) == 1 and &Substitute_frag_base($gene_id, $change_start, $s, $frag_p) == 1){
                            $change_done = 1;
                            $have_a_change ++;
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
            if($have_a_change){
                $change_number++;
                my $changed_seq = substr ($frag_p->{'seq'}, $match_start, $match_end - $match_start + 1);
                push @{$fp->{'anno'}{'repeatsmash'}}, [$match_start, $match_end, "+", "Parent=$gene_id;origin_seq=$match_seq;optimize_seq=$changed_seq;"] if($show_detail_in_gff);
            }

        }
    }

    $fp->{'gene'}[3].= "repeat_smash=$change_number/$match_number;";
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
#  Depend: %syn_code $remove_regexp
#
#############################
sub Optimize_selected_gene {
    my ($gene_list_p, $frag_p, $codon_score_p ) = @_;

    ########### Each gene
    foreach my $g (@{$gene_list_p}) {
        my $fp = $frag_p->{'gene'}{$g};

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
                    if(&Test_new_enzyme_site($g, $frag_p, \$remove_regexp, [[$i, $first_base]]) == 1 and &Substitute_frag_base($g, $i, $first_base, $frag_p, 'mutable') == 1){
                        push @{$frag_p->{'gene'}{$g}{'anno'}{'codonoptimize'}}, [$i, $i, '+', "Parent=$g;origin_codon=$this_codon;optimize_codon=$first_syn;"] if($show_detail_in_gff);
                    }
                }
            }
        }
    }
    return 1;
}

#############################
#
#     Ranking_optimize_gene
#
#  description
#
#############################
sub Ranking_optimize_gene {
    my ($frag_p, $codon_score_p) = @_;

    foreach my $gene (keys %{$frag_p->{'gene'}}) {
        my $codon_count = 0;
        my $best_count = 0;
        foreach my $cds (@{$frag_p->{'gene'}{$gene}{'anno'}{'CDS'}}) {
            for (my $i = $cds->[0]; $i <= $cds->[1]; $i+=3) {
                $codon_count++;
                my $this_codon = $frag_p->{'gene'}{$gene}{'pos'}{$i}{'code'};
                $best_count++ if($codon_score_p->{$this_codon} == 2);
            }
        }
        my $best_codon_rate = sprintf "%.2f", $best_count/$codon_count;
        $frag_p->{'gene'}{$gene}{'gene'}[3] .= "best_codon_rate=$best_codon_rate;";
    }
    return 1;
}

##############################################################################################################
#################################      Sub function for link chromosome      #################################
##############################################################################################################
#############################
#
#     Create_fasta_and_gff
#
#  description
#
#############################
sub Create_fasta_and_gff {
    my ($fragment_order_p, $frag_p, $output_fasta_file, $output_gff_file) = @_;


    my $chr_name = $frag_p->{'name'};
    my $anno_tag = 'Genovo';
    my $gene_list_p;

    open FA, ">", "$output_fasta_file" or die("Can't write file:$output_fasta_file\n");
    open GFF, ">", "$output_gff_file" or die("Can't write file:$output_gff_file\n");

    print FA ">$chr_name\n";
    $frag_p->{'seq'}=~s/\w{60}/$&\n/g;
    chomp $frag_p->{'seq'};
    print FA $frag_p->{'seq'};
    print FA "\n";

    foreach my $f (@{$fragment_order_p}) {
        my $fn = $frag_p->{$f->[0]}{$f->[1]};
        if($f->[0] ne 'gene'){
            print GFF "$chr_name\t$anno_tag\t$f->[0]\t$fn->[0]\t$fn->[1]\t.\t$fn->[2]\t.\t$fn->[3]\n";
        }else{
            &Reverse_gene($f->[1], $frag_p) if($f->[2] eq '-');
            my @text;

            foreach my $e ('gene', 'mRNA', '5UTR', '3UTR') {
                push @text, [($chr_name, $anno_tag, $e, $fn->{$e}[0], $fn->{$e}[1], '.', $fn->{$e}[2], '.', $fn->{$e}[3])];
            }

            foreach my $e (keys %{$fn->{'anno'}}) {
                foreach my $j (@{$fn->{'anno'}{$e}}) {
                    push @text, [($chr_name, $anno_tag, $e, $j->[0], $j->[1], '.', $j->[2], '.', $j->[3])];
                }
            }

            foreach my $e (sort {$a->[3] <=> $b->[3] or $b->[4] <=> $a->[4]} @text) {
                print GFF ''.(join "\t", @{$e})."\n";
            }
        }
    }

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
#  Depend: %syn_code
#
#############################
sub Substitute_frag_base {
    my ($gene_id, $pos, $new_base, $frag_p, $change_option) = @_;

    ######### change_option can be 'test': just check this position can be canged. 'mutable': this position can still change by other method.
    $change_option ||= '';

    ######### !!!! Here, we do NOT check the change is synonymous. !!!!
    ######### -1 means format error, the length of base > 1, or not exist such pos in gene, or new base equal origin base.
    return -1 if(length $new_base != 1 or !defined $frag_p->{'gene'}{$gene_id}{'pos'}{$pos} or substr($frag_p->{'seq'}, $pos - 1, 1) eq $new_base);
    my $pp = $frag_p->{'gene'}{$gene_id}{'pos'}{$pos};

    ######### check whether the change is synonymous
    ######### -2 means nonsynonymous.
    return -2 if($pp->{'type'} eq 'CDS' and !defined $syn_code{$pp->{'code'}}{$pp->{'shift'}});

    ######### 0 means this position can NOT be changed.
    return 0 if($pp->{'immutable'});

    ######### if just test, return 1 for changeable, but do nothing.
    if(!$change_option or $change_option eq 'mutable'){
        $pp->{'immutable'} = 1 if($change_option ne '');

        ########## Record the origin base if no record before. (must be not record for V1)
        $pp->{'change'} = substr($frag_p->{'seq'}, $pos - 1, 1) if(!defined $pp->{'change'});

        ########## change the codon if the pos is in CDS.
        if($pp->{'type'} eq 'CDS'){
            my $this_shift = $pp->{'shift'};
            for my $i ($pos - $this_shift..$pos + 2 - $this_shift) {
                if(defined $frag_p->{'gene'}{$gene_id}{'pos'}{$i} and $frag_p->{'gene'}{$gene_id}{'pos'}{$i}{'type'} eq 'CDS'){
                    substr ($frag_p->{'gene'}{$gene_id}{'pos'}{$i}{'code'}, $this_shift, 1) = $new_base;
                }
            }
        }

        ########## modify the sequence of gene.
        substr ($frag_p->{'seq'}, $pos - 1, 1) = $new_base;
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

    my $fp = $frag_p->{'gene'}{$gene_id};
    my $all_changeable = 1;
    
    my $seq_len = $end_pos - $start_pos + 1;
    my $target_seq = substr ($frag_p->{'seq'}, $start_pos - 1, $seq_len);
    my $enzyme_change_count = 0;

    while(1){
        $target_seq=~/${$regexp_p}/g;
        last if(!defined pos($target_seq) or pos($target_seq) >= $seq_len);
        pos($target_seq) = $-[0] + 1;

        my $match_seq = $&;
        my $match_start = $start_pos + $-[0];
        my $match_end = $match_start + (length $match_seq) - 1;
        my $match_enzyme = $exist_enzyme_p->{$match_seq};
        my $match_length = length $&;
        my $change_done = 0;

        if(!defined $test_only){
            CHANGE_ENZYME:for my $i ($match_start..$match_end) {
                my $this_shift = $fp->{'pos'}{$i}{'shift'};
                my $this_code = $fp->{'pos'}{$i}{'code'};

                ####### next if this pos no synonymous.
                next if(!defined $syn_code{$this_code}{$this_shift});

                my $substitute_result = 0;
                foreach my $e (@{$syn_code{$this_code}{$this_shift}}) {
                    if(&Test_new_enzyme_site($gene_id, $frag_p, \$regexp_p, [[$i, $e]])){
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
        if($change_done == 0){
            $all_changeable = 0;
            push @{$fp->{'anno'}{'enzyme'}}, [($match_start, $match_end, '+', "Parent=$gene_id;name=$match_enzyme;enzyme_seq=$match_seq;status=immutable;")];
        }else{
            push @{$fp->{'anno'}{'enzyme'}}, [($match_start, $match_end, '+', "Parent=$gene_id;name=$match_enzyme;enzyme_seq=$match_seq;status=removed;")] if($show_detail_in_gff);
        }
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
    return 1 if(!defined ${$regexp_p});
    my $flank = 8;
    @{$change_list_p} = sort { $a->[0] <=> $b->[0] } @{$change_list_p} if(@{$change_list_p} > 1);
    my $start_pos = $change_list_p->[0][0] - $flank < 0 ? 0 : $change_list_p->[0][0] - $flank;
    my $end_pos = $change_list_p->[-1][0] + $flank > $frag_p->{'len'} ? $frag_p->{'len'} : $change_list_p->[-1][0] + $flank;

    my $ori_seq = substr ($frag_p->{'seq'}, $start_pos - 1, $end_pos - $start_pos + 1);

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
    my ($ori_seq) = @_;

    $ori_seq =~tr/ACGTMRWSYKVHDB/TGCAKYWSRMBDHV/;
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
        $frag_p->{'gene'}{$gene_id}{'pos'}{$e}{'immutable'} = 1;
    }
    return 1;
}

################## God's in his heaven, All's right with the world. ##################