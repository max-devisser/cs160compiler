BISON	= bison -d -v
FLEX	= flex
CC		= gcc
CXX		= g++
FLAGS   = # add the -g flag to compile with debugging output for gdb
TARGET	= lang

OBJS = ast.o parser.o lexer.o main.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) -o $(TARGET) $(OBJS)

lexer.o: lexer.l
	$(FLEX) -o lexer.cpp lexer.l
	$(CXX) $(FLAGS) -c -o lexer.o lexer.cpp

parser.o: parser.y
	$(BISON) -o parser.cpp parser.y
	$(CXX) $(FLAGS) -c -o parser.o parser.cpp

genast: ast.cpp

ast.cpp:
	python3 genast.py -i lang.def -o ast

ast.o: ast.cpp
	$(CXX) $(FLAGS) -c -o ast.o ast.cpp

main.o: main.cpp
	$(CXX) $(FLAGS) -c -o main.o main.cpp

.PHONY: run
run: $(TARGET)
	@python3 runtests.py -v

.PHONY: diff
diff: $(TARGET)
	python3 runtests.py | diff - output.txt

.PHONY: clean
clean:
	rm -f *.o *~ lexer.cpp parser.cpp parser.hpp ast.cpp ast.hpp parser.output $(TARGET)
