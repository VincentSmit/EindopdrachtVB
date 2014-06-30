from __future__ import unicode_literals
from test import AntlrTest

GRAMMAR_OPTS = ("-no_checker", "-ast")


class GrammarTest(AntlrTest):
    def compile(self, grammar):
        return super(GrammarTest, self).compile(grammar, options=GRAMMAR_OPTS)

    def test_empty_declaration(self):
        """Test empty declaration (without assignment)"""
        for dtype in ("int", "char", "bool", "auto"):
            stdout, stderr = self.compile("%s a;" % dtype)
            self.assertEqual("(PROGRAM (VAR %s a))" % dtype, stdout)
            self.assertEqual("", stderr)

    def test_declaration(self):
        """Test declaration + assignment"""
        stdout, stderr = self.compile("int a = 2;")
        self.assertEqual("(PROGRAM (VAR int a) (ASSIGN a 2))", stdout)
        self.assertEqual("", stderr)

        stdout, stderr = self.compile("char a = 'c';")
        self.assertEqual("(PROGRAM (VAR char a) (ASSIGN a 'c'))", stdout)
        self.assertEqual("", stderr)

    def test_string_value(self):
        """Does escaping work?"""
        # Note: this should raise an error while checking (char --> length 1)
        stdout, stderr = self.compile(r"char a = 'c\'';")
        self.assertEqual(r"(PROGRAM (VAR char a) (ASSIGN a 'c\''))", stdout)
        self.assertEqual("", stderr)

    def test_function_declaration(self):
        stdout, stderr = self.compile(r"func foo(int a, char b) returns bool{}")
        self.assertEqual("(PROGRAM (func foo bool (ARGS int a char b) BODY))", stdout)
        self.assertEqual("", stderr)

    def test_empty_function_declaration(self):
        stdout, stderr = self.compile(r"func foo() returns bool{}")
        self.assertEqual("(PROGRAM (func foo bool ARGS BODY))", stdout)
        self.assertEqual("", stderr)

    def test_auto_type_function_declaration(self):
        stdout, stderr = self.compile(r"func foo(){}")
        self.assertEqual("(PROGRAM (func foo auto ARGS BODY))", stdout)
        self.assertEqual("", stderr)

    def test_array_literal(self):
        # This is wrong of course (types don't match), but we don't run a checker yet
        stdout, stderr = self.compile(r"int a = [1, 2, 3];")
        self.assertEqual("(PROGRAM (VAR int a) (ASSIGN a (ARRAY 1 2 3)))", stdout)
        self.assertEqual("", stderr)

    def test_array_declaration(self):
        stdout, stderr = self.compile(r"int[3/2] a;")
        self.assertEqual("(PROGRAM (VAR (ARRAY int (/ 3 2)) a))", stdout)
        self.assertEqual("", stderr)

    def test_function_call(self):
        stdout, stderr = self.compile(r"fuuuunc(1, 3/4);")
        self.assertEqual("(PROGRAM (CALL fuuuunc 1 (/ 3 4)))", stdout)
        self.assertEqual("", stderr)

    def test_operator(self):
        stdout, stderr = self.compile(r"int a; a = a + b;")
        self.assertEqual("(PROGRAM (VAR int a) (= a (+ a b)))", stdout)
        self.assertEqual("", stderr)

    def test_while(self):
        stdout, stderr = self.compile(r"while(a<b){ a = b + 1; }")
        self.assertEqual("(PROGRAM (while (< a b) (= a (+ b 1))))", stdout)
        self.assertEqual("", stderr)

    def test_for(self):
        stdout, stderr = self.compile(r"for a in b{ a + b; }")
        self.assertEqual("(PROGRAM (for a b (+ a b)))", stdout)
        self.assertEqual("", stderr)

    def test_empty_while(self):
        stdout, stderr = self.compile(r"while(a<b){}")
        self.assertEqual("(PROGRAM (while (< a b)))", stdout)
        self.assertEqual("", stderr)

    def test_if(self):
        stdout, stderr = self.compile(r"if(a<b){ a = b + 1; }")
        self.assertEqual("(PROGRAM (IF (< a b) (= a (+ b 1)) ELSE))", stdout)
        self.assertEqual("", stderr)

    def test_if_else(self):
        stdout, stderr = self.compile(r"if(a<b){ a = b; } else { b = a; }")
        self.assertEqual("(PROGRAM (IF (< a b) (= a b) ELSE (= b a)))", stdout)
        self.assertEqual("", stderr)

    def test_nested(self):
        stdout, stderr = self.compile(r"if(a<b){ if(a<b){ a = b; }}")
        self.assertEqual("(PROGRAM (IF (< a b) (IF (< a b) (= a b) ELSE) ELSE))", stdout)
        self.assertEqual("", stderr)

    def test_boolean(self):
        stdout, stderr = self.compile(r"int a = true;")
        self.assertEqual("(PROGRAM (VAR int a) (ASSIGN a true))", stdout)
        self.assertEqual("", stderr)

        stdout, stderr = self.compile(r"int a = false;")
        self.assertEqual("(PROGRAM (VAR int a) (ASSIGN a false))", stdout)
        self.assertEqual("", stderr)

    def test_operator_precedence(self):
        stdout, stderr = self.compile("auto a = 3 + 4 / 5 ^ 2 <= 6 ^ (3+4) / 5;")
        self.assertEqual(stdout, "(PROGRAM (VAR auto a) (ASSIGN a (<= (+ 3 (/ 4 (^ 5 2))) (/ (^ 6 (+ 3 4)) 5))))")

    # INVALID PROGRAMS


if __name__ == '__main__':
    import unittest
    unittest.main()
