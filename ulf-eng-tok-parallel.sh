#!/usr/bin/env bash
# Author: Thamme Gowda; Created : Sept 05, 2018
# This script uses GNU-parallel to split and execute tokenizer
# in parallel
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
TOK=$DIR/ulf-eng-tok.sh

echoerr() { echo "$@" 1>&2; }

show_help() {
    echoerr "Usage: -t threads -i input.txt -o out/prefix -f input.tok.txt
example: -t 4 -i input.txt -o splits/part- -f input.tok.txt"
}


threads=2
outprefix=part-
input=
while getopts "h?t:i:o:f:" opt; do
    case "$opt" in
        h|\?)
            show_help
            exit 0
            ;;
        t)  threads=$OPTARG
            ;;
        o)  outprefix=$OPTARG
            ;;
        i)  input=$OPTARG
            ;;
        f)  final=$OPTARG
            ;;
    esac
done

[[ -n $input && -n $outprefix && -n $final ]] || { echoerr "ERROR: Invalid Args"; show_help; exit 1; }
[[ -f $input ]] || { echoerr "$input doesnt exist"; exit 2; }

n=$(wc -l $input | awk -v t=$threads '{printf "%d", ($1/t)+1}')
cat $input | parallel --pipe -j $threads -N$n "cat | $TOK > $outprefix{#}"

cat $(ls -v1 ${outprefix}*) > $final

