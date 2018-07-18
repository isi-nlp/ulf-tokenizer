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

    tokr = UlfTokenizer()
    text = "Hello,... this is a test! Is it good? http://isi.edu"
    print(tokr.tokenize(text))

    # if you want to turn the backend off and on
    tokr.stop()
    assert tokr.is_active is False
    with tokr:
        assert tokr.is_active
        print(tokr.tokenize(text))
    assert tokr.is_active is False
