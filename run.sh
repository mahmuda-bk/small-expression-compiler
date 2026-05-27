#!/bin/bash

flex lexer.l
bison -d parser.y
gcc lex.yy.c parser.tab.c symbol_table.c -o compiler -lfl -lm

if [ $? -eq 0 ]; then
    ./compiler < input.txt
else
    echo "Compilation Failed"
fi
