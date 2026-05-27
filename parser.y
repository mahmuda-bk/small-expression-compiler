%code requires {
    #include "symbol_table.h"

#ifndef EXPR_VALUE_DEFINED
#define EXPR_VALUE_DEFINED
    typedef struct {
        double value;
        DataType type;
    } ExprValue;
#endif
}

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "symbol_table.h"

#ifndef EXPR_VALUE_DEFINED
#define EXPR_VALUE_DEFINED
typedef struct {
    double value;
    DataType type;
} ExprValue;
#endif

extern int yylex();
extern int yylineno;
void yyerror(const char *s);

static DataType currentDeclType = TYPE_INT;

static ExprValue makeExpr(double value, DataType type) {
    ExprValue expr;
    expr.value = value;
    expr.type = type;
    return expr;
}

static void reportSyntax(const char *message) {
    printf("Line %d: Syntax Error - %s\n", yylineno, message);
}

static void reportSemantic(const char *message) {
    printf("Line %d: Semantic Error - %s\n", yylineno, message);
}

static void printValue(ExprValue value) {
    if(value.type == TYPE_FLOAT) {
        printf("%g", value.value);
    } else {
        printf("%.0f", value.value);
    }
}
%}

%union {
    double num;
    char* id;
    DataType dtype;
    ExprValue expr;
}

%define parse.error detailed

%token INT FLOAT MAIN RETURN PLUS MINUS MUL DIV ASSIGN SEMICOLON COMMA LPAREN RPAREN LBRACE RBRACE SQRT POW
%token <num> INT_CONST FLOAT_CONST
%token <id> ID
%type <expr> expr
%type <dtype> type_specifier

%left PLUS MINUS
%left MUL DIV
%right UMINUS

%%
program:
    INT MAIN LPAREN RPAREN LBRACE { enterScope(); } statements RBRACE { exitScope(); }
    ;

statements:
    statements statement
    | /* empty */
    ;

statement:
    declaration
    | assignment
    | RETURN expr SEMICOLON {
        printf("Return value = ");
        printValue($2);
        printf("\n");
    }
    | block
    | error SEMICOLON {
        reportSyntax("Invalid statement");
        yyerrok;
    }
    ;

declaration:
    type_specifier { currentDeclType = $1; } id_list SEMICOLON
    ;

block:
    LBRACE { enterScope(); } statements RBRACE { exitScope(); }
    ;

type_specifier:
    INT { $$ = TYPE_INT; }
    | FLOAT { $$ = TYPE_FLOAT; }
    ;

id_list:
    ID { insertSymbol($1, currentDeclType, yylineno); }
    | id_list COMMA ID { insertSymbol($3, currentDeclType, yylineno); }
    ;

assignment:
    ID ASSIGN expr SEMICOLON {
        if(searchSymbol($1) == -1) {
            printf("Line %d: Semantic Error - Undeclared variable '%s'\n", yylineno, $1);
        } else {
            DataType targetType = getSymbolType($1);

            if(targetType == TYPE_INT && $3.type == TYPE_FLOAT) {
                printf("Line %d: Semantic Error - Type mismatch for '%s'\n", yylineno, $1);
            } else {
                double assignedValue = $3.value;
                if(targetType == TYPE_FLOAT && $3.type == TYPE_INT) {
                    assignedValue = $3.value;
                }

                updateSymbol($1, assignedValue);
                printf("%s = ", $1);
                printValue(makeExpr(assignedValue, targetType));
                printf("\n");
            }
        }
    }
    ;

expr:
    expr PLUS expr {
        $$ = makeExpr($1.value + $3.value, ($1.type == TYPE_FLOAT || $3.type == TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT);
    }
    | expr MINUS expr {
        $$ = makeExpr($1.value - $3.value, ($1.type == TYPE_FLOAT || $3.type == TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT);
    }
    | expr MUL expr {
        $$ = makeExpr($1.value * $3.value, ($1.type == TYPE_FLOAT || $3.type == TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT);
    }
    | expr DIV expr { 
        if($3.value == 0) { printf("Line %d: Runtime Error - Division by zero\n", yylineno); $$ = makeExpr(0, TYPE_INT); }
        else $$ = makeExpr($1.value / $3.value, TYPE_FLOAT); 
    }
    | MINUS expr %prec UMINUS { $$ = makeExpr(-$2.value, $2.type); }
    | LPAREN expr RPAREN { $$ = $2; }
    | SQRT LPAREN expr RPAREN {
        if($3.value < 0) {
            reportSemantic("sqrt() requires a non-negative value");
            $$ = makeExpr(0, TYPE_FLOAT);
        } else {
            $$ = makeExpr(sqrt($3.value), TYPE_FLOAT);
        }
    }
    | POW LPAREN expr COMMA expr RPAREN {
        $$ = makeExpr(pow($3.value, $5.value), TYPE_FLOAT);
    }
    | INT_CONST { $$ = makeExpr($1, TYPE_INT); }
    | FLOAT_CONST { $$ = makeExpr($1, TYPE_FLOAT); }
    | ID {
        if(searchSymbol($1) == -1) {
            printf("Line %d: Semantic Error - Undeclared variable '%s'\n", yylineno, $1);
            $$ = makeExpr(0, TYPE_INT);
        } else {
            if(!isSymbolInitialized($1)) {
                printf("Line %d: Semantic Error - Variable '%s' used before assignment\n", yylineno, $1);
                $$ = makeExpr(0, getSymbolType($1));
            } else {
                $$ = makeExpr(getValue($1), getSymbolType($1));
            }
        }
    }
    ;
%%

void yyerror(const char *s) {
    if(strstr(s, "expecting RPAREN") != NULL) {
        printf("Line %d: Syntax Error - Unbalanced parentheses\n", yylineno);
    } else if(strstr(s, "unexpected RPAREN") != NULL) {
        printf("Line %d: Syntax Error - Unexpected ')'\n", yylineno);
    } else if(strstr(s, "expecting PLUS") != NULL || strstr(s, "expecting MINUS") != NULL || strstr(s, "expecting MUL") != NULL || strstr(s, "expecting DIV") != NULL) {
        printf("Line %d: Syntax Error - Missing operator or operand\n", yylineno);
    } else {
        printf("Line %d: Syntax Error - %s\n", yylineno, s);
    }
}

int main() {
    printf("===== COMPILER START =====\n\n");
    yyparse();
    displaySymbolTable();
    return 0;
}
