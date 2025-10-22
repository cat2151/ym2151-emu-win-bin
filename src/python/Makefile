CC = x86_64-w64-mingw32-gcc
CFLAGS = -O3 -Wall -shared -static-libgcc -static-libstdc++
TARGET = nukedopm.dll
SOURCES = vendor/nuked-opm/opm.c
OBJECTS = $(SOURCES:.c=.o)

# This Makefile builds official Nuked-OPM as a shared library
# All exported functions follow the official API from opm.h

all: $(TARGET)

$(TARGET): $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(TARGET)

.PHONY: all clean
