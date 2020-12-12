# Binary Clock for Atari 2600

This is an implementation of a binaray clock for the Atari 2600.
It takes advantage of [6502.ts](https://github.com/6502ts/6502.ts) testing capabilities.

## Prerequisites

In order to build the software:
* Gnu MAKE
* [dasm](https://dasm-assembler.github.io/)

In order to run the tests:
* [NodeJS](https://nodejs.org/en/)
* [Yarn](https://yarnpkg.com)

In order to run the software in an emulator:
* [stella](https://stella-emu.github.io/)

## Build

```
make
```

this will create the ROM file `bitclock.bin`

## Run the tests

```
make test
```

Note: some package manager will install yarn as `yarnpkg` command, like on ubuntu.
In this case, set the environment variable `YARN`,

```
YARN=yarnpkg make test
```
or
```
export YARN=yarnpkg
make test
```

## Run in emulator

```
make run
```
