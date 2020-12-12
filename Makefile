SOURCE = bitclock.asm
BINARIES = bitclock.bin

INCLUDE =

DASM ?= dasm
DASM_OPTS = -I.. -f3 $(DASM_EXTRA_OPTS)

YARN ?= yarn

all: $(BINARIES)

clean:
	-rm -f *.bin *.sym *.lst

run: all
	stella $(BINARIES)

debug: all
	stella -debug $(BINARIES)

test:
	$(YARN) test

%.bin : %.asm $(INCLUDE)
	$(DASM) $< -o$@ $(DASM_OPTS) -s$(<:.asm=.sym) -L$(<:.asm=.lst)


.PHONY: all clean run test
