#!/usr/bin/env python
from __future__ import print_function

import os
import subprocess
import time

EXAMPLES_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '../examples'))
RUN_BINARY = os.path.abspath(os.path.join(EXAMPLES_DIR, "../run_as_tam.py"))

# Delimiters
OUTPUT_START = "********** TAM Interpreter (Java Version 2.0) **********"
OUTPUT_END = "Program has halted normally."
TAM_START = "TAM:"
TAM_END = "Compiling to TASM.."

def get_part(output, start, end):
    output = output.split("\n")

    for i, line in enumerate(output):
        if line.startswith(start):
            start = i
            break

    for i, line in enumerate(output[start:]):
        if line.startswith(end):
            end = i + start
            break

    return ("\n".join(output[start+1:end])).strip()

for fn in os.listdir(EXAMPLES_DIR):
    # Filter non-kib files
    if not fn.endswith(".kib"):
        continue

    # Filter directories
    fn = os.path.join(EXAMPLES_DIR, fn)
    if not os.path.isfile(fn):
        continue

    outfile = fn[:-3] + "out"
    if not os.path.isfile(outfile):
        continue

    # Run file
    process = subprocess.Popen((RUN_BINARY, "--buffer", fn), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    process.wait()

    stdout = process.stdout.read()
    stderr = process.stderr.read()

    output = get_part(stdout, OUTPUT_START, OUTPUT_END)
    code = get_part(stdout, TAM_START, TAM_END)

    print("Checking output of %s: " % os.path.basename(fn), end="")
    if output == open(outfile).read().strip():
        print("OK")
    else:
        print("FAIL")

    print("Checking TAM of %s: " % os.path.basename(fn), end="")
    if code == open(fn[:-3] + "tam").read().strip():
        print("OK")
    else:
        print("FAIL")

    print()

