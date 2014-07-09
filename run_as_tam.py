#!/usr/bin/env python
from __future__ import print_function

import os
import sys
import subprocess
import tempfile
import time

from tests.test import compile_grammar, check_antlr, CLASSPATH

def print_(*args, **kwargs):
    if "--hush" not in sys.argv:
        print(*args, **kwargs)


if "--compile" in sys.argv:
    print_("Checking for antlr..")
    check_antlr()

    print_("Compiling grammar..")
    compile_grammar()

def run_tam(filename, hush=False):
    print_("Compiling to TAM..")
    args = ("java", "-classpath", CLASSPATH, "Grammar", "-ast", "-tam", filename)
    process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()

    if stderr:
        print_(stderr, file=sys.stderr)
        print_(stdout)
        return

    # print_ AST
    print_("AST: ", stdout.split("\n")[0])

    with tempfile.NamedTemporaryFile(suffix=".tam") as tam:
        tam_code = "\n".join(stdout.split("\n")[1:])
        tam.file.write(tam_code)
        tam.file.flush()

        print_("TAM:")
        print_(tam_code)

        with tempfile.NamedTemporaryFile(suffix=".tasm") as tasm:
            print_("Compiling to TASM..")
            args = ("java", "TAM.Assembler", tam.name, tasm.name)
            process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = process.communicate()
            print(stdout)

            print_("Executing TASM..")
            args = ("java", "TAM.Interpreter", tasm.name)
            if "--buffer" in sys.argv:
                process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                stdout, stderr = process.communicate()
                print(stdout)
            else:
                process = subprocess.Popen(args)
                stdout, stderr = process.communicate()

if __name__ == '__main__':
    from tests.test import set_cwd, GRAMMAR_DIR

    filename = os.path.abspath(sys.argv[-1])
    with set_cwd(GRAMMAR_DIR):
        run_tam(filename, hush="--hush" in sys.argv)

