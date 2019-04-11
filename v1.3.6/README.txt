tok-eng version 1.3.5
Release date: April 2, 2019
Author: Ulf Hermjakob, USC Information Sciences Institute

English tokenizer tokenize-english.pl

Usage: tokenize-english.pl [--bio] < STDIN
       Option --bio is for biomedical domain.

Example: bin/tokenize-english.pl --bio < test/tok-challenge.txt > test/tok-challenge.tok
Example: bin/tokenize-english.pl --bio < test/bio-amr-snt.txt > test/bio-amr-snt.tok
Example: bin/tokenize-english.pl < test/amr-general-corpus.txt > test/amr-general-corpus.tok

Tokenizer uses two data files:
(1) List of common English abbreviations (data/EnglishAbbreviations.txt)
    e.g. Jan., Mr., Ltd., i.e., fig. in order to keep abbreviation periods
    attached to their abbreviations.
(2) List of bio patterns to be split/not split (data/BioSplitPatterns.txt)
    e.g. 'SPLIT-DASH-X activated' means that 'P53-activated' should be
          split into 'P53 @-@ activated'
    e.g. 'DO-NOT-SPLIT up-regulate' that 'up-regulate' should stay together.

The tokenizer (in --bio mode) includes a few expansions such as
    Erk1/2 -> Erk1 @/@ Erk2
    Slac2-a/b/c -> Slac2-a @/@ Slac2-b @/@ Slac2-c
which go beyond tokenization in the strictest sense.

The tokenizer (in --bio mode) attempts to split compounds of multiple
molecules while keeping together names for single molecules as far as
this is possible without an extensive database of molecule names.
Example: 'ZO-1/ZO-2/ZO-3' -> 'ZO-1 @/@ ZO-2 @/@ ZO-3'

But without an extensive corpus of molecule names, there are some
limitations in cases such as 'spectrin-F-actin' where heuristics 
might suggest us that "F" is an unlikely molecule name, but where 
it's not clear from simple surface patterns whether the proper 
decomposition is
    spectrin @-@ F-actin   or
    spectrin-F @-@ actin   or
    spectrin-F-actin.
(Based on biological knowledge, the first alternative is the correct 
one, but the tokenizer leaves 'spectrin-F-actin' unsplit.)

-----------------------------------------------------------------

Changes in version 1.3.5:
- Better treatment of extended Latin (e.g. Lithuanian), Cyrillic scripts
- minor improvements re: km2 &x160; No./No.2
Changes in version 1.3.4:
- Replace replacement character with original character in some predictable cases.
- Minor incremental improvements/corrections.
Changes in version 1.3.3:
- Various incremental improvements, particularly relating to period splitting.
- Question marks and exclamation marks are separate tokens (as opposed to clusters of question and exclamation marks).

Changes in version 1.3.2:
- Improved treatment of punctuation, particular odd characters (trademark sign,
  British pound sign) and clusters of punctuation.
- Rare xml-similar tags such [QUOTE=...] and [/IMG]
- Split won't -> will n't; ain't -> is n't; shan't -> shall n't; cannot -> can not
- Keep together: ftp://... e.g. ftp://ftp.funet.fi/pub/standards/RFC/rfc959.txt
- Keep together: mailto:... e.g. mailto:ElRushbo@eibnet.com
- Keep together Twitter hashtags and handles e.g. #btw2017 @nimjan_uyghur
- Impact: 4-5% of sentences in general AMR corpus

-----------------------------------------------------------------

XML sentence extractor xml-reader.pl

Usage: xml-reader.pl -i <xml-filename> [--pretty [--indent <n>]] [--html <html-filename>] [--docid <input-docid>] [--type {nxml|elsxml|ldcxml}]
       <xml-filename> is the input file in XML format
       --pretty is an option that will cause the output to be XML in "pretty" indented format.
          -- index <n> is a suboption to specify the number of space characters per indentation level
       --html <html-filename> specifies an optional output file in HTML that displays the output sentences
                              in a format easily readable (and checkable) by humans
       --docid <input-docid> is an optional input; needed in particular if system can't find docid
                             inside input XML file.
       --type {nxml|elsxml} specifies optional special (non-standard) input type (XML variant).
                            Type will be automatically deduced for filenames ending in .nxml or .elsxml.

Example: bin/xml-reader.pl -i test/Cancel_Cell_pmid17418411.nxml | bin/normalize-workset-sentences.pl | bin/add-prefix.pl a3_ > test/Cancel_Cell_pmid17418411.txt
   Output file test/Cancel_Cell_pmid17418411.txt should match reference file test/Cancel_Cell_pmid17418411.txt-ref
   Postprocessing with normalize-workset-sentences.pl and add-prefix.pl a3_ is recommended. (See note below.)
Example: xml-reader.pl -i test/Cancel_Cell_pmid17418411.nxml --pretty --indent 3
Example: xml-reader.pl -i test/Cancel_Cell_pmid17418411.nxml --html test/Cancel_Cell_pmid17418411.html --docid PMID:17418411 --type nxml

Auxiliary micro-scripts:
   normalize-workset-sentences.pl < STDIN
      normalized spaces wrt XML tags xref/title/sec-title.
   add-prefix.pl <prefix> < STDIN
      adds prefix <prefix> at beginning of each line.
It is strongly recommended to use normalize-workset-sentences.pl and add-prefix.pl a3_
where the a3_-prefix indicates that the segmented sentences have been generated
automatically. This allows fresh sentence IDs in the future for manually corrected
sentence segmentation or improved sentence segmentation without created a sentence ID
conflict.

