#!/usr/bin/perl -w
# Author: Ulf Hermjakob 

while(<>) {
   s/(<xref [^<>]+>)\s*(\[\d+\])\s*(<\/xref>)/$1$2$3/g;
   s/(<title [^<>]+>)\s*(\S.*?\S|\S)\s*(<\/title>)/$1$2$3/g;
   s/(<sec-title [^<>]+>)\s*(\S.*?\S|\S)\s*(<\/sec-title>)/$1$2$3/g;
   s/ +/ /g;
   print;
}

exit 0;

