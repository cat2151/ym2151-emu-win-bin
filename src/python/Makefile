CC = x86_64-w64-mingw32-gcc
CFLAGS = -O3 -Wall -shared -static-libgcc -static-libstdc++
TARGET = ym2151.dll
SOURCES = vendor/nuked-opm/opm.c
OBJECTS = $(SOURCES:.c=.o)

all: $(TARGET)

$(TARGET): $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(TARGET)

.PHONY: all clean
