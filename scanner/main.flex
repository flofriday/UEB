%option noinput
%option nounput

%{
    #include <stdlib.h>
%}

DIGIT   [0-9]
HEX     [0-9a-fA-F]
ALPHA   [a-zA-Z]
IDENTIFIER  [_a-zA-Z][_a-zA-Z0-9]*
WHITESPACE  [' '\t\n]
KEYWORD     end|return|goto|if|var|not|and
PUNCTUITION [;(){},:=\[\]+*>\-@]
COMMENT     \/\/.*(\n)?

%%

{COMMENT}      
{KEYWORD}       printf("%s\n", yytext);
{PUNCTUITION}   printf("%s\n", yytext);
{DIGIT}+        printf("num %ld\n", strtol(yytext, NULL, 10));
${HEX}+         printf("num %ld\n", strtol(yytext+1, NULL, 16));
{IDENTIFIER}    printf("id %s\n", yytext);
[ \t\n]+
.               {printf("Error line %d on: '%s'\n", yylineno, yytext); exit(1);}

%%

int main(int argc, char **argv)
{
    yylex();
    return 0;
}