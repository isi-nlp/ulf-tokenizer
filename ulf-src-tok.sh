#!/usr/bin/env bash

DIR=$(dirname ${BASH_SOURCE[0]})
$DIR/wildeclean-v1.0.pl \
| $DIR/normalize-punctuation.pl \
| $DIR/utftest \
| $DIR/current/bin/tokenize-english.pl \
| sed -u -e 's/ @\([\\*:/-]\)/ \1/g' -e 's/\([\\*:/-]\)@ /\1 /g' -e 's/ @@ / /g' \
| $DIR/utftest
