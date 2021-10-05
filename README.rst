***************
Ulf's Tokenizer
***************

Tokenizer tool developed by Ulf Hermjakob @ USC ISI (so we call it ulf's tokenizer)

===============
Deprecated
===============

This tokenizer is superseded by https://github.com/uhermjakob/utoken written by the same author.
The new tool is much more multi-lingual, modular and contains other tokenization improvements; in Python.

===============
Usage
===============

for english or latin scripts::

  cat input.txt | ulf-eng-tok.sh > input.tok.txt

for non latin scripts::

    cat input.txt | ulf-src-tok.sh > input.tok.txt 



=====
Python API
=====

This is a python wrapper which uses a subprocess for tokenizer communicated using stdin and stdout

Here is how to use it::

    # export PYTHONPATH=$PWD

    from ulftok import tokenize_lines
    text = "Hello,... this is a test! Is it good? http://isi.edu"
    lines = [text] * 10
    for line in tokenize_lines(lines):
        print(line)
