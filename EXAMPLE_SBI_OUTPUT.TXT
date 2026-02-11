```
OpenSBI v1.7
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name               : riscv-virtio,qemu
Platform Features           : medeleg
Platform HART Count         : 2
Platform IPI Device         : aclint-mswi
Platform Timer Device       : aclint-mtimer @ 10000000Hz
Platform Console Device     : uart8250
Platform HSM Device         : ---
Platform PMU Device         : ---
Platform Reboot Device      : syscon-reboot
Platform Shutdown Device    : syscon-poweroff
Platform Suspend Device     : ---
Platform CPPC Device        : ---
Firmware Base               : 0x80000000
Firmware Size               : 329 KB
Firmware RW Offset          : 0x40000
Firmware RW Size            : 73 KB
Firmware Heap Offset        : 0x48000
Firmware Heap Size          : 41 KB (total), 2 KB (reserved), 12 KB (used), 26 KB (free)
Firmware Scratch Size       : 4096 B (total), 1400 B (used), 2696 B (free)
Runtime SBI Version         : 3.0
Standard SBI Extensions     : ipi,pmu,srst,sse,hsm,rfnc,fwft,time,base,legacy,dbcn,dbtr
Experimental SBI Extensions : none

Domain0 Name                : root
Domain0 Boot HART           : 0
Domain0 HARTs               : 0*,1*
Domain0 Region00            : 0x0000000000100000-0x0000000000100fff M: (I,R,W) S/U: (R,W)
Domain0 Region01            : 0x0000000010000000-0x0000000010000fff M: (I,R,W) S/U: (R,W)
Domain0 Region02            : 0x0000000002000000-0x000000000200ffff M: (I,R,W) S/U: ()
Domain0 Region03            : 0x0000000080040000-0x000000008005ffff M: (R,W) S/U: ()
Domain0 Region04            : 0x0000000080000000-0x000000008003ffff M: (R,X) S/U: ()
Domain0 Region05            : 0x000000000c400000-0x000000000c5fffff M: (I,R,W) S/U: (R,W)
Domain0 Region06            : 0x000000000c000000-0x000000000c3fffff M: (I,R,W) S/U: (R,W)
Domain0 Region07            : 0x0000000000000000-0xffffffffffffffff M: () S/U: (R,W,X)
Domain0 Next Address        : 0x0000000080200000
Domain0 Next Arg1           : 0x0000000082200000
Domain0 Next Mode           : S-mode
Domain0 SysReset            : yes
Domain0 SysSuspend          : yes

Boot HART ID                : 0
Boot HART Domain            : root
Boot HART Priv Version      : v1.12
Boot HART Base ISA          : rv64imafdch
Boot HART ISA Extensions    : sstc,zicntr,zihpm,zicboz,zicbom,sdtrig,svadu
Boot HART PMP Count         : 16
Boot HART PMP Granularity   : 2 bits
Boot HART PMP Address Bits  : 54
Boot HART MHPM Info         : 16 (0x0007fff8)
Boot HART Debug Triggers    : 2 triggers
Boot HART MIDELEG           : 0x0000000000001666
Boot HART MEDELEG           : 0x0000000000f0b509
```

# OpenSBI Boot Messages: A Complete Walkthrough

OpenSBI (Open Source Supervisor Binary Interface) is the standard firmware layer for RISC-V that runs in **Machine mode (M-mode)**, the highest privilege level. It provides services to the operating system running in **Supervisor mode (S-mode)**.

Let me explain every single line.

---

## Banner and Version

```
OpenSBI v1.7
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|
```

**Version**: OpenSBI v1.7 - this is the release version of the firmware.

**ASCII Art**: The logo spells "OpenSBI" in stylized text. This is just branding - it confirms OpenSBI is running and helps visually identify the boot stage in console output.

---

## Platform Information

```
Platform Name               : riscv-virtio,qemu
```

**Platform Name**: Identifies the hardware platform. This comes from the Device Tree's `/compatible` property. Here it's QEMU's virtual RISC-V machine ("virt") with VirtIO devices. On real hardware, you'd see something like `sifive,hifive-unmatched-a00` or `starfive,visionfive-2`.

---

```
Platform Features           : medeleg
```

**Platform Features**: Special capabilities this platform supports.

- **medeleg**: Machine Exception Delegation. This means the platform supports delegating certain exceptions from M-mode to S-mode. Without delegation, every exception would trap to M-mode (OpenSBI), even ones the OS should handle. With `medeleg`, exceptions like page faults go directly to the OS kernel, improving performance.

Other possible features include `mideleg` (interrupt delegation), `timer` (hardware timer), etc.

---

```
Platform HART Count         : 2
```

**HART Count**: Number of Hardware Threads (HARTs). RISC-V terminology for CPU cores/threads. This QEMU instance was started with `-smp 2`, so there are 2 HARTs (hart 0 and hart 1).

In RISC-V, each HART:
- Has its own registers and program counter
- Can execute independently
- Has a unique hart ID (accessible via `mhartid` CSR in M-mode)

---

```
Platform IPI Device         : aclint-mswi
```

**IPI Device**: Inter-Processor Interrupt mechanism. How one HART signals another.

**ACLINT-MSWI**: Advanced Core Local Interruptor - Machine Software Interrupt. This is a memory-mapped device where writing to a specific address triggers a software interrupt on a target HART. Used for:
- Waking up a sleeping HART
- Signaling work to other HARTs
- Implementing spinlocks and synchronization

The ACLINT specification defines standard addresses:
- `0x02000000` base for MSWI (Machine Software Interrupt)
- Writing 1 to `base + (hartid * 4)` triggers MSI on that hart

---

```
Platform Timer Device       : aclint-mtimer @ 10000000Hz
```

**Timer Device**: Hardware timer for timekeeping and scheduling.

**ACLINT-MTIMER**: The machine timer device running at **10 MHz** (10,000,000 Hz = 10 million ticks per second). Each tick is 100 nanoseconds.

The timer provides:
- `mtime`: A 64-bit counter that increments at the specified frequency
- `mtimecmp[hart]`: Compare registers - when `mtime >= mtimecmp[hart]`, a timer interrupt fires on that HART

This is how the OS implements:
- Preemptive scheduling (timer interrupts)
- `sleep()` and `usleep()` functions
- Timekeeping (`gettimeofday()`)

At 10MHz, the timer wraps around after ~58,000 years, so overflow isn't a concern.

---

```
Platform Console Device     : uart8250
```

**Console Device**: How OpenSBI outputs text (what you're reading!).

**UART 8250**: A classic serial port controller design from 1987, still widely emulated. QEMU's virt machine emulates an 8250-compatible UART at address `0x10000000`.

The 8250 is register-compatible with:
- 16450, 16550, 16550A (improved versions with FIFOs)
- Most PC serial ports
- Many embedded UART implementations

OpenSBI writes characters to the UART's transmit register for output.

---

```
Platform HSM Device         : ---
```

**HSM Device**: Hart State Management. Hardware mechanism for controlling HART power states.

**`---`**: Not available. This means there's no dedicated hardware for:
- Powering individual HARTs on/off
- Putting HARTs into deep sleep states

On real hardware with HSM, you could:
- Start/stop individual cores dynamically
- Implement CPU hotplug
- Save power by shutting down unused cores

Without HSM, all HARTs start at boot and can only use WFI (Wait For Interrupt) for light sleep.

---

```
Platform PMU Device         : ---
```

**PMU Device**: Performance Monitoring Unit.

**`---`**: Not available in this QEMU configuration. A PMU would provide:
- Hardware performance counters
- Cache miss/hit statistics
- Branch prediction statistics
- Cycle counts
- Instruction counts

Used for profiling and performance analysis. Real RISC-V CPUs typically have PMUs with counters accessible via `hpmcounter` CSRs.

---

```
Platform Reboot Device      : syscon-reboot
```

**Reboot Device**: How to restart the system.

**syscon-reboot**: System Controller reboot mechanism. A memory-mapped register that triggers system reset when written to. In QEMU virt:
- Address: `0x100000` (part of the "test" device)
- Writing `0x5555` triggers reset
- Writing `0x7777` triggers poweroff

This is how `reboot` command works at the firmware level.

---

```
Platform Shutdown Device    : syscon-poweroff
```

**Shutdown Device**: How to power off the system.

**syscon-poweroff**: Similar to reboot but triggers complete power-off. In QEMU:
- Writing `0x5555` to the syscon triggers shutdown
- QEMU process exits

This is how `poweroff` or `shutdown -h now` works.

---

```
Platform Suspend Device     : ---
```

**Suspend Device**: System-wide suspend/sleep mechanism.

**`---`**: Not available. Would enable:
- Suspend to RAM (S3 sleep state)
- Hibernate
- System-wide low-power states

Not emulated in QEMU virt machine.

---

```
Platform CPPC Device        : ---
```

**CPPC Device**: Collaborative Processor Performance Control.

**`---`**: Not available. CPPC is a standard interface for:
- CPU frequency scaling
- Dynamic voltage and frequency scaling (DVFS)
- Power management between OS and firmware

Used by `cpufreq` drivers in Linux to adjust CPU speed for power/performance tradeoffs.

---

## Firmware Memory Layout

```
Firmware Base               : 0x80000000
```

**Firmware Base**: Where OpenSBI is loaded in physical memory.

**0x80000000** (2 GB): This is the standard start of RAM on RISC-V systems. OpenSBI occupies the beginning of RAM. The address `0x80000000` is chosen because:
- RISC-V convention places RAM at this address
- It's a nice round number (2^31)
- Leaves lower addresses for memory-mapped I/O

---

```
Firmware Size               : 329 KB
```

**Firmware Size**: Total size of OpenSBI binary.

**329 KB**: The complete OpenSBI firmware image. This includes:
- M-mode trap handlers
- SBI call implementations
- Platform-specific drivers
- Initialization code

This is quite small for a firmware layer - OpenSBI is designed to be minimal.

---

```
Firmware RW Offset          : 0x40000
```

**RW Offset**: Offset from base where read-write data begins.

**0x40000** (256 KB from base = `0x80040000`): OpenSBI's memory is divided into:
- **Read-only section** (0x80000000 - 0x8003FFFF): Code and constant data
- **Read-write section** (0x80040000+): Variables, stacks, heap

The RO section can be protected by PMP (Physical Memory Protection) to prevent accidental modification.

---

```
Firmware RW Size            : 73 KB
```

**RW Size**: Size of the read-write section.

**73 KB**: Space for:
- Global variables
- Per-HART stacks
- Heap allocations
- Runtime data structures

---

```
Firmware Heap Offset        : 0x48000
```

**Heap Offset**: Where dynamic memory allocation begins.

**0x48000** (0x80048000 absolute): The heap is used for:
- Dynamic data structures
- Platform-specific allocations
- Temporary buffers

---

```
Firmware Heap Size          : 41 KB (total), 2 KB (reserved), 12 KB (used), 26 KB (free)
```

**Heap Size Breakdown**:

- **41 KB total**: Total heap space available
- **2 KB reserved**: Set aside for specific purposes (emergency allocations, alignment padding)
- **12 KB used**: Currently allocated
- **26 KB free**: Available for future allocations

This shows OpenSBI's memory usage at the moment this message is printed (during initialization). The heap is used sparingly since OpenSBI is mostly stateless.

---

```
Firmware Scratch Size       : 4096 B (total), 1400 B (used), 2696 B (free)
```

**Scratch Size**: Per-HART scratch space.

**4096 B (4 KB) per HART**: Each HART gets its own "scratch" area for:
- Trap handler state
- Temporary storage during SBI calls
- Per-HART variables

The scratch area is pointed to by the `mscratch` CSR, allowing quick access during trap handling.

- **1400 B used**: Current per-HART state
- **2696 B free**: Available per HART

---

## SBI Interface

```
Runtime SBI Version         : 3.0
```

**SBI Version**: The Supervisor Binary Interface specification version.

**v3.0**: This is the protocol version that S-mode software (Linux, etc.) uses to call M-mode services. Version 3.0 is recent and includes:
- Standard extension discovery
- Improved error handling
- New extensions for hardware management

Think of SBI like BIOS interrupts on x86 - a standardized way for the OS to request firmware services.

---

```
Standard SBI Extensions     : ipi,pmu,srst,sse,hsm,rfnc,fwft,time,base,legacy,dbcn,dbtr
```

**Standard Extensions**: SBI features this firmware implements.

| Extension | Name | Purpose |
|-----------|------|---------|
| **base** | Base Extension | Version query, extension probing |
| **legacy** | Legacy Extensions | Old v0.1 SBI calls (deprecated) |
| **time** | Timer Extension | Set timer (`sbi_set_timer`) |
| **ipi** | IPI Extension | Send inter-processor interrupts |
| **rfnc** | Remote Fence | TLB/cache maintenance across HARTs |
| **hsm** | Hart State Management | Start/stop/suspend HARTs |
| **srst** | System Reset | Reboot/shutdown system |
| **pmu** | PMU Extension | Performance counter access |
| **dbcn** | Debug Console | Console I/O for debugging |
| **sse** | Supervisor Software Events | Event notification mechanism |
| **fwft** | Firmware Features | Query/set firmware features |
| **dbtr** | Debug Triggers | Hardware breakpoint control |

Each extension has an ID and the OS can probe for support via `sbi_probe_extension()`.

---

```
Experimental SBI Extensions : none
```

**Experimental Extensions**: Non-standard or draft extensions.

**none**: No experimental features enabled. Experimental extensions are vendor-specific or draft specifications being tested before standardization.

---

## Domain Configuration

Domains in OpenSBI provide isolation and resource partitioning. Think of them like virtual machines at the firmware level.

```
Domain0 Name                : root
```

**Domain Name**: Identifier for this domain.

**root**: The primary/default domain. Multiple domains could exist for:
- Running multiple OSes
- Trusted execution environments
- Hypervisor configurations

Most simple setups have just the "root" domain.

---

```
Domain0 Boot HART           : 0
```

**Boot HART**: Which HART boots the OS.

**HART 0**: The first HART (hart ID 0) is designated to:
- Run initialization code
- Load and start the bootloader/OS
- Other HARTs typically wait until signaled

This is similar to the BSP (Bootstrap Processor) concept on x86.

---

```
Domain0 HARTs               : 0*,1*
```

**Domain HARTs**: Which HARTs belong to this domain.

**0\*,1\***: HARTs 0 and 1 are assigned to domain0. The `*` indicates these HARTs are "allowed" to boot into this domain. This listing would be important with multiple domains where HARTs are partitioned.

---

## Memory Regions (PMP Configuration)

The next section defines Physical Memory Protection regions. PMP is a RISC-V hardware feature that controls memory access permissions for different privilege modes.

```
Domain0 Region00            : 0x0000000000100000-0x0000000000100fff M: (I,R,W) S/U: (R,W)
```

**Region00**: First memory region definition.

- **Address Range**: `0x100000-0x100fff` (4 KB at 1 MB)
- **M-mode permissions**: `(I,R,W)` - Instruction fetch, Read, Write
- **S/U-mode permissions**: `(R,W)` - Read, Write (no execute!)

This is the **syscon/test device** region (reset/poweroff registers). S-mode can read/write but not execute code here (which would make no sense for I/O registers).

---

```
Domain0 Region01            : 0x0000000010000000-0x0000000010000fff M: (I,R,W) S/U: (R,W)
```

**Region01**: UART region.

- **Address**: `0x10000000-0x10000fff` (4 KB at 256 MB)
- **Permissions**: Same as above

This is the **UART 8250** serial console. S-mode can access it for console I/O.

---

```
Domain0 Region02            : 0x0000000002000000-0x000000000200ffff M: (I,R,W) S/U: ()
```

**Region02**: CLINT region.

- **Address**: `0x2000000-0x200ffff` (64 KB at 32 MB)
- **M-mode**: Full access
- **S/U-mode**: `()` - **NO ACCESS**

This is the **Core Local Interruptor (CLINT)** containing:
- Machine timer registers (mtime, mtimecmp)
- Machine software interrupt registers

S-mode is **blocked** from direct access. The OS must use SBI calls (`sbi_set_timer`) to access the timer. This is a security/isolation feature - prevents S-mode from manipulating M-mode timer interrupts directly.

---

```
Domain0 Region03            : 0x0000000080040000-0x000000008005ffff M: (R,W) S/U: ()
```

**Region03**: OpenSBI read-write data.

- **Address**: `0x80040000-0x8005ffff` (128 KB)
- **M-mode**: Read, Write (no execute - it's data, not code)
- **S/U-mode**: **NO ACCESS**

This is OpenSBI's **private data section** (heap, stacks, variables). Completely hidden from S-mode to prevent tampering with firmware state.

---

```
Domain0 Region04            : 0x0000000080000000-0x000000008003ffff M: (R,X) S/U: ()
```

**Region04**: OpenSBI code.

- **Address**: `0x80000000-0x8003ffff` (256 KB)
- **M-mode**: Read, Execute (no write - code is immutable)
- **S/U-mode**: **NO ACCESS**

OpenSBI's **code section**. Protected from:
- S-mode reading it (can't extract firmware code)
- S-mode writing it (can't inject code)
- M-mode writing it (prevents accidental corruption)

---

```
Domain0 Region05            : 0x000000000c400000-0x000000000c5fffff M: (I,R,W) S/U: (R,W)
```

**Region05**: PLIC context region.

- **Address**: `0xc400000-0xc5fffff` (2 MB at ~196 MB)
- **Full access for both modes**

Part of the **Platform-Level Interrupt Controller (PLIC)**. This specific range is for interrupt claim/complete registers that S-mode needs to access for interrupt handling.

---

```
Domain0 Region06            : 0x000000000c000000-0x000000000c3fffff M: (I,R,W) S/U: (R,W)
```

**Region06**: PLIC main region.

- **Address**: `0xc000000-0xc3fffff` (4 MB at 192 MB)
- **Full access for both modes**

The main **PLIC** region containing:
- Interrupt priority registers
- Interrupt pending bits
- Interrupt enable bits

S-mode needs this for interrupt management.

---

```
Domain0 Region07            : 0x0000000000000000-0xffffffffffffffff M: () S/U: (R,W,X)
```

**Region07**: Default/catch-all region.

- **Address**: `0x0-0xffffffffffffffff` (entire 64-bit address space)
- **M-mode**: `()` - uses default permissions
- **S/U-mode**: `(R,W,X)` - full access

This is the **default rule** - anything not covered by previous regions is accessible to S-mode. This includes:
- RAM (0x80200000+) where the OS runs
- VirtIO devices
- Other peripherals

PMP rules are checked in order, and the first match wins. So OpenSBI's protected regions (00-06) take precedence over this permissive default.

---

## Next Stage Boot Information

```
Domain0 Next Address        : 0x0000000080200000
```

**Next Address**: Where to jump after OpenSBI initialization.

**0x80200000**: This is where OpenSBI will transfer control. In your setup:
- UEFI firmware (EDK2) is loaded here
- Or a bootloader (U-Boot)
- Or directly a kernel

The address `0x80200000` (2 MB after RAM start) is the standard "payload" location, leaving room for OpenSBI at `0x80000000`.

---

```
Domain0 Next Arg1           : 0x0000000082200000
```

**Next Arg1**: Argument passed to next stage (in register `a1`).

**0x82200000**: This is the **Device Tree Blob (DTB)** address. When OpenSBI jumps to the payload:
- `a0` = hart ID
- `a1` = DTB address (this value)

The DTB describes all hardware to the OS - memory layout, devices, interrupt routing, etc. It's loaded at this address by the boot process.

---

```
Domain0 Next Mode           : S-mode
```

**Next Mode**: Privilege level for next stage.

**S-mode (Supervisor mode)**: OpenSBI will:
1. Set up machine state
2. Configure PMP as shown above
3. Switch from M-mode to S-mode
4. Jump to `Next Address`

The payload runs with reduced privileges, unable to directly access M-mode resources.

---

```
Domain0 SysReset            : yes
```

**SysReset**: Can this domain trigger system reset?

**yes**: Software in this domain can call `sbi_system_reset()` to reboot or poweroff. This permission could be denied in multi-domain setups where you don't want one domain to affect others.

---

```
Domain0 SysSuspend          : yes
```

**SysSuspend**: Can this domain trigger system suspend?

**yes**: This domain can initiate system-wide sleep states (if hardware supports it).

---

## Boot HART Details

```
Boot HART ID                : 0
```

**Boot HART ID**: Which HART is printing this and will boot the OS.

**0**: HART 0 is the bootstrap processor. It:
- Runs this initialization
- Will jump to the payload
- Other HARTs wait in a holding pen (WFI loop) until signaled

---

```
Boot HART Domain            : root
```

**Boot HART Domain**: Which domain the boot HART belongs to.

**root**: The primary domain. In multi-domain setups, you'd see which domain is bootstrapping.

---

```
Boot HART Priv Version      : v1.12
```

**Privileged Specification Version**: Which version of the RISC-V privileged architecture this HART implements.

**v1.12**: The privileged spec defines:
- Machine/Supervisor/User modes
- CSR (Control/Status Register) behavior
- Interrupt and exception handling
- Virtual memory

Version 1.12 is relatively recent (ratified 2021) with features like:
- Svnapot (NAPOT page table entries)
- Svpbmt (Page-based memory types)
- Svinval (fine-grained TLB invalidation)

---

```
Boot HART Base ISA          : rv64imafdch
```

**Base ISA**: The instruction set this HART supports.

Breaking down `rv64imafdch`:

| Letter | Extension | Description |
|--------|-----------|-------------|
| **rv64** | 64-bit | 64-bit base integer ISA |
| **i** | Base Integer | Basic integer operations (mandatory) |
| **m** | Multiplication | Multiply/divide instructions |
| **a** | Atomic | Atomic memory operations (LR/SC, AMO) |
| **f** | Single Float | Single-precision floating-point |
| **d** | Double Float | Double-precision floating-point |
| **c** | Compressed | 16-bit compressed instructions |
| **h** | Hypervisor | Virtualization support |

This HART supports a full "GC" profile (General-purpose + Compressed) plus hypervisor extensions.

---

```
Boot HART ISA Extensions    : sstc,zicntr,zihpm,zicboz,zicbom,sdtrig,svadu
```

**ISA Extensions**: Additional capabilities beyond the base ISA.

| Extension | Full Name | Purpose |
|-----------|-----------|---------|
| **sstc** | Supervisor Timer Compare | S-mode can directly access timer compare registers |
| **zicntr** | Base Counters | Standard cycle/time/instret counters |
| **zihpm** | Hardware Performance Monitors | Performance counter CSRs |
| **zicboz** | Cache Block Zero | `cbo.zero` instruction to clear cache lines |
| **zicbom** | Cache Block Management | `cbo.clean`, `cbo.flush`, `cbo.inval` instructions |
| **sdtrig** | Debug Triggers | Hardware breakpoint/watchpoint support |
| **svadu** | Auto Dirty/Accessed Update | Hardware updates A/D page table bits |

These extensions affect OS behavior:
- **sstc**: Linux can avoid SBI calls for timer management
- **svadu**: Linux doesn't need software A/D bit emulation
- **zicbo***: Enables cache management instructions

---

```
Boot HART PMP Count         : 16
```

**PMP Count**: Number of Physical Memory Protection entries.

**16 entries**: This HART has 16 PMP regions available. Each entry consists of:
- `pmpcfg*` - configuration (R/W/X permissions, matching mode)
- `pmpaddr*` - address/range specification

16 is a common number. The PMP entries define the memory protection shown earlier.

---

```
Boot HART PMP Granularity   : 2 bits
```

**PMP Granularity**: Minimum alignment for PMP regions.

**2 bits**: The minimum granularity is 2^(G+2) = 2^4 = **16 bytes**. This means:
- PMP regions must be aligned to 16-byte boundaries
- Minimum protectable region is 16 bytes

Finer granularity means more precise memory protection but requires more address bits. Most implementations use G=0 (4-byte granularity) or G=2 (16-byte).

---

```
Boot HART PMP Address Bits  : 54
```

**PMP Address Bits**: Physical address width for PMP.

**54 bits**: This HART can protect physical addresses up to 2^54 bytes = **16 petabytes**. This defines:
- Maximum physical memory addressable
- PMP range coverage

64-bit RISC-V typically uses 56-bit physical addresses (Sv39, Sv48 page tables), so 54-bit PMP coverage is sufficient.

---

```
Boot HART MHPM Info         : 16 (0x0007fff8)
```

**MHPM Info**: Machine Hardware Performance Monitor information.

- **16**: Number of hardware performance counters (HPM3-HPM18)
- **0x0007fff8**: Bitmask of available counters

The hex value shows which counters exist:
- Bit 3 = HPM3, Bit 4 = HPM4, ..., Bit 18 = HPM18
- `0x0007fff8` = bits 3-18 set = 16 counters available

These counters can track events like cache misses, branch mispredictions, etc.

---

```
Boot HART Debug Triggers    : 2 triggers
```

**Debug Triggers**: Hardware breakpoint/watchpoint count.

**2 triggers**: This HART has 2 hardware debug triggers for:
- Instruction breakpoints (break on executing specific address)
- Data watchpoints (break on memory access)
- Other trigger conditions

Used by debuggers (GDB) for hardware-assisted breakpoints.

---

```
Boot HART MIDELEG           : 0x0000000000001666
```

**MIDELEG**: Machine Interrupt Delegation register value.

**0x1666** in binary: `0001 0110 0110 0110`

This shows which interrupts are delegated from M-mode to S-mode:

| Bit | Interrupt | Delegated? |
|-----|-----------|------------|
| 1 | Supervisor Software | ✓ |
| 2 | (Reserved) | ✓ |
| 5 | Supervisor Timer | ✓ |
| 6 | (Reserved) | ✓ |
| 9 | Supervisor External | ✓ |
| 10 | (Reserved) | ✓ |
| 12 | (Unused) | ✓ |

Delegated interrupts go directly to S-mode handlers without M-mode involvement, improving performance.

---

```
Boot HART MEDELEG           : 0x0000000000f0b509
```

**MEDELEG**: Machine Exception Delegation register value.

**0xf0b509** in binary shows which exceptions are delegated:

| Bit | Exception | Delegated? |
|-----|-----------|------------|
| 0 | Instruction misaligned | ✓ |
| 3 | Breakpoint | ✓ |
| 8 | Environment call from U-mode | ✓ |
| 12 | Instruction page fault | ✓ |
| 13 | Load page fault | ✓ |
| 15 | Store page fault | ✓ |
| 20-23 | (Reserved/custom) | ✓ |

**Not delegated** (handled in M-mode):
- Illegal instruction (bit 2) - may need M-mode emulation
- Environment call from S-mode (bit 9) - SBI calls must reach M-mode

Page faults are delegated so the OS can handle virtual memory without M-mode involvement.

---

## Summary

After all this initialization, OpenSBI:

1. **Configured memory protection** - Firmware is isolated from S-mode
2. **Set up interrupt/exception delegation** - OS handles most traps directly
3. **Prepared device access** - S-mode can use UART, PLIC, VirtIO
4. **Loaded device tree** - Hardware description available to OS
5. **Printed diagnostic info** - Everything you just read

Then it executes:
```c
// Pseudocode
a0 = boot_hart_id;          // 0
a1 = dtb_address;           // 0x82200000
mstatus.MPP = S_MODE;       // Return to S-mode
mepc = next_address;        // 0x80200000
mret;                       // Jump to payload in S-mode
```

And control transfers to UEFI/U-Boot/Linux at `0x80200000` in Supervisor mode.
