from test import AntlrTest

class GrammarTest(AntlrTest):
    def test_empty_declaration(self):
        """Test empty declaration (without assignment)"""
        for dtype in ("int", "char", "bool"):
            stdout, stderr = self.compile("%s a;" % dtype)
            self.assertEqual("(PROGRAM (%s a))" % dtype, stdout)
            self.assertEqual("", stderr)

    def test_declaration(self):
        """Test declaration + assignment"""
        stdout, stderr = self.compile("int a = 2;")
        self.assertEqual("(PROGRAM (int a 2))", stdout)
        self.assertEqual("", stderr)

        stdout, stderr = self.compile("char a = 'c';")
        self.assertEqual("(PROGRAM (char a 'c'))", stdout)
        self.assertEqual("", stderr)

    def test_string_value(self):
        """Does escaping work?"""
        # Note: this should raise an error while checking (char --> length 1)
        stdout, stderr = self.compile(r"char a = 'c\'';")
        self.assertEqual(r"(PROGRAM (char a 'c\''))", stdout)
        self.assertEqual("", stderr)

    def test_function_declaration(self):
        stdout, stderr = self.compile(r"func foo(int a, char b) returns bool{}")
        self.assertEqual("(PROGRAM (func foo bool (ARGS int a char b) BODY))", stdout)
        self.assertEqual("", stderr)

    def test_array_literal(self):
        # This is wrong of course (types don't match), but we don't run a checker yet
        stdout, stderr = self.compile(r"int a = [1, 2, 3];")
        self.assertEqual("(PROGRAM (int a (ARRAY 1 2 3)))", stdout)
        self.assertEqual("", stderr)

    def test_array_declaration(self):
        stdout, stderr = self.compile(r"array int [7+3] a;")
        print('wtf')
        print(stdout)
        print(stderr)




if __name__ == '__main__':
    import unittest
    unittest.main()
