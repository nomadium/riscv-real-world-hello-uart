#include "sbi.h"

#define NCPU          8  // maximum number of CPUs

// entry.S needs one stack per CPU.
__attribute__ ((aligned (16))) char stack0[4096 * NCPU];

void main() {
	/* this "kernel" does nothing other than to print something to the console
	 *
	 * check out for https://github.com/mit-pdos/xv6-riscv for ideas on how/what to
	 * implement in an OS kernel */
	for (;;);
}

// entry.S jumps here in supervisor mode on stack0.
void
start()
{
	sbi_ecall_console_puts("hello world!\n");
}
