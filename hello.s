.global _start

_start:
    # Main U-Boot use case is to boot Linux kernels.
    # Linux kernel in RISC-V expects to have the hartid of the current core in a0.
    # So by using this bootloader and this de-facto standard, we can rely on that as well.
    # See: https://www.kernel.org/doc/html/next/riscv/boot.html

    # run only one instance
    mv      tp, a0          # Save hart id in tp register
    bnez    tp, forever     # other harts will just spin forever

    # prepare for the loop
    li      s1, 0x10000000  # UART output register   
    la      s2, hello       # load string start addr into s2
    addi    s3, s2, 13      # set up string end addr in s3

loop:
    lb      s4, 0(s2)       # load next byte at s2 into s4
    sb      s4, 0(s1)       # write byte to UART register 
    addi    s2, s2, 1       # increase s2
    blt     s2, s3, loop    # branch back until end addr (s3) reached

forever:
    wfi
    j       forever


.section .data

hello:
  .string "hello world!\n"
  
