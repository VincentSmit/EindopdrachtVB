from __future__ import unicode_literals
from test import AntlrTest

class CheckerTest(AntlrTest):
    def compile(self, grammar):
        return super(CheckerTest, self).compile(grammar)

    def test_binary_expression(self):
        stdout, stderr = self.compile("int a; char b; a+b;")
        print(stderr)
        print(stdout)

if __name__ == '__main__':
    import unittest
    unittest.main()
