#!/usr/bin/perl -w

=head1  example

EXPLANATION OF CONFIG FILE:

{
    "initialPlateNum": 4,                                                                                                                                                           # 96-well plates holding assembled constructs are numbered starting with this number 
    "buildSequencesFile": "input-seqs/yeast_chr1_3_16.all_bb.fasta",
    # the location of a fasta file containing seqs for the desired constructs
    "primerOutputFile": "output-files/primer-output.txt",
    # the location of a txt file which will contain primer sequence outputs
    "oligoOutputFile": "output-files/oligo-output.fasta",
    # the location of a fasta file which will contain oligo sequence outputs for the OLS pool
    "RESpacing": [ # list of offsets of enzyme cut sites from the end of the corresponding enzyme recognition sites, with enzymes ordered as in REVector
        5, 
        2, 
        5, 
        4
    ], 
    "REVector": [ # list of restriction enzymes that gasp will search through if SearchForRe is set to "True"
        "BsaI", 
        "BtsI", 
        "BsmBI", 
        "BspQI"
    ], 
    "SearchForRE": "True",
    # set this to "False" if you wish to control the exact restriction site which is used, specified by REToUse. Examples: usually set to "False" for DNA origami scaffold sequences, usually set to "True" for synthetic genes for in-vivo use.
    "REToUse": "", 
  # Restriction enzyme to use if SearchForRE is set to "False", e.g., "BsaI". Leave blank if SearchForRE is set to "True". Usually set to "BsaI" for Shih lab DNA origami scaffold sequences.
    "forwardPrimersLibraryFile": "primer-library/forward_finalprimers.fasta",
   # Fixed library of ~ 3000 orthogonal forward primers
    "reversePrimersLibraryFile": "primer-library/reverse_finalprimers.fasta", 
   # Fixed library of ~ 3000 orthogonal reverse primers
    "avgoverlapsize": 20,
   # Average length of overlap region between adjacent oligos
    "deltaGThresholdForOverlaps": -3,
   # Overlap is rejected if its hybridization free energy in kcal/mol is below this number
    "selfDimersThreshold": 3,
   # Reject a decomposition if it contains a self-dimer with free energy in kcal/mol below this number
    "insertionSizeToKillRESite": 2, 
   # Leave this set to 2 for now
    "lengthleeway": 10,
   # Leeway in oligo length that is allowed in searching for acceptable overlaps
    "overlaptemps": [ # Overlap regions must have a melting temperature in this range
        55, 
        65
    ], 
    "positionleeway": 10 
   # Leeway in junction position that is allowed in searching for acceptable overlaps
}



=head1 Contact

    Author	:  Boxian Lai
    E-mail	:  laiboxian@genomics.cn
    iGEM-team	:  Shenzhen_BGIC_0101


=cut
use strict;
use Getopt::Std;

#getopts('a:b:c:d:e:f:g:h:i:j:k:l:mn');
getopt('abcdfilnohu');
our ($opt_a,$opt_b,$opt_c,$opt_d,$opt_f,$opt_i,$opt_l,$opt_n,$opt_o,$opt_h,$opt_u);
$opt_a ||='0';
$opt_b ||='False';
$opt_c ||='10';
$opt_d ||='1';
$opt_f ||='10';
$opt_i ||='2';
$opt_n ||='3';
$opt_u ||='200';

die `pod2text $0` unless ($opt_o && $opt_l && !$opt_h);

open OUT,">$opt_o-config.json" or die "can't open the file of output file\n";



#print config file



print OUT"{\n";
print OUT"    \"configDictList\": [\n";
print OUT"        {\n";
print OUT"             \"fixedIndex\":$opt_a,\n";
print OUT"             \"fixedPrimerSetThroughoutFile\":\"$opt_b\",\n";
print OUT"             \"positionleeway\":$opt_c,\n";
print OUT"             \"fixedPlateNumber\":$opt_d,\n";
print OUT"             \"avgoverlapsize\":20,\n";
print OUT"             \"RESpacing\": [\n";
print OUT"                    2,\n";
print OUT"                    5,\n";
print OUT"                    4\n";
print OUT"             ],\n";
print OUT"             \"skip\":[\"ATbias_Seq1\"],\n"; 
print OUT"             \"lengthleeway\":$opt_f,\n";
print OUT"             \"insertionSizeToKillRESite\":2,\n";
print OUT"             \"forwardPrimersLibraryFile\":\"primer-library/forward_finalprimers.fasta\",\n";
print OUT"             \"initialPlateNum\":$opt_i,\n";
print OUT"             \"seqsToAvoidInOverlapRegions\": [],\n";
print OUT"             \"deltaGThresholdForOverlaps\":-3,\n";
print OUT"             \"overlaptemps\": [\n";
print OUT"                      55,\n";
print OUT"                      65\n";
print OUT"             ],\n";
print OUT"             \"SearchForRE\": \"True\",\n";
print OUT"             \"buildSequencesFile\":\"input-seqs/$opt_l\",\n";
print OUT"             \"reversePrimersLibraryFile\":\"primer-library/reverse_finalprimers.fasta\",\n"; 
print OUT"             \"selfDimersThreshold\": $opt_n,\n"; 
print OUT"             \"REVector\": [\n";
print OUT"                    \"BtsI\",\n";
print OUT"                    \"BsmBI\",\n"; 
print OUT"                    \"BspQI\"\n";
print OUT"             ],\n";
print OUT"             \"REToUse\": \"BtsI\",\n";
print OUT"             \"oligoSizeMax\":$opt_u\n";
print OUT"             }\n";
print OUT"          ]\n";
print OUT"}\n";

close (OUT);
