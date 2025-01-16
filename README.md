# riscv-real-world-hello-uart
Minimal real world bare-metal RISC-V assembly example code with UART output for execution in QEMU

The point of this repository is that the typical RISC-V board available to common users
are set up to boot with U-Boot and use OpenSBI firmware. So this repository just attempts to
clarify how to program, build and run a minimal bare-metal program on such hardware provided
with a typical firmware and bootloader.

For a truly minimal example without firmware and bootloader, just checkout https://github.com/nomadium/riscv-hello-uart (or from where I copied it: https://github.com/krakenlake/riscv-hello-uart).

## Requirements
### Tools:
- riscv64-unknown-elf-gcc
- riscv64-unknown-elf-ld
- riscv64-unknown-elf-objcopy
- opensbi
- u-boot-qemu
- u-boot-tools


### Building:
make

### Execution:
qemu-system-riscv64

## Building
make all

## Running
make run
