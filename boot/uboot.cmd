setenv kboot_addr_r 0x85000000
dhcp
tftp ${kboot_addr_r} kernel.itb
bootm ${kboot_addr_r}
