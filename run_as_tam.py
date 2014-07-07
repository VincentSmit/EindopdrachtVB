#!/usr/bin/env python
from __future__ import print_function

import os
import sys
import subprocess
import tempfile
import time

from tests.test import compile_grammar, check_antlr, CLASSPATH

if "--compile" in sys.argv:
    print("Checking for antlr..")
    check_antlr()

    print("Compiling grammar..")
    compile_grammar()


def run_tam(filename):
    print("Compiling to TAM..")
    args = ("java", "-classpath", CLASSPATH, "Grammar", "-ast", "-tam", filename)
    process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()

    if stderr:
        print(stderr, file=sys.stderr)
        print(stdout)
        return

    # Print AST
    #print("AST: ", stdout.split("\n")[0])

    with tempfile.NamedTemporaryFile(suffix=".tam") as tam:
        tam_code = "\n".join(stdout.split("\n")[1:])
        tam.file.write(tam_code)
        tam.file.flush()

        print("TAM:")
        print(tam_code)

        with tempfile.NamedTemporaryFile(suffix=".tasm") as tasm:
            print("Compiling to TASM..")
            subprocess.call(("java", "TAM.Assembler", tam.name, tasm.name))

            print("Executing TASM..")
            subprocess.call(("java", "TAM.Interpreter", tasm.name))

if __name__ == '__main__':
    from tests.test import set_cwd, GRAMMAR_DIR

    filename = os.path.abspath(sys.argv[-1])
    with set_cwd(GRAMMAR_DIR):
        run_tam(filename)

