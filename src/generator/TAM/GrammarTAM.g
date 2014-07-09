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

    import generator.Utils;
}

@members {
    // Keep track of the 'current' function
    protected Stack<FunctionNode> funcs = new Stack<>();
    protected Stack<Integer> loops = new Stack<>();
    protected Emitter emitter = new Emitter();
    protected Function funcUtil = new Function(this, emitter);

    /**
     * Calls Utils.addr() with current call scope.
     *
     * @param inode identifier to resolve address for.
     */
    protected String addr(IdentifierNode inode){
        return Utils.addr(funcs.peek(), inode);
    }
}

program: ^(p=PROGRAM<FunctionNode> {
    funcUtil.enter((FunctionNode)p);
} import_statement* command+){
    funcUtil.exit((FunctionNode)p);
    emitter.emit("HALT");
};
    
import_statement: ^(IMPORT from=IDENTIFIER imprt=IDENTIFIER);
command: declaration | statement | expression{
    emitter.emit("POP(0) 1", "Pop (unused) result of expression");
} | ^(PROGRAM command+);
commands: command commands?;

declaration: var_declaration | func_declaration;

statement:
    assignment |
    while_statement |
    return_statement |
    if_statement |
    print_statement |
    break_statement |
    continue_statement;

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
@init{ loops.push(input.index()); emitter.emitLabel("DO", loops.peek()); }:
    ^(WHILE expression {
        emitter.emit("JUMPIF(0) AFTER" + loops.peek() + "[CB]");
    } command*){
        emitter.emit("JUMP DO" + loops.peek() + "[CB]");
        emitter.emitLabel("AFTER", loops.peek());
        loops.pop();
    };

break_statement: b=BREAK{
    emitter.emit("JUMP AFTER" + loops.peek() + "[CB]");
};

continue_statement: c=CONTINUE{
    emitter.emit("JUMP DO" + loops.peek() + "[CB]");
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
    funcUtil.enter(func);
} type ^(ARGS arguments?) ^(BODY commands?)){
    funcUtil.exit(func);
};

assign returns [int value=0]:
    ^(DEREFERENCE a=assign){
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
    ^(DEREFERENCE type);

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
    | ^(MULT x=expression y=expression)   { emitter.emit("CALL mult"); }
    | ^(MOD x=expression y=expression)    { emitter.emit("CALL mod"); }
    | ^(POWER x=expression y=expression)  { emitter.emit("CALL fockdeze"); }
    | ^(AND x=expression y=expression)    { emitter.emit("CALL and"); }
    | ^(OR x=expression y=expression)     { emitter.emit("CALL or"); }
    | ^(c=CALL<TypedNode> id=IDENTIFIER<IdentifierNode> expression_list?){
        FunctionNode func = (FunctionNode)((IdentifierNode)id).getRealNode();
        emitter.emit(String.format("CALL (\%s) \%s[CB]",
            Utils.register(funcs.peek(), func), func.getFullName()
        ));
    }
    | ^(a=AMPERSAND id=IDENTIFIER){
        emitter.emit(String.format("LOADA \%s", addr((IdentifierNode)id)), "\%" + $id.text);
    }
    | ^(p=DEREFERENCE ex=expression){
        emitter.emit("LOADI(1)");
    }
    | ^(g=GET id=IDENTIFIER{
        emitter.emit("LOADA " + addr((IdentifierNode)id), $id.text);
        emitter.emit("LOADI(1)", "Resolve pointer to first element");
    } index=expression){
        emitter.emit("CALL (SB) get_from_array[CB]");
    }
    | ^(n=NOT ex=expression){
        emitter.emit("CALL not");
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
    TRUE{
        emitter.emit("LOADL 1");
    } |
    FALSE{
        emitter.emit("LOADL 0");
    } |
    ^(arr=ARRAY{
        $value = arr;
    } expression*){

    } |
    ^(TAM type s=STRING_VALUE){
        emitter.emit($s.text.substring(1, $s.text.length() - 1).trim());
    };

