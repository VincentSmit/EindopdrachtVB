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
    COMMA = ',';
    DOUBLE_QUOTE = '"';
    SINGLE_QUOTE = '\'';
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
    OR = '||';
    AND = '&&';

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
    VAR = 'var';
    OF = 'of';

    // Type keywords
    INTEGER = 'int';
    CHARACTER = 'char';
    BOOLEAN = 'bool';
    ARRAY = 'array';
    CALL = 'call';
}

@lexer::header {
}

@header {
    import ast.TypedNode;
}

// Parser rules
program: command+ -> ^(PROGRAM command+);

command:
    (IDENTIFIER ASSIGN) => assign_statement |
    declaration |
    statement |
    expression SEMICOLON!;

commands: command command?;

// DECLARATIONS 
declaration:
    var_declaration |
    scope_declaration;

var_declaration: type IDENTIFIER (a=var_assignment)? SEMICOLON
                     -> {a == null}? ^(VAR type IDENTIFIER<TypedNode>)
                     -> ^(VAR type IDENTIFIER<TypedNode>) ^(ASSIGN IDENTIFIER<TypedNode> $a);

var_assignment: ASSIGN! expression;
assignment: ASSIGN expression;

scope_declaration: 
    func_declaration; // |
//    class_declaration;

func_declaration: FUNC IDENTIFIER LPAREN arguments RPAREN RETURNS type LCURLY commands? RCURLY
                      -> ^(FUNC IDENTIFIER type ^(ARGS arguments) ^(BODY commands?));


// Parses arguments of function declaration
argument: type IDENTIFIER;
arguments: argument (COMMA! arguments)?;

// Statements
statement:
    if_statement | 
    while_statement |
    return_statement |
    for_statement |
    BREAK SEMICOLON! |
    CONTINUE SEMICOLON!;

if_part: IF LPAREN expression RPAREN LCURLY (command SEMICOLON)* RCURLY
             -> expression command*;

else_part: ELSE LCURLY (command SEMICOLON)* RCURLY
             -> command*;

if_statement: if_part else_part? -> ^(IF if_part ELSE else_part?);

while_statement: WHILE LPAREN expression RPAREN LCURLY command* RCURLY
                     -> ^(WHILE expression command*);
for_statement: FOR LPAREN IDENTIFIER IN expression RPAREN LCURLY command* RCURLY
                   -> ^(FOR IDENTIFIER<TypedNode> expression command*);
return_statement: RETURN expression SEMICOLON!;

assign_statement: IDENTIFIER ASSIGN expression
                    -> ^(ASSIGN IDENTIFIER<TypedNode> expression);

// Expressions, order of operands:
// ()
// ^
// *, /
// +, -
// <=, >=, <, >, ==, !=, ||, &&
expression:
    //(IDENTIFIER LPAREN) => call_expression|
    expressionAO |
    array_literal ;
expressionAO: expressionLO (AND<TypedNode>^ expressionLO | OR<TypedNode>^ expressionLO)*;
expressionLO: expressionPM ((LT<TypedNode>^ | GT<TypedNode>^ | LTE<TypedNode>^ | GTE<TypedNode>^ | EQ<TypedNode>^ | NEQ<TypedNode>^) expressionPM)*;
expressionPM: expressionMD ((PLUS<TypedNode>^ | MINUS<TypedNode>^) expressionMD)*;
expressionMD: expressionPW ((MULTIPL<TypedNode>^ | DIVIDES<TypedNode>^) expressionPW)*;
expressionPW: operand (POWER<TypedNode>^ operand)*;

expression_list: expression (COMMA! expression)?;
//call_expression: IDENTIFIER LPAREN expression_list? RPAREN
//                     -> ^(CALL IDENTIFIER expression_list?);

operand:
    LPAREN! expression RPAREN! |
    IDENTIFIER<TypedNode> |
    NUMBER<TypedNode> |
    STRING_VALUE<TypedNode>;

array_literal: LBLOCK array_value_list? RBLOCK -> ^(ARRAY array_value_list?);
array_value_list: expression (COMMA! array_value_list)?;

// Types
type:
    (primitive_type LBLOCK) => composite_type |
    primitive_type;

primitive_type:
    INTEGER<TypedNode> |
    BOOLEAN<TypedNode> |
    CHARACTER<TypedNode> ;

composite_type: ARRAY<TypedNode> primitive_type LBLOCK! expression RBLOCK!;

// Lexer rules
IDENTIFIER: LETTER (LETTER | DIGIT)*;
STRING_VALUE:  '\'' ( '\\' '\''? | ~('\\' | '\'') )* '\'';

NUMBER: DIGIT+;
COMMENT: '//' .* '\n' { $channel=HIDDEN; };
WS: (' ' | '\t' | '\f' | '\r' | '\n')+ { $channel=HIDDEN; };

fragment DIGIT : ('0'..'9');
fragment LOWER : ('a'..'z');
fragment UPPER : ('A'..'Z');
fragment LETTER : LOWER | UPPER;

