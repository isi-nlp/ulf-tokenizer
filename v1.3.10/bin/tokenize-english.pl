#!/usr/bin/perl -w

# Author: Ulf Hermjakob
# Written: May 15, 2017 - April 23, 2021

# $version = "v1.3.10";

$|=1;

use FindBin;
use Cwd "abs_path";
use File::Basename qw(dirname);
use File::Spec;

my $bin_dir = abs_path(dirname($0));
my $root_dir = File::Spec->catfile($bin_dir, File::Spec->updir());
my $data_dir = File::Spec->catfile($root_dir, "data");
my $lib_dir = File::Spec->catfile($root_dir, "lib");

use lib "$FindBin::Bin/../lib";
use NLP::English;
use NLP::utilities;
use NLP::UTF8;
$englishPM = NLP::English;
$control = " ";
$english_abbreviation_filename = File::Spec->catfile($data_dir, "EnglishAbbreviations.txt");
$bio_split_patterns_filename = File::Spec->catfile($data_dir, "BioSplitPatterns.txt");
%ht = ();

while (@ARGV) {
   $arg = shift @ARGV;
   if ($arg =~ /^-*bio/) {
      $control .= "bio ";
   } else {
      print STDERR "Ignoring unrecognized arg $arg\n";
   }
}

$englishPM->load_english_abbreviations($english_abbreviation_filename, *ht);
$englishPM->load_split_patterns($bio_split_patterns_filename, *ht);

while (<>) {
   ($pre, $s, $post) = ($_ =~ /^(\s*)(.*?)(\s*)$/);
   my $s = $englishPM->tokenize($s, *ht, $control);
   $s =~ s/^\s*//;
   $s =~ s/\s*$//;
   print "$pre$s$post";
}

exit 0;

