/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <string.h>

void append(char* s, char c)
{
        int len = strlen(s);
        s[len] = c;
        s[len+1] = '\0';
}


/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed"); \
	else if (buf[0]=='\n') curr_lineno++;

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

int comment_depth;

/*
 *  Add Your own definitions here
 */

%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
%Start COMMENT
%X STRING

%%

[ \t]					        ;
\n	++curr_lineno; printf("Line: %i\n", curr_lineno);

[0-9]+	{
	printf("\n+++ INT_CONST: %d\n", atoi(yytext));
	yylval.symbol = inttable.add_string(yytext);
	return (INT_CONST);
}

 /* One line comment */
--.*	;

 /*
  *  Nested comments
  */
"(*"	{ BEGIN(COMMENT); comment_depth++; }
<COMMENT>"*)"	{
		comment_depth--;
		if (comment_depth == 0) BEGIN(0);
	}
<COMMENT>.	;

 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for
  *  \n \t \b \f, the result is c.
  *
  */

\"			{ BEGIN(STRING); strcpy(string_buf,""); }
<STRING>[^\\\"]*	{
				strcat(string_buf, yytext);
				// TODO: lengh testing
			}

<STRING>\\.		{
				switch (yytext[1])
				{
					case 'b': append(string_buf, '\b'); break;
					case 't': append(string_buf, '\t'); break;
					case 'n': append(string_buf, '\n'); break;
					case 'f': append(string_buf, '\f'); break;
					default: append(string_buf, yytext[1]);
				}
			}
<STRING>\\$		curr_lineno++;
<STRING>\"		{
				BEGIN(INITIAL);
				yylval.symbol = inttable.add_string(string_buf);
				return (STR_CONST);
			}


.                       printf("Unknown token!\n\"%s\"\n", yytext); //yyterminate();


%%
