import os
from subprocess import Popen, PIPE
import logging as log
from typing import List
log.basicConfig(level=log.DEBUG)

class UlfTokenizer:
    """Python wrapper for Ulf's tokenizer
    """

    def __init__(self, english_like=True):
        """
        :param english_like: if text is in latin script, False for non latin scripts
        """
        script_path = 'ulf-eng-tok.sh' if english_like else 'ulf-src-tok.sh'
        dir_path = os.path.dirname(os.path.abspath(__file__))
        self.script_path = os.path.join(dir_path, script_path)
        self.proxy = None
        self.start()

    def tokenize(self, text: str) -> List[str]:
        assert self.proxy is not None
        out, _ = self.proxy.communicate(input=text.strip())
        return out.split()

    def start(self):
        self.proxy = Popen(self.script_path, stdin=PIPE, stdout=PIPE, universal_newlines=True)
        log.info(f'started tokenizer process {self.proxy.pid}')

    def stop(self):
        if self.proxy is not None:
            log.info(f'Stopping tokenizer process {self.proxy.pid}')
            self.proxy.terminate()
            self.proxy = None

    def __enter__(self):
        self.start()

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.stop()

    def __del__(self):
        self.stop()

    @property
    def is_active(self):
        return self.proxy is not None


if __name__ == '__main__':
    tokr = UlfTokenizer()
    text = "Hello,... this is a test! Is it good? http://isi.edu"
    print(tokr.tokenize(text))
    tokr.stop()
    assert tokr.is_active is False
    with tokr:
        assert tokr.is_active
        print(tokr.tokenize(text))
    assert tokr.is_active is False
