#! /usr/bin/perl

use strict;
use warnings;
use LWP::Simple;
use HTML::TokeParser;
use Getopt::Long;
my %pa;
GetOptions(
		'ENZYM=s'	=>	\$pa{ENZYM},
		'NOWEB'		=>	\$pa{NOWEB},
		'HELP'		=>	\$pa{HELP}
	  );

sub disHelp {
	print "This is the plugin to fetch the enzymes' price from neb.com\n";
	print "-E\tthe enzyme to fetch\n";
	print "-N\tno web, fetch from local file\n";
	print "-H\tdisplay this help.\n";
}

if( $pa{HELP} ) {
	disHelp();
	exit(0);
}
unless( $pa{ENZYM} ) {
	print "No enzyme was named.\n";
	disHelp();
	exit(0);
}

my $ProductFilePath = "GetPrice/product.txt";
open ProductFile, "<$ProductFilePath" or die "#! $ProductFilePath";
my $flag = 0;
while( <ProductFile> ) {
	my @data = split( '\s+', $_ );
	if( $data[0] eq $pa{ENZYM} or $data[0] eq $pa{ENZYM}."®" or $data[0] eq $pa{ENZYM}."™") {
		$flag = 1;
		print "$data[0]\t$data[1]\t$data[2] $data[3]\t $data[4]";
		print "\n";
	}
}
if( $flag ==  0 ) {
	my $webFilePath = "GetPrice/web.txt";
	open webFile, "<$webFilePath" or die "#! $webFilePath";
	my $web;
	my @data;
	my $flag = 0;
	while( <webFile> ) {
		@data = split;
		if( $data[0] eq $pa{ENZYM} or $data[0] eq $pa{ENZYM}."®" or $data[0] eq $pa{ENZYM}."™" ) {
			$web = $data[-1];
			$flag = 1;
			last;
		}
	}
	if( $flag == 0 ) { die "unable to find the enzyme: $pa{ENZYM}";}
	my $root = "https://www.neb.com";
	#print "fetch from $root$web\n";
	my $html = get( $root.$web );
	unless( defined( $html ) ) { die "unable to get to the website"; }
	my $stream = HTML::TokeParser->new(\$html);
	my @Catalog;
	my @Size;
	my @Price;
	while(my $token = $stream->get_token){
		if ($token->[0] eq 'S' && $token->[1] eq 'td') {
			if( defined( $token->[2]{'class'} ) && $token->[2]{'class'} eq "sku" ) {
				my $cat = $stream->get_text();
				push( @Catalog, $cat );
				for( 1..2 ) { $stream->get_token; }
				my $size = $stream->get_text();
				push( @Size, $size );
				for( 1..5 ) { $stream->get_token; }
				my $price = $stream->get_text();
				push( @Price, $price );
			}
		}
	}
	for( 0..@Price-1 ) {
		print $data[0]."\t".$Catalog[$_]."\t".$Size[$_]."\t".$Price[$_]."\n";
	}
}
