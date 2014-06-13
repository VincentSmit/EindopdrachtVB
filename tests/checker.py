from __future__ import unicode_literals
from test import AntlrTest

class CheckerTest(AntlrTest):
    def compile(self, grammar):
        return super(CheckerTest, self).compile(grammar, options=("-ast",))

    def test_function_declaration(self):
        stdout, stderr = self.compile("func a(int x) returns int{ x = x + 1; }")
        print(stdout)
        print(stderr)
        pass

    def test_int_inference(self):
        stdout, stderr = self.compile("auto a = 3; int b = 3; a+b;")
        print(stdout, stderr)

    def test_binary_expression(self):
        stdout, stderr = self.compile("int a; char b; a+b;")
        print(stderr)
        print(stdout)

if __name__ == '__main__':
    import unittest
    unittest.main()
