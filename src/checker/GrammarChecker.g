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

    private IdentifierNode getID(String id){
        return symtab.retrieve(id).getNode();
    }

    // Keep a stack of all loops within functions.
    private Stack<Pair<FunctionNode, Stack<CommonNode>>> loops = new Stack<Pair<FunctionNode, Stack<CommonNode>>>();

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
            reporter.error(op, "Operator expected operands to be of same type. Found: " +
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
    loops.peek().getValue0().setMemAddr(Pair.with(0, -1));
} command+);

commands: command commands?;
command: declaration | expression | statement;

declaration: var_declaration | scope_declaration;

var_declaration:
    ^(VAR t=type id=IDENTIFIER<IdentifierNode> assignment?){
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
        var.setMemAddr(Pair.with(symtab.currentLevel(), func.getVars().size() - 1));

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
    ^(f=FUNC<FunctionNode> id=IDENTIFIER<IdentifierNode> t=type{
        // Set name and parent of function
        FunctionNode func = (FunctionNode)$f.tree;
        func.setName($id.text);
        func.setParent(loops.peek().getValue0());
        log(String.format("Setting \%s.parent = \%s", $id.text, func.getParent().getName()));

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

        ((TypedNode)$id.tree).setExprType(((TypedNode)$t.tree).getExprType());
        func.setExprType(((TypedNode)$t.tree).getExprType());
        symtab.openScope();
        func.setMemAddr(Pair.with(symtab.currentLevel(), -1));

        // Disallow nesting deeper than 6 levels (limitation in TAM, as the pseudoregisters
        // L1, L2... only exist up to L6).
        //
        // TODO: Implement our own pseudoregisters (resolving static links dynamically)
        if (loops.size() > 6 + 2){ // +2 for root node, and current function declaration
            reporter.error(func, "You can only nest functions 6 levels deep, it's morally wrong to nest deeper ;-).");
        }

    } ^(ARGS arguments?) ^(BODY commands?)) {
        symtab.closeScope();
        loops.pop();
   };

argument: t=type id=IDENTIFIER<IdentifierNode>{
    // Code duplication! :(
    try {
        symtab.enter($id.text, new IdEntry((IdentifierNode)$id.tree));
        ((TypedNode)$id.tree).setExprType(((TypedNode)$t.tree).getExprType());
    } catch (SymbolTableException e) {
        reporter.error($id.tree, e.getMessage());
    }

    FunctionNode function = loops.peek().getValue0();
    function.getArgs().add((TypedNode)$id.tree);

    log(String.format(
        "Register argument \%s of \%s to \%s().",
        $id.text, ((TypedNode)$id.tree).getExprType(), function.getName()
    ));
};
arguments: argument (arguments)?;

statement:
    ^(IF if_part ELSE else_part) |
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
     } id=IDENTIFIER ex=expression commands?) {
        // Retrieve identifier from symtab.
        ((IdentifierNode)$id.tree).setRealNode(getID($id.text));

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
        ret.setParent(loops.peek().getValue0());

        FunctionNode func = (FunctionNode)ret.getParent();
        TypedNode expr = (TypedNode)$ex.tree;

        // PROGRAM is a special 'function node', but doesn't allow return statements.
        if(loops.size() == 1){
            reporter.error(r, "Return must be used in function.");
        }

        // Set expression type of function if type inference requested
        if (func.getExprType().getPrimType() == Type.Primitive.AUTO){
            func.setExprType(expr.getExprType());
            log(String.format("Setting '\%s' to \%s", func.getName(), func.getExprType()));
        }

        // If we don't know the type of `expr`, throw an error.
        System.out.println(expr.getExprType());
        if (expr.getExprType().getPrimType() == Type.Primitive.AUTO){
            reporter.error(ret, "Return value must have type, not auto (maybe we did not discover its type yet?)");
        }

        // Test equivalence of types
        if (!func.getExprType().equals(expr.getExprType())){
            reporter.error(ret, String.format(
                "Expected \%s, but got \%s.", func.getExprType(), expr.getExprType())
            );
        }


    }|
    b=BREAK<ControlNode>{
        try{
            CommonNode loop = loops.peek().getValue1().peek();
        } catch(EmptyStackException e){
            reporter.error($b.tree, "'break' outside loop.");
        }

        ((ControlNode)$b.tree).setParent(loops.peek().getValue0());
    }|
    c=CONTINUE<ControlNode>{
        try{
            CommonNode loop = loops.peek().getValue1().peek();
        } catch(EmptyStackException e){
            reporter.error($c.tree, "'continue' outside loop.");
        }

        ((ControlNode)$c.tree).setParent(loops.peek().getValue0());
    }|
    assignment;

assignment: ^(a=ASSIGN id=IDENTIFIER<IdentifierNode> ex=expression){
    // Retrieve identifier from symtab.
    ((IdentifierNode)$id.tree).setRealNode(getID($id.text));

    // If `id` is AUTO, infer type from expression
    if(((TypedNode)$id.tree).getExprType().getPrimType().equals(Type.Primitive.AUTO)){
        ((TypedNode)$id.tree).setExprType((TypedNode)$ex.tree);
        log(String.format("Setting '\%s' to \%s", $id.text, ((TypedNode)$id.tree).getExprType()));
    }

    TypedNode idt = (TypedNode)$id.tree;
    TypedNode ext = (TypedNode)$ex.tree;

    if(!idt.getExprType().equals(ext.getExprType())){
        reporter.error($a.tree, String.format(
            "Cannot assign value of \%s to variable of type \%s.",
            idt.getExprType(), ext.getExprType()
        ));
    }
};

if_part
@init{ symtab.openScope(); }
@after{ symtab.closeScope(); }:
    ^(ex=expression command*) {
        TypedNode ext = (TypedNode)$ex.tree;
        if(!(ext.getExprType().equals(Type.Primitive.BOOLEAN))){
            reporter.error($ex.tree, "Expression must of be of type boolean. Found: " + ext.getExprType() + ".");
        }
    };

else_part
@init{ symtab.openScope(); }
@after{ symtab.closeScope(); }:
    command*;

bool_op: AND | OR;
same_op: PLUS | MINUS | DIVIDES | MULTIPL | POWER;
same_bool_op: LT | GT | LTE | GTE | EQ | NEQ;

expression:
    operand |
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
    };

operand:
    id=IDENTIFIER<IdentifierNode> {
        ((IdentifierNode)$id.tree).setRealNode(getID($id.text));
    } |
    n=NUMBER {
        ((TypedNode)$n.tree).setExprType(Type.Primitive.INTEGER);
    } |
    s=STRING_VALUE {
        ((TypedNode)$s.tree).setExprType(Type.Primitive.CHARACTER);
    } |
    b=(TRUE|FALSE){
        ((TypedNode)$b.tree).setExprType(Type.Primitive.BOOLEAN);
    };
