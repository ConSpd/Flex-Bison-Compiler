all:
	bison -d bison_code.y
	flex flex_code.l
	gcc -o parser_code bison_code.tab.c lex.yy.c 
	./parser_code

clean:
	rm bison_code.tab.c bison_code.tab.h lex.yy.c parser_code
