#!/usr/bin/env bash

DIR=$(dirname $BASH_SOURCE)
cat $1 \
 | $DIR/wildeclean-v1.0.pl \
 | $DIR/normalize-punctuation.pl \
 | $DIR/v1.3.4/bin/tokenize-english.pl \
 | sed -u -e 's/ @@ / /g' \
 | $DIR/utftest
