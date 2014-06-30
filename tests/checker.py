from __future__ import unicode_literals
from test import AntlrTest


class CheckerTest(AntlrTest):
    def compile(self, grammar):
        return super(CheckerTest, self).compile(grammar, options=("-report", "-ast"))

    def test_return(self):
        # Return in root.
        stdout, stderr = self.compile("return 1;")
        self.assertIn("Return must be used in function.", stderr)

        # Return unknown type
        stdout, stderr = self.compile("func a() returns int{ auto b; return b; }")
        self.assertIn("Return value must have type, not auto (maybe we did not discover its type yet?)", stderr)

        # Return wrong type
        stdout, stderr = self.compile("func a() returns int{ return true; }")
        self.assertIn("Expected Type<INTEGER>, but got Type<BOOLEAN>", stderr)

        # Return known type
        stdout, stderr = self.compile("func a() returns auto{ return true; }")
        self.assertIn("Setting 'a' to Type<BOOLEAN>", stdout.split("\n"))

    def test_continue(self):
        stdout, stderr = self.compile("continue;")
        self.assertIn("'continue' outside loop.", stderr)

        stdout, stderr = self.compile("int i;\nint[1] a;\nfor i in a{ continue; } \n")
        self.assertFalse(stderr)

        # Don't know why you would use this syntax but hey..
        stdout, stderr = self.compile("while(true){ func a () returns int { continue; } }")
        self.assertIn("'continue' outside loop.", stderr)

    def test_break(self):
        stdout, stderr = self.compile("break;")
        self.assertIn("'break' outside loop.", stderr)

        stdout, stderr = self.compile("int i;\nint[1] a;\nfor i in a{ break; } \n")
        self.assertFalse(stderr)

        # Don't know why you would use this syntax but hey..
        stdout, stderr = self.compile("while(true){ func a () returns int { break; } }")
        self.assertIn("'break' outside loop.", stderr)

    def test_function_declaration(self):
        stdout, stderr = self.compile("func a(int x) returns int{ x = x + 1; }")
        self.assertIn("Register argument x of Type<INTEGER> to a()", stdout)

        stdout, stderr = self.compile("func a(int x, char y) returns int{ x = x + 1; }")
        self.assertIn("Register argument x of Type<INTEGER> to a()", stdout)
        self.assertIn("Register argument y of Type<CHARACTER> to a()", stdout)

    def test_double_declaration(self):
        # Primitive, then function
        stdout, stderr = self.compile("int a;\nfunc a() returns int {}")
        self.assertIn("but variable a was already declared on ", stderr)

        # Function, then primitive
        stdout, stderr = self.compile("func a() returns int {}; int a;")
        self.assertIn("but variable a was already declared on ", stderr)

        # Function, then function
        stdout, stderr = self.compile("func a() returns int {};" * 2)
        self.assertIn("but variable a was already declared on ", stderr)

        # Primitive, then primitive
        stdout, stderr = self.compile("int a; int a;")
        self.assertIn("but variable a was already declared on ", stderr)

        # Inside scope, should not trigger error
        stdout, stderr = self.compile("func a() returns int{ int a; }")
        self.assertFalse(stderr)

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

    def test_assign(self):
        stdout, stderr = self.compile("int a = 'c';")
        self.assertIn("Cannot assign value of Type<INTEGER> to variable of type Type<CHARACTER>.", stderr)

if __name__ == '__main__':
    import unittest
    unittest.main()
