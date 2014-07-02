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
            for (int i=label.length(); i < 20; i++) System.out.print(' ');
        } else {
            for (int i=0; i < 20; i++) System.out.print(' ');
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
        emitLabel(s, ((Integer)ix).toString());
    }

    public void emitLabel(String s1, String s2){
        if (this.label != null){
            // A label was already defined. Do a NOP and add an extra label on next line.
            emit("PUSH 0", "NOP for secondary label");
        }

        this.label = String.format("\%s\%s:", s1, s2);
    }

    public void emitLabel(String s1, String s2, String s3){
        emitLabel(s1 + s2, s3);
    }

    private void prepareFunction(FunctionNode f){
        if(f.getMemAddr().getValue0() != 0){
            // We're not the root note, so we need to make sure the TAM interpreter
            // skips this function while executing the code.
            emit(String.format("JUMP func\%safter[CB]", f.getName()));
        }

        emitLabel("func", f.getName());
        funcs.push(f);

        if (f.getVars().size() > 0)
            emit(String.format("PUSH \%s", f.getVars().size()));
    }

    private String register(int diff, int lookupScopeLevel){
        String base = "LB"; // Local base
        if (diff == 6 || lookupScopeLevel == 0){
            // Declared as global, so we need to fetch it from stack base
            base = "SB";
        } else if (diff > 0){
            // Declared in one of enclosing functions, so we need to use
            // pseudoregisters L1, L2 ... L6.
            base = "L" + diff;
        }

        return base;
    }

    /*
     * Determines memory address of given identifier (which might be a pointer,
     * in case of an array).
     *
     * @return: String formatted as {offset:int}[{base:string}]
     */
    private String addr(IdentifierNode id){
        int lookupScopeLevel = (Integer)funcs.peek().getMemAddr().getValue0();
        int idScopeLevel = (Integer)id.getRealNode().getMemAddr().getValue0();
        int diff = lookupScopeLevel - idScopeLevel;

        String base = register(diff, lookupScopeLevel);

        // Return offset[base]
        return String.format("\%s[\%s]", id.getRealNode().getMemAddr().getValue1(), base);
    }
}

program: ^(p=PROGRAM<FunctionNode> {
    prepareFunction((FunctionNode)p);
} import_statement* command+){
    emit("HALT");
};
    
import_statement: ^(IMPORT from=IDENTIFIER imprt=IDENTIFIER);
command: declaration | statement | expression{
    emit("POP(0) 1", "Pop (unused) result of expression");
};
commands: command commands?;

declaration: var_declaration | func_declaration;

statement:
    assignment |
    while_statement |
    return_statement;

return_statement:
    ^(r=RETURN<ControlNode> ex=expression){

    };

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

arguments: argument arguments?;
argument: t=type id=IDENTIFIER<IdentifierNode>;

func_declaration: ^(FUNC id=IDENTIFIER {
    FunctionNode func = (FunctionNode)id;
    prepareFunction(func);
} type ^(ARGS arguments?) ^(BODY commands?)){
    emit("RETURN (1) " + func.getArgs().size(), "Return and pop arguments");
    emitLabel("func", func.getName(), "after");
    funcs.pop();
};

assignment: ^(ASSIGN id=IDENTIFIER expression){
    emit("STORE(1) " + addr((IdentifierNode)id), $id.text);
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
    | ^(c=CALL<TypedNode> id=IDENTIFIER<IdentifierNode> expression_list?){
        IdentifierNode inode = (IdentifierNode)id;
        FunctionNode func = (FunctionNode)inode.getRealNode();
        int funcLevel = (Integer)func.getMemAddr().getValue0() - 1;
        int currentLevel = funcs.size() - 1;

        String base = register(currentLevel - funcLevel, currentLevel);
        emit(String.format("CALL (\%s) \%s[CB]", base, "func" + func.getName()));
    }
    | operand;

expression_list: expression expression_list?;

operand: 
    id=IDENTIFIER{
       emit("LOAD(1) " + addr((IdentifierNode)id), $id.text);
    } |
    n=NUMBER{
        emit("LOADL " + $n.text);
    } |
    STRING_VALUE;

