%{
    #include <stdlib.h>
    #include "y.tab.h"
    #include "tree.h"
    #include "vector.h"
%}

DIGIT   [0-9]
HEX     [0-9a-fA-F]
ID  [_a-zA-Z][_a-zA-Z0-9]*
COMMENT     \/\/.*(\n)?

%%

{COMMENT}      

end     return END;
return  return RETURN;
goto    return GOTO;
if      return IF;
var     return VAR;
not     return NOT;
and     return AND;

";"     return SEMICOLON;
"("     return LEFT_PAREN;
")"     return RIGHT_PAREN;
"{"     return LEFT_BRACE;
"}"     return RIGHT_BRACE;
","     return COMMA;
":"     return COLON;
"="     return EQUAL;
"["     return LEFT_BRACKET;
"]"     return RIGHT_BRACKET;
"+"     return PLUS;
"*"     return STAR;
">"     return GREATER;
"-"     return MINUS;
"@"     return AT;

{DIGIT}+        return NUMBER; @{ @NUMBER.val@ = strtol(yytext, NULL, 10); @}
${HEX}+         return NUMBER; @{ @NUMBER.val@ = strtol(yytext + 1, NULL, 16); @}
{ID}            return IDENTIFIER; @{ @IDENTIFIER.name@ = strdup(yytext); @}

[ \t\n]+
.               {printf("Lexical Error line: %d\nUnexpected character(s): %s\n", yylineno, yytext); exit(1);}

%%

int yywrap() {}

void exitScannerError() {
    printf("Lexical Error line: %d\nUnexpected character(s): %s\n", yylineno, yytext);
    exit(1);
}