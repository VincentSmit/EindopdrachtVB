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
}

// Alter code generation so catch-clauses get replaced with this action. 
// This disables ANTLR ERROR handling: CalcExceptions are propagated upwards.
@members {
    private SymbolTable<IdEntry> symtab = new SymbolTable<>();

    private boolean equalType(CommonTree a, CommonTree b){
        TypedNode ta = (TypedNode)a;
        TypedNode tb = (TypedNode)b;
        return (ta.getExprType() != null &&
                tb.getExprType() != null &&
                ta.getExprType().equals(tb.getExprType()));
    }

    private TypedNode getID(String id){
        return symtab.retrieve(id).getNode();
    }
}

program
@init { symtab.openScope(); }
    : ^(PROGRAM command+) { symtab.closeScope(); }
    ;

commands: command+;
command: declaration | expression | statement;

declaration
    :   var_declaration
    |   scope_declaration
    ; 

var_declaration
    :   ^(VAR t=type id=IDENTIFIER<TypedNode> assignment?){

        try {
            symtab.enter($id.text, new IdEntry((TypedNode)$id.tree));
            ((TypedNode)$id.tree).setExprType(((TypedNode)$t.tree).getExprType());
        } catch (SymbolTableException e) {
            System.err.print("ERROR: exception thrown by symboltable: ");
            System.err.println(e.getMessage());
        }
    }
    ;

scope_declaration
@init{ symtab.openScope(); }
@after{ symtab.closeScope(); }:
    func_declaration;

func_declaration:
   ^(FUNC id=IDENTIFIER<TypedNode> t=type ^(ARGS arguments?) ^(BODY commands?)) {
        try {
            symtab.enter($id.text, new IdEntry((TypedNode)$id.tree));
            ((TypedNode)$id.tree).setExprType(((TypedNode)$t.tree).getExprType());
        } catch (SymbolTableException e) {
            System.err.print("ERROR: exception thrown by symboltable: ");
            System.err.println(e.getMessage());
        } 
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
        if(!((TypedNode)$ex.tree).getExprType().equals(Type.Primitive.BOOLEAN)) {
            throw new InvalidTypeException("ERROR: expression must be of type boolean.");
        }
    } |
    ^(FOR IDENTIFIER ex=expression command*) {
        if(!((TypedNode)$ex.tree).getExprType().equals(Type.Primitive.BOOLEAN)) {
            throw new InvalidTypeException("ERROR: expression must be of type boolean.");
        }
    } |
    ^(RETURN expression) |
    assignment;

assignment: ^(ASSIGN id=IDENTIFIER<TypedNode> ex=expression){
    // Retrieve identifier from symtab.
    id_tree = getID($id.text);

    // If `id` is AUTO, infer type from expression
    if(((TypedNode)$id.tree).getExprType().getPrimType().equals(Type.Primitive.AUTO)){
        ((TypedNode)$id.tree).setExprType((TypedNode)$ex.tree);
    }

    if(!equalType($id.tree, $ex.tree)){
        throw new InvalidTypeException(String.format(
            "ERROR: Type mismatch: \%s vs \%s.",
            ((TypedNode)$id.tree).getExprType(),
            ((TypedNode)$ex.tree).getExprType()
        ));

    }
};

if_part
@init{ symtab.openScope(); }
@after{ symtab.closeScope(); }:
    ^(ex=expression command*) {
        if(!((TypedNode)$ex.tree).getExprType().equals(Type.Primitive.BOOLEAN)){
            throw new InvalidTypeException("ERROR: expression must be of type boolean.");
        }
    };

else_part
@init{ symtab.openScope(); }
@after{ symtab.closeScope(); }:
    command*;

bool_op: AND | OR;
same_op: PLUS | MINUS | LT | GT | LTE | GTE | EQ | NEQ | DIVIDES | MULTIPL | POWER;

expression:
    operand |
    ^(op=bool_op ex1=expression ex2=expression) {
        ((TypedNode)$op.tree).setExprType(new Type(Type.Primitive.BOOLEAN));

        TypedNode ex1tree = (TypedNode)$ex1.tree;
        TypedNode ex2tree = (TypedNode)$ex2.tree;

        if(!(ex1tree.getExprType().equals(Type.Primitive.BOOLEAN))) {
            throw new InvalidTypeException("ERROR: Expression of type boolean expected. Found: " + ex1tree.getExprType());
        }else if(!ex2tree.getExprType().equals(Type.Primitive.BOOLEAN)) {
            throw new InvalidTypeException("ERROR: Expression of type boolean expected. Found: " + ex2tree.getExprType());
        }
    } |
    ^(op=same_op ex1=expression ex2=expression){
        TypedNode ex1tree = (TypedNode)$ex1.tree;
        TypedNode ex2tree = (TypedNode)$ex2.tree;

        System.out.println(ex1tree.getExprType());
        System.out.println(ex1tree.getExprType().equals(ex2tree.getExprType()));

        ((TypedNode)$op.tree).setExprType(ex1tree.getExprType());
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
    };

