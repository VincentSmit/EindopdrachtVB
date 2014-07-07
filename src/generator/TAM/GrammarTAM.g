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

    private Emitter emitter = new Emitter();

    private void prepareFunction(FunctionNode f){
        if(f.getMemAddr().getValue0() != 0){
            // We're not the root note, so we need to make sure the TAM interpreter
            // skips this function while executing the code.
            emitter.emit(String.format("JUMP \%safter[CB]", f.getFullName()));
        }

        emitter.emitLabel(f.getFullName());
        funcs.push(f);

        if (f.getVars().size() > 0)
            emitter.emit(String.format("PUSH \%s", f.getVars().size()));
    }

    private void cleanFunction(FunctionNode func){
        // Deallocate all arrays. Yes, I know this is O(n) with n being the amount
        // of variables in this function. We could keep an extra list for arrays
        // only, but this is even uglier IMO.
        for (TypedNode node : funcs.peek().getVars()){
            if (node.getExprType().getPrimType() == Type.Primitive.ARRAY){
                emitter.emit("LOADA " + addr((IdentifierNode)node), node.getText());                        
                emitter.emit("LOADI(1)", "Load heap pointer to array"); 
                emitter.emit("CALL (L1) free[CB]", "Freeeedooooooom"); 
                emitter.emit("POP(1) 0", "Pop useless call result");
            }
        };

        emitter.emitLabel(func.getFullName(), "after");
        funcs.pop();
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
    cleanFunction((FunctionNode)p);
    emitter.emit("HALT");
};
    
import_statement: ^(IMPORT from=IDENTIFIER imprt=IDENTIFIER);
command: declaration | statement | expression{
    int size = ($expression.value == null) ? 1 : $expression.value.getSize();
    emitter.emit("POP(0) " + size, "Pop (unused) result of expression");
} | ^(PROGRAM command+);
commands: command commands?;

declaration: var_declaration | func_declaration;

statement:
    assignment |
    while_statement |
    return_statement |
    if_statement |
    print_statement;

if_statement
@init{ int ix = input.index(); }:
^(IF {
    emitter.emitLabel("IF", ix);
} expression {
    emitter.emit("JUMPIF (0) ELSE" + ix + "[CB]");
} ^(THEN commands?) {
    emitter.emit("JUMP ENDIF" + ix + "[CB]");
    emitter.emitLabel("ELSE", ix);
} (^(ELSE commands?))?){
    emitter.emitLabel("ENDIF", ix);
};

print_statement: ^(PRINT expr=expression){
    emitter.emit("CALL putint");
    emitter.emit("LOADL 10", "Print newline");
    emitter.emit("CALL put");
};

return_statement: ^(RETURN<ControlNode> expression){
    emitter.emit("RETURN (1) " + funcs.peek().getArgs().size(), "Return and pop arguments");
};

while_statement
@init{ int ix = input.index(); emitter.emitLabel("DO", ix); }:
    ^(WHILE expression {
        emitter.emit("JUMPIF(0) AFTER" + ix + "[CB]");
    } command*){
        emitter.emit("JUMP DO" + ix + "[CB]");
        emitter.emitLabel("AFTER", ix);
    };


// Already handled in function/program declaration
var_declaration: 
    ^(VAR type id=IDENTIFIER) |
    ^(VAR ^(ARRAY type expression) id=IDENTIFIER){
        // We don't never need no static link yo
        emitter.emit("CALL (L1) alloc[CB]", "Allocate array");
        emitter.emit("STORE(1) " + addr((IdentifierNode)id), "Store pointer in " + $id.text);
    };

arguments: argument arguments?;
argument: t=type id=IDENTIFIER<IdentifierNode>;

func_declaration: ^(FUNC id=IDENTIFIER {
    FunctionNode func = (FunctionNode)id;
    prepareFunction(func);
} type ^(ARGS arguments?) ^(BODY commands?)){
    cleanFunction(func);
};

assign returns [int value=0]:
    ^(ASTERIX a=assign){
        $value = $a.value + 1;
    }|
    ^(EXPR expression);

assignment:
    ^(ASSIGN id=IDENTIFIER assign){
        String address = addr((IdentifierNode)id);

        if ($assign.value == 0){
            // We can prevent instruction if we do not need to dereference pointers; we
            // can directly store the result on the desired location
            emitter.emit("STORE(1) " + address, $id.text);
        } else {
            // Load address of current identifier onto the stack
            emitter.emit("LOADA " + address, $id.text);

            // For each dereference (\%) found, load pointer which is the current
            // pointer is pointing to (nice...)
            for (int i=0; i < $assign.value; i++){
                emitter.emit("LOADI (1)");
            }

            // Pop address from stack and store results
            emitter.emit("STOREI(1)");
        }
    }|
    ^(ASSIGN id=IDENTIFIER ^(GET value=assign index=expression)){
        // 'expression' holding the amount of 
        emitter.emit("LOADA " + addr((IdentifierNode)id));
        emitter.emit("LOADI(1)", "First element of array " + id.getText());
        emitter.emit("CALL add", "Plus N elements");
        emitter.emit("STOREI(1)", "Store array value");
    }
;


type: primitive_type | composite_type;
primitive_type: INTEGER | BOOLEAN | CHARACTER | VAR;
composite_type:
    ARRAY primitive_type expression |
    ^(ASTERIX type);

expression returns [CommonNode value]:
      ^(PLUS x=expression y=expression)   { emitter.emit("CALL add"); }
    | ^(MINUS x=expression y=expression)  { emitter.emit("CALL sub"); }
    | ^(LT x=expression y=expression)     { emitter.emit("CALL lt"); }
    | ^(GT x=expression y=expression)     { emitter.emit("CALL gt"); }
    | ^(LTE x=expression y=expression)    { emitter.emit("CALL le"); }
    | ^(GTE x=expression y=expression)    { emitter.emit("CALL ge"); }
    | ^(EQ x=expression y=expression)     { emitter.emit("LOADL 1"); emitter.emit("CALL eq"); }
    | ^(NEQ x=expression y=expression)    { emitter.emit("LOADL 1"); emitter.emit("CALL ne"); }
    | ^(DIVIDES x=expression y=expression){ emitter.emit("CALL div"); }
    | ^(MULTIPL x=expression y=expression){ emitter.emit("CALL mult"); }
    | ^(POWER x=expression y=expression)  { emitter.emit("CALL fockdeze"); }
    | ^(AND x=expression y=expression)    {
        emitter.emit("CALL add", "&&");
        emitter.emit("LOADL 2", "&&");
        emitter.emit("LOADL 1", "&&");
        emitter.emit("CALL eq", "&&");
    }
    | ^(OR x=expression y=expression){
        emitter.emit("CALL add", "||");
        emitter.emit("LOADL 0", "||");
        emitter.emit("CALL gt", "||"); 
    }
    | ^(c=CALL<TypedNode> id=IDENTIFIER<IdentifierNode> expression_list?){
        IdentifierNode inode = (IdentifierNode)id;
        FunctionNode func = (FunctionNode)inode.getRealNode();
        int funcLevel = (Integer)func.getMemAddr().getValue0() - 1;
        int currentLevel = funcs.size() - 1;

        String base = register(currentLevel - funcLevel, currentLevel);
        emitter.emit(String.format("CALL (\%s) \%s[CB]", base, func.getFullName()));
    }
    | ^(a=AMPERSAND id=IDENTIFIER){
        emitter.emit(String.format("LOADA \%s", addr((IdentifierNode)id)), "\%" + $id.text);
    }
    | ^(p=ASTERIX ex=expression){
        emitter.emit("LOADI(1)");
    }
    | ^(g=GET id=IDENTIFIER{
        emitter.emit("LOADA " + addr((IdentifierNode)id), $id.text);
        emitter.emit("LOADI(1)", "Resolve pointer to first element");
    } index=expression){
        emitter.emit("CALL (SB) get_from_array[CB]");

    }
    | operand {
        $value = $operand.value;
    };

expression_list: expression expression_list?;

operand returns [CommonNode value]:
    id=IDENTIFIER{
        emitter.emit("LOAD(1) " + addr((IdentifierNode)id), $id.text);
    } |
    n=NUMBER{
        emitter.emit("LOADL " + $n.text);
    } |
    s=STRING_VALUE{
        emitter.emit("LOADL " + (int)($s.text).charAt(1));
    } |
    ^(arr=ARRAY{
        $value = arr;
    } expression*){

    } |
    ^(TAM type s=STRING_VALUE){
        emitter.emit($s.text.substring(1, $s.text.length() - 1).trim());
    }
    ;

