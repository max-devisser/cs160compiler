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

%type <statement_list_ptr> Statements Block
%type <statement_ptr> Statement
%type <assignment_ptr> Assignment
%type <call_ptr> MethodCallStatement
%type <print_ptr> Print
%type <returnstatement_ptr> Return
%type <expression_ptr> Expression
%type <methodcall_ptr> MethodCall 
%type <expression_list_ptr> Arguments Arguments2
%type <identifier_ptr> T_ID
%type <base_int> T_NUMBER

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

/* TEST THIS */
Statements : Statement Statements
		{
		if ($2 != NULL) { $$ = $2; }
		else { $$ = new std::list<StatementNode*>(); }
		$$->push_front($1);
		}
	| %empty
		{ $$ = NULL; }
	;

Statement : Assignment
		{ $$ = $1; }
	| MethodCallStatement
		{ $$ = $1; astRoot = $$; }
	| IfElse
	| While
	| DoWhile
	| Print
	;

Assignment : T_ID T_ASSEQUALS Expression T_SEMICOLON
		{ $$ = new AssignmentNode($1, NULL, $3); }
	| T_ID T_DOT T_ID T_ASSEQUALS Expression T_SEMICOLON
		{ $$ = new AssignmentNode($1, $3, $5); }
	;

MethodCallStatement : MethodCall T_SEMICOLON
		{ $$ = new CallNode($1); }
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

/* TEST THIS */
Block : Statement Statements
		{
		if ($2 != NULL) { $$ = $2; }
		else { $$ = new std::list<StatementNode*>(); }
		$$->push_front($1);
		}
	;

Print : T_PRINT Expression T_SEMICOLON
		{ $$ = new PrintNode($2); }
	;

Return : T_RETURN Expression T_SEMICOLON
		{ $$ = new ReturnStatementNode($2); }
	| %empty
		{ $$ = NULL; }
	;

Expression : Expression T_PLUS Expression
		{ $$ = new PlusNode($1, $3); }
	| Expression T_MINUS Expression
		{ $$ = new MinusNode($1, $3); }
	| Expression T_TIMES Expression
		{ $$ = new TimesNode($1, $3); }
	| Expression T_DIVIDE Expression
		{ $$ = new DivideNode($1, $3); }
	| Expression T_GTHAN Expression
		{ $$ = new GreaterNode($1, $3); }
	| Expression T_GTHANE Expression
		{ $$ = new GreaterEqualNode($1, $3); }
	| Expression T_EQUALS Expression
		{ $$ = new EqualNode($1, $3); }
	| Expression T_AND Expression
		{ $$ = new AndNode($1, $3); }
	| Expression T_OR Expression
		{ $$ = new OrNode($1, $3); }
	| T_NOT Expression
		{ $$ = new NotNode($2); }
	| T_MINUS Expression %prec T_NOT
		{ $$ = new NegationNode($2); }
	| T_ID
		{ $$ = new VariableNode($1); }
	| T_ID T_DOT T_ID
		{ $$ = new MemberAccessNode($1, $3); }
	| MethodCall
		{ $$ = $1; }
	| T_LPAREN Expression T_RPAREN
		{ $$ = $2; }
	| T_NUMBER
		{ $$ = new IntegerLiteralNode(new IntegerNode($1)); }
	| T_TRUE
		{ $$ = new BooleanLiteralNode(new IntegerNode(1)); }
	| T_FALSE
		{ $$ = new BooleanLiteralNode(new IntegerNode(0)); }
	| T_NEW T_ID
		{ $$ = new NewNode($2, NULL); }
	| T_NEW T_ID T_LPAREN Arguments T_RPAREN
		{ $$ = new NewNode($2, $4); }
	;

MethodCall : T_ID T_LPAREN Arguments T_RPAREN
		{ $$ = new MethodCallNode($1, NULL, $3); }
	| T_ID T_DOT T_ID T_LPAREN Arguments T_RPAREN
		{ $$ = new MethodCallNode($1, $3, $5); }
	;

Arguments : Arguments2
		{ $$ = $1; }
	| %empty
		{ $$ = NULL; }
	;

Arguments2 : Arguments2 T_COMMA Expression
		{ $$ = $1; $$->push_back($3); }
	| Expression
		{ $$ = new std::list<ExpressionNode*>(); $$->push_back($1); }
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
