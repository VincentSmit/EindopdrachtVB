tree grammar GrammarChecker;

options {
    tokenVocab=Grammar;
    ASTLabelType=CommonTree;
}

@header {
    package checker;
    import symtab.SymbolTable;
    import symtab.SymbolTableException;
    import symtab.IdEntry;
    import ast.ExprNode;
    import ast.ExprNodeAdaptor;
}

// Alter code generation so catch-clauses get replaced with this action. 
// This disables ANTLR ERROR handling: CalcExceptions are propagated upwards.
@members {

}

program
@init { symtab.openScope(); }
    : ^(PROGRAM import_statement* command+) { symtab.closeScope(); }
    ;

import_statement
    :   ^(IMPORT IDENTIFIER y=IDENTIFIER){
        try{
            symtab.enter($y.text, new IdEntry());
        } catch (SymbolTableException e){
            System.err.print("ERROR: exception thrown by symboltable: ");
            System.err.println(e.getMessage());
        }
    };

command: declaration | expression | statement;

declaration
    :   var_declaration
    |   scope_declaration
    ; 

var_declaration
    :   ^(VAR t=type id=IDENTIFIER<ExprNode> assignment?){
        try {
            symtab.enter($id.text, new IdEntry());
            id.setExprType(new Type(Type.getPrimFromString($t.text)));
        } catch (SymbolTableException e) {
            System.err.print("ERROR: exception thrown by symboltable: ");
            System.err.println(e.getMessage());
        } catch (InvalidTypeException e){
            System.err.print("ERROR: exception thrown by typesetter: ");
            System.err.println(e.getMessage());
        }
    }
    ;

scope_declaration
@init{ symtab.openScope(); }
@after{ symtab.closeScope(); }:
    func_declaration;

func_declaration:
   ^(FUNC id=IDENTIFIER<ExprNode> t=type ^(ARGS arguments) ^(BODY command*)) {
        try {
            symtab.enter(&id.text, new IdEntry());
            iid.setExprType(new Type(Type.getPrimFromString($t.text)));
        } catch (SymbolTableException e) {
            System.err.print("ERROR: exception thrown by symboltable: ");
            System.err.println(e.getMessage());
        } catch (InvalidTypeException e){
            System.err.print("ERROR: exception thrown by typesetter: ");
            System.err.println(e.getMessage());
        }
    };

argument:
    (t=type id=IDENTIFIER) {
        try {
            symtab.enter($id.text, new IdEntry());
            id.setExprType(new Type(Type.getPrimFromString($t.text)));
        } catch (SymbolTableException e) {
            System.err.print("ERROR: exception thrown by symboltable: ");
            System.err.println(e.getMessage());
        } catch (InvalidTypeExceoption e){
            System.err.print("ERROR: exception thrown by typesetter: ");
            System.err.println(e.getMessage());
        }
    };

arguments:
    argument (arguments)?;

statement:
    ^(IF if_part ELSE else_part) |
    ^(WHILE expression command*) {
        if(!ex.getExprType().equals(Type.Primitive.BOOLEAN)) {
            throw new InvalidTypeException("ERROR: expression must be of type boolean.");
        }
    } |
    ^(FOR IDENTIFIER expression command*) {
        if(!ex.getExprType().equals(Type.Primitive.BOOLEAN)) {
            throw new InvalidTypeException("ERROR: expression must be of type boolean.");
        }
    } |
    ^(RETURN expression) |
    assignment;

assignment: ^(ASSIGN id=IDENTIFIER expression){
    if(!id.getExprType().equals(ex.getExprType())) {
        throw new InvalidTypeException("ERROR: Type mismatch: identifier of type " + id.getExprType() + ", expression of type " + ex.getExprType() + ".");
    }
};

if_part
@init{ symtab.openScope() }
@after{ symtab.closeScope() }:
    ^(ex=expression command*) {
        if(!ex.getExprType().equals(Type.Primitive.BOOLEAN)){
            throw new InvalidTypeException("ERROR: expression must be of type boolean.");
        }
    };

else_part
@init{ symtab.openScope() }
@after{ symtab.closeScope() }:
    command*;

expression
    :   operand
    |   ^(AND ex1=expression ex2=expression) {
        if(!ex1.getExprType().equals(Type.Primitive.BOOLEAN)) {
            throw new InvalidTypeException("ERROR: Expression of type boolean expected. Found: " + ex1.getExprType());
        }else if(!ex1.getExprType().equals(Type.Primitive.BOOLEAN)) {
            throw new InvalidTypeException("ERROR: Expression of type boolean expected. Found: " + ex2.getExprType());
        }
    };


type: primitive_type | composite_type;
primitive_type: INTEGER | BOOLEAN | CHARACTER;
composite_type: ARRAY primitive_type expression;
operand: IDENTIFIER | NUMBER | STRING_VALUE;
