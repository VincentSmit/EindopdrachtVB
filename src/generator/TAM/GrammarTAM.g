tree grammar GrammarTAM;

options {
    tokenVocab=Grammar;
    ASTLabelType=CommonNode;
}

@header {
    package generator.TAM;
    import ast.*;
    import java.util.Map;
    import java.util.HashMap;
    import java.util.Stack;
    import java.util.List;
}

@members {
    // Keep track of the 'current' function
    private Stack<FunctionNode> funcs = new Stack<>();

    // Used to determine at which position on the stack a variable is kept.
    private String label;
    private String comment;

    /*
     * Prints code `s` formatted nicely.
     *
     * @requires: s != null
     * @ensures: this.label == null && this.comment == null;
     */
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

    /*
     * Prints code `s` formatted nicely according to emit(String).
     *
     * @requires: s != null
     * @ensures: this.label == null && this.comment == null;
     */
    public void emit(String s, String comment){
        this.comment = comment;
        emit(s);
    }

    /*
     * Set label property for following emit() call.
     *
     * @requires: s != null
     * @ensures: this.label != null
     */
    public void emitLabel(String s, int ix){
        this.label = s + ix + ":";
    }

    private void prepareFunction(FunctionNode f){
        funcs.push(f);
        emit(String.format("PUSH \%s", f.getVars().size()));
    }

    private void var(String s){
    }

    /*
     * Determines memory address of given identifier (which might be a pointer,
     * in case of an array).
     *
     * @return: String formatted as {offset:int}[{base:string}]
     */
    private String addr(IdentifierNode id){
        int lookupScopeLevel = (Integer)funcs.peek().getMemAddr().getValue0();
        int idScopeLevel = (Integer)id.getMemAddr().getValue0();
        int diff = lookupScopeLevel - idScopeLevel;

        String base = "LB"; // Local base
        if (diff == 6 || lookupScopeLevel == 0){
            // Declared as global, so we need to fetch it from stack base
            base = "SB";
        } else if (diff > 0){
            // Declared in one of enclosing functions, so we need to use
            // pseudoregisters L1, L2 ... L6.
            base = "L" + diff;
        }

        // Return offset[base]
        return String.format("\%s[\%s]", id.getMemAddr().getValue1(), base);
    }
}

program: ^(p=PROGRAM<FunctionNode> {
    prepareFunction((FunctionNode)p);
} import_statement* command+){
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


// Already handled in function/program declaration
var_declaration: ^(VAR type id=IDENTIFIER);

assignment: ^(ASSIGN id=IDENTIFIER expression){
    emit("STORE(1) " + addr((IdentifierNode)id));
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
       emit("LOAD(1) " + addr((IdentifierNode)id));
    } |
    n=NUMBER{
        emit("LOADL " + $n.text);
    } |
    STRING_VALUE;

