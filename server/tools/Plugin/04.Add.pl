#!/usr/bin/perl -w


use strict;
use Getopt::Long;
my ($help,$);
GetOptions(
		""=>\$,
		"help"=>\$help,
);
$ ||= '';

die `pod2text $0` if (@ARGV != 3);

my $input = shift;
my $output = shift;

open IN,"$input" || die "fail open $input";
while(<>)
{
    chomp;
}
close IN;

open OUT,"$output" || die "fail open $output";
{
    chomp;
}
close OUT;


