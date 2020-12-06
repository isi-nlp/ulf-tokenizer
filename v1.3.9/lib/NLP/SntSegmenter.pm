################################################################
#                                                              #
# SntSegmenter                                                 #
#                                                              #
################################################################

package NLP::SntSegmenter;

# use NLP::UTF8;
# $util = NLP::utilities;

sub segment {
   local($this, $s, $lang_code) = @_;

   $s =~ s/\n/ /g;
   $s =~ s/\s*$//;
   return $s if $s =~ /^\s*<sec-title.*<\/sec-title>\s*$/;
   # print STDERR "SEGMENT $s\n" if $s =~ /\[<xref/; #]
   $reg_tag = "(?:<[^<>]*>)?";
   $lang_code = "en" unless defined($lang_code);

   # protect certain ". " by inserting \x01;
   # Sen. Feinstein
   foreach $_ ((1 .. 2)) {
      $s =~ s/\b((?:Adm|Amb|Brig|Capt|Co|Col|Cpt|Dr|Eng|Fr|Gen|Gov|Hon|Ing|Lt|Maj|Mr|Mrs|Ms|Mt|Pfc|Pres|Pr|Prof|Rep|Rev|Sen|Sens|Sgt|Spt|St|Sup|Supt)\.)(\s+[A-Z][a-z]|\s+[A-Z]\.\s+[A-Z][a-z])/$1\x01$2/g;
   }
   $s =~ s/(Sgt\.)(\s+1st Class)/$1\x01$2/g;
   $s =~ s/\b((?:Jan|Feb|Febr|Apr|Aug|Sep|Sept|Oct|Nov|Dec)\.)(\s+[1-9])/$1\x01$2/g;
   $s =~ s/\b((?:No)\.)(\s+[1-9])/$1\x01$2/g;
   # J.F. Kennedy
   $s =~ s/((?:[ ()])(?:[A-Z]\.)+)(\s+(?:[A-Z]\.)+)(\s+[A-Z][a-z])/$1\x01$2\x01$3/g; # George H. + W. Bush.
   $s =~ s/^([A-Z]\.)(\s+[A-Z][a-z])/$1\x01$2/g;
   $s =~ s/((?:[ ()])(?:[A-Z]\.)+)(\s+[A-Z][a-z])/$1\x01$2/g;
   $s =~ s/\b([A-Z]{4,} (?:[A-Z]\.)+)(\s+[A-Z]{4,})/$1\x01$2/g; # MARTIN L.C. FELDMAN
   $s =~ s/^((?:[A-Z]\.)+)(\s+[A-Z]{4,})/$1\x01$2/g; # F. DENNIS
   $s =~ s/([A-Z]\S*\.)(\s(?:Jr|Sr)\.\s*)$/$1\x01$2/g; # McNeil. Jr.
   # et al. (2015)
   $s =~ s/(\bet al$reg_tag\.$reg_tag)(\s+\(\d+\))/$1\x01$2/g;
   $s =~ s/(\bet al$reg_tag\.$reg_tag)(\s+(?:19|20)\d\d)/$1\x01$2/g;
   $s =~ s/(\bet al$reg_tag\.$reg_tag)(\s+[a-z])/$1\x01$2/g;
   $s =~ s/(\bet al$reg_tag\.$reg_tag)(\s+\[<xref)/$1\x01$2/g;
   $s =~ s/(\bet\.)(\s+al$reg_tag\.?$reg_tag\s+[a-z])/$1\x01$2/g; # bad Latin even in journals
   $s =~ s/(ref$reg_tag\.$reg_tag)(\s+\[<xref)/$1\x01$2/g;
   $s =~ s/((?:vs|i\.e)$reg_tag\.$reg_tag)(\s+\S)/$1\x01$2/g;
   $s =~ s/\b(Fig\.)(\s+$reg_tag[0-9A-Z])/$1\x01$2/g;
   $s =~ s/\b([A-Z]\.)(\s+[a-z])/$1\x01$2/g;
   $s =~ s/((?:Ph\.D|M\.D)$reg_tag\.$reg_tag)(\s+\(.{1,80}\))/$1\x01$2/g;
   $s =~ s/\b((?:Co|Corp|Inc|Jr|min|resp)\.)(\s+[a-z])/$1\x01$2/g;
   $s =~ s/\b(E\.)(\s+coli)/$1\x01$2/g;
   $s =~ s/\b(S\.)(\s+cerevisiae)/$1\x01$2/g;
   $s =~ s/\b(e\.g\.|i\.e\.)(\s+[a-zA-Z])/$1\x01$2/g;
   $s =~ s/\b([a-z]\.[a-z]\.$reg_tag)(\s+(?:[a-z()]|\xE2\xA9|\xE2\x89))/$1\x01$2/g; # s.c. lower-case
   $s =~ s/([a-zA-Z]{2,2}[.!?]\xE2\x80\x9D)(\s+[a-z]+\s)/$1\x01$2/g; # end of embedded quote
   $s =~ s/\b(U\.)(\s+S\.)/$1\x01$2/g; # split U. S.
   $s =~ s/\b(U\.S\.|S\.C\.)(\s+(?:Supreme Court|Senate|Pres\.|President|Sen?s\.|Senators?|Mexico border|District Judge|Jury|Malls|Killing Spree))/$1\x01$2/ig; # U.S. Supreme Court
   $s =~ s/\b(a\.m\.|p\.m\.)(\s(?:EDT|PDT)\b)/$1\x01$2/g; # 3 p.m. EDT
   $s =~ s/([A-Z][a-z]+ v\.)(\s[A-Z][a-z])/$1\x01$2/g; # Bowers v. + Hardwick
   $s =~ s/(\s[a-z]+\s\.\.\.)(\s(?:and|be|by)\s)/$1\x01$2/g; # enunciated ... by
   foreach $i ((1 .. 2)) {
      $s =~ s/(\((?:<[^<>]*>|[^()<>]){1,60}\.)(\s(?:<[^<>]*>|[^()<>]){1,60}\))/$1\x01$2/g if $i; # keep modestly short material in parentheses together (...)
   }

   # break these after all
   $s =~ s/\b(in (?:[Pp]anel|[Tt]able|[Ff]igure) [A-Z]\.)\x01(\s+[A-Z][a-z])/$1$2/g;
   $s =~ s/([- >;\x80-\xDF][A-Z]\.)\x01(\s+(?:After|Data|Detection|Each|However|Interestingly|The|Then|This|Total)[, ])/$1$2/g;
   $s =~ s/\b(s\.d\.)\x01(\(<bold>[A-Z1-9]<\/bold>\))/$1$2/g;

   $s =~ s/([.!?]) /$1\n/g;
   $s =~ s/([.!?])(<\/(?:bold|i)>|"|\xE2\x80\x9D|<sup>(?:[^<>]*|<(?:xref) [^<>]*>[^<>]*<\/[a-z]+>)*<\/sup>) /$1$2\n/g;
   $s =~ s/\x01//g;

   # special cases: break
   $s =~ s/(\xC2\xB0[CF]\.)\s+/$1\n/g; # degree sign+[CF]
   $s =~ s/(Sos-1)\s*(\(B\) Cos-7 cells were)/$1\n$2/g;
   $s =~ s/(\.)\s*(To pinpoint)/$1\n$2/g;
   $s =~ s/(\.)\s*(Total cellular proteins)/$1\n$2/g;
   $s =~ s/(annexin V\.)\s+(Cells)/$1\n$2/g;
   $s =~ s/(as in C\.)\s+(Antibodies)/$1\n$2/g;
   $s =~ s/(subgroup [A-Z]\.)\s+(Second,)/$1\n$2/g;
   $s =~ s/(U\.S\.)\s+(Ramadan)\b/$1\n$2/g;

   # special cases: don't break
   $s =~ s/(,\s+cat\.)\s+(no?.\s+\d)/$1 $2/g;
   $s =~ s/([.!?])\s+(\(PMID:\d+\)\s*)$/$1 $2/g; # headline (PMID:12345678)
   $s =~ s/( models\.)\s+(such as )/$1 $2/g; # probably bad English
   $s =~ s/(More recently,)\s+(\S)/$1 $2/g; # bad paragraph break
   $s =~ s/(the molecules'expression\.)\s+(and <i>EGFR)/$1 $2/g; # bad English
   $s =~ s/(me\?")\s+(the)/$1 $2/g;

   # special cases: glue
   $s =~ s/(\xE2\x80\xB2|&#x02032;|[ACGT]{4,4})(-)\s+([ACGT]{4,4})/$1$2$3/g; # DNA sequences
   $s =~ s/(\xE2\x80\xB2|&#x02032;|[ACGT]{4,4})(-)\s+([ACGT]{4,4})/$1$2$3/g; # DNA sequences

   return $s;
}

1;

