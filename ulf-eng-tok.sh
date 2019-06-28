#!/usr/bin/env bash
[[ -n $1 ]] && inp=$1 || inp=/dev/stdin
[[ -n $2 ]] && out=$2 || out=/dev/stdout

DIR=$(dirname $BASH_SOURCE)
cat $inp \
 | $DIR/wildeclean-v1.0.pl \
 | $DIR/normalize-punctuation.pl \
 | $DIR/current/bin/tokenize-english.pl \
 | sed -e 's/ @@ / /g' \
 | $DIR/utftest > $out
