# Prerequisites

* [dasm](https://dasm-assembler.github.io/)
* [6502.ts](https://github.com/6502ts/6502.ts)
* [stella](https://stella-emu.github.io/)

# How to build

```
make DASM_EXTRA_OPTS=-IPATH_TO/6502.ts/aux/2600
```
# How to run in simulator

```
make run
```