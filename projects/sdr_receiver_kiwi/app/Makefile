CFLAGS = -O3 -march=armv7-a -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard -ffast-math -fsingle-precision-constant -mvectorize-with-neon-quad

all: write-c2-files

write-c2-files: write-c2-files.c
	gcc $(CFLAGS) -o $@ $^ -lm

clean:
	rm -rf write-c2-files
