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

===============
Acknowledgments
===============
This research is based upon work supported in part by the Office of the Director of National Intelligence (ODNI), Intelligence Advanced Research Projects Activity (IARPA), via contract # FA8650-17-C-9116, and by research sponsored by Air Force Research Laboratory (AFRL) under agreement number FA8750-19-1-1000. The views and conclusions contained herein are those of the authors and should not be interpreted as necessarily representing the official policies, either expressed or implied, of ODNI, IARPA, Air Force Laboratory, DARPA, or the U.S. Government. The U.S. Government is authorized to reproduce and distribute reprints for governmental purposes notwithstanding any copyright annotation therein.
