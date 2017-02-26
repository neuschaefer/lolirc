SRCS = main.m
CFLAGS += -Wall --arc

all: lolirc

lolirc: $(SRCS)
	objfw-compile $(CFLAGS) -lobjirc $(SRCS) -o $@

clean:
	rm -f $(SRCS:.m=.o) lolirc

.PHONY: all clean
