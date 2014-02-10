grammar Mantra;

@header {package mantra;}

compilationUnit : (function|clazz|interfaze|enumb)* EOF ;

clazz
    :   ('api'|'abstract')* 'class' ID typeArgumentNames? ('extends' type)? ('implements' type (',' type)*)?
        '{'
            clazzMember*
            function*
        '}'
    ;

interfaze
    :   'api'? 'interface' ID ('extends' type (',' type)*)?
        '{'
//            field*
            functionHead*
        '}'
    ;

enumb
    :   'enum' ID '{' ID (',' ID)* '}'
    ;

clazzMember
    :   clazz
    |	interfaze
    |	field
    |	memberFunction
    |   enumb
    ;

field:  ('static'|'api')? vardecl
// 	|	'api'? propdecl
 	|	'api'? valdecl
 	;

commands : stat+ ;

memberFunction
	:	('static'|'api'|'overload')* function
	;

function
    :   functionHead block
    ;

functionHead
    :   'def' ID functionSignature
    ;

functionSignature
    :   '(' argList? ')' (':' type)?
    ;

argList
    :   argDef (',' argDef)*
    ;

argDef
    :   decl ('=' expression)?  // const exprs
    ;

lambdaSignature
    :   '(' argList? ')' (':' type)?
    |   ID (',' ID)* // shorthand for inferred arg and return types
    ;

/*
propdecl
    :   'property' decl ('=' expression)?
    |   'property' ID ('=' expression)?
    ;
*/

vardecl
    :   'var' decl ('=' expression)?
    |   'var' ID ('=' expression)?
    ;

valdecl
    :   'val' decl '=' expression
    |   'val' ID '=' expression
    ;

decl:   ID ':' type ;

type:	classOrInterfaceType ('[' ']')*
    |	primitiveType ('[' ']')*
    |	tupleType ('[' ']')* // (x:int, y:float)[100]
	|   functionType ('[' ']')* // (x:int):void[100]???
	;

tupleType
	:	'(' decl (',' decl)+ ')'
	;

/** (x:float):int
 *  (x:A):(x:B):C // right assoc. func returns func taking B, returning C
 *
 *  func arg looks complicated:
 *
 *		def do(f : (x:int) : int) : int { return f(3) }
 *                 ^^^^^^^^^^^^^ arg type
 *
 *  On func type (not on func def), need void as return type to distinguish
 *  from tuples:
 *
 *		def do(f : (x:int) : void) : int { return f(3) }
 *                 ^^^^^^^^^^^^^ arg type
 *
 */
functionType
    :   '(' argList? ')' ':' (type|'void')
    ;

classOrInterfaceType
	:	qualifiedName typeArguments?
    |	'set' typeArguments?
	;

typeArguments
    :   '<' type (',' type)* '>'
    ;

typeArgumentNames // only built-in types can use this like llist<string>
    :   '<' ID (',' ID)* '>'
    ;

primitiveType
    :   'boolean'
    |   'char'
    |   'byte'
    |   'short'
    |   'int'
    |   'long'
    |   'float'
    |   'double'
/*
    |	'dict'
    |	'string'
    |	'tree'
    |	'llist'
    */
    ;

block : '{' stat* '}' ;

stat:   lvalue (',' lvalue)* assignmentOperator expression
    |   expression // calls, expression in a lambda
    |   vardecl
    |   valdecl
    |   'for' expression block
    |   'while' expression block
    |   'if' expression block ('else' block)?
    |   'return' expression
    |   'do' block 'while' expression ';'
    |   'try' block (catches finallyBlock? | finallyBlock)
    |   'switch' expression '{' switchCase+ ('default' ':' (stat|block)?)? '}'
    |   'return' expression?
    |   'throw' expression
    |   'break'
    |   'continue'
    |   'print' expression
    |   'throw' expression
    |   clazz
    |   interfaze
    |   function
    |   enumb
    ;

switchCase
    :   'case' expression (',' expression)* ':' (stat|block)?
    ;

catches
    :   catchClause+
    ;

catchClause
    :   'catch' '(' catchType ID ')' block
    ;

catchType
	:	qualifiedName ('|' qualifiedName)*
	;

finallyBlock
	:	'finally' block
	;

argExprList
    :   expression
    |   ID '=' expression (',' ID '=' expression)*
    ;

lvalue
	:	ID
	|	expression '[' expression ']'
	|	expression '.' ID
	;

expression
	:   primary
    |   expression '.' ID
    |   expression '[' expression ']'
    |   expression ('++' | '--')
    |	'len' '(' expression ')' // calls expression.size()
    |   expression '(' argExprList? ')' lambda?
    |   ('+'|'-'|'++'|'--') expression
    |   ('~'|'!') expression
    |   expression ('*'|'/'|'%') expression
    |   expression ('+'|'-') expression
    |   expression ('<' '<' | '>' '>' '>' | '>' '>') expression
    |   expression ('<=' | '>=' | '>' | '<') expression
	|   expression 'instanceof' type
	|   expression ('==' | '!=' | 'is') expression
	|   expression '&' expression
	|   expression '^' expression
	|   expression '|' expression
	|	expression ':' expression // range
	|   expression 'and' expression
	|   expression 'or' expression
	|   expression 'in' expression
	|   expression '?' expression ':' expression
	|	expression '->' '[' expression ']' expression
	|	expression '->' '*' expression
	|	expression ('->'|'>-') expression // pipe, merge
    ;

// dup with expr but need to limit in primary
pipeline
    :   expression ('->'|'>-') expression
    ;

primary
	:	'(' expression ')'
	|	'(' pipeline pipeline+ ')' // 2+ pipes in parens is graph spec
    |	'(' expression (',' expression)+ ')' // tuple
    |   'this'
    |   'super'
    |   literal
    |   type '.' 'class'
    |   list
    |   dict
    |   set
    |   ctor
    |   lambda
    |   ID // string[] could match string here then [] as next statement; keep this last
    ;

// ctor (ambig with call)
ctor:	classOrInterfaceType '(' argExprList? ')'
	|	primitiveType        '(' argExprList ')'
	|	classOrInterfaceType ('[' expression? ']')+
	|	primitiveType        ('[' expression? ']')+
	;

list:   '[' ']' // type inferred
    |   '[' expression (',' expression)* ']'
    ;

dict:   '{' '}' // empty set, not ambig with blank lambda {=>}
    |   '{' dictMap (',' dictMap)* '}'
    ;

dictMap
    :   expression '?' expression
    ;

// special case for convenience set(1,2), set<User>(User(), User())
set :   'set' typeArguments? '(' expression (',' expression)* ')' ;

// no empty lambda, just use nil
lambda
    :   lambdaSignature '=>' expression   // special case single expression
    |   '{' (lambdaSignature '=>')? stat+ '}'
    ;

qualifiedName
    :   ID ('.' ID)*
    ;

literal
    :   IntegerLiteral
    |   FloatingPointLiteral
    |   CharacterLiteral
    |   StringLiteral
    |   BooleanLiteral
    |   'nil'
    ;

assignmentOperator
    :   '='
    |   '+='
    |   '-='
    |   '*='
    |   '/='
    |   '&='
    |   '|='
    |   '^='
    |   '%='
    |   '<<='
    |   '>>='
    |   '>>>='
    ;

ABSTRACT : 'abstract';
API : 'api';
ASSERT : 'assert';
BOOLEAN : 'boolean';
BREAK : 'break';
BYTE : 'byte';
CASE : 'case';
CATCH : 'catch';
CHAR : 'char';
CLASS : 'class';
CONST : 'const';
CONTINUE : 'continue';
DEFAULT : 'default';
DO : 'do';
DOUBLE : 'double';
ELSE : 'else';
ENUM : 'enum';
EXTENDS : 'extends';
FINAL : 'final';
FINALLY : 'finally';
FLOAT : 'float';
FOR : 'for';
IF : 'if';
GOTO : 'goto';// reserved, not used
IMPLEMENTS : 'implements';
IMPORT : 'import';
INSTANCEOF : 'instanceof';
INT : 'int';
INTERFACE : 'interface';
LEN : 'len';
LONG : 'long';
NATIVE : 'native';
OVERLOAD : 'overload';
PACKAGE : 'package';
PROPERTY : 'property'; // reserved, not used
RETURN : 'return';
SET : 'set';
SHORT : 'short';
STATIC : 'static';
SUPER : 'super';
SWITCH : 'switch';
THIS : 'this';
THROW : 'throw';
TRANSIENT : 'transient';
TRY : 'try';
WHILE : 'while';
VAR : 'var' ;
VOID : 'void' ;

// §3.10.1 Integer Literals

IntegerLiteral
	:	DecimalIntegerLiteral
	|	HexIntegerLiteral
	|	OctalIntegerLiteral
	|	BinaryIntegerLiteral
	;

fragment
DecimalIntegerLiteral
	:	DecimalNumeral IntegerTypeSuffix?
	;

fragment
HexIntegerLiteral
	:	HexNumeral IntegerTypeSuffix?
	;

fragment
OctalIntegerLiteral
	:	OctalNumeral IntegerTypeSuffix?
	;

fragment
BinaryIntegerLiteral
	:	BinaryNumeral IntegerTypeSuffix?
	;

fragment
IntegerTypeSuffix
	:	[lL]
	;

fragment
DecimalNumeral
	:	'0'
	|	NonZeroDigit (Digits? | Underscores Digits)
	;

fragment
Digits
	:	Digit (DigitsAndUnderscores? Digit)?
	;

fragment
Digit
	:	'0'
	|	NonZeroDigit
	;

fragment
NonZeroDigit
	:	[1-9]
	;

fragment
DigitsAndUnderscores
	:	DigitOrUnderscore+
	;

fragment
DigitOrUnderscore
	:	Digit
	|	'_'
	;

fragment
Underscores
	:	'_'+
	;

fragment
HexNumeral
	:	'0' [xX] HexDigits
	;

fragment
HexDigits
	:	HexDigit (HexDigitsAndUnderscores? HexDigit)?
	;

fragment
HexDigit
	:	[0-9a-fA-F]
	;

fragment
HexDigitsAndUnderscores
	:	HexDigitOrUnderscore+
	;

fragment
HexDigitOrUnderscore
	:	HexDigit
	|	'_'
	;

fragment
OctalNumeral
	:	'0' Underscores? OctalDigits
	;

fragment
OctalDigits
	:	OctalDigit (OctalDigitsAndUnderscores? OctalDigit)?
	;

fragment
OctalDigit
	:	[0-7]
	;

fragment
OctalDigitsAndUnderscores
	:	OctalDigitOrUnderscore+
	;

fragment
OctalDigitOrUnderscore
	:	OctalDigit
	|	'_'
	;

fragment
BinaryNumeral
	:	'0' [bB] BinaryDigits
	;

fragment
BinaryDigits
	:	BinaryDigit (BinaryDigitsAndUnderscores? BinaryDigit)?
	;

fragment
BinaryDigit
	:	[01]
	;

fragment
BinaryDigitsAndUnderscores
	:	BinaryDigitOrUnderscore+
	;

fragment
BinaryDigitOrUnderscore
	:	BinaryDigit
	|	'_'
	;

FloatingPointLiteral
	:	DecimalFloatingPointLiteral
	|	HexadecimalFloatingPointLiteral
	;

fragment
DecimalFloatingPointLiteral
	:	Digits '.' Digits? ExponentPart? FloatTypeSuffix?
	|	'.' Digits ExponentPart? FloatTypeSuffix?
	|	Digits ExponentPart FloatTypeSuffix?
	|	Digits FloatTypeSuffix
	;

fragment
ExponentPart
	:	ExponentIndicator SignedInteger
	;

fragment
ExponentIndicator
	:	[eE]
	;

fragment
SignedInteger
	:	Sign? Digits
	;

fragment
Sign
	:	[+-]
	;

fragment
FloatTypeSuffix
	:	[fFdD]
	;

fragment
HexadecimalFloatingPointLiteral
	:	HexSignificand BinaryExponent FloatTypeSuffix?
	;

fragment
HexSignificand
	:	HexNumeral '.'?
	|	'0' [xX] HexDigits? '.' HexDigits
	;

fragment
BinaryExponent
	:	BinaryExponentIndicator SignedInteger
	;

fragment
BinaryExponentIndicator
	:	[pP]
	;

// §3.10.3 Boolean Literals

BooleanLiteral
	:	'true'
	|	'false'
	;

// §3.10.4 Character Literals

CharacterLiteral
	:	'\'' SingleCharacter '\''
	|	'\'' EscapeSequence '\''
	;

fragment
SingleCharacter
	:	~['\\]
	;

// §3.10.5 String Literals

StringLiteral
	:	'"' StringCharacters? '"'
	;

fragment
StringCharacters
	:	StringCharacter+
	;

fragment
StringCharacter
	:	~["\\]
	|	EscapeSequence
	;

// §3.10.6 Escape Sequences for Character and String Literals

fragment
EscapeSequence
	:	'\\' [btnfr"'\\]
	|	OctalEscape
	;

fragment
OctalEscape
	:	'\\' OctalDigit
	|	'\\' OctalDigit OctalDigit
	|	'\\' ZeroToThree OctalDigit OctalDigit
	;

fragment
ZeroToThree
	:	[0-3]
	;

Nil :	'nil'
	;

LPAREN : '(';
RPAREN : ')';
LBRACE : '{';
RBRACE : '}';
LBRACK : '[';
RBRACK : ']';
SEMI : ';';
COMMA : ',';
DOT : '.';

//ASSIGN : '=';
GT : '>';
LT : '<';
BANG : '!';
TILDE : '~';
QUESTION : '?';
COLON : ':';
EQUAL : '==';
IS : 'is' ;
IN : 'in' ;
LE : '<=';
GE : '>=';
NOTEQUAL : '!=';
AND : 'and';
OR : 'or';
INC : '++';
DEC : '--';
ADD : '+';
SUB : '-';
MUL : '*';
DIV : '/';
BITAND : '&';
BITOR : '|';
CARET : '^';
MOD : '%';
FROM : '=>' ;
PIPE : '->' ;

ADD_ASSIGN : '+=';
SUB_ASSIGN : '-=';
MUL_ASSIGN : '*=';
DIV_ASSIGN : '/=';
AND_ASSIGN : '&=';
OR_ASSIGN : '|=';
XOR_ASSIGN : '^=';
MOD_ASSIGN : '%=';
LSHIFT_ASSIGN : '<<=';
RSHIFT_ASSIGN : '>>=';
URSHIFT_ASSIGN : '>>>=';

ID  :	JavaLetter JavaLetterOrDigit*
	;

fragment
JavaLetter
	:	[a-zA-Z$_] // these are the "java letters" below 0xFF
	|	// covers all characters above 0xFF which are not a surrogate
		~[\u0000-\u00FF\uD800-\uDBFF]
		{Character.isJavaIdentifierStart(_input.LA(-1))}?
	|	// covers UTF-16 surrogate pairs encodings for U+10000 to U+10FFFF
		[\uD800-\uDBFF] [\uDC00-\uDFFF]
		{Character.isJavaIdentifierStart(Character.toCodePoint((char)_input.LA(-2), (char)_input.LA(-1)))}?
	;

fragment
JavaLetterOrDigit
	:	[a-zA-Z0-9$_] // these are the "java letters or digits" below 0xFF
	|	// covers all characters above 0xFF which are not a surrogate
		~[\u0000-\u00FF\uD800-\uDBFF]
		{Character.isJavaIdentifierPart(_input.LA(-1))}?
	|	// covers UTF-16 surrogate pairs encodings for U+10000 to U+10FFFF
		[\uD800-\uDBFF] [\uDC00-\uDFFF]
		{Character.isJavaIdentifierPart(Character.toCodePoint((char)_input.LA(-2), (char)_input.LA(-1)))}?
	;

WS  :  [ \t\u000C]+ -> skip
    ;

NL  :   '\r'? '\n' -> skip ;    // command separator (ignore for now)

COMMENT
    :   '/*' .*? '*/' -> skip
    ;

LINE_COMMENT
    :   '//' ~[\r\n]* -> skip
    ;
