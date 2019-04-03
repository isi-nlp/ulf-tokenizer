################################################################
#                                                              #
# xml                                                          #
#                                                              #
################################################################

package NLP::xml;

use NLP::SntSegmenter;
use NLP::UTF8;
use NLP::utilities;

$snt_segm = NLP::SntSegmenter;
$utf8 = NLP::UTF8;
$util = NLP::utilities;

sub read_xml_file {
   local($this, $filename, *ht, $xml_id, $schema, $control) = @_;

   $control = "" unless defined($control);
   my $s = $util->read_file($filename);
   $s =~ s/<\/?a\b[^<>]*\/?>//ig if $control =~ /-a\b/;
   $s =~ s/<\/?img\b[^<>]*\/?>//ig if $control =~ /-img\b/;
   $this->read_xml($s, *ht, $xml_id, $schema, $control);
}

sub n_newlines {
   local($this, @strings) = @_;

   my $n = 0;
   foreach $s (@strings) {
      $n += (() = ($s =~ /\n/g));
   }
   return $n;
}

sub level_of_tag_nesting {
   local($this, *ht, $xml_id, $node_id, $ref_tag) = @_;
 
   my $n = 0;
   while ($node_id) {
      my $tag = $ht{$xml_id}->{TAG}->{$node_id};
      $n++ if $tag && ($tag eq $ref_tag);
      $node_id = $ht{$xml_id}->{PARENT}->{$node_id};
   }
   return $n;
}

sub read_xml {
   local($this, $s, *ht, $xml_id, $schema, $control) = @_;

   my $ping_every_n_lines = 100;
   my $next_ping_at = 0;
   my $line_number = 1;
   my $nesting_level = 0;
   my $printed_message_p = 0;
   my $parent_node_id = "1";
   $ht{$xml_id}->{N_SUBS}->{$parent_node_id} = 0;
   $ht{$xml_id}->{SCHEMA} = $schema;
   $control = "" unless defined($control);
   my $prev_text = "";
   $s =~ s/(<ext-link(?: (?:[^<>]*))?) xlink:(href=)/$1 $2/g;  # xlink:href -> href
   # $tmp = $s;
   # $tmp =~ s/.*(<ext-link[^<>]*>).*/$1/s;
   # print STDERR "EXT-LINK: $tmp\n";
   while ($s ne "") {
      if ($line_number >= $next_ping_at) {
	 print STDERR ".";
	 $next_ping_at += $ping_every_n_lines;
      }
      $s =~ s/^\xEF\xBB\xBF//;
      # <!--...--> # comment
      if (($tag, $rest) = ($s =~ /^(\s*<!--.*?-->)(.*)$/s)) {
         $line_number += $this->n_newlines($tag);
	 $prev_text = $tag;
      # open tag
      } elsif (($pre, $tag, $arg_s, $close_s, $rest) = ($s =~ /^(\s*)<([a-zA-Z][-_:a-zA-Z0-9]*)([^<>]*?)(\s*\/|)>(.*)$/s)) {
	 $line_number += $this->n_newlines($pre);
         $tag = lc $tag;
	 $nesting_level++;
	 $ht{$xml_id}->{N_SUBTAGS}->{$parent_node_id} = ($ht{$xml_id}->{N_SUBTAGS}->{$parent_node_id} || 0) + 1;
	 $n_subs = $ht{$xml_id}->{N_SUBS}->{$parent_node_id} || 0;
	 $n_subs++;
	 $ht{$xml_id}->{N_SUBS}->{$parent_node_id} = $n_subs;
	 $node_id = join(".", $parent_node_id,$n_subs);
         $ht{$xml_id}->{PARENT}->{$node_id} = $parent_node_id;
	 $ht{$xml_id}->{N_SUBS}->{$node_id} = 0;
	 $ht{$xml_id}->{TAG}->{$node_id} = $tag;
	 # print STDERR "   OPEN <$tag> $node_id (l.$line_number)\n";
	 $ht{$xml_id}->{START_LINE}->{$node_id} = $line_number;
         while (($pre, $slot, $value, $arg_rest) = ($arg_s =~ /^(\s*)([a-zA-Z][-:_a-zA-Z0-9]*)=("[^"]*"|'[^']*')(.*)$/s)) {
	    if ($value =~ /^".*"$/) {
	       $value =~ s/^"//;
	       $value =~ s/"$//;
	    } elsif ($value =~ /^'.*'$/) {
	       $value =~ s/^'//;
	       $value =~ s/'$//;
	    }
	    $line_number += $this->n_newlines($pre);
            $arg_s = $arg_rest;
	    $slot = lc $slot;
	    $ht{$xml_id}->{ARG}->{$node_id}->{$slot} = $value;
	    $line_number += $this->n_newlines($slot, $value);
	 }
	 if ($arg_s =~ /\S/) {
	    print STDERR "   Unprocessed (remaining) tag arg string '$arg_s' in line $line_number in $xml_id\n";
	    $printed_message_p = 1;
	 }
         $n_tags = $ht{$xml_id}->{N_TAGS}->{$tag} || 0;
	 $n_tags++;
	 $ht{$xml_id}->{N_TAGS}->{$tag} = $n_tags;
	 $ht{$xml_id}->{NTH_TAG}->{$tag}->{$n_tags} = $node_id;
         if ($close_s ne "") {
	    $ht{$xml_id}->{END_LINE}->{$node_id} = $line_number;
	    $nesting_level--;
	 } else {
	    $parent_node_id = $node_id;
	 }
	 $prev_text = "<" . "$tag$arg_s$close_s" . ">";
      # close tag
      } elsif (($pre, $tag, $rest) = ($s =~ /^(\s*)<\/([a-zA-Z][-_:a-zA-Z0-9]*)>(.*)$/s)) {
	 $line_number += $this->n_newlines($pre);
	 # print STDERR "   CLOSE <\/$tag> $parent_node_id (l.$line_number)\n";
         $tag = lc $tag;
	 $open_tag = $ht{$xml_id}->{TAG}->{$parent_node_id} || "?";
         if ($tag ne $open_tag) {
	    $open_tag_start = $ht{$xml_id}->{START_LINE}->{$parent_node_id} || "?";
	    print STDERR "Ignoring close tag $tag (line $line_number in $xml_id), because it does not match open tag $open_tag (line $open_tag_start)\n";
	    $printed_message_p = 1;
	  # print LOG "Ignoring close tag $tag (line $line_number in $xml_id), because it does not match open tag $open_tag (line $open_tag_start)\n" if defined LOG;
	 } else {
	    $parent_node_id = $ht{$xml_id}->{PARENT}->{$parent_node_id} || 0;
	    $nesting_level--;
	 }
	 $prev_text = "</" . $tag . ">";
      # special/bad tag
      } elsif (($pre, $tag, $rest) = ($s =~ /^(\s*)(<[^<>]*>?)(.*)$/s)) {
	 $line_number += $this->n_newlines($pre);
         # <!DOCTYPE...>
	 if ($tag =~ /^\s*<!DOCTYPE[^<>]*>/s) {
	    $ht{$xml_id}->{DOCTYPE} = $doctype if ($doctype) = ($tag =~ /^<!DOCTYPE\s+(\S+).*>/s);
	    $ht{$xml_id}->{SYSTEM} = $system if ($system) = ($tag =~ / SYSTEM\s+\"([^"]*)\"/s);
         # <?...?>
         } elsif ($tag =~ /^\s*<\?xml\s[^<>]*\?>/s) {
	    $ht{$xml_id}->{XML_VERSION} = $version if ($version) = ($tag =~ /^<\?xml\s+[^<>]*bversion="([^"]+)"[^<>]*\?>$/s);
         } elsif ($tag =~ /^\s*<\?properties\s[^<>]*\?>/s) {
	    $ht{$xml_id}->{PROPERTIES} = $properties if ($properties) = ($tag =~ /^<\?properties\s+([^<>]*?)\s*\?>$/s);
         } elsif ($tag =~ /^\s*<\?supplied-pmid\s[^<>]*\?>/s) {
	    # ignore pmid of referenced papers
	 } else {
            print STDERR "Ignoring unrecognized tag $tag in line $line_number of $xml_id\n";
	    $printed_message_p = 1;
          # print LOG "Ignoring unrecognized tag $tag in line $line_number\n" if defined LOG;
	 }
	 $line_number += $this->n_newlines($tag);
	 $prev_text = $tag;
      # text
      } elsif (($text, $rest) = ($s =~ /^([^<>]+)(.*)$/s)) {
	 $ht{$xml_id}->{N_SUBTEXTS}->{$parent_node_id} = ($ht{$xml_id}->{N_SUBTEXTS}->{$parent_node_id} || 0) + 1;
         $n_subs = $ht{$xml_id}->{N_SUBS}->{$parent_node_id} || 0;
	 $n_subs++;
	 $ht{$xml_id}->{N_SUBS}->{$parent_node_id} = $n_subs;
	 $node_id = join(".", $parent_node_id,$n_subs);
	 $ht{$xml_id}->{PARENT}->{$node_id} = $parent_node_id;
	 $ht{$xml_id}->{N_SUBS}->{$node_id} = 0;
	 $ht{$xml_id}->{TAG}->{$node_id} = "TEXT";
	 $ht{$xml_id}->{TEXT}->{$node_id} = $text;
         $line_number += $this->n_newlines($text);
	 $prev_text = $text;
      # final catch all (should never get here)
      } else {
         $s = substr($s, 0, 160) . "....." if length($s) > 160;
         print STDERR "Ignoring rest starting in $xml_id line $line_number: $prev_text *FROM-HERE->* $s\n";
	 $printed_message_p = 1;
       # print LOG "Ignoring rest starting in $xml_id line $line_number: $prev_text *FROM-HERE->* $s\n" if defined(LOG);
         $rest = "";
	 $prev_text = $s;
      }
      $s = $rest;
   }
   if ($nesting_level) {
      print STDERR "Unbalanced xml (ending with nesting level $nesting_level) at line $line_number in $xml_id \n";
      $printed_message_p = 1;
   }
 # print LOG "Unbalanced xml (ending with nesting level $nesting_level)\n" if $nesting_level && defined(LOG);
   $line_number--;
   unless ($control =~ /\bsilent\b/) {
      print STDERR "Read in $line_number lines.\n";
      $printed_message_p = 1;
   }
 # print LOG "Read in $line_number lines.\n" unless ($control =~ /\bsilent\b/) || (! defined(LOG));
   print STDERR "\n" if $printed_message_p;
}

sub arg_value {
   local($this, $node_id, *ht, $xml_id, $slot) = @_;

   return (defined($value = $ht{$xml_id}->{ARG}->{$node_id}->{$slot})) ? $value : "";
}

sub text_value {
   local($this, $node_id, *ht, $xml_id) = @_;

   my $value = $ht{$xml_id}->{TEXT}->{$node_id};
   return $value if defined($value);
   my $text_node_id = $this->sub_node_of_tag($node_id, *ht, $xml_id, 0, "TEXT");
   return "" unless $text_node_id;
   $value = $ht{$xml_id}->{TEXT}->{$text_node_id};
   return $value if defined($value);
   return "";
}

sub tag_value {
   local($this, $node_id, *ht, $xml_id) = @_;
   return $ht{$xml_id}->{TAG}->{$node_id} || "";
}

sub write_xml {
   local($this, $parent_node_id, *ht, $xml_id, $schema, $indent, $rec_p) = @_;
   # converts ht structure to string
   # root has $parent_node_id = "1";

   $indent = 0 unless defined($indent);
   $rec_p = 0 unless defined($rec_p);
   # print STDERR "write_xml($parent_node_id) REC: $rec_p\n";
   my $result = "";
   my $tag = $ht{$xml_id}->{TAG}->{$parent_node_id} || "";
   my $n_subs = $ht{$xml_id}->{N_SUBS}->{$parent_node_id} || 0;
   if ($tag) {
      if ($tag eq "TEXT") {
         $result .= $ht{$xml_id}->{TEXT}->{$parent_node_id};
      } else {
	 if ($indent) {
	    $result .= "\n" if $rec_p;
            my $n_periods = (() = ($parent_node_id =~ /\./g));
	    foreach $i ((2 .. $n_periods)) {
	       foreach $j ((1 .. $indent)) {
	          $result .= " ";
	       }
	    }
	 }
         $result .= "<$tag";
         foreach $slot (sort keys %{$ht{$xml_id}->{ARG}->{$parent_node_id}}) {
	    $value = $ht{$xml_id}->{ARG}->{$parent_node_id}->{$slot};
	    $result .= " $slot=\"$value\"";
         }
	 $result .= " \/" unless $n_subs;
         $result .= ">";
      }
   }
   foreach $i ((1 .. $n_subs)) {
      my $node_id = join(".", $parent_node_id,$i);
      my $tag = $ht{$xml_id}->{TAG}->{$node_id};
      if ($tag eq "TEXT") {
	 $result .= $ht{$xml_id}->{TEXT}->{$node_id};
      } else {
         $result .= $this->write_xml($node_id, *ht, $xml_id, $schema, $indent, 1);
      }
   }
   if ($n_subs) {
      if ($indent && $ht{$xml_id}->{N_SUBTAGS}->{$parent_node_id}) {
         $result .= "\n";
         my $n_periods = (() = ($parent_node_id =~ /\./g));
         foreach $i ((2 .. $n_periods)) {
	    foreach $j ((1 .. $indent)) {
               $result .= " ";
	    }
         }
      }
      $result .= "<\/$tag>" if $tag && ($tag ne "TEXT");
   }
   return $result;
}

sub write_xml_without_tags_at_ends {
   local($this, $parent_node_id, *ht, $xml_id, $schema, $indent, $rec_p) = @_;

   return $this->trim_xml_tags_at_ends($this->write_xml($parent_node_id, *ht, $xml_id, $schema, $indent, $rec_p));
}

sub trim_xml_tags_at_ends {
   local($this, $s) = @_;

   $s =~ s/^\s*<[^<>]*>//;
   $s =~ s/<[^<>]*>\s*$//;
   return $s;
}

sub sub_node_of_tag {
   local($this, $node_id, *ht, $xml_id, $rec_p, @tags) = @_;
  
   my @sub_nodes = $this->sub_nodes_of_tag($node_id, *ht, $xml_id, $rec_p, @tags);
   return (@sub_nodes) ? $sub_nodes[0] : "";
}

sub sub_nodes_of_tag {
   local($this, $node_id, *ht, $xml_id, $rec_p, @tags) = @_;
   # Return (space separated list of) node IDs of nodes under $node_id with tag in @tags.
   # If $rec_p, include nodes of tag in @tags inside node of tag in @tags.
   # For any node, search under TOP $node_id "1".

   my $tag_s = join(" ", @tags);
   @{$ht{$xml_id}->{SUB_NODES_OF_TYPE}->{$node_id}->{$tag_s}} = ();
   $this->sub_nodes_of_tag_rec($node_id, $node_id, *ht, $xml_id, $rec_p, $tag_s, @tags);
   return @{$ht{$xml_id}->{SUB_NODES_OF_TYPE}->{$node_id}->{$tag_s}};
}

sub sub_nodes_of_tag_rec {
   local($this, $root_node_id, $parent_node_id, *ht, $xml_id, $rec_p, $tag_s, @tags) = @_;

   $n_subs = $ht{$xml_id}->{N_SUBS}->{$parent_node_id} || 0;
   foreach $i ((1 .. $n_subs)) {
      my $node_id = join(".", $parent_node_id, $i);
      my $tag = $ht{$xml_id}->{TAG}->{$node_id};
      if ($util->member($tag, @tags)) {
         push(@{$ht{$xml_id}->{SUB_NODES_OF_TYPE}->{$root_node_id}->{$tag_s}}, $node_id);
         $this->sub_nodes_of_tag_rec($root_node_id, $node_id, *ht, $xml_id, $rec_p, $tag_s, @tags)
	    if $rec_p;
      } else {
         $this->sub_nodes_of_tag_rec($root_node_id, $node_id, *ht, $xml_id, $rec_p, $tag_s, @tags);
      }
   }
}

sub direct_sub_nodes_of_tag {
   local($this, $parent_node_id, *ht, $xml_id, @tags) = @_;

   my $tag_s = join(" ", @tags);
   my $n_subs = $ht{$xml_id}->{N_SUBS}->{$parent_node_id} || 0;
   @{$ht{$xml_id}->{DIRECT_SUB_NODES_OF_TYPE}->{$parent_node_id}->{$tag_s}} = ();
   foreach $i ((1 .. $n_subs)) {
      my $node_id = join(".", $parent_node_id, $i);
      my $tag = $ht{$xml_id}->{TAG}->{$node_id};
      if ($util->member($tag, @tags)) {
         push(@{$ht{$xml_id}->{DIRECT_SUB_NODES_OF_TYPE}->{$parent_node_id}->{$tag_s}}, $node_id);
      }
   }
   return @{$ht{$xml_id}->{DIRECT_SUB_NODES_OF_TYPE}->{$parent_node_id}->{$tag_s}};
}

sub normalize_tags {
   local($this, $s, $schema) = @_;

   $s =~ s/(<\/?)ce:(sub|sup)\b/$1$2/ig;
   $s =~ s/(<\/?)ce:italic\b/$1i/ig;
   $s =~ s/(<\/?)italic\b/$1i/ig;
 # $s =~ s/(<\/?)bold\b/$1b/ig; 
   return $s;
}

sub xml_to_html {
   local($this, $s, $schema, $control, $snt_id) = @_;

   $schema  = "" unless defined($schema);
   $control = "" unless defined($control);
   $snt_id  = "" unless defined($snt_id);
   my $result = "";
   while ($s ne "") {
      if (($pre, $close1_s, $tag, $arg_s, $close2_s, $rest) = ($s =~ /^(.*?)<(\/|)([a-zA-Z][-_:a-zA-Z0-9]*)([^<>]*?)(\s*\/|)>(.*)$/s)) {
	$result .= $pre;
	$tag = lc $this->normalize_tags($tag, $schema);
	if (($tag eq "a") && (($href_value) = ($arg_s =~ /\bhref="(https?:[^" ]+)"/i))) {
	   $result .= "<$close1_s$tag href=\"$href_value\" title=\"$href_value\" target=\"_EXT\"$close2_s>";
	} elsif (($tag eq "a") && ($arg_s =~ /^\s*(\s*onclick="popup\([^()"]+\);")?\s*$/)) {
	   $result .= "<$close1_s$tag$arg_s$close2_s>";
	} elsif (($tag eq "span") && ($arg_s =~ /^\s*(\s*\b(style|title)="[^"]*")*\s*$/)) {
	   $result .= "<$close1_s$tag$arg_s$close2_s>";
	} elsif ($tag =~ /^(b|i|sub|sup)$/) {
	   $result .= "<$close1_s$tag$close2_s>";
	} elsif (($tag =~ /^(ce:cross-refs?|ce:inter-ref|ext-link|xref)$/) && ($control =~ /color-markup/)) {
	   if ($close1_s) {
	      $result .= "<\/span>";
	   } else {
	      my $style = "color:#A000A0;";
	      my $tag_clause = "tag: <$tag$arg_s>";
	      my $text_clause = "";
	      my $onclick_clause = "";
	      my $url = "";
	      if (($text) = ($rest =~ /^([^<>]+)<\/$tag>/)) {
		 $text_clause = ": $text";
	         if (($tag =~ /^(ce:inter-ref|ext-link)$/)
	           && $util->likely_valid_url_format($text)
	           && ($url = $text)) {
		    $style = "color:#0000A0;text-decoration:underline;";
		    $onclick_clause = " onclick=\"window.open('$url', '_blank');\"";
		 }
	      }
	      $title = ($text) ? "$text\n$tag_clause" : $tag_clause;
	      $title = "url-entity$text_clause\n$tag_clause" 
		 if $url && ($tag =~ /^(ce:inter-ref|ext-link)$/);

	      $title = "figure$text_clause\n$tag_clause" 
		 if ($tag =~ /^(ce:cross-ref)$/) && ($arg_s =~ / refid="fig\S+"/);
	      $title = "table$text_clause\n$tag_clause" 
		 if ($tag =~ /^(ce:cross-ref)$/) && ($arg_s =~ / refid="tbl\S+"/);
	      $title = "publication$text_clause\n$tag_clause" 
		 if ($tag =~ /^(ce:cross-ref)$/) && ($arg_s =~ / refid="bib\S+"/);
	      $title = "publications$text_clause\n$tag_clause" 
		 if ($tag =~ /^(ce:cross-refs)$/) && ($arg_s =~ / refid="bib\S+(\sbib\S+)+"/);

	      $title = "figure$text_clause\n$tag_clause" 
		 if ($tag =~ /^(xref)$/) && ($arg_s =~ / rid="fig\S+"/);
	      $title = "table$text_clause\n$tag_clause" 
		 if ($tag =~ /^(xref)$/) && ($arg_s =~ / rid="(table|tbl)\S+"/);
	      $title = "figure$text_clause\n$tag_clause" 
		 if ($tag =~ /^(xref)$/) && ($arg_s =~ / rid="app\S+"/) && ($text =~ /^(figure|fig\b)/i);
	      $title = "table$text_clause\n$tag_clause" 
		 if ($tag =~ /^(xref)$/) && ($arg_s =~ / rid="app\S+"/) && ($text =~ /^table/i);
	      $title = "publication$text_clause\n$tag_clause" 
		 if ($tag =~ /^(xref)$/) && ($arg_s =~ / rid="bib\S+"/);
	      $title = "publications$text_clause\n$tag_clause" 
		 if ($tag =~ /^(xref)$/) && ($arg_s =~ / rid="bib\S+(\sbib\S+)+"/);

	      $title = $util->guard_html($title);
	      $result .= "<span style=\"$style\" title=\"$title\"$onclick_clause>";
	   }
	}
	$s = $rest;
      } else {
	 $result .= $s;
	 $s = "";
      }
   }
   foreach $bc_anomality (split(/;/, $this->xml_balance_check($result, $snt_id))) {
      if (($tag,$type,$count) = ($bc_anomality =~ /^(\S+):([a-z]+):(-?\d+)$/)) {
         if (($count > 0) && ($tag =~ /^(b|bold|i|sub|sup)$/)) {
	    foreach $i ((1 .. $count)) {
	       my $close_tag = "<\/$tag>";
	       $result .= $close_tag;
	       print STDERR "Adding $close_tag to line $snt_id\n" if $snt_id;
	    }
	 }
      }
   }
   return $result;
}

sub xml_balance_check {
   local($this, $s, $snt_id) = @_;

   my %bc_ht = ();
   my @bc_anomalities = ();
   while ($s ne "") {
      if (($close1_s, $tag, $close2_s, $rest) = ($s =~ /^.*?<(\/|)([a-zA-Z][-_:a-zA-Z0-9]*)[^<>]*?(\s*\/|)>(.*)$/s)) {
	 $tag = lc $tag;
	 # open&close tag
	 if ($close2_s ne "") {
	    $bc_ht{OPEN_TAG_COUNT}->{$tag} = $bc_ht{OPEN_TAG_COUNT}->{$tag} || 0;
	 # open tag
         } elsif ($close1_s eq "") {
	    $bc_ht{OPEN_TAG_COUNT}->{$tag} = ($bc_ht{OPEN_TAG_COUNT}->{$tag} || 0) + 1;
	 # close tag
	 } else {
	    $bc_ht{OPEN_TAG_COUNT}->{$tag} = ($bc_ht{OPEN_TAG_COUNT}->{$tag} || 0) - 1;
            $bc_ht{TAG_COUNT_UNDERFLOW}->{$tag} = ($bc_ht{TAG_COUNT_UNDERFLOW}->{$tag} ||  0) + 1
	       if $bc_ht{OPEN_TAG_COUNT} < 0;
	 }
         $s = $rest;
      } else {
         $s = "";
      }
   }
   foreach $tag (sort keys %{$bc_ht{OPEN_TAG_COUNT}}) {
      push(@bc_anomalities, "$tag:o:$open_tag_count") if $open_tag_count = $bc_ht{OPEN_TAG_COUNT}->{$tag};
      push(@bc_anomalities, "$tag:u:$tag_count_underflow") if $tag_count_underflow = $bc_ht{TAG_COUNT_UNDERFLOW}->{$tag};
   }
   # print STDERR "xml_balance_check ($snt_id): @bc_anomalities\n" if $snt_id && ($snt_id =~ /^\d+$/) && ($snt_id <= 25);
   return join(";", @bc_anomalities);
}

sub extract_ldc_snts {
   local($this, $filename, *ht, $xml_id, $doc_id, $schema) = @_;
   
   my @paras = ();
   my @snts = ();
   my $root_node_id = "1";
   my $headline = "";
   my $dateline = "";
   $this->read_xml_file($filename, *ht, $xml_id, $schema);
   $doc_id = $this->find_doc_id(*ht, $xml_id, "elsxml") unless $doc_id;

   if ($headline_node_id = $this->sub_node_of_tag($root_node_id, *ht, $xml_id, 0, "headline")) {
      $headline = $this->write_xml_without_tags_at_ends($headline_node_id, *ht, $xml_id, $schema);
      $headline =~ s/^\s*//;
      $headline =~ s/\s*$//;
      push(@paras, $headline);
   }
   if ($dateline_node_id = $this->sub_node_of_tag($root_node_id, *ht, $xml_id, 0, "dateline")) {
      $dateline = $this->write_xml_without_tags_at_ends($dateline_node_id, *ht, $xml_id, $schema);
      $dateline =~ s/^\s*//;
      $dateline =~ s/\s*$//;
      push(@paras, $dateline);
   }
   if ($text_node_id = $this->sub_node_of_tag($root_node_id, *ht, $xml_id, 0, "text")) {
      my $node_index = 0;
      foreach $node_id ($this->sub_nodes_of_tag($text_node_id, *ht, $xml_id, 0, "p")) {
	 $node_index++;
         my $tag = $ht{$xml_id}->{TAG}->{$node_id};
         my $text = $this->write_xml_without_tags_at_ends($node_id, *ht, $xml_id, $schema);
         $text =~ s/^\s*//;
         $text =~ s/\s*$//;
	 print STDERR "headline: $headline\nnode_index: $node_index\ntext: $text\n" if $text =~ /IFC signs deal to expand insurance to farmers/;
         push(@paras, $text)
	    unless ($text =~ /It is a condensed version of a story that will appear in tomorrow.*s New York Times./)
		|| ($text =~ /(?:EDS:|Eds:)/)
		|| (($node_index == 1) && ($text eq $headline));
      }
   }
   foreach $para (@paras) {
      $para = $this->html2guarded_utf8($para);
      $para = $utf8->html2utf8($para);
      $para = $utf8->xhtml2utf8($para);
      $para =~ s/\xC2\xA0/ /g; # nbsp -> space
      $para = $util->normalize_extreme_string($para);
      $para = $this->normalize_tags($para, $schema);
      foreach $snt (split(/\n/, $snt_segm->segment($para))) {
         push(@snts, $snt);
      }
   }
   return join("\n", @snts);
}

sub extract_elsxml_paper_snts {
   local($this, $filename, *ht, $xml_id, $doc_id, $schema) = @_;
   
   my @paras = ();
   my @snts = ();
   my $root_node_id = "1";
   $this->read_xml_file($filename, *ht, $xml_id, $schema);
   $doc_id = $this->find_doc_id(*ht, $xml_id, "elsxml") unless $doc_id;

   if ($title_node_id = $this->sub_node_of_tag($root_node_id, *ht, $xml_id, 0, "ce:title")) {
      my $title = $this->write_xml_without_tags_at_ends($title_node_id, *ht, $xml_id, $schema);
      push(@paras, "$title ($doc_id)");
   }
   if ($abstract_node_id = $this->sub_node_of_tag($root_node_id, *ht, $xml_id, 0, "ce:abstract")) {
      foreach $para_node_id ($this->sub_nodes_of_tag($abstract_node_id, *ht, $xml_id, 0, "ce:simple-para")) {
         my $para = $this->write_xml_without_tags_at_ends($para_node_id, *ht, $xml_id, $schema);
         push(@paras, $para);
      }
   }
   if ($sections_node_id = $this->sub_node_of_tag($root_node_id, *ht, $xml_id, 0, "ce:sections")) {
      foreach $node_id ($this->sub_nodes_of_tag($sections_node_id, *ht, $xml_id, 0, "ce:section-title", "ce:para")) {
         my $tag = $ht{$xml_id}->{TAG}->{$node_id};
         my $text = $this->write_xml_without_tags_at_ends($node_id, *ht, $xml_id, $schema);
         push(@paras, $text);
      }
   }
   foreach $figure_node_id ($this->sub_nodes_of_tag($root_node_id, *ht, $xml_id, 0, "ce:figure")) {
      foreach $para_node_id ($this->sub_nodes_of_tag($figure_node_id, *ht, $xml_id, 0, "ce:label", "ce:simple-para")) {
         my $para = $this->write_xml_without_tags_at_ends($para_node_id, *ht, $xml_id, $schema);
         push(@paras, $para);
      }
   }
   foreach $para (@paras) {
      $para = $this->html2guarded_utf8($para);
      $para = $utf8->html2utf8($para);
      $para = $utf8->xhtml2utf8($para);
      $para =~ s/\xC2\xA0/ /g; # nbsp -> space
      $para = $util->normalize_extreme_string($para);
      $para = $this->normalize_tags($para, $schema);
      foreach $snt (split(/\n/, $snt_segm->segment($para))) {
         push(@snts, $snt);
      }
   }
   return join("\n", @snts);
}

sub extract_nxml_paper_snts {
   local($this, $filename, *ht, $xml_id, $doc_id, $schema) = @_;
   
   my @paras = ();
   my @fig_paras = ();
   my @snts = ();
   my $root_node_id = "1";
   my %visited_node_ids = ();
   $this->read_xml_file($filename, *ht, $xml_id, $schema);
   $doc_id = $this->find_doc_id(*ht, $xml_id, "nxml") unless $doc_id;

   if ($title_node_id = $this->sub_node_of_tag($root_node_id, *ht, $xml_id, 0, "article-title")) {
      my $title = $this->write_xml_without_tags_at_ends($title_node_id, *ht, $xml_id, $schema);
      push(@paras, "$title ($doc_id)");
   }
   foreach $abstract_node_id ($this->sub_nodes_of_tag($root_node_id, *ht, $xml_id, 0, "abstract")) {
      foreach $para_node_id ($this->sub_nodes_of_tag($abstract_node_id, *ht, $xml_id, 0, "title", "p")) {
	 if (@sub_para_node_ids = $this->sub_nodes_of_tag($para_node_id, *ht, $xml_id, 0, "p")) {
	    foreach $sub_para_node_id (@sub_para_node_ids) {
               my $sub_para = $this->write_xml_without_tags_at_ends($sub_para_node_id, *ht, $xml_id, $schema);
               my $tag = $ht{$xml_id}->{TAG}->{$sub_para_node_id};
	       if ($tag && ($tag eq "title")) {
		  my $sec_level = $this->level_of_tag_nesting(*ht, $xml_id, $sub_para_node_id, "sec");
		  $sub_para = "<sec-title level=\"$sec_level\" sec-area=\"abstract\">$sub_para<\/sec-title>";
	       }
               push(@paras, $sub_para);
	    }
	 } else {
            my $para = $this->write_xml_without_tags_at_ends($para_node_id, *ht, $xml_id, $schema);
            my $tag = $ht{$xml_id}->{TAG}->{$para_node_id};
	    if ($tag && ($tag eq "title")) {
	       my $sec_level = $this->level_of_tag_nesting(*ht, $xml_id, $para_node_id, "sec");
	       $para = "<sec-title level=\"$sec_level\" sec-area=\"abstract\">$para<\/sec-title>";
	    }
            push(@paras, $para);
	 }
      }
   }
   foreach $float_node_id ($this->sub_nodes_of_tag($root_node_id, *ht, $xml_id, 0, "fig", "table-wrap")) {
      foreach $para_node_id ($this->sub_nodes_of_tag($float_node_id, *ht, $xml_id, 0, "label", "p")) {
	 next if $visited_node_ids{$para_node_id};
	 $visited_node_ids{$para_node_id} = 1;
         my $para = $this->write_xml_without_tags_at_ends($para_node_id, *ht, $xml_id, $schema);
	 next unless $para =~ /\S/;
 	 my $tag = $ht{$xml_id}->{TAG}->{$para_node_id};
         my $parent_node_id = $ht{$xml_id}->{PARENT}->{$para_node_id} || "";
         my $parent_tag = ($parent_node_id) ? $ht{$xml_id}->{TAG}->{$parent_node_id} : "";
	 if (($tag eq "label") && ($parent_tag =~ /\btable\b/i)) {
	    $para = "<label type=\"table\">$para<\/label>";
	 } elsif (($tag eq "label") && ($parent_tag eq "fig")) {
	    $para = "<label type=\"figure\">$para<\/label>";
	 } elsif (($tag eq "label") && ($parent_tag eq "fn")) {
	    $para = "<label type=\"footnote\">$para<\/label>";
         }
         push(@fig_paras, $para);
      }
   }
   if ($body_node_id = $this->sub_node_of_tag($root_node_id, *ht, $xml_id, 0, "body")) {
      # Section node IDs can also be <p> or <body>, when no <sec> is available.
      my @section_node_ids = $this->sub_nodes_of_tag($body_node_id, *ht, $xml_id, 1, "sec", "p");
      @section_node_ids = ($body_node_id) unless @section_node_ids;
      foreach $section_node_id (@section_node_ids) {
	 my @node_ids = ($ht{$xml_id}->{TAG}->{$section_node_id} eq "p")
			? ($section_node_id)
			: $this->sub_nodes_of_tag($section_node_id, *ht, $xml_id, 0, "title", "p");
         foreach $node_id (@node_ids) {
	    next if $visited_node_ids{$node_id};
	    $visited_node_ids{$node_id} = 1;
            my $tag = $ht{$xml_id}->{TAG}->{$node_id};
            my $text = $this->write_xml_without_tags_at_ends($node_id, *ht, $xml_id, $schema);
	    while (($pre, $xtag, $url, $post)
		 = ($text =~ /^(.*)<(ext-link\b[^<>]* href=\"(http[^"]*)\"[^<>]*?)\s*\/>(.*)$/)) {
	       $text = "$pre<$xtag>$url<\/ext-link>$post";
	       # print STDERR "HTTP: <$xtag>$url<\/ext-link>\n";
	    }
	    if ($tag && ($tag eq "title")) {
               my $sec_level = $this->level_of_tag_nesting(*ht, $xml_id, $node_id, "sec");
	       $text = "<sec-title level=\"$sec_level\">$text<\/sec-title>";
	       # print STDERR "TITLE($sec_level): $text\n" if $tag eq "title";
	    }
            push(@paras, $text);
         }
      }
   }
   push(@paras, @fig_paras);
   foreach $para (@paras) {
      $para = $this->html2guarded_utf8($para);
      $para = $utf8->html2utf8($para);
      $para = $utf8->xhtml2utf8($para);
      $para =~ s/\xC2\xA0/ /g; # nbsp -> space
      $para = $util->normalize_extreme_string($para);
      $para =~ s/<fig\b.*?<\/fig>//gs; # already covered
      # print STDERR "Point A: $para\n" if $para =~ /table-wrap/;
      $para =~ s/<table-wrap[ >].*?<\/table-wrap>//gs;
      # print STDERR "Point B: $para\n" if $para =~ /table-wrap/;
      $para = $this->normalize_tags($para, $schema);
      foreach $snt (split(/\n/, $snt_segm->segment($para))) {
         push(@snts, $snt);
      }
   }
   return join("\n", @snts);
}

sub html2guarded_utf8 {
   local($this, $s) = @_;

   # hexadecimal
   $s =~ s/&#x0*26;/&amp;/ig;
   $s =~ s/&#x0*3C;/&lt;/ig;
   $s =~ s/&#x0*3E;/&gt;/ig;
   # decimal
   $s =~ s/&#0*38;/&amp;/g;
   $s =~ s/&#0*60;/&lt;/g;
   $s =~ s/&#0*62;/&gt;/g;
   return $s;
}

sub find_doc_id {
   local($this, *ht, $xml_id, $xml_type, $doc_id_type) = @_;
   # $doc_id_type = pmid | pmc [optional]
   
   $doc_id_type = "" unless defined($doc_id_type);
   if ($doc_id_type eq "pmid") {
      return $doc_id if $doc_id = $ht{$xml_id}->{DOC_PMID};
   } elsif ($doc_id_type eq "pmc") {
      return $doc_id if $doc_id = $ht{$xml_id}->{DOC_PMC};
   } else {
      return $doc_id if $doc_id = $ht{$xml_id}->{DOC_ID};
   }
   my $root_node_id = "1";
   # if ($xml_type eq "nxml")
   if (($doc_node_id = $this->sub_node_of_tag($root_node_id, *ht, $xml_id, 0, "doc"))
    && ($doc_id = $ht{$xml_id}->{ARG}->{$doc_node_id}->{"id"})) {
      $ht{$xml_id}->{DOC_ID} = $doc_id;
      return $doc_id;
   }
   if (1) {
      foreach $article_id_node_id ($this->sub_nodes_of_tag($root_node_id, *ht, $xml_id, 0, "article-id")) {
	 my $pub_id_type = $ht{$xml_id}->{ARG}->{$article_id_node_id}->{"pub-id-type"};
	 next unless $pub_id_type && ($pub_id_type =~ /^(pmid|pmc|pmcid)$/i);
	 my $lc_core_pub_id_type = lc $pub_id_type;
	 $lc_core_pub_id_type = "pmc" if $lc_core_pub_id_type eq "pmcid";
	 next if $doc_id_type && (lc $pub_id_type ne $lc_core_pub_id_type);
         next unless $text_node_id = $this->sub_node_of_tag($article_id_node_id, *ht, $xml_id, 0, "TEXT");
	 next unless $text = $ht{$xml_id}->{TEXT}->{$text_node_id} || "";
	 $text = $util->trim($text);
	 next unless $text =~ /\d{5,}$/;
	 my $doc_id = join(":", uc $lc_core_pub_id_type, $text) unless $text =~ /(pmc|pmid):\d+/i;
	 $ht{$xml_id}->{DOC_ID} = $doc_id;
	 $ht{$xml_id}->{DOC_PMID} = $doc_id if $lc_core_pub_id_type eq "pmid";
	 $ht{$xml_id}->{DOC_PMC} = $doc_id if $lc_core_pub_id_type eq "pmc";
	 print STDERR "Found doc_id: $doc_id\n";
	 return $doc_id;
      }
   }
   return "";
}

sub find_pmid_in_file {
   local($this, $filename) = @_;

   if (open(IN, $filename)) {
      while (<IN>) {
	 return "pmid:$pmid_number" if ($pmid_number) = ($_ =~ /<article-id pub-id-type="pmid">(\d+)<\/article-id>/);
      }
      close(IN);
   }
   return "";
}

sub find_pmc_in_file {
   local($this, $filename) = @_;

   if (open(IN, $filename)) {
      while (<IN>) {
	 return "pmc:$pmc_number" if ($pmc_number) = ($_ =~ /<article-id pub-id-type="pmc-uid">(\d+)<\/article-id>/i);
	 return "pmc:$pmc_number" if ($pmc_number) = ($_ =~ /<article-id pub-id-type="pmcid">PMC[:]?(\d+)<\/article-id>/i);
      }
      close(IN);
   }
   return "";
}

sub write_workset_as_plain_txt {
   local($this, *ht, *OUT, $snt_id_core, @snts) = @_;

   my $snt_counter = 0;
   foreach $snt (@snts) {
      $snt =~ s/\s*$//;
      next if $snt =~ /^(\s+|<[^<>]*>)*$/; # skip empty lines (or those with just xml tags)
      $snt_counter++;
      $snt =~ s/^\s*//;
      print OUT "$snt_id_core.$snt_counter $snt\n";
      print STDERR "Warning l.$snt_counter: $bc_anomalities\n"
        if $bc_anomalities = $this->xml_balance_check($snt, $snt_counter);
   }
   return $snt_counter;
}

sub write_workset_to_html {
   local($this, *ht, $html_out_filename, $doc_id, $workset_name, $snt_id_core, $schema, @snts) = @_;

   my $snt_counter = 0;
   if (open(HTML, ">$html_out_filename")) {
      $util->print_html_head($doc_id, *HTML, "AMR no javascript");
      $banner_text = "<nobr> &nbsp; <font size=\"+1\"><b>Workset: $workset_name</b></font> &nbsp; &nbsp; <font color=\"#999999\"></font></nobr>";
      $util->print_html_banner($banner_text, "#BBCCFF", *HTML);
      print HTML "<table border=\"0\" cellpadding=\"3\" cellspacing=\"0\">\n";
      foreach $snt (@snts) {
         $snt =~ s/\s*$//;
         next if $snt =~ /^(\s+|<[^<>]*>)*$/; # skip empty lines (or those with just xml tags)
         $snt_counter++;
         $snt = $this->xml_to_html($snt, $schema, "/color-markup/", $snt_counter);
         print HTML "  <tr><td valign=\"top\" style=\"color:#BBBBBB;\">$snt_id_core.$snt_counter<\/td><td> &nbsp; <\/td><td>$snt<\/td><\/tr>\n";
         print STDERR "Warning l.$snt_counter: $bc_anomalities\n"
           if $bc_anomalities = $this->xml_balance_check($snt, $snt_counter);
      }
      print HTML "<\/table>\n";
      $util->print_html_foot(*HTML);
      close(HTML);
   } else {
      print STDERR "Can't write to $html_out_filename\n";
   }
   return $snt_counter;
}

sub text_in_xml_p {
   local($this, $s) = @_;

   return ($s =~ /<\/?([a-z][-_:a-z0-9]*)(?:\s+[a-z][-_:a-z0-9]*="[^"]*")*\s*\/?>/si);
}

1;

