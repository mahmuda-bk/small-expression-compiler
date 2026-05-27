%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}

%option yylineno

%%
"int"           { return INT; }
"float"         { return FLOAT; }
"main"          { return MAIN; }
"return"        { return RETURN; }
"sqrt"          { return SQRT; }
"pow"           { return POW; }

[0-9]+\.[0-9]+([eE][+-]?[0-9]+)? { yylval.num = atof(yytext); return FLOAT_CONST; }
[0-9]+          { yylval.num = atof(yytext); return INT_CONST; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.id = strdup(yytext); return ID; }

"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MUL; }
"/"             { return DIV; }
"="             { return ASSIGN; }
";"             { return SEMICOLON; }
","             { return COMMA; }
"("             { return LPAREN; }
")"             { return RPAREN; }
"{"             { return LBRACE; }
"}"             { return RBRACE; }

[ \t\r\n]       ; /* Ignore whitespace and newlines */

.               { printf("Line %d: Lexical Error - Invalid token '%s'\n", yylineno, yytext); }

%%
int yywrap() { return 1; }
