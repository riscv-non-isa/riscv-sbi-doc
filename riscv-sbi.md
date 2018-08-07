# RISC-V SBI specification

## Table of Contents
1. [Introduction](#Introduction)
1. [SBI List](#sbi-list)
1. [Types](#Types)
1. [Description](#Description)
	* [Timer](#Timer)
	* [Inter Processor Interrupt (IPI)](#IPI)
	* [Memory Model](#memory-model)
	* [Console](#Console)
	* [Shutdown](#Shutdown)
1. [Conclusion](#Conclusion)


## Copyright and license information

This RISC-V Supervisor Binary Interface(SBI) specification document is

 &copy; 2018 Atish Patra <atish.patra@wdc.com>

 &copy; 2018 Andrew Waterman <aswaterman@gmail.com>

 &copy; 2018 Palmer Dabbelt <palmer@dabbelt.com>

It is licensed under the Creative Commons Attribution 4.0 International
License (CC-BY 4.0).  The full license text is available at
https://creativecommons.org/licenses/by/4.0/.

## Introduction<a name="Introduction" />

Supervisor Binary Interface (SBI) describes the instructions that can be executed
together with a set of SBI calls out to the supervisor execution environment (SEE)
on a given platform. Several instructions that might normally be handled by the
supervisor operating system (OS) directly are handled via SBI calls to the SEE in
RISC-V. This provides a cleaner interface for the supervisor OS. Currently, SBI
is currently implemented by Berkeley Boot Loader (BBL). The next section will
describe different types of SBI calls defined for RISC-V.

## SBI List<a name="sbi-list" />
There are mainly 5 types of SBI calls defined in the specification as per below
table.

| Type          | Function          |
|:--------------|:------------------|
| Timer         | sbi_set_timer     |
| IPI           | sbi_clear_ipi<br>sbi_send_ipi  |
| Memory Model  | sbi_remote_fence_i<br>sbi_remote_sfence_vma<br>sbi_remote_sfence_vma_asid |
| Console       | sbi_console_putbyte<br>sbi_console_getbyte |
| Shutdown      | sbi_shutdown |

## Types<a name="Types" />

Most types are defined through standards such as C99's `stdbool.h`, `stdint.h`, etc.
SBI-specific types are defined here.

### `asid_t`

This type's precise definition is implementation dependent.  Its requirements are:

* It **must** accommodate at least an unsigned 9-bit integer for RV32 systems, and,
* It **must** accommodate at least an unsigned 16-bit integer for RV64 systems.

When the RV128 platform is refined further, this definition must be amended to cope.

Here's an example typical of RV64 systems:

```C
typedef uint16_t asid_t;
```

## Description<a name="Description" />
Each SBI call adheres to a specific calling convention that defines how data is
provided as input to or read as output. The SBI calling convention matches the
syscall calling convention (which in turn is very similar to the function calling
convention). Every SBI call uses *ecall* instructions to make a request to the SEE
environment. When executed in S-mode, it generates an environment-call-from-S-mode
exception and performs no other operation. The required arguments are passed
through registers `a0`-`a2` and the SBI call type is passed via register `a7`. Once
the machine mode receives the trap, it identifies the type of SBI call from `a7`
register and perform required operation. Individual SBI call signature and its
purpose is described next.

### Timer<a name="Timer" />
```C
void sbi_set_timer(uint64_t interval)
```
Programs the clock to generate an timer interrupt after `interval` units of time. This function also
clears the current timer interrupt, if one is pending.

If the supervisor wishes to clear the
timer interrupt without scheduling the next timer event,
it can either request a timer interrupt infinitely far into the future (i.e., (uint64_t)-1),
or it can instead mask the timer interrupt by clearing sie.STIE.

### IPI<a name="IPI" />
```C
void sbi_send_ipi(const unsigned long *hart_mask)
```
Send an inter-processor interrupt to all the harts defined in hart_mask.
Interprocessor interrupts manifest at the receiving harts as Supervisor Software
Interrupts.

hart_mask is a physical address that points to a bit-vector of harts. The bit
vector is represented as a sequence of unsigned longs whose length equals the
number of harts in the system divided by the number of bits in an unsigned long,
rounded up to the next integer.

If hart_mask is `NULL`, an IPI is sent to every hart in the system.

```C
	void sbi_clear_ipi(void)
```
Clears the pending IPIs if any. The IPI is cleared only in the hart for which
this SBI call is invoked.

### Memory Model<a name="memory-model" />
```C
void sbi_remote_fence_i(const unsigned long *hart_mask)
```
Instruct remote harts to execute a `FENCE.I` instruction.
`hart_mask` is as described in `sbi_send_ipi`, above.

```C
void sbi_remote_sfence_vma(const unsigned long *hart_mask,
                           const void *start,
                           size_t size)
```
//TODO

```C
void sbi_remote_sfence_vma_asid(const unsigned long *hart_mask,
                                const void *start,
                                size_t size,
                                asid_t asid)
```
//TODO

### Console<a name="Console" />
```C
void sbi_console_putbyte(uint8_t ch)
```
Write data present in *ch* to debug console.
Unlike `sbi_console_getbyte` (below),
this SBI call **will block** if there remain any pending characters to be transmitted
or if the receiving terminal is not yet ready to receive the byte.
However, if the console doesn't exist at all,
then the character is thrown away.


```C
int sbi_console_getbyte(void)
```
Read a byte from debug console.
If successful, it returns the byte.
Otherwise, -1 is returned indicating some failure occurred
(e.g., a byte is not yet available, or perhaps the terminal is not physically present).

### Shutdown<a name="Shutdown" />
```C
void sbi_shutdown(void)
```
Puts all the harts to shut down state from supervisor point of view. This SBI
call doesn't return.

## Conclusion<a name="Conclusion" />
The objective of defining SBI at this point is to prevent any further changes
unless absolutely necessary. Thus, we can say that It is mostly a permanent
interface. This also allows the OS developers to develop supervisor code without
worrying about modifying their code in future due to change in SBI interface.
