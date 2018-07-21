import os
import subprocess
from subprocess import Popen, PIPE
import logging as log
from typing import Iterator, List
import threading

from multiprocessing.pool import ThreadPool

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


def tokenize_files(inp_paths: List[str], outp_paths: List[str], jobs: int=None, english_like=True):
    assert len(inp_paths) == len(outp_paths)
    log.info(f" Going to tokenize {len(inp_paths)} using {jobs} pool")

    def tokenize_file(inp_path, out_path):
        script_path = eng_script_path if english_like else src_script_path
        cmd = f'{script_path} < {inp_path} > {out_path} '
        log.debug(f" Going to tokenize {len(inp_paths)} using {jobs} pool")
        status, _ = subprocess.getstatusoutput(cmd)

    pool = ThreadPool(jobs)
    for (inp, out) in zip(inp_paths, outp_paths):
        pool.apply_async(tokenize_file, (inp, out))

    pool.close()
    pool.join()


if __name__ == '__main__':

    text = "Hello,... this is a test! Is it good? http://isi.edu"
    print(tokenize(text))
    lines = [text] * 10
    for line in tokenize_lines(lines):
        print(line)
