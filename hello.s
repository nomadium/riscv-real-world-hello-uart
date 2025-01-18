.global _start

_start:
    # Main U-Boot use case is to boot Linux kernels.
    # Linux kernel in RISC-V expects to have the hartid of the current core in a0.
    # So by using this bootloader and this de-facto standard, we can rely on that as well.
    # See: https://www.kernel.org/doc/html/next/riscv/boot.html

    # run only one instance
    mv      tp, a0          # Save hart id in tp register
    bnez    tp, forever     # other harts will just spin forever
                            # Note this trivial "kernel" doesn't do much with the hart id
                            # value, but it's good idea to save it, as there are no standard
                            # mechanisms (that I'm aware of in 2025, see comment above)
                            # other than the register mhartid (not accessible in S-mode)
    # setup a stack for C.
    # stack0 is declared in start.c,
    # with a 4096-byte stack per CPU.
    # sp = stack0 + (hartid * 4096)
    la      sp, stack0
    li      a0, 1024*4
    mv      a1, tp
    addi    a1, a1, 1
    mul     a0, a0, a1
    add     sp, sp, a0
    # jump to start() in start.c
    call start

forever:
    wfi
    j       forever
