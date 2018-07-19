***************
Ulf's Tokenizer
***************

Tokenizer tool developed by Ulf Harmjakob @ USC ISI (so we call it ulf's tokenizer)

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
