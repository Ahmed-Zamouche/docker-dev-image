CC:=$(shell which clang)
CXX:=$(shell which clang++)
LD:=$(shell which lld)

CFLAGS:= -O0 -g -Wall -Wextra -Werror -DNDEBUG
LDFLAGS:=
LDLIBS:= -lm -lpthread -rdynamic

all:
	mkdir -p build/printf
	${CC} -std=c99 ${CFLAGS} -c printf/printf.c -o build/printf/printf.o
	${CXX} -std=c++17 ${CFLAGS} -c common.cpp -o build/common.o
	${CXX} -std=c++17 ${CFLAGS} -c main.cpp -o build/main.o
	${CXX} -std=c++17 ${CFLAGS} ${LDFLAGS} ${LDLIBS} build/main.o build/common.o build/printf/printf.o -o build/a.out
clean:
	rm -rf build/*

