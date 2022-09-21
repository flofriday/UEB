%{
    #include <stdlib.h>
    #include <string.h>

    #include "generator.h"
    #include "tree.h"
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
@autosyn ast
@autosyn new_vars
@autoinh vars
@autoinh params
@autoinh funcname

// TODO: There is also autosynth to give attributes from the child to the 
// parent which will be very helpfull as well.

// Attributes of the tree nodes
@attributes {char *name;} IDENTIFIER
@attributes {long val;} NUMBER
@attributes {vector *labels; char *funcname;} labeldefs
@attributes {vector *labels; vector *used_labels; vector *new_vars; vector *params; char *funcname;} stats
@attributes {vector *used_labels; vector* vars; vector *new_vars; tree* ast; vector *params; char *funcname;} stat
@attributes {vector *vars; tree* ast; vector *params;} exprs expr lexpr prefix_expr plus_expr star_expr and_expr term 
@attributes {vector *new_params;} pars

@traversal @preorder reg

@traversal @postorder vis
@traversal @postorder gen

%%

input:
     @{
         @gen write_file_metadata();
     @}
     | program
     @{
         @gen @revorder(1) write_file_metadata();
     @}
     ;

program: def SEMICOLON
       | program def SEMICOLON
       ;

def: IDENTIFIER LEFT_PAREN pars RIGHT_PAREN END
   @{
       @vis assert_unique_vector(@pars.new_params@);
       @gen @revorder(1) write_function_header(@IDENTIFIER.name@, 0, false);
   @}
   | IDENTIFIER LEFT_BRACE pars RIGHT_BRACE LEFT_PAREN pars RIGHT_PAREN END
   @{
       @vis assert_unique_vector(merge_vector(clone_vector(@pars.0.new_params@), @pars.1.new_params@));
       @gen @revorder(1) write_function_header(@IDENTIFIER.name@, 0, false);
   @}
   | IDENTIFIER LEFT_PAREN pars RIGHT_PAREN stats END
   @{
       @i @stats.params@ = @pars.new_params@;
       @i @stats.funcname@ = @IDENTIFIER.name@;
       @vis assert_contains_vector(@stats.labels@, @stats.used_labels@);
    //    @vis assert_disjoined_vector(merge_vector(clone_vector(@stats.params@), @stats.new_vars@), @stats.labels@);
       @vis assert_unique_vector(merge_vector(merge_vector(clone_vector(@stats.params@), @stats.new_vars@), @stats.labels@));

        // TODO: somehow check if there is a function call in the body
       @gen @revorder(1) write_function_header(@IDENTIFIER.name@, @stats.params@->len + @stats.new_vars@->len, false);
   @}
   | IDENTIFIER LEFT_BRACE pars RIGHT_BRACE LEFT_PAREN pars RIGHT_PAREN stats END
   @{
       @i @stats.params@ = merge_vector(clone_vector(@pars.1.new_params@), @pars.0.new_params@);
       @i @stats.funcname@ = @IDENTIFIER.name@;
       @vis assert_contains_vector(@stats.labels@, @stats.used_labels@);
    //    @vis assert_disjoined_vector(merge_vector(clone_vector(@stats.params@), @stats.new_vars@), @stats.labels@);
       @vis assert_unique_vector(merge_vector(merge_vector(clone_vector(@stats.params@), @stats.new_vars@), @stats.labels@));

        // TODO: somehow check if there is a function call in the body
       @gen @revorder(1) write_multistage_function_header(@IDENTIFIER.name@, @stats.params@->len + @stats.new_vars@->len, false, @pars.0.new_params@, @pars.1.new_params@);
   @}
   ;

pars: IDENTIFIER 
    @{
        @i @pars.new_params@ = add_vector(new_vector(), @IDENTIFIER.name@);
    @}
    | pars COMMA IDENTIFIER
    @{
        @i @pars.0.new_params@ = add_vector(@pars.1.new_params@, @IDENTIFIER.name@); 
    @}
    ;

stats: stat SEMICOLON
     @{
        @i @stat.vars@ = clone_vector(@stats.params@);

        @i @stats.labels@ = new_vector();
        @i @stats.used_labels@ = @stat.used_labels@;
        @gen /*print_tree(@stat.ast@);*/ if(@stat.ast@ != NULL) {burm_label(@stat.ast@); burm_reduce(@stat.ast@, 1);};
     @}
     | stats stat SEMICOLON
     @{
         
        @i @stat.vars@ = merge_vector(clone_vector(@stats.0.params@), @stats.1.new_vars@);
        @i @stats.0.new_vars@ = merge_vector(clone_vector(@stats.1.new_vars@), @stat.new_vars@); 

        @i @stats.0.labels@ = @stats.1.labels@;
        @i @stats.0.used_labels@ = merge_vector(@stats.1.used_labels@, @stat.used_labels@);
        @gen /*print_tree(@stat.ast@);*/ if(@stat.ast@ != NULL) {burm_label(@stat.ast@); burm_reduce(@stat.ast@, 1);};
     @}
     | labeldefs stat SEMICOLON
     @{
        @i @stat.vars@ = clone_vector(@stats.params@);

        @i @stats.labels@ = @labeldefs.labels@;
        @i @stats.used_labels@ = @stat.used_labels@;
        @gen if(@stat.ast@ != NULL) {burm_label(@stat.ast@); burm_reduce(@stat.ast@, 1);}
     @}
     | stats labeldefs stat SEMICOLON
     @{
        @i @stat.vars@ = merge_vector(clone_vector(@stats.0.params@), @stats.1.new_vars@); 
        @i @stats.0.new_vars@ = merge_vector(clone_vector(@stats.1.new_vars@), @stat.new_vars@);

        @i @stats.0.labels@ = merge_vector(@stats.1.labels@, @labeldefs.labels@); 
        @i @stats.0.used_labels@ = merge_vector(@stats.1.used_labels@, @stat.used_labels@);
        @gen if(@stat.ast@ != NULL) {burm_label(@stat.ast@); burm_reduce(@stat.ast@, 1);}
     @}
     ;

labeldefs: IDENTIFIER COLON
         @{
            @i @labeldefs.labels@ = add_vector(new_vector(), @IDENTIFIER.name@); 
            @gen write_label(@IDENTIFIER.name@, @labeldefs.funcname@);
         @}
         | labeldefs IDENTIFIER COLON
         @{
            @i @labeldefs.0.labels@ = add_vector(@labeldefs.1.labels@, @IDENTIFIER.name@);
            @gen write_label(@IDENTIFIER.name@, @labeldefs.1.funcname@);
         @}
         ;

stat: RETURN expr
    @{
        @i @stat.used_labels@ = new_vector();
        @i @stat.ast@ = new_tree(OP_RETURN, @expr.ast@, NULL);
        @i @stat.new_vars@ = new_vector();
        @reg @stat.ast@->reg = first_reg(); @expr.ast@->reg = @stat.ast@->reg;
    @}
    | GOTO IDENTIFIER
    @{
        @i @stat.used_labels@ = add_vector(new_vector(), @IDENTIFIER.name@);
        @i @stat.ast@ = new_tree(OP_GOTO, new_label_leaf(@IDENTIFIER.name@, @stat.funcname@), NULL);
        @i @stat.new_vars@ = new_vector();
        @reg @stat.ast@->reg = first_reg();
    @}
    | IF expr GOTO IDENTIFIER
    @{
        @i @stat.used_labels@ = add_vector(new_vector(), @IDENTIFIER.name@);
        @i @stat.ast@ = new_tree(OP_IF, @expr.ast@, new_label_leaf(@IDENTIFIER.name@, @stat.funcname@));
        @i @stat.new_vars@ = new_vector();

        @reg @stat.ast@->reg = first_reg(); @expr.ast@->reg = @stat.ast@->reg;
    @}
    | VAR IDENTIFIER EQUAL expr
    @{ 
        @i @expr.vars@ = @stat.vars@;
        @i @stat.new_vars@ = add_vector(new_vector(), @IDENTIFIER.name@); 
        @i @stat.used_labels@ = new_vector();

        @i @stat.ast@ = new_tree(OP_ASSIGN, new_param_leaf(@IDENTIFIER.name@, @stat.vars@->len), @expr.ast@);

        // TODO: we maybe can give the expression the register of the destination variable
        // and therefore avoid one unneccessry move?
        @reg @stat.ast@->reg = first_reg(); @expr.ast@->reg = @stat.ast@->reg;
    @}
    | lexpr EQUAL expr
    @{
        @i @stat.used_labels@ = new_vector();
        @i @stat.new_vars@ = new_vector();
        @i @stat.ast@ = new_tree(OP_ASSIGN, @lexpr.ast@, @expr.ast@);

        // TODO: we maybe can give the expression the register of the destination variable
        // and therefore avoid one unneccessry move?
        @reg @stat.ast@->reg = first_reg(); @lexpr.ast@->reg = @stat.ast@->reg; @expr.ast@->reg = next_reg(@stat.ast@->reg);
    @}
    | term
    @{
        @i @stat.used_labels@ = new_vector();
        @i @stat.new_vars@ = new_vector();
        @reg @stat.ast@->reg = first_reg(); @term.ast@->reg = @stat.ast@->reg;
    @}
    ;

lexpr: IDENTIFIER
     @{
         //@i @lexpr.ast@ = new_param_leaf(@IDENTIFIER.name@, index_in_vector(@lexpr.params@, @IDENTIFIER.name@));
         @i @lexpr.ast@ =  new_param_leaf(@IDENTIFIER.name@, index_in_vector(@lexpr.vars@, @IDENTIFIER.name@));
         @vis assert_in_vector(@lexpr.vars@, @IDENTIFIER.name@);
     @}
     | term LEFT_BRACKET expr RIGHT_BRACKET
     @{
         @i @lexpr.ast@ = new_tree(OP_INDEX, @term.ast@, @expr.ast@);
         @reg @term.ast@->reg = @lexpr.ast@->reg; @expr.ast@->reg = next_reg(@lexpr.ast@->reg);
     @}
     ;

exprs: expr
     | exprs COMMA expr
     @{
         @i @exprs.0.ast@ = new_tree(OP_EXPRS, @exprs.1.ast@, @expr.ast@);

         @reg @exprs.1.ast@->reg = next_reg(@exprs.0.ast@->reg); @expr.ast@->reg = @exprs.0.ast@->reg;
     @}
     ;

expr: term
    | prefix_expr
    | plus_expr
    | star_expr
    | and_expr
    | term EQUAL term
    @{
        @i @expr.ast@ = new_tree(OP_EQUAL, @term.0.ast@, @term.1.ast@);
        @reg @term.0.ast@->reg = @expr.ast@->reg; @term.1.ast@->reg = next_reg(@expr.ast@->reg);
    @}
    | term GREATER term
    @{
        @i @expr.ast@ = new_tree(OP_GREATER, @term.0.ast@, @term.1.ast@);
        @reg @term.0.ast@->reg = @expr.ast@->reg; @term.1.ast@->reg = next_reg(@expr.ast@->reg);
    @}
    ;

prefix_expr: NOT term
           @{
              @i @prefix_expr.ast@ = new_tree(OP_NOT, @term.ast@, NULL);
              @reg @term.ast@->reg = @prefix_expr.ast@->reg;
           @}
           | MINUS term
           @{
              @i @prefix_expr.ast@ = new_tree(OP_SUB, @term.ast@, NULL);
              @reg @term.ast@->reg = @prefix_expr.ast@->reg;
           @}
           | NOT prefix_expr
           @{
              @i @prefix_expr.0.ast@ = new_tree(OP_NOT, @prefix_expr.1.ast@, NULL);
              @reg @prefix_expr.1.ast@->reg = @prefix_expr.0.ast@->reg;
           @}
           | MINUS prefix_expr
           @{
              @i @prefix_expr.0.ast@ = new_tree(OP_SUB, @prefix_expr.1.ast@, NULL);
              @reg @prefix_expr.1.ast@->reg = @prefix_expr.0.ast@->reg;
           @}
           ;

plus_expr: term PLUS term
         @{
             @i @plus_expr.ast@ = new_tree(OP_ADD, @term.0.ast@, @term.1.ast@);
             @reg @term.0.ast@->reg = @plus_expr.ast@->reg; @term.1.ast@->reg = next_reg(@plus_expr.ast@->reg);
         @}
         | plus_expr PLUS term
         @{
             @i @plus_expr.0.ast@ = new_tree(OP_ADD, @plus_expr.1.ast@, @term.ast@);
             @reg @plus_expr.1.ast@->reg = @plus_expr.0.ast@->reg; @term.ast@->reg = next_reg(@plus_expr.0.ast@->reg);
         @}
         ;

star_expr: term STAR term
         @{
             @i @star_expr.ast@ = new_tree(OP_MUL, @term.0.ast@, @term.1.ast@);
             @reg @term.0.ast@->reg = @star_expr.ast@->reg; @term.1.ast@->reg = next_reg(@star_expr.ast@->reg);
         @}
         | star_expr STAR term
         @{
             @i @star_expr.0.ast@ = new_tree(OP_MUL, @star_expr.1.ast@, @term.ast@);
             @reg @star_expr.1.ast@->reg = @star_expr.0.ast@->reg; @term.ast@->reg = next_reg(@star_expr.0.ast@->reg);
         @}
         ;

and_expr: term AND term
        @{
            @i @and_expr.ast@ = new_tree(OP_AND, @term.0.ast@, @term.1.ast@);
            @reg @term.0.ast@->reg = @and_expr.ast@->reg; @term.1.ast@->reg = next_reg(@and_expr.ast@->reg);
        @}
        | and_expr AND term
        @{
            @i @and_expr.0.ast@ = new_tree(OP_AND, @and_expr.1.ast@, @term.ast@);
            @reg @and_expr.1.ast@->reg = @and_expr.0.ast@->reg; @term.ast@->reg = next_reg(@and_expr.0.ast@->reg);
        @}
        ;

term: LEFT_PAREN expr RIGHT_PAREN
    | NUMBER
    @{
        @i @term.ast@ = new_num_leaf(@NUMBER.val@);
    @}
    | term LEFT_BRACKET expr RIGHT_BRACKET
    @{
        @i @term.0.ast@ = new_tree(OP_INDEX, @term.1.ast@, @expr.ast@);
        @reg @term.1.ast@->reg = @term.0.ast@->reg; @expr.ast@->reg = next_reg(@term.0.ast@->reg);
    @}
    | IDENTIFIER
    @{
        @i @term.ast@ = new_param_leaf(@IDENTIFIER.name@, index_in_vector(@term.vars@, @IDENTIFIER.name@));

        @vis assert_in_vector(@term.vars@, @IDENTIFIER.name@);
    @}
    | IDENTIFIER LEFT_PAREN exprs RIGHT_PAREN
    @{
        @i @term.ast@ = new_nop_leaf();
    @}
    | IDENTIFIER LEFT_BRACE exprs RIGHT_BRACE
    @{
        @i @term.ast@ = new_tree(OP_STAGE_ONE, new_param_leaf(@IDENTIFIER.name@, index_in_vector(@term.vars@, @IDENTIFIER.name@)), @exprs.ast@);

        @reg @exprs.ast@->reg = next_reg(@term.ast@->reg);
    @}
    | term AT LEFT_PAREN exprs RIGHT_PAREN
    @{
        @i @term.ast@ = new_nop_leaf();
    @}
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