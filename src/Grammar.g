grammar Grammar;

options {
    k=1; // LL(1) - do not use LL(*)
    language=Java; // target language is Java (= default)
    output=AST; // build an AST
    ASTLabelType=CommonNode;
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
    EXPR = 'assignment_expression';
    GET = 'get_expression';

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

    // Pointers
    AMPERSAND = '&'; // Reference
    ASTERIX = '%'; // Dereference

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
    TRUE = 'true';
    FALSE = 'false';
    CONTINUE = 'continue';
    RETURN = 'return';
    FOR = 'for';
    IN = 'in';
    RETURNS = 'returns';
    FUNC = 'func';
    ARRAY = 'array';
    ARGS = 'args';
    CALL = 'call';
    VAR = 'var';
    OF = 'of';
    PRINT = 'print';
    TAM = '__tam__';

    // Type keywords
    INTEGER = 'int';
    CHARACTER = 'char';
    BOOLEAN = 'bool';
    AUTO = 'auto';
    // VAR
}

@lexer::header {
}

@header {
    import ast.*;
    import org.antlr.runtime.CommonTokenStream;
    import org.antlr.runtime.ANTLRInputStream;
}

// Parser rules
program: command+ -> ^(PROGRAM command+);

command:
    // Antlr complains about being able to match multiple alternatives for 'ASTERIX' even though we prioritise
    // it below. Antlr then goes on and tells us it disabled rule 5 and 6, which is exactly what we wanted
    // to achieve with the line below in the first place. Oh well..
    //
    // @Theo (or PA): we can solve this by either instructing antlr to ignore 5/6 if ASTERIX is matched (what
    // essentially happens now) or by separating `expression` into `expression` and `inline_expression`
    // which is its own horror. All in all, we think letting antlr figure it out on its own is not a clean
    // solution but nonetheless a consciously chosen one.
    (IDENTIFIER ASSIGN) => assign_statement SEMICOLON! |
    (IDENTIFIER ASTERIX) => assign_statement SEMICOLON! |
    statement |
    declaration |
    expression SEMICOLON!|
    SEMICOLON!;

commands: command commands?;

// DECLARMULTIPLIONS
declaration:
    var_declaration |
    scope_declaration;

var_declaration: type IDENTIFIER (a=var_assignment)? SEMICOLON
                     -> {a == null}? ^(VAR type IDENTIFIER<IdentifierNode>)
                     -> ^(VAR type IDENTIFIER<IdentifierNode>) ^(ASSIGN IDENTIFIER<IdentifierNode> ^(EXPR $a));

var_assignment: ASSIGN! expression;

scope_declaration: 
    func_declaration; // |
//    class_declaration;

func_declaration: FUNC IDENTIFIER LPAREN arguments? RPAREN (RETURNS t=type)? LCURLY commands? RCURLY
                      -> {t == null}? ^(FUNC IDENTIFIER<FunctionNode> IDENTIFIER<IdentifierNode>["auto"] ^(ARGS arguments?) ^(BODY commands?))
                      -> ^(FUNC IDENTIFIER<FunctionNode> type ^(ARGS arguments?) ^(BODY commands?));


// Parses arguments of function declaration
argument: type IDENTIFIER;
arguments: argument (COMMA! arguments)?;

// Statements
statement:
    if_statement | 
    while_statement |
    return_statement |
    for_statement |
    print_statement |
    import_statement |

    // Defining both tokens as <ControlNode>s throws a cryptic error. Converting them later
    // in GrammarChecker works :-/.
    BREAK SEMICOLON! |
    CONTINUE SEMICOLON!;


if_part: IF LPAREN expression RPAREN LCURLY commands? RCURLY
             -> expression ^(THEN commands?);

else_part: ELSE LCURLY commands? RCURLY
             -> ^(ELSE commands?);

if_statement: if_part ep=else_part?
    -> ^(IF if_part else_part?);

while_statement: WHILE LPAREN expression RPAREN LCURLY command* RCURLY
                     -> ^(WHILE expression command*);
for_statement: FOR IDENTIFIER IN expression LCURLY commands? RCURLY
                   -> ^(FOR IDENTIFIER<IdentifierNode> expression commands?);

return_statement: RETURN expression SEMICOLON -> ^(RETURN expression);

// Shamelessly stolen from:
//  https://theantlrguy.atlassian.net/wiki/pages/viewpage.action?pageId=2686987
import_statement
@init { CommonNode includetree = null; }:
  IMPORT s=STRING_VALUE {
    try {
      String filename = $s.text.substring(1, $s.text.length() - 1);
      GrammarLexer lexer = new GrammarLexer(new ANTLRFileStream(filename + ".kib"));
      GrammarParser parser = new GrammarParser(new CommonTokenStream(lexer));
      parser.setTreeAdaptor(new CommonNodeAdaptor());
      includetree = (CommonNode)(parser.program().getTree());
    } catch (Exception fnf) {
        // TODO: Error handling?
      ;
    }
  }
  -> ^({includetree})
;

assign:
    ASTERIX^ assign |
    ASSIGN expression -> ^(EXPR expression);

assign_statement: IDENTIFIER assign
                    -> ^(ASSIGN IDENTIFIER assign);

print_statement: PRINT LPAREN expression RPAREN -> ^(PRINT expression);

// Expressions, order of operands:
// ()
// ^
// *, /
// +, -
// <=, >=, <, >, ==, !=, ||, &&
expression:
    expressionAO |
    raw_expression |
    array_literal;

expressionAO: expressionLO (AND<TypedNode>^ expressionLO | OR<TypedNode>^ expressionLO)*;
expressionLO: expressionPM ((LT<TypedNode>^ | GT<TypedNode>^ | LTE<TypedNode>^ | GTE<TypedNode>^ | EQ<TypedNode>^ | NEQ<TypedNode>^) expressionPM)*;
expressionPM: expressionMD ((PLUS<TypedNode>^ | MINUS<TypedNode>^) expressionMD)*;
expressionMD: expressionPW ((MULTIPL<TypedNode>^ | DIVIDES<TypedNode>^) expressionPW)*;
expressionPW: operand (POWER<TypedNode>^ operand)*;

expression_list: expression (COMMA! expression_list)?;
raw_expression: TAM^ LPAREN! type COMMA! STRING_VALUE RPAREN!;
call_expression: IDENTIFIER LPAREN expression_list? RPAREN
                     -> ^(CALL IDENTIFIER expression_list?);
get_expression: IDENTIFIER LBLOCK expression RBLOCK
                    -> ^(GET IDENTIFIER expression);

operand:
    (IDENTIFIER LBLOCK) => get_expression|
    (IDENTIFIER LPAREN) => call_expression|
    (ASTERIX IDENTIFIER) => ASTERIX^ IDENTIFIER<IdentifierNode> |
    AMPERSAND^ IDENTIFIER<IdentifierNode> |
    ASTERIX^ operand |
    LPAREN! expression RPAREN! |
    IDENTIFIER<IdentifierNode> |
    NUMBER<TypedNode> |
    STRING_VALUE<TypedNode>|
    bool;

bool: TRUE<TypedNode> | FALSE<TypedNode>;

array_literal: LBLOCK array_value_list? RBLOCK -> ^(ARRAY array_value_list?);
array_value_list: expression (COMMA! array_value_list)?;

// Types
type:
    (primitive_type LBLOCK) => composite_type |
    ASTERIX type -> ^(ASTERIX type) |
    primitive_type;

primitive_type:
    INTEGER<TypedNode> |
    BOOLEAN<TypedNode> |
    CHARACTER<TypedNode> |
    AUTO<TypedNode> |
    VAR<TypedNode>;

composite_type:
    primitive_type LBLOCK expression RBLOCK
        -> ^(ARRAY primitive_type expression);

// Lexer rules
IDENTIFIER: (LETTER | UNDERSCORE) (LETTER | DIGIT | UNDERSCORE)*;
STRING_VALUE:  '\'' ( '\\' '\''? | ~('\\' | '\'') )* '\'';

NUMBER: DIGIT+;
COMMENT: '//' .* '\n' { $channel=HIDDEN; };
WS: (' ' | '\t' | '\f' | '\r' | '\n')+ { $channel=HIDDEN; };

fragment DIGIT : ('0'..'9');
fragment LOWER : ('a'..'z');
fragment UPPER : ('A'..'Z');
fragment UNDERSCORE : '_';
fragment LETTER : LOWER | UPPER;

