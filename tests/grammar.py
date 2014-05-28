from test import AntlrTest

class GrammarTest(AntlrTest):
    def test_empty_declaration(self):
        for dtype in ("int", "char", "bool"):
            stdout, stderr = self.compile("%s a;" % dtype)
            self.assertEqual("(PROGRAM (%s a))" % dtype, stdout)
            self.assertEqual("", stderr)

    def test_declaration(self):
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

if __name__ == '__main__':
    import unittest
    unittest.main()
