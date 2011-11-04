#! /usr/bin/perl

++$|;
use strict;

die "usage: $0 inputfile.pdf" unless $ARGV[0] =~ /(.*?)\.pdf$/;

my $inputpdf = "$1.pdf";
my $inputps = "$1.ps";
my $outputps = "$1-dbl.ps";
my $outputpdf = "$1-dbl.pdf";

my $retVal = system("pdftops $inputpdf $inputps");
die "pdftops failed" if $retVal;

open my $ifh, $inputps;
open my $ofh, ">$outputps";

for my $line (<$ifh>) {
  # Change document size
  $line =~ s/^(\%\%DocumentMedia: \w+ \d+ )(\d+)/$1.($2 * 2)/e;
  $line =~ s/^(\%\%BoundingBox: \d+ \d+ \d+ )(\d+)/$1.($2 * 2)/e;
  $line =~ s|pdfSetup {|$& exch 2 mul exch |;

  # Change y
  $line =~ s|/cm {|$& dup dup 5 get 2 mul 5 2 -1 roll put |; 
  $line =~ s|/re {|$& 3 2 roll 2 mul 3 -2 roll 2 mul |;
  $line =~ s|/Td { pdfTextMat transform|$& 2 mul |;
  print $ofh $line;
}

