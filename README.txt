#README

To complie do either of the following:

1. make   //(this will work if make is installed)

OR

2. flex a3_lexer.l
   bison -d -Wnone a3_parser.y
   gcc -w lex.yy.c a3_parser.tab.c


To parse a file afterwards, do:

1. ./a.out path_to_file

For ex:
	./a.out /mnt/c/users/desktop/SampleInputs_Assignment2/test4.c  //(path syntax will differ in case of different terminals)

		or if the file is in the same folder, do:

	./a.out test4.c

see ThreeAddressCode.txt for three address code.