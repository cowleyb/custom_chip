CFLAGS = `pkg-config --cflags sdl3`
LDFLAGS = `pkg-config --libs sdl3`
CC = gcc
TARGET = build/clear
SRC = clear.c

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)


clean:
	rm -f $(TARGET)