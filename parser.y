%{
    #include <cstdlib>
    #include <cstdio>
    #include <iostream>

    #include "ast.hpp"

    #define YYDEBUG 1
    int yylex(void);
    void yyerror(const char *);

    extern ASTNode* astRoot;
%}

%error-verbose

/* WRITEME: List all your tokens here */

%token T_EXTENDS T_TRUE T_FALSE T_NEW T_PRINT T_RETURN
%token T_IF T_ELSE T_WHILE T_INTEGER T_BOOLEAN T_NONE
%token T_EQUALS T_AND T_OR T_NOT T_DO T_LBRACKET
%token T_RBRACKET T_LPAREN T_RPAREN T_SEMICOLON T_ARROW
%token T_COMMA T_DOT T_ID T_NUMBER T_GTHANE T_GTHAN
%token T_PLUS T_MINUS T_TIMES T_DIVIDE T_ASSEQUALS

/* WRITEME: Specify precedence here */

%left T_OR
%left T_AND
%left T_GTHAN T_GTHANE T_EQUALS
%left T_PLUS T_MINUS
%left T_TIMES T_DIVIDE
%right T_NOT

/* WRITEME: Specify types for all nonterminals and necessary terminals here */

%type <base_int> T_INTEGER
%type <base_char_ptr> T_ID

%%

/* WRITME: Write your Bison grammar specification here */

Program : Class
	| Class Program
	;
	

Class : T_ID T_LBRACKET ClassBody T_RBRACKET
	| T_ID T_EXTENDS T_ID T_LBRACKET ClassBody T_RBRACKET
	;

ClassBody : Members Methods
	;

Members : Members Type T_ID T_SEMICOLON
	| %empty
	;

Methods : T_ID T_LPAREN Parameters T_RPAREN T_ARROW ReturnType T_LBRACKET Body T_RBRACKET Methods
	| %empty
	;

Parameters : Parameters2
	| %empty
	;

Parameters2 : Type T_ID
	| Type T_ID T_COMMA Parameters2
	;

Body : Declarations Statements Return
	;

Declarations : Declarations Declaration
	| %empty
	;

Declaration : Type VarName T_SEMICOLON
	;

VarName : T_ID T_COMMA VarName
	| T_ID
	;

Statements : Statement Statements
	| %empty
	;

Statement : Assignment
	| MethodCallStatement
	| IfElse
	| While
	| DoWhile
	| Print
	;

Assignment : T_ID T_ASSEQUALS Expression T_SEMICOLON
	| T_ID T_DOT T_ID T_ASSEQUALS Expression T_SEMICOLON
	;

MethodCallStatement : MethodCall T_SEMICOLON
	;

IfElse : If
	| If Else
	;

If : T_IF Expression T_LBRACKET Block T_RBRACKET
	;

Else : T_ELSE T_LBRACKET Block T_RBRACKET
	;

While : T_WHILE Expression T_LBRACKET Block T_RBRACKET
	;

DoWhile : T_DO T_LBRACKET Block T_RBRACKET T_WHILE T_LPAREN Expression T_RPAREN T_SEMICOLON
	;

Block : Statement Statements
	;

Print : T_PRINT Expression T_SEMICOLON
	;

Return : T_RETURN Expression T_SEMICOLON
	| %empty
	;

Expression : Expression T_PLUS Expression
	| Expression T_MINUS Expression
	| Expression T_TIMES Expression
	| Expression T_DIVIDE Expression
	| Expression T_GTHAN Expression
	| Expression T_GTHANE Expression
	| Expression T_EQUALS Expression
	| Expression T_AND Expression
	| Expression T_OR Expression
	| T_NOT Expression
	| T_MINUS Expression %prec T_NOT
	| T_ID  									
	| T_ID T_DOT T_ID
	| MethodCall
	| T_LPAREN Expression T_RPAREN
	| T_NUMBER									{ $$.expression_ptr = new IntegerLiteralNode(new IntegerNode($1.base_int)); }
	| T_TRUE
	| T_FALSE
	| T_NEW T_ID
	| T_NEW T_ID T_LPAREN Arguments T_RPAREN
	;

MethodCall : T_ID T_LPAREN Arguments T_RPAREN
	| T_ID T_DOT T_ID T_LPAREN Arguments T_RPAREN
	;

Arguments : Arguments2
	| %empty
	;

Arguments2 : Arguments2 T_COMMA Expression
	| Expression
	;

Type : T_INTEGER
	| T_BOOLEAN
	| T_ID
	;

ReturnType : T_INTEGER
	| T_BOOLEAN
	| T_ID
	| T_NONE
	;

%%

extern int yylineno;

void yyerror(const char *s) {
  fprintf(stderr, "%s at line %d\n", s, yylineno);
  exit(0);
}
