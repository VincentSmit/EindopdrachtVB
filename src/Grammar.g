grammar Grammar;

options {
    k=1; // LL(1) - do not use LL(*)
    language=Java; // target language is Java (= default)
    output=AST; // build an AST
}

tokens {
    COLON = ':' ;
    SEMICOLON = ';' ;
    LPAREN = '(' ;
    RPAREN = ')' ;
    LBLOCK = '[';
    RBLOCK = ']';
    LCURLY = '{';
    RCURLY = '}';
    COMMA = ',' ;
    BODY = 'body';

    // operators
    PLUS = '+';
    MINUS = '-';
    DIVIDES = '/';
    MULTIPL = '*';
    POWER = '^';
    LT = '<';
    GT = '>';
    GTE = '>=';
    LTE = '<=';
    EQ = '==';
    NEQ = '!=';
    ASSIGN = '=';

    // keywords
    PROGRAM = 'program';
    SWAP = 'swap';
    IF = 'if';
    THEN = 'then';
    ELSE = 'else';
    DO = 'do';
    WHILE = 'while';
    FROM = 'from';
    IMPORT = 'import';
    BREAK = 'break';
    CONTINUE = 'continue';
    RETURN = 'return';
    FOR = 'for';
    IN = 'in';
    RETURNS = 'returns';
    FUNC = 'func';
    ARGS = 'args';

    // Type keywords
    INTEGER = 'int';
    CHARACTER = 'char';
    BOOLEAN = 'bool';
    ARRAY = 'array';
}

@lexer::header {
    package vb.week4.calc;
}

@header {
    package vb.week4.calc;
}

// Parser rules
program: import_statement* command+;

import_statement: FROM IDENTIFIER IMPORT IDENTIFIER SEMICOLON
                      -> ^(IMPORT IDENTIFIER IDENTIFIER);

command:
    declaration |
    expression |
    statement;

// DECLARATIONS 
declaration:
    var_declaration; //|
//    scope_declaration;

var_declaration:
   type IDENTIFIER assignment? SEMICOLON;

assignment: ASSIGN expression;

scope_declaration: 
    func_declaration; // |
//    class_declaration;

func_scope: LCURLY command* RCURLY;
func_declaration: FUNC IDENTIFIER LPAREN arguments RPAREN RETURNS type func_scope
                      -> ^(FUNC IDENTIFIER type func_scope ARGS arguments BODY func_scope);


//class_scope: LCURLY declaration* RCURLY;
//class_declaration: CLASS IDENTIFIER EXTENDS IDENTIFIER class_scope
//                       -> ^(CLASS IDENTIFIER IDENTIFIER (^BODY class_scope));

// Parses arguments of function declaration
argument: type IDENTIFIER;
arguments: argument (COMMA! arguments)?;

// Statements
statement:
    if_statement | 
    while_statement |
    return_statement |
    for_statement |
    BREAK SEMICOLON |
    CONTINUE SEMICOLON;

if_statement:
    IF LPAREN! expression RPAREN! LCURLY! command* RCURLY!
    ELSE LCURLY! command* RCURLY!;

while_statement: WHILE LPAREN expression RPAREN LCURLY command* RCURLY
                     -> ^(WHILE expression command*);
for_statement: FOR LPAREN IDENTIFIER IN expression RPAREN LCURLY command* RCURLY
                   -> ^(FOR IDENTIFIER expression command*);
return_statement: RETURN expression SEMICOLON!;

// Expressions, order of operands:
// ()
// ^
// *, /
// +, -
// <=, >=, <, >, ==, !=
expression: expressionLO | array_literal;
expressionLO: expressionPM ((LT^ | GT^ | LTE^ | GTE^ | EQ^ | NEQ^) expressionPM)*;
expressionPM: expressionMD ((PLUS^ | MINUS^) expressionMD)*;
expressionMD: expressionPW ((MULTIPL^ | DIVIDES^) expressionPW)*;
expressionPW: operand (POWER operand)*;

operand:
    LPAREN! expression RPAREN! |
    IDENTIFIER |
    NUMBER;

array_literal: LBLOCK! array_value_list? RBLOCK!;
array_value_list: expression (COMMA! array_value_list)?;


// Types
type: primitive_type; //| composite_type;
primitive_type: INTEGER | BOOLEAN | CHARACTER;
//composite_type: ^ARRAY primitive_type LBLOCK! expression RBLOCK!;

// Lexer rules
IDENTIFIER: LETTER (LETTER | DIGIT)*;
NUMBER: DIGIT+;
COMMENT: '//' .* '\n' { $channel=HIDDEN; };
WS: (' ' | '\t' | '\f' | '\r' | '\n')+ { $channel=HIDDEN; };

fragment DIGIT : ('0'..'9');
fragment LOWER : ('a'..'z');
fragment UPPER : ('A'..'Z');
fragment LETTER : LOWER | UPPER;

