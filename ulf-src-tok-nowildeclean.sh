#!/usr/bin/env bash
[[ -n $1 ]] && inp=$1 || inp=/dev/stdin
[[ -n $2 ]] && out=$2 || out=/dev/stdout

DIR=$(dirname ${BASH_SOURCE[0]})

    # | $DIR/wildeclean-v1.0.pl \
cat $inp \
| $DIR/normalize-punctuation.pl \
| $DIR/utftest \
| $DIR/current/bin/tokenize-english.pl \
| sed -e 's/ @\([\\*:/-]\)/ \1/g' -e 's/\([\\*:/-]\)@ /\1 /g' -e 's/ @@ / /g' \
| $DIR/utftest > $out
