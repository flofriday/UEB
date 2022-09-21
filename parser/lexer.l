%{
    #include <stdlib.h>
    #include "parser.h"
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

{DIGIT}+        {yylval.num = strtol(yytext, NULL, 10); return NUMBER;}
${HEX}+         {yylval.num = strtol(yytext, NULL, 16); return NUMBER;}
{ID}            {yylval.sym = yytext; return IDENTIFIER;}

[ \t\n]+
.               {printf("Error line %d on: '%s'\n", yylineno, yytext); exit(1);}

%%

int yywrap() {}