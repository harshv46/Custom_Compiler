%option yylineno

O   [0-7]
D   [0-9]
NZ  [1-9]
L   [a-zA-Z_]
A   [a-zA-Z_0-9]
H   [a-fA-F0-9]
HP  (0[xX])
E   ([Ee][+-]?{D}+)
P   ([Pp][+-]?{D}+)
CP  (u|U|L)
SP  (u8|u|U|L)
ES  (\\(['"\?\\abfnrtv]|[0-7]{1,3}|x[a-fA-F0-9]+))
WS  [ \t\v\n\f]
FS  (f|F|l|L)
IS  (((u|U)(l|L|ll|LL)?)|((l|L|ll|LL)(u|U)?))

%{

#include <stdio.h>
#include "semantics.h"
#include "symbol.h"
#include "a3_parser.tab.h"

#define INT_T 1
#define CHAR_T 3
#define FLOAT_T 2

extern void yyerror(const char *);

static void comment(void);

int cur_type=0;



%}

%%
"/*"                    { comment(); }
"//".*                  {  }


"unsigned"				{ return(UNSIGNED); }
"void"					{ return(VOID); }
"switch"				{ return(SWITCH); }
"else"					{ return(ELSE); }
"break"					{ return(BREAK); }
"while"					{ return(WHILE); }
"double"				{ return(DOUBLE); }
"int"					{ cur_type=INT_T;  return(INT);
                            
                        }
"float"					{ cur_type=FLOAT_T; return(FLOAT);
                            
                        }
"long"					{ return(LONG); }
"return"				{ return(RETURN); }
"short"					{ return(SHORT); }
"signed"				{ return(SIGNED); }
"continue"				{ return(CONTINUE); }
"__global__"            { return(GLOBAL); }
"default"				{ return(DEFAULT); }
"main"					{ return(MAIN); }
"if"					{ return(IF); }
"case"					{ return(CASE); }
"char"					{ cur_type=CHAR_T;
                            return(CHAR);
                            
                        }


{HP}{H}+{IS}?				    { 
                                    char *dest = (char*)malloc(12*sizeof(char));
                                    strncpy(dest, yytext, strlen(yytext));
                                    univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
                                    univ->name=dest;
                                    univ->type=INT_T;
                                    yylval.symbol=univ;
                                    return INTEGER_CONST; 
                                }
{NZ}{D}*{IS}?				    { 
                                    char *dest = (char*)malloc(12*sizeof(char));
                                    strncpy(dest, yytext, strlen(yytext));
                                    univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
                                    univ->name=dest;
                                    univ->type=INT_T;
                                    yylval.symbol=univ;
                                    return INTEGER_CONST; 
                                }
"0"{O}*{IS}?				    { 
                                    char *dest = (char*)malloc(12*sizeof(char));
                                    strncpy(dest, yytext, strlen(yytext));
                                    univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
                                    univ->name=dest;
                                    univ->type=INT_T;
                                    yylval.symbol=univ;
                                    return INTEGER_CONST; 
                                }


{CP}?"'"([^'\\\n]|{ES})+"'"		{ 
                                    char *dest = (char*)malloc(12*sizeof(char));
                                    strncpy(dest, yytext, strlen(yytext));
                                    univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
                                    univ->name=dest;
                                    univ->type=CHAR_T;
                                    yylval.symbol=univ;
                                    return CHAR_CONST; 
                                }

{D}+{E}{FS}?				    { 
                                    char *dest = (char*)malloc(12*sizeof(char));
                                    strncpy(dest, yytext, strlen(yytext));
                                    univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
                                    univ->name=dest;
                                    univ->type=FLOAT_T;
                                    yylval.symbol=univ;
                                    return FLOAT_CONST; 
                                }
{D}*"."{D}+{E}?{FS}?			{ 
                                    char *dest = (char*)malloc(12*sizeof(char));
                                    strncpy(dest, yytext, strlen(yytext));
                                    univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
                                    univ->name=dest;
                                    univ->type=FLOAT_T;
                                    yylval.symbol=univ;
                                    return FLOAT_CONST; 
                                }
{D}+"."{E}?{FS}?			    { 
                                    char *dest = (char*)malloc(12*sizeof(char));
                                    strncpy(dest, yytext, strlen(yytext));
                                    univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
                                    univ->name=dest;
                                    univ->type=FLOAT_T;
                                    yylval.symbol=univ;
                                    return FLOAT_CONST; 
                                }
{HP}{H}+{P}{FS}?			    { 
                                    char *dest = (char*)malloc(12*sizeof(char));
                                    strncpy(dest, yytext, strlen(yytext));
                                    univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
                                    univ->name=dest;
                                    univ->type=FLOAT_T;
                                    yylval.symbol=univ;
                                    return FLOAT_CONST; 
                                }
{HP}{H}*"."{H}+{P}{FS}?			{ 
                                    char *dest = (char*)malloc(12*sizeof(char));
                                    strncpy(dest, yytext, strlen(yytext));
                                    univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
                                    univ->name=dest;
                                    univ->type=FLOAT_T;
                                    yylval.symbol=univ;
                                    return FLOAT_CONST; 
                                }
{HP}{H}+"."{P}{FS}?			    { 
                                    char *dest = (char*)malloc(12*sizeof(char));
                                    strncpy(dest, yytext, strlen(yytext));
                                    univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
                                    univ->name=dest;
                                    univ->type=FLOAT_T;
                                    yylval.symbol=univ;
                                    return FLOAT_CONST; 
                                }




"<"					    { return '<'; }
">"					    { return '>'; }
"^"					    { return '^'; }
"&"					    { return '&'; }
"|"					    { return '|'; }
"?"					    { return '?'; }
"!"					    { return '!'; }
"~"					    { return '~'; }
"="                     { return '='; }
"("					    { return '('; }
")"					    { return ')'; }
"[" 				    { return '['; }
"]" 				    { return ']'; }
","					    { return ','; }
":"					    { return ':'; }
"."					    { return '.'; }
";"					    { return ';'; }
"{" 				    { return '{'; }
"}" 				    { return '}'; }
"%"					    { return '%'; }
"-"					    { return '-'; }
"+"					    { return '+'; }
"*"					    { return '*'; }
"/"					    { return '/'; }
">>"					{ return R_OPERATOR; }
"<<"					{ return L_OPERATOR; }
"=="					{ return EQ_OPERATOR; }
"!="					{ return NE_OPERATOR; }
"&&"                    { return AND_OPERATOR; }
"--"					{ return DEC_OPERATOR; }
"++"					{ return INC_OPERATOR; }
">="					{ return GE_OPERATOR; }
"<="					{ return LE_OPERATOR; }
"||"                    { return OR_OPERATOR; }

{L}{A}*					{ insert(yytext, strlen(yytext), cur_type, yylineno);
                            univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
                            char *dest = (char*)malloc(12*sizeof(char));
                            strncpy(dest, yytext, strlen(yytext));
                            univ->name=dest;
                            univ->type=get_type(dest);
                            yylval.symbol=univ;
                            return IDEN; }

{WS}+					{ }
.					    { }

%%

int yywrap(void)        /* called at end of input */
{
    return 1;           /* terminate now */
}

static void comment(void)
{
    int c;

    while ((c = input()) != 0)
        if (c == '*')
        {
            while ((c = input()) == '*')
                ;

            if (c == '/')
                return;

            if (c == 0)
                break;
        }
    yyerror("unterminated comment");
}
