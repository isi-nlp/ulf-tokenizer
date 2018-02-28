#!/usr/bin/perl -w
# Author: Ulf Hermjakob 
# Created: July 20, 2004
# Add prefix to lines from stdin

$prefix = $ARGV[0];
while (<STDIN>) {
   print "$prefix$_";
}
