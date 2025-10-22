CC = x86_64-w64-mingw32-gcc
AR = x86_64-w64-mingw32-ar
CFLAGS = -O3 -Wall -static-libgcc
TARGET = libnukedopm.a
SOURCES = vendor/nuked-opm/opm.c
OBJECTS = $(SOURCES:.c=.o)

# This Makefile builds official Nuked-OPM as a static library
# All exported functions follow the official API from opm.h

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(AR) rcs $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: all clean
