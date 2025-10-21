CC = x86_64-w64-mingw32-gcc
CFLAGS = -O3 -Wall -shared -static-libgcc -static-libstdc++
TARGET = nukedopm.dll
LEGACY_TARGET = ym2151.dll
SOURCES = vendor/nuked-opm/opm.c
OBJECTS = $(SOURCES:.c=.o)

# This Makefile builds official Nuked-OPM as a shared library
# All exported functions follow the official API from opm.h

all: $(TARGET) $(LEGACY_TARGET)

$(TARGET): $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $^

# Create legacy name for backward compatibility
$(LEGACY_TARGET): $(TARGET)
	cp $(TARGET) $(LEGACY_TARGET)

clean:
	rm -f $(TARGET) $(LEGACY_TARGET)

.PHONY: all clean
