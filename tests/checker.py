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
        self.assertTrue("Expression must of be of type boolean. Found: Type<INTEGER>." in stderr)

    def test_for(self):
        stdout, stderr = self.compile("int a;\nfor a in a{}")
        self.assertTrue("Expression must be iterable. Found: Type<INTEGER>." in stderr)

        stdout, stderr = self.compile("int a; char[1] b;\nfor a in b{}")
        self.assertTrue("""
Variable must be of same type as elements of iterable:
   a: Type<INTEGER>
   elements of iterable: Type<CHARACTER>""" in stderr)

    def test_bool_op(self):
        stdout, stderr = self.compile("int a = 3; a && (1 < 2);")
        self.assertTrue("Expression of type boolean expected. Found: Type<INTEGER>" in stderr)

        stdout, stderr = self.compile("(2 > 3) && (1 < 2);")
        self.assertFalse(stderr)

    def test_binary_expression(self):
        stdout, stderr = self.compile("int a; char b; a+b;")

    def test_error_reporter(self):
        stdout, stderr = self.compile("int a;\nchar b;\na+b;")
        # ... on line 3, char 2:
        #    a+b;
        #     ^
        self.assertIn("   a+b;\n    ^\n", stderr)
        self.assertIn("on line 3, char 2", stderr)


if __name__ == '__main__':
    import unittest
    unittest.main()
