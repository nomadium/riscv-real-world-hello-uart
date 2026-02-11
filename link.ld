SECTIONS
{
  /* 0x80200000 is standard for RISC-V Linux kernels, avoids OpenSBI at 0x80000000 */
  . = 0x80200000;
  .text : { *(.text) }
  .data : { *(.data) }
  .bss  : { *(.bss) }
}