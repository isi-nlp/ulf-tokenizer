import os
from subprocess import Popen, PIPE
import logging as log
from typing import Iterator, List
import threading
log.basicConfig(level=log.DEBUG)

dir_path = os.path.dirname(os.path.abspath(__file__))
eng_script_path = os.path.join(dir_path, 'ulf-eng-tok.sh')
src_script_path = os.path.join(dir_path, 'ulf-src-tok.sh')

def tokenize(line: str) -> List[str]:
    """Tokenize a single line .
    This is not efficient, please use tokenize_lines(...) instead
    """
    return list(tokenize_lines([line]))[0]

def tokenize_lines(lines: Iterator[str], english_like=True) -> Iterator[List[str]]:
    """Tokenize a stream of lines"""
    script_path = eng_script_path if english_like else src_script_path
    p = Popen(script_path, stdin=PIPE, stdout=PIPE, universal_newlines=True, bufsize=1)

    def write(iter, out):
        for line in iter:
            out.write(line + '\n')
        out.close()

    writer = threading.Thread(target=write, args=(lines, p.stdin))
    writer.daemon = True
    writer.start()

    for out_line in p.stdout:
        yield out_line.strip().split()
    log.debug(f'stopping {p.pid}')
    p.kill()


if __name__ == '__main__':

    text = "Hello,... this is a test! Is it good? http://isi.edu"
    print(tokenize(text))
    lines = [text] * 10
    for line in tokenize_lines(lines):
        print(line)
