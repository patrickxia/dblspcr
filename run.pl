#! /usr/bin/perl
# doublespaces a two-column pdf
# req: xpdf (pdftops, pstops, pstopdf)
# only tested with v0.12.4
# req: pdfcrop
# only tested with 1.20

++$|;
use strict;
sub filter($);

die "usage: $0 inputfile.pdf" unless $ARGV[0] =~ /(.*?)\.pdf$/;

my $inputpdf = "$1.pdf";
my $inputps = "$1.ps";
my $outputps = "$1-tmp.ps";
my $tmppdf = "$1-tmp.pdf";
my $finalps = "$1-dbl.ps";
my $outputpdf = "$1-dbl.pdf";

my $cmd = "pdftops $inputpdf $inputps";
print "Executing $cmd\n";
my $retVal = system($cmd);
die "pdftops failed" if $retVal;

my $pageWidth;
my $pageHeight;

open my $ifh, $inputps;
open my $ofh, ">$outputps";

print "Filtering postscript...\n";
for my $line (<$ifh>) {
  print $ofh filter($line);
}
close $ofh;
close $ifh;

# now to rearrange pages
# pages are currently twice as tall. cut them in half

my $DPageHeight = $pageHeight * 2;
my $hPageWidth = $pageWidth / 2;
$cmd = "pstops -q -w$pageWidth -h$DPageHeight ";
my $slop = 50;
my $hWithSlop = -$pageHeight+$slop;
$cmd .="\"0(0,$hWithSlop),0(0,$slop),0(-$hPageWidth,$hWithSlop),0(-$hPageWidth,$slop)\" ";
$cmd .= "$outputps $finalps";
print "Executing $cmd\n";
die "pstops failed" if system($cmd);

open my $ifh, $finalps;
open my $ofh, ">$outputps";
print "Refiltering postscript to $outputps...\n";
my $boundingBox;
for (<$ifh>) {
  s/^(\%\%DocumentMedia: \w+) \d+ \d+/$1 $hPageWidth $pageHeight/ and print;
  s/^(\%\%BoundingBox: (\d+ \d+)) \d+ \d+/$1 $hPageWidth $pageHeight/ and 
    ($boundingBox = $2. " $hPageWidth $pageHeight", print);
  print $ofh $_;
}
close $ofh;
close $ifh;

print "Converting to pdf...\n";
system("pstopdf $outputps");
$cmd = "pdfcrop --bbox \"$boundingBox\" $tmppdf $tmppdf.crop.pdf";
print "Executing $cmd...\n";
system($cmd);
print "Converting back to postscript...\n";
system("pdftops -paperw $pageWidth -paperh $pageHeight -nocenter $tmppdf.crop.pdf $outputps");

#my $slop = 50;
#$cmd = "pstops -q -w$pageWidth -h$pageHeight ";
#$cmd .="\"2:0(0,$slop),1(0,-$slop)\" ";
#$cmd .= "$finalps $outputps";
#print "Executing $cmd\n";
#die "pstops failed" if system($cmd);

$cmd = "pstops -q -w$pageWidth -h$pageHeight ";
$cmd .="\"2:0(0,0)+1($hPageWidth,0)\" ";
$cmd .= "$outputps $finalps";
print "Executing $cmd\n";
die "pstops failed" if system($cmd);


$cmd = "pstopdf -q $finalps $outputpdf >/dev/null 2>&1";
print "Executing $cmd\n";
die "pstopdf failed" if system($cmd);


sub filter($) {
  $_ = shift;
  # Document size
  s/^(\%\%DocumentMedia: \w+ (\d+) )(\d+)/$1.($3 * 2)/e and 
    ($pageWidth = $2, $pageHeight = $3, print);
  s/^(\%\%BoundingBox: \d+ \d+ \d+ )(\d+)/$1.($2 * 2)/e and print;
  s|pdfSetup {|$& exch 2 mul exch | and print;

  # Change y
  s|/cm {|$& dup dup 5 get 2 mul 5 2 -1 roll put | and print; 
  s|/re {|$& 3 2 roll 2 mul 3 -2 roll 2 mul | and print;
  s|/Td { pdfTextMat transform|$& 2 mul | and print;
  return $_;
}

