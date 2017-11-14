%{
    #include <cstdlib>
    #include <cstdio>
    #include <iostream>

    #include "ast.hpp"

    #define YYDEBUG 1
    #define YYINITDEPTH 10000
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

%type <program_ptr> Program
%type <class_ptr> Class ClassBody
%type <method_list_ptr> Methods
%type <parameter_list_ptr> Parameters Parameters2
%type <methodbody_ptr> Body
%type <declaration_list_ptr> Declarations Members
%type <declaration_ptr> Declaration
%type <identifier_list_ptr> VarName
%type <statement_list_ptr> Statements Block Else
%type <statement_ptr> Statement
%type <assignment_ptr> Assignment
%type <call_ptr> MethodCallStatement
%type <ifelse_ptr> IfElse If
%type <while_ptr> While
%type <dowhile_ptr> DoWhile
%type <print_ptr> Print
%type <returnstatement_ptr> Return
%type <expression_ptr> Expression
%type <methodcall_ptr> MethodCall 
%type <expression_list_ptr> Arguments Arguments2
%type <identifier_ptr> T_ID
%type <base_int> T_NUMBER
%type <type_ptr> Type ReturnType


%%

/* WRITME: Write your Bison grammar specification here */

Program : Class
		{ 
		$$ = new ProgramNode(new std::list<ClassNode*>());
		$$->class_list->push_front($1);
		astRoot = $$;
		}
	| Class Program
		{ $$ = $2; $$->class_list->push_front($1); }
	;
	

Class : T_ID T_LBRACKET ClassBody T_RBRACKET
		{ $$ = $3; $$->identifier_1 = $1; $$->identifier_2 = NULL; }
	| T_ID T_EXTENDS T_ID T_LBRACKET ClassBody T_RBRACKET
		{ $$ = $5; $$->identifier_1 = $1; $$->identifier_2 = $3; }
	;

ClassBody : Members Methods
		{ $$ = new ClassNode(NULL, NULL, $1, $2); }
	;

Members : Members Type T_ID T_SEMICOLON
		{ 
		$$ = $1; 
		std::list<IdentifierNode*>* id = new std::list<IdentifierNode*>();
		id->push_front($3);
		$$->push_back(new DeclarationNode($2, id)); 
		}
	| %empty
		{ $$ = new std::list<DeclarationNode*>(); }
	;

Methods : T_ID T_LPAREN Parameters T_RPAREN T_ARROW ReturnType T_LBRACKET Body T_RBRACKET Methods
		{ $$ = $10; $$->push_front(new MethodNode($1, $3, $6, $8)); }
	| %empty
		{ $$ = new std::list<MethodNode*>(); }
	;

Parameters : Parameters2
		{ $$ = $1; }
	| %empty
		{ $$ = NULL; }
	;

Parameters2 : Type T_ID
		{ $$ = new std::list<ParameterNode*>(); $$->push_front(new ParameterNode($1, $2)); }
	| Type T_ID T_COMMA Parameters2
		{ $$ = $4; $$->push_front(new ParameterNode($1, $2)); }
	;

Body : Declarations Statements Return
		{ $$ = new MethodBodyNode($1, $2, $3); astRoot = $$; }
	;

Declarations : Declarations Declaration
		{ $$ = $1; $$->push_back($2); }
	| %empty
		{ $$ = new std::list<DeclarationNode*>(); }
	;

Declaration : Type VarName T_SEMICOLON
		{ $$ = new DeclarationNode($1, $2); }
	;

VarName : T_ID T_COMMA VarName
		{ $$ = $3; $$->push_front($1); }
	| T_ID
		{ $$ = new std::list<IdentifierNode*>(); $$->push_front($1); }
	;

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
		{ $$ = $1; }
	| IfElse
		{ $$ = $1; }
	| While
		{ $$ = $1; }
	| DoWhile
		{ $$ = $1; }
	| Print
		{ $$ = $1; }
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
		{ $$ = $1; }
	| If Else
		{ $$ = $1; $$->statement_list_2 = $2; }
	;

If : T_IF Expression T_LBRACKET Block T_RBRACKET
		{ $$ = new IfElseNode($2, $4, NULL); }
	;

Else : T_ELSE T_LBRACKET Block T_RBRACKET
		{ $$ = $3; }
	;

While : T_WHILE Expression T_LBRACKET Block T_RBRACKET
		{ $$ = new WhileNode($2, $4); }
	;

DoWhile : T_DO T_LBRACKET Block T_RBRACKET T_WHILE T_LPAREN Expression T_RPAREN T_SEMICOLON
		{ $$ = new DoWhileNode($3, $7); }
	;

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

/* TEST THIS */
Type : T_INTEGER
		{ $$ = new IntegerTypeNode(); }
	| T_BOOLEAN
		{ $$ = new BooleanTypeNode(); }
	| T_ID
		{ $$ = new ObjectTypeNode($1); }
	;
/* TEST THIS */
ReturnType : Type
		{ $$ = $1; }
	| T_NONE
		{ $$ = new NoneNode(); }
	;

%%

extern int yylineno;

void yyerror(const char *s) {
  fprintf(stderr, "%s at line %d\n", s, yylineno);
  exit(0);
}
