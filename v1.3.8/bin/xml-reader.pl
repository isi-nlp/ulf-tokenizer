#!/usr/bin/perl -w

# Author: Ulf Hermjakob
# First written: February 2, 2015
# Version: 1.3 (May 16, 2017)

# Usage: xml-reader.pl -i <xml-filename> [--pretty [--indent <n>]] [--html <html-filename>] [--docid <input-docid>] [--type {nxml|elsxml|ldcxml}]
#        <xml-filename> is the input file in XML format
#        --pretty is an option that will cause the output to be XML in "pretty" indented format.
#           -- index <n> is a suboption to specify the number of space characters per indentation level
#        --html <html-filename> specifies an optional output file in HTML that displays the output sentences 
#                               in a format easily readable (and checkable) by humans
#        --docid <input-docid> is an optional input; needed in particular if system can't find docid 
#                              inside input XML file.
#        --type {nxml|elsxml} specifies optional special (non-standard) input type (XML variant). 
#                             Type will be automatically deduced for filenames ending in .nxml or .elsxml.
# Example: bin/xml-reader.pl -i test/Cancel_Cell_pmid17418411.nxml | bin/normalize-workset-sentences.pl | bin/add-prefix.pl a3_ > test/Cancel_Cell_pmid17418411.txt
# Example: xml-reader.pl -i test/Cancel_Cell_pmid17418411.nxml --pretty --indent 3
# Example: xml-reader.pl -i test/Cancel_Cell_pmid17418411.nxml --html test/Cancel_Cell_pmid17418411.html --docid PMID:17418411 --type nxml

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
use NLP::utilities;
use NLP::xml;

$xml = NLP::xml;
%ht = ();
$pretty_print_p = 0;
$xml_in_filename = "";
$html_out_filename = "";
$xml_id = "XML1";
$doc_id = "";
$workset_name = "";
$snt_id_core = "";
$schema = "";
$indent = 3;
$xml_type = "";

while (@ARGV) {
   $arg = shift @ARGV;
   if ($arg =~ /^-+(pretty|pp)$/) {
      $pretty_print_p = 1;
   } elsif ($arg =~ /^-+(i|xml)$/) {
      $xml_in_filename = shift @ARGV;
      $xml_type = "elsxml" if ($xml_type eq "") && ($xml_in_filename =~ /\.elsxml$/);
      $xml_type = "nxml" if ($xml_type eq "") && ($xml_in_filename =~ /\.nxml$/);
   } elsif ($arg =~ /^-+indent$/) {
      $indent = shift @ARGV;
   } elsif ($arg =~ /^-+doc[-_]?id$/) {
      $doc_id = shift @ARGV;
   } elsif ($arg =~ /^-+html$/) {
      $html_out_filename = shift @ARGV;
   } elsif ($arg =~ /^-+(xml[-_]?type|type)$/) {
      $xml_type = shift @ARGV;
   } else {
      print STDERR "Ignoring unrecognized arg $arg\n";
   }
}

if ($xml_type eq "elsxml") {
   @snts = split(/\n/, $xml->extract_elsxml_paper_snts($xml_in_filename, *ht, $xml_id, $doc_id, $schema));
} elsif ($xml_type eq "nxml") {
   @snts = split(/\n/, $xml->extract_nxml_paper_snts($xml_in_filename, *ht, $xml_id, $doc_id, $schema));
} elsif ($xml_type eq "ldcxml") {
   @snts = split(/\n/, $xml->extract_ldc_snts($xml_in_filename, *ht, $xml_id, $doc_id, $schema));
} else {
   # The following read_xml_file is already included in above extract_...xml_paper_snts
   $xml->read_xml_file($xml_in_filename, *ht, $xml_id, $schema);
}

unless ($doc_id) {
   $doc_id = $xml->find_doc_id(*ht, $xml_id, $xml_type, "pmid")
          || $xml->find_doc_id(*ht, $xml_id, $xml_type, "pmc")
          || $xml->find_doc_id(*ht, $xml_id, $xml_type);
}

if ($pretty_print_p) {
   print $xml->write_xml("1.1", *ht, $xml_id, $schema, $indent);
} else {
   die "No doc_id available (neither as argument nor in specified in doc)" unless $doc_id;
   $workset_name = lc $doc_id;
   $workset_name =~ s/[_:]+/-/g;
   $snt_id_core = $workset_name;
   $snt_id_core =~ s/-+/_/g;
   if ($snt_id_core =~ /\d\d\d\d\d$/) {
      $snt_id_core =~ s/(\d\d\d\d)$/_$1/;
   } elsif ($snt_id_core =~ /\d[-_.]\d\d\d\d$/) {
      $snt_id_core =~ s/[-_.](\d\d\d\d)$/_$1/;
   } else {
      $snt_id_core .= "_0000";
   }
   if ($html_out_filename) {
      $n_snt = $xml->write_workset_to_html(*ht, $html_out_filename, $doc_id, $workset_name, $snt_id_core, $schema, @snts);
   } else {
      $n_snt = $xml->write_workset_as_plain_txt(*ht, *STDOUT, $snt_id_core, @snts);
   }
   print STDERR "Output $n_snt sentences\n";
}

exit 0;

