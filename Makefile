SRCS = main.m
CFLAGS = -Werror

all:
	objfw-compile $(CFLAGS) -lobjirc $(SRCS) -o lolirc

clean:
	rm -f $(SRCS:.m=.o) lolirc

.PHONY: all clean
