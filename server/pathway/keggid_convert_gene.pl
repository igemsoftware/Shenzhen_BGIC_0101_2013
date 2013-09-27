#!/usr/bin/perl -w
use strict;
die "This stript will convert the Kegg id into genes through genelist.\nUsage:\nperl $0 <pathway_name>\nFor example:\nperl $0 ko04010\n" unless @ARGV>=1;

my $pathway=$ARGV[0];

my $list=$pathway;
for(my $i=0;$i<5;$i++)
{
   chop($list);
}

open LIST,"<$list.txt" or die $!;
my %hash;
while(<LIST>)
{
	chomp;
	my ($name,$detail)= split;
    chop($detail);
	$hash{$name}=$detail;
}
close LIST;

open PATHWAY,"<$pathway.xml" or die $!;
open OUT,">./out.xml" or die $!;
while(<PATHWAY>)
{
	chomp;
	my $key;
	foreach $key (sort keys %hash)
	{
		$_ =~ s/$key/$hash{$key}/g;
	}
	$_ =~ s/ortholog/gene/g;
	print OUT "$_\n";
}
close PATHWAY;
`mv out.xml $pathway.xml`;

