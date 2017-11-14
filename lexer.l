%option yylineno
%pointer

%{
    #include <stdlib.h>
    #include <errno.h>
    #include <limits.h>
    #include "ast.hpp"
    #include "parser.hpp"
    void yyerror(const char *);
%}

/* WRITEME: Write any definitions here. You can find information on
            definitions here:
            http://flex.sourceforge.net/manual/Definitions-Section.html */

number		        0|[1-9][0-9]*
id		            [a-zA-Z][a-zA-Z0-9]*

/* WRITEME: If you are going to use BEGIN conditions, write them here.
            You can find more information on BEGIN conditions here:
            http://flex.sourceforge.net/manual/BEGIN-Conditions.html
            You will probably want to use exclusive conditions rather
            than inclusive conditions (use the %x instead of the %s). */

%s subtract
%x comment

%%

  /* WRITEME: Write your Flex token rules here */


extends				{ return T_EXTENDS; }
true				{ return T_TRUE; }
false				{ return T_FALSE; }
new					{ return T_NEW; }
print				{ return T_PRINT; }
return				{ return T_RETURN; }
if					{ return T_IF; }
else				{ return T_ELSE; }
while				{ return T_WHILE; }
integer				{ return T_INTEGER; }
boolean				{ return T_BOOLEAN; }
none				{ return T_NONE; }
equals				{ return T_EQUALS; }
and					{ return T_AND; }
or					{ return T_OR; }
not					{ return T_NOT; }
do					{ return T_DO; }
"{"					{ return T_LBRACKET; }
"}"					{ return T_RBRACKET; }
"("					{ return T_LPAREN; }
")"					{ return T_RPAREN; }
";"					{ return T_SEMICOLON; }
"->"				{ return T_ARROW; }
","					{ return T_COMMA; }
"/*"				{ BEGIN(comment); }
<comment>"*/"		{ BEGIN(INITIAL); }
<comment>[ \t\n]	{ } /* skip whitespace */
<comment><<EOF>> 	{ yyerror("invalid character"); }
<comment>.			{ }
"."					{ return T_DOT; }
"+"					{ return T_PLUS; }
"-"					{ return T_MINUS; }
"*"					{ return T_TIMES; }
"/"					{ return T_DIVIDE; }
">"					{ return T_GTHAN; }
">="				{ return T_GTHANE; }
"="					{ return T_ASSEQUALS; }
{id}				{ yylval.identifier_ptr = new IdentifierNode(strdup(yytext)); return T_ID; }
{number}			{ yylval.base_int = atoi(yytext); return T_NUMBER; }

[ \t\n]				{ } /* skip whitespace */

.                 	{ yyerror("invalid character"); }

%%

int yywrap(void) {
  return 1;
}
