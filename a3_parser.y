%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol.c"
#include "semantics.c"

extern FILE *yyout;
extern FILE *yyin;
extern FILE *fp;
extern char yyval;
extern int yylineno;


#define INT_T 1
#define CHAR_T 3
#define FLOAT_T 2

FILE *three_address;
list_t *l;
char *temp_buffer;
int count_X=0, *count_flag, scope=-1, flag, *list, *list_symbol,list_index=0;
int init_arr_flag=0, use_arr_flag=0;
int *dimension_list;
int index_count=0, init_list_index=0;
int declaration_arr_flag=0;


%}

%error-verbose

/* YYSTYPE union */
%union{
	int integer;
	univ_type* symbol;
}

%token<integer>	GLOBAL 
%token<symbol>		INTEGER_CONST FLOAT_CONST CHAR_CONST IDEN
%token<integer>	INC_OPERATOR DEC_OPERATOR L_OPERATOR R_OPERATOR
%token<integer>	LE_OPERATOR GE_OPERATOR EQ_OPERATOR NE_OPERATOR AND_OPERATOR OR_OPERATOR
%token<integer>	CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE VOID
%token<integer>	CASE DEFAULT IF ELSE SWITCH WHILE MAIN CONTINUE BREAK RETURN
%type<symbol> 		assignment_expression inclusive_or_expression unary_expression unary_operator primary_expression expression 
%type<symbol>		relational_expression logical_or_expression shift_expression and_expression postfix_expression
%type<symbol> 		multiplication_expression addition_expression exclusive_or_expression equality_expression  init_declarator init declarator logical_and_expression

%start program

%%


program
	:program external_declaration
	| external_declaration
	;

external_declaration
	: { declare=1; } declaration_specifiers gconflict_resolve
	;

declaration_specifiers
	: type_specifier declaration_specifiers
	| type_specifier
	;

declaration
	: declaration_specifiers ';'
	| declaration_specifiers init_declarator_list ';'
	;


gconflict_resolve
	: MAIN { declare=0; incr_scope(); } declarator_main compound_statement { /*hide_scope();*/ }
	| init_declarator_list { declare=0; } ';'

type_specifier
	: INT
	| LONG
	| FLOAT
	| DOUBLE
	| VOID
	| CHAR
	| SHORT
	| SIGNED
	| UNSIGNED
	| GLOBAL VOID
	;

declarator_main
	: '(' { declare=1; } param_list { declare=0; } ')'
	| '(' ')'
	;

compound_statement
	: '{' '}'
	| '{' {
		scope++;
	} block_item_list '}' {
		scope--;
	}
	;

init_declarator_list
	: init_declarator {
		init_arr_flag=0;
		
	}
	| init_declarator_list ',' init_declarator {
		init_arr_flag=0;
	}
	;

init_declarator
	: declarator '=' {
		init_arr_flag=0;
		declare=0;
	} init {
		printf("");
		type_check($1->type, $4->type, yylineno);
		declare=1;
		if(strcmp($1->name, $4->name)!=0)
			fprintf(three_address, "%s = %s\n", $1->name, $4->name);
		$$=$1;
	}
	| declarator { init_arr_flag=0;}
	;

declarator
	: IDEN {
		l = lookup($1->name);
		l->arr_dim=(int*)calloc(10, sizeof(int));
		l->dim=0;
		$$=$1;
	}
	| '(' declarator ')' {
		$$=$2;
	}
	| declarator '(' param_list ')'
	| declarator '(' ')'
	| declarator '(' id_list ')'
	| declarator '[' ']'
	| declarator '[' '*' ']'
	| declarator '[' {
		if(init_arr_flag==0) {
			init_arr_flag=1;
		}
	} assignment_expression {
		l->arr_dim[l->dim++]=atoi(($4->name)+1);
	} ']'
	;

init
	: '{' {
		declaration_arr_flag=1;
		init_list_index=0;
	} init_list '}' {
		declaration_arr_flag=0;
	}
	| assignment_expression {

		$$=$1;
	}
	;

init_list
	: designator_list '=' init{
		printf("");
	}
	| init {
		fprintf(three_address, "%s[%d] = %s\n", l->st_name, init_list_index++, $1->name);
	}
	| init_list ',' designator_list '=' init{
		printf("");
	}
	| init_list ',' init {
		fprintf(three_address, "%s[%d] = %s\n", l->st_name, init_list_index++, $3->name);
	}
	;

direct_abstract_declarator
	: '(' direct_abstract_declarator ')'
	| '(' ')'
	| '(' param_list ')'
	| direct_abstract_declarator '(' ')'
	| direct_abstract_declarator '(' param_list ')'
	| '[' ']'
	| '[' '*' ']'
	| '[' assignment_expression ']'
	| direct_abstract_declarator '[' ']'
	| direct_abstract_declarator '[' '*' ']'
	| direct_abstract_declarator '[' assignment_expression ']'
	;

param_list
	: param_decl
	| param_list ',' param_decl
	;

param_decl
	: declaration_specifiers declarator
	| declaration_specifiers direct_abstract_declarator
	| declaration_specifiers
	;


assignment_expression
	: logical_or_expression {
		$$=$1;
	}
	| unary_expression '=' assignment_expression {
		type_check($1->type, $3->type, yylineno);
		$$=$1;
		if(flag==0)
			fprintf(three_address, "%s = %s\n", $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "%s = %s\n", $1->name, $3->name);
	}
	;


expression
	: assignment_expression {
		$$=$1;
	}
	| expression ',' assignment_expression {
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		$$=univ;
	}
	;

primary_expression
	: IDEN { 
		$$=$1;
	}
	| INTEGER_CONST {
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s\n", count_X, $1->name);
		else
			sprintf(temp_buffer + strlen(temp_buffer), "X%d = %s\n", count_X, $1->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	| FLOAT_CONST {
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s\n", count_X, $1->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s\n", count_X, $1->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	| CHAR_CONST {
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s\n", count_X, $1->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s\n", count_X, $1->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	| '(' expression ')' {
		$$=$2;
	}
	;

postfix_expression
	: primary_expression {
		$$=$1;
	}
	| postfix_expression '[' expression ']' {
		if(use_arr_flag==0){
			l=lookup($1->name);
			use_arr_flag=1;
			index_count=1;
			dimension_list=(int*)calloc(10, sizeof(int));
		}
		type_check(INT_T, $3->type, yylineno);
		if(l!=NULL){
			int temp = atoi(($3->name)+1);
			for(int i=index_count; i<l->dim; i++){
				count_X++;
				if(flag==0)
					fprintf(three_address, "X%d = X%d * X%d\n", count_X, temp, l->arr_dim[i]);
				else
					sprintf(temp_buffer + strlen(temp_buffer), "X%d = X%d * X%d\n", count_X, temp, l->arr_dim[i]);
				temp=count_X;
			}
			dimension_list[index_count-1]=count_X;
			index_count++;
			if(index_count==l->dim+1){
				temp=count_X;
				for(int i=l->dim-2;i>=0;i--){
					count_X++;
					if(flag==0)
						fprintf(three_address, "X%d = X%d + X%d\n", count_X, temp, dimension_list[i]);
					else
						sprintf(temp_buffer + strlen(temp_buffer), "X%d = X%d + X%d\n", count_X, temp, dimension_list[i]);
					temp=count_X;
				}
				use_arr_flag=0;
				char *temp_string = (char*)malloc(50*sizeof(char));
				sprintf(temp_string, "%s[X%d]", l->st_name, count_X);
				univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
				univ->name=temp_string;
				univ->type=$1->type;
				$$=univ;
			}
		}

		
	}
	| postfix_expression INC_OPERATOR {
		use_arr_flag=0;
		if(flag==0)
			fprintf(three_address, "%s = %s + 1\n", $1->name, $1->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "%s = %s + 1\n", $1->name, $1->name);
		$$=$1;
	}
	| postfix_expression DEC_OPERATOR {
		use_arr_flag=0;
		if(flag==0)
			fprintf(three_address, "%s = %s - 1\n", $1->name, $1->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "%s = %s - 1\n", $1->name, $1->name);
		$$=$1;
	}
	;

unary_expression
	: postfix_expression {
		// use_arr_flag=0;
		$$=$1;
	}
	| INC_OPERATOR unary_expression {
		if(flag==0)
			fprintf(three_address, "%s = %s + 1\n", $2->name, $2->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "%s = %s + 1\n", $2->name, $2->name);
		$$=$2;
	}
	| DEC_OPERATOR unary_expression {
		if(flag==0)
			fprintf(three_address, "%s = %s - 1\n", $2->name, $2->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "%s = %s - 1\n", $2->name, $2->name);
		$$=$2;
	}
	| unary_operator unary_expression {
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s %s\n", count_X, $1->name, $2->name);
		else
			sprintf(temp_buffer + strlen(temp_buffer), "X%d = %s %s\n", count_X, $1->name, $2->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$2->type;
		$$=univ;
	}
	;



unary_operator
	: '+' {
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "+");
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=-1;
		$$=univ;
	}
	| '-' {
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "-");
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=-1;
		$$=univ;
	}
	| '~' {
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "~");
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=-1;
		$$=univ;
	}
	| '!' {
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "!");
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=-1;
		$$=univ;
	}
	;

multiplication_expression
	: unary_expression {
		$$=$1;
	}
	| multiplication_expression '*' unary_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s * %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s * %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	| multiplication_expression '/' unary_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s / %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s / %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	| multiplication_expression '%' unary_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s % %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s % %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	;

addition_expression
	: multiplication_expression {
		$$=$1;
	}
	| addition_expression '+' multiplication_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s + %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s + %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	| addition_expression '-' multiplication_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s - %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s - %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	;

shift_expression
	: addition_expression {
		$$=$1;
	}
	| shift_expression L_OPERATOR addition_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s << %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s << %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	| shift_expression R_OPERATOR addition_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s >> %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s >> %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	;

relational_expression
	: shift_expression {
		$$=$1;
	}
	| relational_expression '<' shift_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s < %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s < %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	| relational_expression '>' shift_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s > %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s > %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	| relational_expression LE_OPERATOR shift_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s <= %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s <= %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	| relational_expression GE_OPERATOR shift_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s >= %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d >= %s < %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	;

equality_expression
	: relational_expression {
		$$=$1;
	}
	| equality_expression EQ_OPERATOR relational_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s == %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s == %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	| equality_expression NE_OPERATOR relational_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		fprintf(three_address, "X%d = %s != %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	;

and_expression
	: equality_expression {
		$$=$1;
	}
	| and_expression '&' equality_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s & %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s & %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	;

exclusive_or_expression
	: and_expression {
		$$=$1;
	}
	| exclusive_or_expression '^' and_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s ^ %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s ^ %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	;

inclusive_or_expression
	: exclusive_or_expression {
		$$=$1;
	}
	| inclusive_or_expression '|' exclusive_or_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s | %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s | %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	;

logical_and_expression
	: inclusive_or_expression {
		$$=$1;
	}
	| logical_and_expression AND_OPERATOR inclusive_or_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s && %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer+ strlen(temp_buffer), "X%d = %s && %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	;

logical_or_expression
	: logical_and_expression {
		$$=$1;
	}
	| logical_or_expression OR_OPERATOR logical_and_expression {
		type_check($1->type, $3->type, yylineno);
		count_X++;
		if(flag==0)
			fprintf(three_address, "X%d = %s || %s\n", count_X, $1->name, $3->name);
		else
			sprintf(temp_buffer + strlen(temp_buffer),"X%d = %s || %s\n", count_X, $1->name, $3->name);
		char *temp_string = (char*)malloc(50*sizeof(char));
		sprintf(temp_string, "X%d", count_X);
		univ_type *univ = (univ_type*)malloc(sizeof(univ_type));
		univ->name=temp_string;
		univ->type=$1->type;
		$$=univ;
	}
	;


id_list
	: IDEN
	| id_list ',' IDEN
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list
	| type_specifier
	;

designator_list
	: designator
	| designator_list designator
	;

designator
	: '[' logical_or_expression ']'
	| '.' IDEN
	;

statement
	: label_statement
	| { incr_scope(); } select_statement { hide_scope(); }
	| iter_statement
	| jump_statement
	| compound_statement
	| expression_statement
	;

label_statement
	: IDEN ':' statement
	| CASE {
		flag=1;
	} logical_or_expression { flag=0; } ':' {
		fprintf(three_address, "\n-->Flag %c%d :-\n\n", scope+97, ++count_flag[scope]);
		list[list_index++]=count_flag[scope];
		list_symbol[list_index-1]=atoi(($3->name)+1);
	} statement
	| DEFAULT ':' {
		fprintf(three_address, "\n-->Flag %c%d :-\n\n", scope+97, ++count_flag[scope]);
		list[list_index++]=count_flag[scope];
		list_symbol[list_index-1]=-1;
	} statement
	;


block_item_list
	: block_item
	| block_item_list block_item
	;

block_item
	: { declare=1; } declaration { declare=0; }
	| statement
	;

expression_statement
	: ';'
	| expression ';'
	;

select_statement
	: IF '(' expression ')' {
		fprintf(three_address, "if (%s == 0) goto Flag %c%d :-\n", $3->name, scope+97, ++count_flag[scope]);
	} statement if_tail
	| SWITCH '(' expression ')' {
		fprintf(three_address, "goto Flag %c%d\n", scope+97, ++count_flag[scope]);
		list = (int*)malloc(100*sizeof(int));
		list_symbol = (int*)malloc(100*sizeof(int));
		list[list_index++]=count_flag[scope];
		temp_buffer = (char*)malloc(sizeof(char)*10001);
	} statement {
		fprintf(three_address, "goto Flag %c%d\n", scope+97, ++count_flag[scope]);
		fprintf(three_address, "\n-->Flag %c%d :-\n\n", scope+97, list[0]);
		fprintf(three_address, "%s", temp_buffer);
		for(int i=1;list[i]<=count_flag[scope+1]&&list[i]>0;i++){
			if(list_symbol[i]!=-1)
				fprintf(three_address, "if (%s == X%d) goto Flag %c%d :-\n", $3->name, list_symbol[i], scope+1+97, list[i]);
			else{
				fprintf(three_address, "goto Flag %c%d\n", scope+1+97, list[i]);
				break;
			}
		}
		fprintf(three_address, "\n-->Flag %c%d :-\n\n", scope+97, count_flag[scope]);
	}
	;

if_tail
	: ELSE {
		fprintf(three_address, "goto Flag %c%d\n", scope+97, ++count_flag[scope]);
		fprintf(three_address, "\n-->Flag %c%d :-\n\n", scope+97, count_flag[scope]-1);
		hide_scope();
		incr_scope(); 
	} statement {
		fprintf(three_address, "\n-->Flag %c%d :-\n\n", scope+97, count_flag[scope]);
	}
	| {
		fprintf(three_address, "\n-->Flag %c%d :-\n\n", scope+97, count_flag[scope]);
	}
	;

iter_statement
	: WHILE {
		fprintf(three_address, "\n-->Flag %c%d :-\n\n", scope+97, ++count_flag[scope]);
	} while_tail
	;

while_tail
	: '(' expression ')' {
		incr_scope();
		fprintf(three_address, "if (%s == 0) goto Flag %c%d :-\n", $2->name, scope+97, ++count_flag[scope]);
	} statement {
		hide_scope();
		fprintf(three_address, "goto Flag %c%d\n", scope+97, count_flag[scope]-1);
		fprintf(three_address, "\n-->Flag %c%d :-\n\n", scope+97, count_flag[scope]);
	}
	;

jump_statement
	:RETURN ';'
	| RETURN expression ';'
	;



%%
#include <stdio.h>

void yyerror(const char *msg)
{
	fflush(stdout);
	fprintf(stderr, "*** %s at line %d\n", msg, yylineno);
}

int main(int argc, char *argv[])
{
	init_hash_table();
	count_flag=(int*)calloc(26, sizeof(int));
	dimension_list=(int*)calloc(10, sizeof(int));
	yyin = fopen(argv[1], "r");
	
	three_address = fopen("ThreeAddressCode.txt", "w");

    if(!yyparse())
		printf("\nProgram Parsing Completed\n");
	else
		printf("\nProgram Parsing Failed\n");
	
	fclose(yyin);

	// symbol table dump
	yyout = fopen("table_dump.out", "w");
	table_dump(yyout);
	fclose(yyout);	

    return 0;
}
