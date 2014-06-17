tree grammar GrammarChecker;

options {
    tokenVocab=Grammar;
    ASTLabelType=CommonTree;
    output=AST;
}

@rulecatch {
    catch(RecognitionException e){
        throw e;
    }
}

@header {
    package checker;
    import symtab.SymbolTable;
    import symtab.SymbolTableException;
    import symtab.IdEntry;
    import ast.Type;
    import ast.TypedNode;
    import ast.TypedNodeAdaptor;
    import ast.InvalidTypeException;
    import reporter.Reporter;
}

// Alter code generation so catch-clauses get replaced with this action. 
// This disables ANTLR ERROR handling: CalcExceptions are propagated upwards.
@members {
    private SymbolTable<IdEntry> symtab = new SymbolTable<>();

    private TypedNode getID(String id){
        return symtab.retrieve(id).getNode();
    }

    public Reporter reporter;
    public void setReporter(Reporter r){ this.reporter = r; }
    public void log(String msg){ this.reporter.log(msg); }

    public void checkSameOp(CommonTree op, TypedNode ex1tree, TypedNode ex2tree) throws InvalidTypeException{
        if(!(ex1tree.getExprType().equals(ex2tree.getExprType()))){
            reporter.error(op, "Operator expected operands to be of same type. Found: " +
            ex1tree.getExprType() + " and " + ex2tree.getExprType() + ".");
        }

        ((TypedNode)op).setExprType(ex1tree.getExprType());
    }
}

program
@init { symtab.openScope(); }
    : ^(PROGRAM command+) { symtab.closeScope(); }
    ;

commands: command+;
command: declaration | expression | statement;

declaration: var_declaration | scope_declaration;

var_declaration:
    ^(VAR t=type id=IDENTIFIER<TypedNode> assignment?){
        try {
            symtab.enter($id.text, new IdEntry((TypedNode)$id.tree));
        } catch (SymbolTableException e) {
            reporter.error($id.tree, String.format(
                "but variable \%s was already declared \%s",
                $id.text, reporter.pointer(symtab.retrieve($id.text).getNode())
            ));
        }

        ((TypedNode)$id.tree).setExprType(((TypedNode)$t.tree).getExprType());
    };

scope_declaration: func_declaration;

func_declaration:
   ^(FUNC id=IDENTIFIER<TypedNode> t=type ^(ARGS arguments?){
       try {
            symtab.enter($id.text, new IdEntry((TypedNode)$id.tree));
        } catch (SymbolTableException e) {
            reporter.error($id.tree, String.format(
                "but variable \%s was already declared \%s",
                $id.text, reporter.pointer(symtab.retrieve($id.text).getNode())
            ));
        }

        ((TypedNode)$id.tree).setExprType(((TypedNode)$t.tree).getExprType());
        symtab.openScope();
   } ^(BODY commands?)) {
        symtab.closeScope();
   };

argument: t=type id=IDENTIFIER{
    // Code duplication! :(
    try {
        symtab.enter($id.text, new IdEntry((TypedNode)$id.tree));
        ((TypedNode)$id.tree).setExprType(((TypedNode)$t.tree).getExprType());
    } catch (SymbolTableException e) {
        System.err.print("ERROR: exception thrown by symboltable: ");
        System.err.println(e.getMessage());
    } 
};
arguments: argument (arguments)?;

statement:
    ^(IF if_part ELSE else_part) |
    ^(WHILE ex=expression command*) {
        TypedNode ext = (TypedNode)$ex.tree;
        if(!ext.getExprType().equals(Type.Primitive.BOOLEAN)) {
            reporter.error($ex.tree, "Expression must be of type boolean. Found: " + ext.getExprType() + ".");
        }
    } |
    ^(FOR id=IDENTIFIER ex=expression command*) {
        // Retrieve identifier from symtab.
        CommonTree old_id_tree = id_tree;
        id_tree = getID($id.text);

        TypedNode ext = (TypedNode)$ex.tree;
        if(!ext.getExprType().getPrimType().equals(Type.Primitive.ARRAY)) {
            reporter.error($ex.tree, "Expression must be iterable. Found: " + ext.getExprType() + ".");
        }

        Type inner = ext.getExprType().getInnerType();
        if(!((TypedNode)$id.tree).getExprType().equals(inner)){
            reporter.error(old_id_tree,
                "Variable must be of same type as elements of iterable:\n" +
                String.format("   \%s: \%s\n", $id.text, ((TypedNode)$id.tree).getExprType()) +
                String.format("   elements of iterable: \%s", inner)
            );
        }
    } |
    ^(RETURN expression) |
    assignment;

assignment: ^(a=ASSIGN id=IDENTIFIER<TypedNode> ex=expression){
    // Retrieve identifier from symtab.
    id_tree = getID($id.text);

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
    i=INTEGER    { ((TypedNode)$i.tree).setExprType(Type.Primitive.INTEGER); }|
    b=BOOLEAN    { ((TypedNode)$b.tree).setExprType(Type.Primitive.BOOLEAN); }|
    c=CHARACTER  { ((TypedNode)$c.tree).setExprType(Type.Primitive.CHARACTER); }|
    a=AUTO       { ((TypedNode)$a.tree).setExprType(Type.Primitive.AUTO); };

composite_type:
    ^(arr=ARRAY t=primitive_type expression){
        Type ttype = ((TypedNode)$t.tree).getExprType();
        ((TypedNode)$arr.tree).setExprType(new Type(Type.Primitive.ARRAY, ttype));
    };

operand:
    id=IDENTIFIER {
        Type t = symtab.retrieve($id.text).getNode().getExprType();
        ((TypedNode)$id.tree).setExprType(t);
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

