tree grammar GrammarChecker;

options {
    tokenVocab=Grammar;
    ASTLabelType=CommonNode;
    output=AST;
}

@rulecatch {
    catch(RecognitionException e){
        throw e;
    }
}

@header {
    package checker;
    import java.util.Stack;
    import java.util.EmptyStackException;
    import symtab.SymbolTable;
    import symtab.SymbolTableException;
    import symtab.IdEntry;
    import ast.*;
    import reporter.Reporter;
    import org.javatuples.Pair;
}

// Alter code generation so catch-clauses get replaced with this action. 
// This disables ANTLR ERROR handling: CalcExceptions are propagated upwards.
@members {
    private SymbolTable<IdEntry> symtab = new SymbolTable<>();

    private IdentifierNode getID(CommonNode node, String id) throws InvalidTypeException{
        if (symtab.retrieve(id) == null){
            reporter.error(node, "Could not find symbol.");
        }
        return symtab.retrieve(id).getNode();
    }

    // Upon evaluating pointer assignments (b\% = 3, for example) we need to keep track
    // of the current type while descending the tree: (ASSIGN b (\% 3)).
    private Type assignType;

    // Used to keep track of arguments in a function definition call
    private int argumentCount;

    // Used to keep track of currently called function, which is used by 'expression_list'
    // to verify the correctness of given types.
    private FunctionNode calling;

    // Keep a stack of all loops within functions.
    private Stack<Pair<FunctionNode, Stack<CommonNode>>> loops = new Stack<Pair<FunctionNode, Stack<CommonNode>>>();

    // Keep track of array literals
    private Stack<TypedNode> arrays = new Stack<>();

    public Reporter reporter;
    public void setReporter(Reporter r){ this.reporter = r; }
    public void log(String msg){ this.reporter.log(msg); }

    public void checkSameOp(CommonNode op, TypedNode ex1tree, TypedNode ex2tree) throws InvalidTypeException{
        // If one of the typednodes has type auto, assume type of other typednode.
        if(ex1tree.getExprType().getPrimType().equals(Type.Primitive.AUTO)){
            ex1tree.setExprType(ex2tree.getExprType());
        } else if(ex2tree.getExprType().getPrimType().equals(Type.Primitive.AUTO)){
            ex2tree.setExprType(ex1tree.getExprType());
        }

        if(!(ex1tree.getExprType().equals(ex2tree.getExprType()))){
            reporter.error(op, "Expected operands to be of same type. Found: " +
            ex1tree.getExprType() + " and " + ex2tree.getExprType() + ".");
        }

        ((TypedNode)op).setExprType(ex1tree.getExprType());
    }
}

program
@init {
    symtab.openScope();
}
@after {
    symtab.closeScope();
    loops.pop();
}
: ^(p=PROGRAM<FunctionNode>{
    loops.push(Pair.with((FunctionNode)$p.tree, new Stack<CommonNode>()));
    loops.peek().getValue0().setName("__root__");
    loops.peek().getValue0().setMemAddr(Pair.with(loops.size() - 1, -1));
} command+);

commands: command commands?;
command: declaration | expression | statement;

declaration: var_declaration | scope_declaration;

var_declaration:
    ^(VAR t=type id=IDENTIFIER<IdentifierNode>){
        IdentifierNode var = (IdentifierNode)$id.tree;

        try {
            symtab.enter($id.text, new IdEntry(var));
        } catch (SymbolTableException e) {
            reporter.error($id.tree, String.format(
                "but variable \%s was already declared \%s",
                $id.text, reporter.pointer(symtab.retrieve($id.text).getNode())
            ));
        }

        // Copy expression type of `t`
        var.setExprType(((TypedNode)$t.tree).getExprType());

        // Register variable with function
        FunctionNode func = loops.peek().getValue0();
        func.getVars().add(var);
        var.setMemAddr(Pair.with(loops.size() - 1, func.getVars().size() - 1));

        log(String.format(
            "Set relative memory address of \%s to (\%s, \%s)",
            $id.text, var.getMemAddr().getValue0(), var.getMemAddr().getValue1()
        ));

        // Set scope to textual function scope
        var.setScope(func);
        log(String.format("Setting scope of \%s to \%s().", $id.text, func.getName()));
    };

scope_declaration: func_declaration;

func_declaration:
    ^(FUNC id=IDENTIFIER<FunctionNode> t=type{
        // Set name and parent of function
        FunctionNode func = (FunctionNode)$id.tree;
        func.setName($id.text);
        func.setScope(loops.peek().getValue0());
        func.setExprType(Type.Primitive.FUNCTION);
        log(String.format("Setting \%s.parent = \%s", $id.text, func.getScope().getName()));

        // Register new scope of looping
        loops.push(Pair.with(func, new Stack<CommonNode>()));

        try {
            symtab.enter($id.text, new IdEntry((IdentifierNode)$id.tree));
        } catch (SymbolTableException e) {
            reporter.error($id.tree, String.format(
                "but variable \%s was already declared \%s",
                $id.text, reporter.pointer(symtab.retrieve($id.text).getNode())
            ));
        }

        func.setReturnType(((TypedNode)$t.tree).getExprType());
        symtab.openScope();
        func.setMemAddr(Pair.with(loops.size() - 1, -1));

        // Disallow nesting deeper than 6 levels (limitation in TAM, as the pseudoregisters
        // L1, L2... only exist up to L6).
        //
        // TODO: Implement our own pseudoregisters (resolving static links dynamically)
        if (loops.size() > 6 + 2){ // +2 for root node, and current function declaration
            reporter.error(func, "You can only nest functions 6 levels deep, it's morally wrong to nest deeper ;-).");
        }

        argumentCount = 0;
    } ^(ARGS arguments?) {
        // Set memory addresses for arguments
        IdentifierNode arg;
        int inverse_count;
        for (int i=0; i < func.getArgs().size(); i++){
            arg = func.getArgs().get(i);
            inverse_count = -1 * (func.getArgs().size() - i);
            arg.setMemAddr(Pair.with(loops.size() - 1, inverse_count));

            log(String.format(
                "Setting relative address of \%s to (\%s, \%s).",
                arg.getText(), loops.size() - 1, inverse_count
            ));
        }
    } ^(BODY commands?)) {
        symtab.closeScope();
        loops.pop();
   };

argument: t=type id=IDENTIFIER<IdentifierNode>{
    IdentifierNode inode = (IdentifierNode)$id.tree;

    // Code duplication! :(
    try {
        symtab.enter($id.text, new IdEntry(inode));
        ((TypedNode)$id.tree).setExprType(((TypedNode)$t.tree).getExprType());
    } catch (SymbolTableException e) {
        reporter.error(inode, e.getMessage());
    }

    // Register argument with FunctionNode
    FunctionNode function = loops.peek().getValue0();
    function.getArgs().add(inode);

    log(String.format(
        "Register argument \%s of \%s to \%s().",
        $id.text, ((TypedNode)$id.tree).getExprType(), function.getName()
    ));

    // Set memory address of node, which counts backwards for stack-based models
    inode.setMemAddr(Pair.with(loops.size() - 1, 0));
};

arguments: argument {
    argumentCount += 1;
} arguments?;

statement:
    ^(PRINT expression) |
    ^(IF exp=expression {
        symtab.openScope();

        // Expression must be of type boolean.
        TypedNode ext = (TypedNode)$exp.tree;
        if(!(ext.getExprType().equals(Type.Primitive.BOOLEAN))){
            reporter.error($exp.tree, "Expression must of be of type boolean. Found: " + ext.getExprType() + ".");
        }
    } ^(THEN commands?) {
        symtab.closeScope();
        symtab.openScope();
    } (^(ELSE commands?))?){
        symtab.closeScope();
    } |
    ^(w=WHILE{
        // Add this loop to the stack of current loops
        loops.peek().getValue1().push($w.tree);
     } ex=expression command*) {
        TypedNode ext = (TypedNode)$ex.tree;
        if(!ext.getExprType().equals(Type.Primitive.BOOLEAN)) {
            reporter.error($ex.tree, "Expression must be of type boolean. Found: " + ext.getExprType() + ".");
        }
    } |
    ^(f=FOR{
        // Add this loop to the stack of current loops
        loops.peek().getValue1().push($f.tree);
     } id=IDENTIFIER<IdentifierNode> ex=expression commands?) {
        // Retrieve identifier from symtab.
        ((IdentifierNode)$id.tree).setRealNode(getID($id.tree, $id.text));

        // Check if argument is indeed an array
        TypedNode ext = (TypedNode)$ex.tree;
        if(!ext.getExprType().getPrimType().equals(Type.Primitive.ARRAY)) {
            reporter.error($ex.tree, "Expression must be iterable. Found: " + ext.getExprType() + ".");
        }

        // Compare innertype of array with identifier type
        Type inner = ext.getExprType().getInnerType();
        if(!((TypedNode)$id.tree).getExprType().equals(inner)){
            reporter.error($id.tree,
                "Variable must be of same type as elements of iterable:\n" +
                String.format("   \%s: \%s\n", $id.text, ((TypedNode)$id.tree).getExprType()) +
                String.format("   elements of iterable: \%s", inner)
            );
        }
    } |
    ^(r=RETURN<ControlNode> ex=expression){
        // Set parent (function) of this control node (break, continue)
        ControlNode ret = (ControlNode)$r.tree;
        ret.setScope(loops.peek().getValue0());

        FunctionNode func = (FunctionNode)ret.getScope();
        TypedNode expr = (TypedNode)$ex.tree;

        // PROGRAM is a special 'function node', but doesn't allow return statements.
        if(loops.size() == 1){
            reporter.error(r, "Return must be used in function.");
        }

        // Set expression type of function if type inference requested
        if (func.getReturnType().getPrimType() == Type.Primitive.AUTO){
            func.setReturnType(expr.getExprType());
            log(String.format("Setting '\%s' to \%s", func.getName(), func.getReturnType()));
        }

        // If we don't know the type of `expr`, throw an error.
        if (expr.getExprType().getPrimType() == Type.Primitive.AUTO){
            reporter.error(ret, "Return value must have type, not auto (maybe we did not discover its type yet?)");
        }

        // Test equivalence of types
        if (!func.getReturnType().equals(expr.getExprType())){
            reporter.error(ret, String.format(
                "Expected \%s, but got \%s.", func.getReturnType(), expr.getExprType())
            );
        }


    }|
    b=BREAK<ControlNode>{
        try{
            CommonNode loop = loops.peek().getValue1().peek();
        } catch(EmptyStackException e){
            reporter.error($b.tree, "'break' outside loop.");
        }

        ((ControlNode)$b.tree).setScope(loops.peek().getValue0());
    }|
    c=CONTINUE<ControlNode>{
        try{
            CommonNode loop = loops.peek().getValue1().peek();
        } catch(EmptyStackException e){
            reporter.error($c.tree, "'continue' outside loop.");
        }

        ((ControlNode)$c.tree).setScope(loops.peek().getValue0());
    }|
    assignment;

assign:
    ^(a=ASTERIX<TypedNode> as=assign){
        ((TypedNode)$a.tree).setExprType(new Type(
            Type.Primitive.POINTER, ((TypedNode)$as.tree).getExprType()
        ));
    } |
    ^(expr=EXPR<TypedNode> ex=expression){
        ((TypedNode)$expr.tree).setExprType(((TypedNode)$ex.tree).getExprType());

    };

assignment: ^(a=ASSIGN id=IDENTIFIER<IdentifierNode> ex=assign){
    IdentifierNode inode = (IdentifierNode)$id.tree;

    // Retrieve identifier from symtab.
    inode.setRealNode(getID(inode, $id.text));

    // Set assign type, so we can use it in `assign`
    assignType = inode.getExprType();


    // If `id` is AUTO, infer type from expression
    if((inode.getExprType().getPrimType().equals(Type.Primitive.AUTO))){
        inode.setExprType((TypedNode)$ex.tree);
        log(String.format("Setting '\%s' to \%s", $id.text, inode.getExprType()));
    } else if(inode.getExprType().getPrimType().equals(Type.Primitive.ARRAY) &&
                inode.getExprType().getInnerType().getPrimType().equals(Type.Primitive.AUTO)){
        // Infer type for arrays
        inode.setExprType((TypedNode)$ex.tree);
        log(String.format("Setting '\%s' to \%s", $id.text, inode.getExprType()));

    }

    TypedNode idt = (TypedNode)$id.tree;
    TypedNode ext = (TypedNode)$ex.tree;

    if(!idt.getExprType().equals(ext.getExprType())){
        reporter.error($a.tree, String.format(
            "Cannot assign value of \%s to variable of \%s.",
            ext.getExprType(), idt.getExprType()
        ));
    }
};

bool_op: AND | OR;
same_op: PLUS | MINUS | DIVIDES | MULTIPL | POWER;
same_bool_op: LT | GT | LTE | GTE | EQ | NEQ;

expression_list: expr=expression {
    TypedNode arg = calling.getArgs().get(argumentCount);
    TypedNode exp = (TypedNode)$expr.tree;

    if (!arg.getExprType().equals(exp.getExprType())){
        reporter.error(exp, String.format(
            "Argument \%s of \%s expected \%s, but got \%s.",
            argumentCount + 1, calling.getName(),
            arg.getExprType(), exp.getExprType()
        ));
    }

    argumentCount += 1;
} expression_list?;

expression:
    operand |
    ^(c=CALL<TypedNode> id=IDENTIFIER<IdentifierNode>{
        // TODO: Check against function definition
        IdentifierNode idNode = (IdentifierNode)$id.tree;
        idNode.setRealNode(getID($id.tree, $id.text));
        FunctionNode func = calling = (FunctionNode)idNode.getRealNode();
        ((TypedNode)$c.tree).setExprType(func.getReturnType());

        // Reset argumentCount to allow counting the numbers of arguments following
        argumentCount = 0;
    } expression_list? {
        // Compare the number of arguments given with the number of needed arguments
        if (argumentCount != func.getArgs().size()){
            reporter.error(func, String.format(
                "Expected \%s arguments, \%s given.", func.getArgs().size(), argumentCount
            ));
        }
    })|
    ^(op=bool_op ex1=expression ex2=expression) {
        ((TypedNode)$op.tree).setExprType(new Type(Type.Primitive.BOOLEAN));

        TypedNode ex1tree = (TypedNode)$ex1.tree;
        TypedNode ex2tree = (TypedNode)$ex2.tree;

        if(!(ex1tree.getExprType().equals(Type.Primitive.BOOLEAN))) {
            reporter.error(ex1tree, "Expression of type boolean expected. Found: " + ex1tree.getExprType());
        }else if(!ex2tree.getExprType().equals(Type.Primitive.BOOLEAN)) {
            reporter.error(ex2tree, "Expression of type boolean expected. Found: " + ex2tree.getExprType());
        }
    } |
    ^(op=same_op ex1=expression ex2=expression){
        checkSameOp($op.tree, (TypedNode)$ex1.tree, (TypedNode)$ex2.tree);
    }|
    ^(op=same_bool_op ex1=expression ex2=expression){
        checkSameOp($op.tree, (TypedNode)$ex1.tree, (TypedNode)$ex2.tree);
        ((TypedNode)$op.tree).setExprType(Type.Primitive.BOOLEAN);
    }|
    ^(tam=TAM<TypedNode> t=type STRING_VALUE){
        ((TypedNode)$tam.tree).setExprType(((TypedNode)$t.tree).getExprType());
    }|
    ^(p=ASTERIX<TypedNode> ex=expression){
        if(((TypedNode)$ex.tree).getExprType().getPrimType() != Type.Primitive.POINTER){
            reporter.error($ex.tree, "Cannot dereference non-pointer.");
        }

        // Dereference variable: take over inner type
        ((TypedNode)$p.tree).setExprType(((TypedNode)$ex.tree).getExprType().getInnerType());
    }|
    ^(p=AMPERSAND<TypedNode> id=IDENTIFIER<IdentifierNode>){
        // Make pointer to variable
        ((IdentifierNode)$id.tree).setRealNode(getID($id.tree, $id.text));

        ((TypedNode)$p.tree).setExprType(new Type(
            Type.Primitive.POINTER, ((IdentifierNode)$id.tree).getExprType()
        ));
    };


type:
    primitive_type |
    composite_type ;

primitive_type:
    i=INTEGER<TypedNode>    { ((TypedNode)$i.tree).setExprType(Type.Primitive.INTEGER); }|
    b=BOOLEAN<TypedNode>    { ((TypedNode)$b.tree).setExprType(Type.Primitive.BOOLEAN); }|
    c=CHARACTER<TypedNode>  { ((TypedNode)$c.tree).setExprType(Type.Primitive.CHARACTER); }|
    a=AUTO<TypedNode>       { ((TypedNode)$a.tree).setExprType(Type.Primitive.AUTO); };

composite_type:
    ^(arr=ARRAY<TypedNode> t=primitive_type expression){
        Type ttype = ((TypedNode)$t.tree).getExprType();
        ((TypedNode)$arr.tree).setExprType(new Type(Type.Primitive.ARRAY, ttype));
    }|
    ^(a=ASTERIX<TypedNode> t=type){
        ((TypedNode)$a.tree).setExprType(new Type(
            Type.Primitive.POINTER, ((TypedNode)$t.tree).getExprType()
        ));
    };

array_expression:
    ex=expression{
        Type arrType = arrays.peek().getExprType();
        Type expType = ((TypedNode)$ex.tree).getExprType();

        if(arrType.getInnerType().getPrimType() == Type.Primitive.AUTO){
            // We are the first one!
            arrType.setInnerType(expType);
        }

        if(arrType.getInnerType().getPrimType() == Type.Primitive.AUTO){
            // If this type is *still* AUTO, we do not know what to do.
            reporter.error($ex.tree, String.format(
                "Cannot assign AUTO types to an array of AUTO."
            ));
        }

        // Checking type against previous array element (essentially)
        if (!arrType.getInnerType().equals(expType)){
            reporter.error($ex.tree, String.format(
                "Elements of array must be of same type. Found: \%s, expected \%s.",
                expType, arrType.getInnerType()
            ));
        }
    };

operand:
    id=IDENTIFIER<IdentifierNode> {
        ((IdentifierNode)$id.tree).setRealNode(getID($id.tree, $id.text));
    } |
    n=NUMBER {
        ((TypedNode)$n.tree).setExprType(Type.Primitive.INTEGER);
    } |
    s=STRING_VALUE {
        ((TypedNode)$s.tree).setExprType(Type.Primitive.CHARACTER);
    } |
    b=(TRUE|FALSE){
        ((TypedNode)$b.tree).setExprType(Type.Primitive.BOOLEAN);
    } |
    ^(arr=ARRAY<TypedNode> {
        TypedNode array = (TypedNode)$arr.tree;
        array.setExprType(Type.Primitive.ARRAY);
        array.getExprType().setInnerType(new Type(Type.Primitive.AUTO));
        arrays.push(array);
    } values=array_expression*){
        arrays.pop();
    } 
;
