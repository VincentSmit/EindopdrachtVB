from __future__ import unicode_literals
from test import AntlrTest
import time

class UseThisForDebugging:
    def really(self):
        print(stdout)
        print(stderr)
        time.sleep(1)

class CheckerTest(AntlrTest):
    def compile(self, grammar):
        return super(CheckerTest, self).compile(grammar, options=("-report", "-ast"))

    def test_array_to_pointer(self):
        stdout, stderr = self.compile("""
            import 'builtins/heap';

            int[1] tmp;
            func a(*int p) returns int{
                return 1;
            }
            a(tmp);
        """)
        self.assertFalse(stderr)

    def test_pointer_logic(self):
        stdout, stderr = self.compile("int a; *int b = &a; b = b + 1;")
        self.assertIn("Warning: pointer arithmetic is unchecked logic.", stdout)

        stdout, stderr = self.compile("int a; *int b = &a; b = 1 + b;")
        self.assertIn("Expected operands to be of same type. Found: Type<INTEGER> and Type<POINTER, Type<INTEGER>>", stderr)

    def test_array_declaration(self):
        stdout, stderr = self.compile("int[3] a;")
        self.assertIn("Could not find alloc()", stderr)

        stdout, stderr = self.compile("import 'builtins/heap'; int['c'] a;")
        self.assertIn("Expected Type<INTEGER> but found Type<CHARACTER>", stderr)

        stdout, stderr = self.compile("import 'builtins/heap'; int[3] a;")
        self.assertFalse(stderr)

    def test_array_lookup(self):
        stdout, stderr = self.compile("""
            import 'builtins/heap';
            int[3] a;
            a[2];
        """)
        self.assertIn("Could not find get_from_array()", stderr)

        stdout, stderr = self.compile("""
            import 'builtins/heap';
            import 'builtins/array';
            int[3] a;
            a['c'];
        """)
        self.assertIn("Expected Type<INTEGER> but found Type<CHARACTER>", stderr)

        stdout, stderr = self.compile("""
            import 'builtins/array';
            int a;
            a[3];
        """)
        self.assertIn("Expected array but found Type<INTEGER>", stderr)

    def test_variable_type(self):
        """We only accept variable types on assignments and function returns."""
        stdout, stderr = self.compile("func malloc(int size) returns *var{ return 6; }")
        self.assertIn("Expected Type<POINTER, Type<VARIABLE>>, but got Type<INTEGER>.", stderr)

        stdout, stderr = self.compile("func malloc(int size) returns *var{ return &size; }")
        self.assertFalse(stderr)

        stdout, stderr = self.compile("**var a;")
        self.assertIn("Variable cannot have variable type.", stderr)

    def test_undefined(self):
        stdout, stderr = self.compile("print(a);")
        self.assertIn("Could not find symbol.", stderr)

    def test_pointers(self):
        stdout, stderr = self.compile("""
            int a  = 3;
            int b = &a;
        """)
        self.assertIn("Cannot assign value of Type<POINTER, Type<INTEGER>> to variable of Type<INTEGER>", stderr);

        stdout, stderr = self.compile("int a = 3; *int b = &a; """)
        self.assertFalse(stderr)

        stdout, stderr = self.compile("int a = 3; print(*(&a));""")
        self.assertFalse(stderr)

        stdout, stderr = self.compile("int x = 5; print(*x);""")
        self.assertIn("Cannot dereference non-pointer", stderr)

        stdout, stderr = self.compile("""
            int x = 5;
            func test(*int a) returns int{
                return 0;
            }
            print(&x);
        """)
        self.assertFalse(stderr)

        stdout, stderr = self.compile("""
            int x = 5;
            *int y = &x;
            **int z = &y;
            z* = 9;
        """)
        self.assertIn("Cannot assign value of Type<POINTER, Type<INTEGER>> to variable of Type<POINTER, Type<POINTER, Type<INTEGER>>>", stderr)

        stdout, stderr = self.compile("""
            int x = 5;
            *int y = &x;
            **int z = &y;
            z** = 9;
        """)
        self.assertFalse(stderr)

    def test_array_literal(self):
        stdout, stderr = self.compile("""
        import 'builtins/heap';
        int[3] a = [1, 'c', 3];
        """)
        self.assertIn("Elements of array must be of same type. Found: Type<CHARACTER>, expected Type<INTEGER>.", stderr)

        stdout, stderr = self.compile("""import 'builtins/heap'; char[3] a = [1, 2, 3]; """)
        self.assertIn("Cannot assign value of Type<ARRAY, Type<INTEGER>> to variable of Type<ARRAY, Type<CHARACTER>>.", stderr)

        stdout, stderr = self.compile("""import 'builtins/heap'; int[4] a = [1, 2, 3]; """)
        self.assertFalse(stderr)

        stdout, stderr = self.compile("""import 'builtins/heap'; auto[3] a = [1];""")
        self.assertIn("Cannot assign value of Type<ARRAY, Type<INTEGER>> to variable of Type<ARRAY, Type<AUTO>>", stderr)

        stdout, stderr = self.compile("""import 'builtins/heap'; auto x; auto[1] a = [x]; """)
        self.assertIn("Cannot assign AUTO types to an array of AUTO.", stderr)

    def test_relative_addresses(self):
        stdout, stderr = self.compile("""func x(int a, char b) returns char{}""")
        self.assertIn("Setting relative address of a to (1, -2).", stdout)
        self.assertIn("Setting relative address of b to (1, -1).", stdout)

    def test_wrong_number_of_arguments(self):
        stdout, stderr = self.compile("""
        func x(int a, char b) returns char{
            return 'c';
        }
        x(3);
        """)
        self.assertIn("Expected 2 arguments, 1 given.", stderr)

    def test_wrong_return_type(self):
        stdout, stderr = self.compile("""
        func x() returns char{ return 'c'; }
        int a = x();
        """)
        self.assertIn("Cannot assign value of Type<CHARACTER> to variable of Type<INTEGER>.", stderr)

    def test_wrong_arguments(self):
        stdout, stderr = self.compile("""
        func x(int a, char b) returns char{
            return 'c';
        }
        x('q', 'x');
        """)
        self.assertIn("Argument 1 of x expected Type<INTEGER>, but got Type<CHARACTER>.", stderr)

    def test_nesting(self):
        nested_horror = ("""
        func a0() returns int{
            func a1() returns int{
                func a2() returns int{
                    func a3() returns int{
                        func a4() returns int{
                            func a5() returns int{
                                func a6() returns int{
                                    func a7() returns int{}
                                }}}}}}}""")

        # Remove line with a7. Should work, as we can work 6 levels back
        six_levels = nested_horror.split("\n")
        six_levels = "\n".join(six_levels[0:-2] + six_levels[-1:])
        stdout, stderr = self.compile(six_levels)

        self.assertFalse(stderr)

        # Test 7 levels of nesting. Should return error.
        stdout, stderr = self.compile(nested_horror)
        self.assertIn("You can only nest functions 6 levels deep", stderr)

    def test_memory_addresses(self):
        stdout, stderr = self.compile("""
        import 'builtins/heap';
        int a;
        int b;

        func c() returns int{
            int d;
            int[3] e;
        }""")
        self.assertIn("Set relative memory address of a to (0, 0)", stdout)
        self.assertIn("Set relative memory address of b to (0, 1)", stdout)
        self.assertIn("Set relative memory address of d to (1, 0)", stdout)
        self.assertIn("Set relative memory address of e to (1, 1)", stdout)

    def test_variable_scope(self):
        stdout, stderr = self.compile("""
        int a;

        func b() returns int{
            int c;
        }
        """)
        self.assertIn("Setting scope of a to __root__()", stdout)
        self.assertIn("Setting scope of c to b()", stdout)

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

        stdout, stderr = self.compile("""
            import 'builtins/heap';
            int i;
            int[1] a;
            for i in a{ continue; }
        """)
        self.assertFalse(stderr)

        # Don't know why you would use this syntax but hey..
        stdout, stderr = self.compile("while(true){ func a () returns int { continue; } }")
        self.assertIn("'continue' outside loop.", stderr)

    def test_break(self):
        stdout, stderr = self.compile("break;")
        self.assertIn("'break' outside loop.", stderr)

        stdout, stderr = self.compile("""
            import 'builtins/heap';
            int i;
            int[1] a;
            for i in a{ break; }
        """)
        self.assertFalse(stderr)

        # Don't know why you would use this syntax but hey..
        stdout, stderr = self.compile("while(true){ func a () returns int { break; } }")
        self.assertIn("'break' outside loop.", stderr)

    def test_function_declaration(self):
        # Check argument setting
        stdout, stderr = self.compile("func a(int x) returns int{ x = x + 1; }")
        self.assertIn("Register argument x of Type<INTEGER> to a()", stdout)

        stdout, stderr = self.compile("func a(int x, char y) returns int{ x = x + 1; }")
        self.assertIn("Register argument x of Type<INTEGER> to a()", stdout)
        self.assertIn("Register argument y of Type<CHARACTER> to a()", stdout)

        # Check parent setting
        stdout, stderr = self.compile("func a() returns int{ func b() returns int{} }")
        self.assertIn("Setting a.parent = __root__", stdout)
        self.assertIn("Setting b.parent = a", stdout)

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

    def test_raw_type(self):
        stdout, stderr = self.compile("func a() returns int{ return __tam__(int, 'PUSH 0'); }")
        self.assertFalse(stderr)

        stdout, stderr = self.compile("func a() returns char{ return __tam__(int, 'PUSH 0'); }")
        self.assertIn("Expected Type<CHARACTER>, but got Type<INTEGER>.", stderr)

    def test_if(self):
        stdout, stderr = self.compile("int a = 3; if(a){}")
        self.assertTrue("Expression must of be of type boolean. Found: Type<INTEGER>." in stderr)

    def todo_test_for(self):
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
        self.assertIn("Cannot assign value of Type<CHARACTER> to variable of Type<INTEGER>.", stderr)

    def test_not(self):
        stdout, stderr = self.compile("!false;")
        self.assertFalse(stderr)

        stdout, stderr = self.compile("!1;")
        self.assertIn("Expected Type<BOOLEAN> but found Type<INTEGER>", stderr)


if __name__ == '__main__':
    import unittest
    unittest.main()
