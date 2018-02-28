#!/usr/bin/env perl
#
# This file is part of moses.  Its use is licensed under the GNU Lesser General
# Public License version 2.1 or, at your option, any later version.

use warnings;
use strict;
$|++;
my $language = "en";
my $PENN = 0;

while (@ARGV) {
    $_ = shift;
    /^-b$/ && ($| = 1, next); # not buffered (flush each line)
    /^-l$/ && ($language = shift, next);
    /^[^\-]/ && ($language = $_, next);
    /^-penn$/ && ($PENN = 1, next);
}

while(<STDIN>) {
    s/\r//g;
    # remove extra spaces
    # normalize unicode punctuation
    if ($PENN == 0) {
	s/\`/\'/g;
	s/\'\'/\"/g;
    }

    s/፡/:/g;
    s/„/\"/g;
    s/ʼ/'/g;
    s/“/\"/g;
    s/‹/'/g;
    s/›/'/g;
    s/”/\"/g;
    s/–/-/g;
    s/—/ - /g;
    s/،/,/g;
    s/ +/ /g;
    s/´/'/g;
    s/([a-z])‘([a-z])/$1\'$2/gi;
    s/([a-z])’([a-z])/$1\'$2/gi;
    s/‘/\"/g;
    s/‚/\"/g;
    s/’/'/g;
    s/''/\"/g;
    s/´´/\"/g;
    s/…/.../g;
    # French quotes
    s/«/\"/g;
    s/»/\"/g;
    s/[ ]+$//;
    s/^[ ]+//;
    # handle pseudo-spaces
    print $_;
}
