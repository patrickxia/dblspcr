#! /usr/bin/perl

++$|;
use strict;

die "usage: $0 inputfile.pdf" unless $ARGV[0] =~ /(.*?)\.pdf$/;

my $inputpdf = "$1.pdf";
my $inputps = "$1.ps";
my $outputps = $1-dbl.ps";
my $outputpdf = "$1-dbl.pdf";

my $retVal = system("pdftops $inputpdf $inputps");
die "pdftops failed" if $retVal;


