#!/usr/bin/env bash

DIR=$(dirname $BASH_SOURCE)
cat $1 \
 | $DIR/wildeclean-v1.0.pl \
 | $DIR/normalize-punctuation.pl \
 | $DIR/current/bin/tokenize-english.pl \
 | sed -e 's/ @@ / /g' \
 | $DIR/utftest
