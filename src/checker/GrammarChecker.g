tree grammar GrammarChecker;

options {
    tokenVocab=Grammar;
    ASTLabelType=CommonTree;
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

}

program
@init { symtab.openScope(); }
    : ^(PROGRAM command+) { symtab.closeScope(); }
    ;

command: declaration | expression | statement;

declaration
    :   var_declaration
    |   scope_declaration
    ; 

var_declaration
    :   ^(VAR t=type id=IDENTIFIER<TypedNode> assignment?){
        try {
            symtab.enter($id.text, new IdEntry());
            ((TypedNode)id).setExprType(((TypedNode)$t.tree).getExprType());
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
   ^(FUNC id=IDENTIFIER<TypedNode> t=type ^(ARGS arguments) ^(BODY command*)) {
        try {
            symtab.enter($id.text, new IdEntry());
            ((TypedNode)id).setExprType(new Type(Type.getPrimFromString($t.text)));
        } catch (SymbolTableException e) {
            System.err.print("ERROR: exception thrown by symboltable: ");
            System.err.println(e.getMessage());
        } catch (InvalidTypeException e){
            System.err.print("ERROR: exception thrown by typesetter: ");
            System.err.println(e.getMessage());
        }
    };

argument:
    (t=type id=IDENTIFIER) {};

arguments:
    argument (arguments)?;

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
    if(!((TypedNode)id).getExprType().equals(((TypedNode)$ex.tree).getExprType())) {
        throw new InvalidTypeException("ERROR: Type mismatch: identifier of type " + ((TypedNode)id).getExprType() + ", expression of type " + ((TypedNode)$ex.tree).getExprType() + ".");
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

expression
    :   operand
    |   ^(ik=AND ex1=expression ex2=expression) {
        ((TypedNode)ik).setExprType(new Type(Type.Primitive.BOOLEAN));

        TypedNode ex1tree = (TypedNode)$ex1.tree;
        TypedNode ex2tree = (TypedNode)$ex2.tree;

        if(!(ex1tree.getExprType().equals(Type.Primitive.BOOLEAN))) {
            throw new InvalidTypeException("ERROR: Expression of type boolean expected. Found: " + ex1tree.getExprType());
        }else if(!ex2tree.getExprType().equals(Type.Primitive.BOOLEAN)) {
            throw new InvalidTypeException("ERROR: Expression of type boolean expected. Found: " + ex2tree.getExprType());
        }
    };


type: primitive_type | composite_type;
primitive_type:
    i=INTEGER { ((TypedNode)i).setExprType(new Type(Type.Primitive.INTEGER)); }|
    b=BOOLEAN { ((TypedNode)b).setExprType(new Type(Type.Primitive.BOOLEAN)); }|
    c=CHARACTER { ((TypedNode)b).setExprType(new Type(Type.Primitive.CHARACTER)); };
composite_type:
    arr=ARRAY t=primitive_type expression{
        Type ttype = ((TypedNode)$t.tree).getExprType();
        ((TypedNode)arr).setExprType(new Type(Type.Primitive.ARRAY, ttype));
    };

operand: IDENTIFIER | NUMBER | STRING_VALUE;
