tree grammar GrammarTAM;

options {
    tokenVocab=Grammar;
    ASTLabelType=CommonTree; // AST nodes are of type CommonTree
}

@header {
import java.util.Map;
import java.util.HashMap;
import java.util.Stack;
import java.util.List;
}

@members {
    // Used to determine at which position on the stack a variable is kept.
    private List<String> vars = new ArrayList<String>();

    public void emit(String s){
        System.out.println(s);
    }

    public void emit(String s, String comment){
        System.out.print(s);
        System.out.print(" ;");
        System.out.println(comment);
    }

    private void var(String s){
        vars.add(s);
        emit("PUSH 1", "var " + s);
    }

    private String addr(String id){
        return vars.indexOf(id) + "[SB]";
    }
}

program: ^(PROGRAM import_statement* command+){
  System.out.println("HALT");
};
    
import_statement: ^(IMPORT from=IDENTIFIER imprt=IDENTIFIER);
command: declaration | statement;

declaration: var_declaration;
statement: assignment;

var_declaration: 
    ^(VAR type id=IDENTIFIER){ var($id.text); };

assignment: ^(ASSIGN id=IDENTIFIER expression){
    emit("STORE(1) " + addr($id.text));
};


type: primitive_type | composite_type;
primitive_type: INTEGER | BOOLEAN | CHARACTER;
composite_type: ARRAY primitive_type expression;

expression:
      ^(PLUS x=expression y=expression)   { emit("CALL add"); }
    | ^(MINUS x=expression y=expression)  { emit("CALL sub"); }
    | ^(LT x=expression y=expression)     { emit("CALL lt"); }
    | ^(GT x=expression y=expression)     { emit("CALL gt"); }
    | ^(LTE x=expression y=expression)    { emit("CALL le"); }
    | ^(GTE x=expression y=expression)    { emit("CALL ge"); }
    | ^(EQ x=expression y=expression)     { emit("LOADL 1\nCALL eq"); }
    | ^(NEQ x=expression y=expression)    { emit("LOADL 1\nCALL ne"); }
    | ^(DIVIDES x=expression y=expression){ emit("CALL div"); }
    | ^(MULTIPL x=expression y=expression){ emit("CALL mult"); }
    | ^(POWER x=expression y=expression)  { emit("CALL fockdeze"); }
    | operand;

operand: 
    id=IDENTIFIER{
        emit("LOAD " + addr($id.text));
    } |
    n=NUMBER{
        emit("LOADL " + $n.text);
    } |
    STRING_VALUE;

