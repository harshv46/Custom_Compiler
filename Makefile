all:
	flex a3_lexer.l
	bison -d -Wnone a3_parser.y
	gcc -w lex.yy.c a3_parser.tab.c
