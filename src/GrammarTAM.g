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
    private String label;
    private String comment;

    public void emit(String s){
        // Print label
        if(label != null){
            System.out.print(label);
            for (int i=label.length(); i < 10; i++) System.out.print(' ');
        } else {
            for (int i=0; i < 10; i++) System.out.print(' ');
        }

        // Print command
        System.out.print(s);

        // Print comment
        if (comment != null){
            for (int i=s.length(); i < 30; i++) System.out.print(' ');
            System.out.print("; ");
            System.out.print(comment);
        }

        this.comment = null;
        this.label = null;
        System.out.println("");
    }

    public void emit(String s, String comment){
        this.comment = comment;
        emit(s);
    }

    public void emitLabel(String s, int ix){
        this.label = s + ix + ":";
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
    emit("HALT");
};
    
import_statement: ^(IMPORT from=IDENTIFIER imprt=IDENTIFIER);
command: declaration | statement;

declaration: var_declaration;
statement:
    assignment |
    while_statement;

while_statement
@init{ int ix = input.index(); emitLabel("DO", ix); }:
    ^(WHILE expression {
        emit("JUMPIF(0) AFTER" + ix + "[CB]");
    } command*){
        emit("JUMP DO" + ix + "[CB]");
        emitLabel("AFTER", ix);
    };


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
        emit("LOAD " + addr($id.text), $id.text);
    } |
    n=NUMBER{
        emit("LOADL " + $n.text);
    } |
    STRING_VALUE;

