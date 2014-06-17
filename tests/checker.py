from __future__ import unicode_literals
from test import AntlrTest

class CheckerTest(AntlrTest):
    def compile(self, grammar):
        return super(CheckerTest, self).compile(grammar, options=("-report",))

    def test_function_declaration(self):
        stdout, stderr = self.compile("func a(int x) returns int{ x = x + 1; }")

    def test_int_inference(self):
        stdout, stderr = self.compile("auto a = 3;")
        self.assertIn("Setting 'a' to Type<INTEGER>", stdout.split("\n"))

    def test_boolean_inference(self):
        stdout, stderr = self.compile("auto a = true;")
        self.assertIn("Setting 'a' to Type<BOOLEAN>", stdout.split("\n"))

    def test_if(self):
        stdout, stderr = self.compile("int a = 3; if(a){}")
        self.assertTrue("ERROR: expression must be of type boolean." in stderr)

    def test_bool_op(self):
        stdout, stderr = self.compile("bool a = 3;")
        self.assertTrue("ERROR: Type mismatch: Type<BOOLEAN> vs Type<INTEGER>.")

        stdout, stderr = self.compile("bool a = true;")
        self.assertFalse(stderr)


    def test_binary_expression(self):
        stdout, stderr = self.compile("int a; char b; a+b;")

if __name__ == '__main__':
    import unittest
    unittest.main()
