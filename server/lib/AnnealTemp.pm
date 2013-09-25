package AnnealTemp;
# This module used to calculate annealing temperature of DNA only.

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(Tm);
%EXPORT_TAGS = ( Only => [qw(&Tm)]);

sub Tm {
  my @line = @_;
  my $seq = $line[0];
  $seq = lc ($seq);
  #print "$seq\n";
  my $seqlen = length($seq); 
  #print "Sequence length:$seqlen\n";
  my %enthalpy = ("aa", -7.6,
                 "ac", -8.4,
                 "ag", -7.8,
                 "at", -7.2,
                 "ca", -8.5,
                 "cc", -8.0,
                 "cg", -10.6,
                 "ct", -7.8,
                 "ga", -8.2,
                 "gc", -9.8,
                 "gg", -8.0,
                 "gt", -8.4,
                 "ta", -7.2,
                 "tc", -8.2,
                 "tg", -8.5,
                 "tt", -7.6);
  my %entropy =   ("aa", -21.3,
                 "ac", -22.4,
                 "ag", -21,
                 "at", -20.4,
                 "ca", -22.7,
                 "cc", -19.9,
                 "cg", -27.2,
                 "ct", -21,
                 "ga", -22.2,
                 "gc", -24.4,
                 "gg", -19.9,
                 "gt", -22.4,
                 "ta", -21.3,
                 "tc", -22.2,
                 "tg", -22.7,
                 "tt", -21.3);
  # Tm calculating...
  my $dH = 0.2;
  my $dS = -5.7;

  for(my $i=0; $i<$seqlen-1;$i++){
 	  my $ss = substr($seq,$i,2);
 	  $dH += $enthalpy{$ss};
 	  $dS += $entropy{$ss};
	 }
  if(substr($seq, $seqlen-1) eq "a" || substr($seq, $seqlen-1) eq "t"){
	  $dH += 2.2;
	  $dS += 6.9;
	 }
  my  $tm = 945*$dH/($dS + 1.9872*log(0.0001)) - 273.15;
  $tm = (int ($tm*100))/100;
 # printf ("Annealing temperature:%6.2f\n",$tm);
  return $tm ;
}
  1;
