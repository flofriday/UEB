%{
    #include <stdlib.h>
    #include <string.h>

    #include "vector.h"

    int yylex(void);
    int yywrap();
    int yyerror(char *s);
%}

%union {
    long num;
    char *sym;
}

// Single char tokens
%token LEFT_PAREN RIGHT_PAREN LEFT_BRACE RIGHT_BRACE LEFT_BRACKET RIGHT_BRACKET

// Operator tokens
%token AT COLON COMMA EQUAL GREATER MINUS PLUS SEMICOLON STAR

// Keyworkd tokens
%token AND END GOTO IF NOT RETURN VAR

// Named tokens
%token NUMBER IDENTIFIER

%start input

// Make available variables automatically inheriented to avoid a lot of 
// boilerplate.
@autoinh vars

// TODO: There is also autosynth to give attributes from the child to  the 
// parent which will be very helpfull as well.

// Attributes of the tree nodes
@attributes {char *name;} IDENTIFIER
@attributes {vector *labels;} labeldefs
@attributes {vector *labels; vector *used_labels; vector *vars;} stats
@attributes {vector *used_labels; vector *vars;} stat
@attributes {vector *vars;} exprs expr lexpr prefix_expr plus_expr star_expr and_expr term 
@attributes {vector *params;} pars

@traversal @postorder vis

%%

input:
     | program
     ;

program: def SEMICOLON
       | program def SEMICOLON
       ;

def: IDENTIFIER LEFT_PAREN pars RIGHT_PAREN END
   | IDENTIFIER LEFT_BRACE pars RIGHT_BRACE LEFT_PAREN pars RIGHT_PAREN END
   | IDENTIFIER LEFT_PAREN pars RIGHT_PAREN stats END
   @{
       @i @stats.vars@ = @pars.params@;
       @vis assert_contains_vector(@stats.labels@, @stats.used_labels@);
       @vis assert_disjoined_vector(@stats.vars@, @stats.labels@);
   @}
   | IDENTIFIER LEFT_BRACE pars RIGHT_BRACE LEFT_PAREN pars RIGHT_PAREN stats END
   @{
       // TODO: I am not sure that both pars are needed here
       @i @stats.vars@ = merge_vector(@pars.0.params@, @pars.1.params@);
       @vis assert_contains_vector(@stats.labels@, @stats.used_labels@);
       @vis assert_disjoined_vector(@stats.vars@, @stats.labels@);
   @}
   ;

pars: IDENTIFIER 
    @{
        @i @pars.params@ = add_vector(new_vector(), @IDENTIFIER.name@);
    @}
    | pars COMMA IDENTIFIER
    @{
        @i @pars.0.params@ = add_vector(@pars.1.params@, @IDENTIFIER.name@);
    @}
    ;

stats: stat SEMICOLON
     @{
        @i @stats.labels@ = new_vector();
        @i @stats.used_labels@ = @stat.used_labels@;
     @}
     | stats stat SEMICOLON
     @{
        @i @stats.0.labels@ = @stats.1.labels@;
        @i @stats.0.used_labels@ = merge_vector(@stats.1.used_labels@, @stat.used_labels@);
     @}
     | labeldefs stat SEMICOLON
     @{
        @i @stats.labels@ = @labeldefs.labels@;
        @i @stats.used_labels@ = @stat.used_labels@;
     @}
     | stats labeldefs stat SEMICOLON
     @{
        @i @stats.0.labels@ = merge_vector(@stats.1.labels@, @labeldefs.labels@);
        @i @stats.0.used_labels@ = merge_vector(@stats.1.used_labels@, @stat.used_labels@);
     @}
     ;

labeldefs: IDENTIFIER COLON
         @{
            @i @labeldefs.labels@ = add_vector(new_vector(), @IDENTIFIER.name@);
         @}
         | labeldefs IDENTIFIER COLON
         @{
            @i @labeldefs.0.labels@ = add_vector(@labeldefs.1.labels@, @IDENTIFIER.name@);
         @}
         ;

stat: RETURN expr
    @{
        @i @stat.used_labels@ = new_vector();
    @}
    | GOTO IDENTIFIER
    @{
        @i @stat.used_labels@ = add_vector(new_vector(), @IDENTIFIER.name@);
    @}
    | IF expr GOTO IDENTIFIER
    @{
        @i @stat.used_labels@ = add_vector(new_vector(), @IDENTIFIER.name@);
    @}
    | VAR IDENTIFIER EQUAL expr
    @{ 
        //@i @expr.vars@ = clone_vector(@stat.vars@);
        @i @expr.vars@ = @stat.vars@;
        @i @stat.used_labels@ = new_vector();

        // TODO: it crashes if I put the @i here, but I think that is needed.
        @vis @stat.vars@ = add_vector(@stat.vars@, @IDENTIFIER.name@);
    @}
    | lexpr EQUAL expr
    @{
        @i @stat.used_labels@ = new_vector();
    @}
    | term
    @{
        @i @stat.used_labels@ = new_vector();
    @}
    ;

lexpr: IDENTIFIER
     @{
         @vis assert_in_vector(@lexpr.vars@, @IDENTIFIER.name@);
     @}
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
    @{
        @vis assert_in_vector(@term.vars@, @IDENTIFIER.name@);
    @}
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