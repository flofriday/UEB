%{
    #include <stdlib.h>
    #include "parser.h"
    int yylex(void);
    int yywrap();
    int yyerror(char *s);
%}

%union {
    long num;
    char *sym;
}

%token LEFT_PAREN
%token RIGHT_PAREN
%token LEFT_BRACE
%token RIGHT_BRACE
%token LEFT_BRACKET
%token RIGHT_BRACKET

%token AT
%token COLON
%token COMMA
%token EQUAL
%token GREATER
%token MINUS
%token PLUS
%token SEMICOLON
%token STAR

%token AND
%token END
%token GOTO
%token IF
%token NOT
%token RETURN
%token VAR

%token<num> NUMBER
%token<sym> IDENTIFIER

%%

input: %empty
     | program
     ;

program: def SEMICOLON
       | program def SEMICOLON
       ;

def: IDENTIFIER LEFT_PAREN pars RIGHT_PAREN END
   | IDENTIFIER LEFT_BRACE pars RIGHT_BRACE LEFT_PAREN pars RIGHT_PAREN END
   | IDENTIFIER LEFT_PAREN pars RIGHT_PAREN stats END
   | IDENTIFIER LEFT_BRACE pars RIGHT_BRACE LEFT_PAREN pars RIGHT_PAREN stats END
   ;

pars: IDENTIFIER 
    | pars COMMA IDENTIFIER
    ;

stats: stat SEMICOLON
     | stats stat SEMICOLON
     | labeldefs stat SEMICOLON
     | stats labeldefs stat SEMICOLON
     ;

labeldefs: IDENTIFIER COLON
         | labeldefs IDENTIFIER COLON
         ;

stat: RETURN expr
    | GOTO IDENTIFIER
    | IF expr GOTO IDENTIFIER
    | VAR IDENTIFIER EQUAL expr
    | lexpr EQUAL expr
    | term
    ;

lexpr: IDENTIFIER
     | term LEFT_BRACKET expr RIGHT_BRACKET
     ;

exprs: expr
     | exprs COMMA expr
     ;

expr: term
    | prefix_expr
    | plus_expr
    | star_expr
    | and_expr
    | term EQUAL term
    | term GREATER term
    ;

prefix_expr: NOT term
           | MINUS term
           | NOT prefix_expr
           | MINUS prefix_expr
           ;

plus_expr: term PLUS term
         | plus_expr PLUS term
         ;

star_expr: term STAR term
         | star_expr STAR term
         ;

and_expr: term AND term
        | and_expr AND term
        ;

term: LEFT_PAREN expr RIGHT_PAREN
    | NUMBER
    | term LEFT_BRACKET expr RIGHT_BRACKET
    | IDENTIFIER
    | IDENTIFIER LEFT_PAREN exprs RIGHT_PAREN
    | IDENTIFIER LEFT_BRACE exprs RIGHT_BRACE
    | term AT LEFT_PAREN exprs RIGHT_PAREN
    ;


%%

int yyerror(char *s) {
    printf("ERROR: %s\n", s);
    exit(2);
    return 0;
}

int main() {
    yyparse();
    return 0;
}