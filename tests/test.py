import os
import unittest
import subprocess

from tempfile import NamedTemporaryFile
from contextlib import contextmanager
from subprocess import PIPE

try:
    # Python 3.x
    from io import StringIO
    from urllib.request import urlopen
except ImportError:
    # Python 2.7
    from urllib2 import urlopen
    from StringIO import StringIO

# Determine where the

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
ANTLR_DIR = os.path.join(THIS_DIR, "build")
ANTLR_FILE = "antlr-3.5.2-complete.jar"
ANTLR_PATH = os.path.join(ANTLR_DIR, ANTLR_FILE)

GRAMMAR_DIR = os.path.join(THIS_DIR, "../src")
GRAMMAR_FILE = os.path.join(GRAMMAR_DIR, "Grammar.g")
GRAMMAR_CHECKER_FILE = os.path.join(GRAMMAR_DIR, "checker/GrammarChecker.g")
GRAMMAR_TAM_FILE = os.path.join(GRAMMAR_DIR, "generator/TAM/GrammarTAM.g")

CLASSPATH = ".:%s:%s" % (ANTLR_PATH, os.environ.get("CLASSPATH"))

@contextmanager
def set_cwd(path):
    old_cwd = os.getcwd()
    yield os.chdir(path)
    os.chdir(old_cwd)

def check_antlr():
    if os.path.exists(ANTLR_PATH):
        return

    # Create build directory if it does not exist
    if not os.path.exists(ANTLR_DIR):
        os.mkdir(ANTLR_DIR)

    # Fetch ANTLR binary
    print("Fetching antlr...")
    fp = urlopen("http://www.antlr3.org/download/" + ANTLR_FILE)
    open(ANTLR_PATH, "wb").write(fp.read())


def compile_grammar(stdin=None, stdout=None, stderr=None):
    with set_cwd(GRAMMAR_DIR):
        subprocess.call(["java", "-jar", ANTLR_PATH, GRAMMAR_FILE, GRAMMAR_CHECKER_FILE, GRAMMAR_TAM_FILE])
        subprocess.call(["javac", "-Xlint:unchecked", "-classpath", CLASSPATH, "Grammar.java"])

class AntlrTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        super(AntlrTest, cls).setUpClass()
        print("Checking for antlr..")
        check_antlr()
        print("Compiling grammar..")
        compile_grammar()
        print("Testing %s" % cls.__name__)

    def compile(self, grammar, options=()):
        with set_cwd(GRAMMAR_DIR):
            with NamedTemporaryFile() as fp:
                fp.write(grammar.encode('utf-8'))
                fp.flush()

                args = ("java", "-classpath", CLASSPATH, "Grammar") + tuple(options) + (fp.name,)
                process = subprocess.Popen(args, stdout=PIPE, stderr=PIPE)
                stdout, stderr = process.communicate()

                return stdout.decode("utf-8").strip(), stderr.decode("utf-8").strip()

    @classmethod
    def tearDownClass(cls):
        pass
