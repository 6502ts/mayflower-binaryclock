SOURCE = bitclock.asm
BINARIES = bitclock.bin

INCLUDE =

DASM = dasm
DASM_OPTS = -I.. -f3 $(DASM_EXTRA_OPTS)

all: $(BINARIES)

clean:
	-rm *.bin

run: all
	stella $(BINARIES)

debug: all
	stella -debug $(BINARIES)

%.bin : %.asm $(INCLUDE)
	$(DASM) $< -o$@ $(DASM_OPTS)


.PHONY: all clean run
