#!/usr/bin/perl -w

=head1  example
  {
     "configDictList": [
          {
               "fixedIndex": 0, 
               "fixedPrimerSetThroughoutFile": "False", 
               "positionleeway": 10, 
               "fixedPlateNumber": 1, 
               "RESpacing": [
                    2, 
                    5, 
                    4
               ], 
               "avgoverlapsize": 20, 
               "skip": [], 
               "lengthleeway": 10, 
               "insertionSizeToKillRESite": 2, 
               "forwardPrimersLibraryFile": "gaspserver/primer-library/forward_finalprimers.fasta", 
               "initialPlateNum": 2, 
               "seqsToAvoidInOverlapRegions": [], 
               "deltaGThresholdForOverlaps": -3, 
               "overlaptemps": [
                    55, 
                    65
               ], 
               "SearchForRE": "True", 
               "buildSequencesFile": "gaspserver/input-seqs/inputfile.txt", 
               "reversePrimersLibraryFile": "gaspserver/primer-library/reverse_finalprimers.fasta", 
               "selfDimersThreshold": 3, 
               "REVector": [
                    "BtsI", 
                    "BsmBI", 
                    "BspQI"
               ], 
               "REToUse": "BtsI", 
               "oligoSizeMax": 200
          }
     ]
}
=head2 gasp_para example
{
 "SMTPserver":"smtp.gmail.com",
"emailAddressFrom":"adam.h.marblestone@gmail.com",
"SMTPlogin":"gaspserver@gmail.com",
"SMTPpw":"syngaspbiogaspsisgaspgeorgechurch"
}



=cut
use strict;
use Getopt::Std;

#getopts('a:b:c:d:e:f:g:h:i:j:k:l:mn');
getopt('abcdefgzijlmnohupqtr');
our ($opt_a,$opt_b,$opt_c,$opt_d,$opt_e,$opt_f,$opt_g,$opt_z,$opt_i,$opt_j,$opt_l,$opt_m,$opt_n,$opt_o,$opt_h,$opt_u,$opt_p,$opt_q,$opt_r,$opt_t);
$opt_a ||='0';
$opt_b ||='False';
$opt_c ||='10';
$opt_d ||='1';
$opt_e ||='20';
$opt_f ||='10';
$opt_g ||='2';
$opt_i ||='2';
$opt_j ||='-3';
$opt_n ||='3';
$opt_u ||='200';

die `pod2text $0` unless ($opt_o && $opt_l && $opt_m && $opt_z && !$opt_h);
die "plase input  Email config" unless ($opt_p && $opt_q && $opt_t && $opt_r);

open OUT,">$opt_o-config.json" or die "can't open the file of output file\n";
open OUT2,">$opt_o-gasp.params" or die "can't open the file of gasp.params\n";

#print config file



print OUT"{\n";
print OUT"    \"configDictList\": [\n";
print OUT"        {\n";
print OUT"             \"fixedIndex\":$opt_a,\n";
print OUT"             \"fixedPrimerSetThroughoutFile\":\"$opt_b\",\n";
print OUT"             \"positionleeway\":$opt_c,\n";
print OUT"             \"fixedPlateNumber\":$opt_d,\n";
print OUT"             \"avgoverlapsize\":$opt_e,\n";
print OUT"             \"RESpacing\": [\n";
print OUT"                    2,\n";
print OUT"                    5,\n";
print OUT"                    4\n";
print OUT"             ],\n";
print OUT"             \"skip\":[],\n"; 
print OUT"             \"lengthleeway\":$opt_f,\n";
print OUT"             \"insertionSizeToKillRESite\":$opt_g,\n";
print OUT"             \"forwardPrimersLibraryFile\":\"gaspserver/primer-library/$opt_z\",\n";
print OUT"             \"initialPlateNum\":$opt_i,\n";
print OUT"             \"seqsToAvoidInOverlapRegions\": [],\n";
print OUT"             \"deltaGThresholdForOverlaps\":$opt_j,\n";
print OUT"             \"overlaptemps\": [\n";
print OUT"                      55,\n";
print OUT"                      65,\n";
print OUT"             ],\n";
print OUT"             \"SearchForRE\": \"True\",\n";
print OUT"             \"buildSequencesFile\":\"gaspserver/input-seqs/$opt_l\",\n";
print OUT"             \"reversePrimersLibraryFile\":\"gaspserver/primer-library/$opt_m\",\n"; 
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



# print Email file 


print OUT2"{\n";
print OUT2"\"SMTPserver\":\"$opt_p\",";
print OUT2"\"emailAddressFrom\":\"$opt_q\",";
print OUT2"\"SMTPlogin\":\"$opt_t\",";
print OUT2"\"SMTPpw\":\"$opt_r\"";
print OUT2"}";
close(OUT2);
