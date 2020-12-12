SOURCE = bitclock.asm
BINARIES = bitclock.bin

INCLUDE = macro.h vcs.h bitclock_macros.h constants.h variables.h

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
	$(YARN) install
	$(YARN) test

%.bin : %.asm $(INCLUDE)
	$(DASM) $< -o$@ $(DASM_OPTS) -s$(<:.asm=.sym) -L$(<:.asm=.lst)


.PHONY: all clean run test
