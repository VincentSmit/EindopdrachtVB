from __future__ import unicode_literals
from test import AntlrTest

GRAMMAR_OPTS = ("-no_checker", "-ast")


class GrammarTest(AntlrTest):
    def compile(self, grammar):
        return super(GrammarTest, self).compile(grammar, options=GRAMMAR_OPTS)

    def test_array_lookup(self):
        stdout, stderr = self.compile("a[3];")
        self.assertEqual(stdout, "(PROGRAM (GET a 3))")

    def test_array_assign(self):
        stdout, stderr = self.compile("a[3] = 5;")
        self.assertEqual(stdout, "(PROGRAM (ASSIGN a (GET (EXPR 5) 3)))")
        
    # TODO: Nested array declaration
    def todo_test_nested_array(self):
        stdout, stderr = self.compile(r"int[6][5] a;")
        self.assertEqual(stdout, "(PROGRAM (VAR (ARRAY int 6 5) a))")

    def test_pointer_type(self):
        stdout, stderr = self.compile("func malloc(int size) returns *var{}")
        self.assertEqual(stdout, "(PROGRAM (func malloc (DEREFERENCE var) (ARGS int size) BODY))")

    def test_import(self):
        stdout, stderr = self.compile("import 'builtins/test';")
        self.assertEqual(stdout, "(PROGRAM (PROGRAM (print 1)))")

        stdout, stderr = self.compile("import 'builtins/test'; print(2);")
        self.assertEqual(stdout, "(PROGRAM (PROGRAM (print 1)) (print 2))");

    def test_pointer_logic(self):
        stdout, stderr = self.compile("""
            int  a;
            *int b = &a;
            b = b + 1;
            a = *(b - 1);
        """)
        self.assertEqual("(PROGRAM (VAR int a) (VAR (DEREFERENCE int) b) (ASSIGN b (EXPR (& a))) (ASSIGN b (EXPR (+ b 1))) (ASSIGN a (EXPR (DEREFERENCE (- b 1)))))", stdout)
    
    def test_pointers(self):
        stdout, stderr = self.compile("**int a;")
        self.assertEqual(stdout, "(PROGRAM (VAR (DEREFERENCE (DEREFERENCE int)) a))")

        stdout, stderr = self.compile("f(&a);")
        self.assertEqual(stdout, "(PROGRAM (CALL f (& a)))")

        stdout, stderr = self.compile("f(&&a);")
        self.assertTrue(stderr)

        stdout, stderr = self.compile("f(*a);")
        self.assertEqual(stdout, "(PROGRAM (CALL f (DEREFERENCE a)))")

        stdout, stderr = self.compile("f(**a);")
        self.assertEqual(stdout, "(PROGRAM (CALL f (DEREFERENCE (DEREFERENCE a))))")

        stdout, stderr = self.compile("func f(*int a) returns int{}")
        self.assertFalse(stderr)
        
        return
        stdout, stderr = self.compile("""
            int a = 2;
            *int b = &a;
            b* = 5;
        """)
        print(stdout)
        self.assertEqual("(PROGRAM (VAR int a) (ASSIGN a (EXPR 2)) (VAR (DEREFERENCE int) b) (ASSIGN b (EXPR (& a))) (ASSIGN b (DEREFERENCE (EXPR 5))))", stdout)

        stdout, stderr = self.compile("b*** = 4;")
        self.assertEqual("(PROGRAM (ASSIGN b (DEREFERENCE (DEREFERENCE (DEREFERENCE (EXPR 4))))))", stdout)

    def test_tam(self):
        stdout, stderr = self.compile("""
        __tam__(int, '
            LOADL 9
            POP (0) 1
        ');""")

        self.assertEqual(stdout, """(PROGRAM (__tam__ int '
            LOADL 9
            POP (0) 1
        '))""")

    def test_empty_declaration(self):
        """Test empty declaration (without assignment)"""
        for dtype in ("int", "char", "bool", "auto"):
            stdout, stderr = self.compile("%s a;" % dtype)
            self.assertEqual("(PROGRAM (VAR %s a))" % dtype, stdout)
            self.assertEqual("", stderr)

    def test_declaration(self):
        """Test declaration + assignment"""
        stdout, stderr = self.compile("int a = 2;")
        self.assertEqual("(PROGRAM (VAR int a) (ASSIGN a (EXPR 2)))", stdout)
        self.assertEqual("", stderr)

        stdout, stderr = self.compile("char a = 'c';")
        self.assertEqual("(PROGRAM (VAR char a) (ASSIGN a (EXPR 'c')))", stdout)
        self.assertEqual("", stderr)

    def test_string_value(self):
        """Does escaping work?"""
        # Note: this should raise an error while checking (char --> length 1)
        stdout, stderr = self.compile(r"char a = 'c\'';")
        self.assertEqual(r"(PROGRAM (VAR char a) (ASSIGN a (EXPR 'c\'')))", stdout)
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
        self.assertEqual("(PROGRAM (VAR int a) (ASSIGN a (EXPR (ARRAY 1 2 3))))", stdout)
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
        self.assertEqual("(PROGRAM (VAR int a) (ASSIGN a (EXPR (+ a b))))", stdout)
        self.assertEqual("", stderr)

    def test_while(self):
        stdout, stderr = self.compile(r"while(a<b){ a = b + 1; }")
        self.assertEqual("(PROGRAM (while (< a b) (ASSIGN a (EXPR (+ b 1)))))", stdout)
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
        self.assertEqual("(PROGRAM (IF (< a b) (THEN (ASSIGN a (EXPR (+ b 1))))))", stdout)
        self.assertEqual("", stderr)

    def test_if_else(self):
        stdout, stderr = self.compile(r"if(a<b){ a = b; } else { b = a; }")
        self.assertEqual("(PROGRAM (IF (< a b) (THEN (ASSIGN a (EXPR b))) (else (ASSIGN b (EXPR a)))))", stdout)
        self.assertEqual("", stderr)

    def test_nested(self):
        stdout, stderr = self.compile(r"if(a<b){ if(a<b){ a = b; }}")
        self.assertEqual("(PROGRAM (IF (< a b) (THEN (IF (< a b) (THEN (ASSIGN a (EXPR b)))))))", stdout)
        self.assertEqual("", stderr)

    def test_boolean(self):
        stdout, stderr = self.compile(r"int a = true;")
        self.assertEqual("(PROGRAM (VAR int a) (ASSIGN a (EXPR true)))", stdout)
        self.assertEqual("", stderr)

        stdout, stderr = self.compile(r"int a = false;")
        self.assertEqual("(PROGRAM (VAR int a) (ASSIGN a (EXPR false)))", stdout)
        self.assertEqual("", stderr)

    def test_operator_precedence(self):
        stdout, stderr = self.compile("auto a = 3 + 4 / 5 ^ 2 <= 6 ^ (3+4) / 5;")
        self.assertEqual(stdout, "(PROGRAM (VAR auto a) (ASSIGN a (EXPR (<= (+ 3 (/ 4 (^ 5 2))) (/ (^ 6 (+ 3 4)) 5)))))")

    def test_call_operator_precedence(self):
        stdout, stderr = self.compile("""a() + b();""")
        self.assertEqual(stdout, "(PROGRAM (+ (CALL a) (CALL b)))")

    def test_multiline_string(self):
        stdout, stderr = self.compile("""char a = 'ab\nc';""")
        self.assertEqual(stdout, "(PROGRAM (VAR char a) (ASSIGN a (EXPR 'ab\nc')))")

    # INVALID PROGRAMS


if __name__ == '__main__':
    import unittest
    unittest.main()
