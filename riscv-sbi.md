# RISC-V SBI specification

## Table of Contents
1. [Introduction](#Introduction)
2. [SBI calls](#SBI calls)
3. [Description](#Description)
	* [Timer](#Timer)
	* [Inter Processor Interrupt (IPI)](#IPI)
	* [Memory Model](#Memory Model)
	* [Console](#Console)
	* [Shutdown](#Shutdown)
4. [Conclusion](#Conclusion)


## Copyright and license information

This RISC-V Supervisor Binary Interface(SBI) specification document is

 &copy; 2018 Atish Patra <atish.patra@wdc.com>
 &copy; 2018 Andrew Waterman <aswaterman@gmail.com>
 &copy; 2018 Palmer Dabbelt <palmer@dabbelt.com>

It is licensed under the Creative Commons Attribution 4.0 International
License (CC-BY 4.0).  The full license text is available at
https://creativecommons.org/licenses/by/4.0/.

## Introduction

Supervisor Binary Interface(SBI) describes the instructions that can be executed together with a set of SBI calls out to the supervisor execution environment (SEE)
on a given platform. Several instructions that might normally be handled by the
supervisor operating system (OS) directly are handled via SBI calls to the SEE in
RISC-V. This provides a cleaner interface for the supervisor OS. Currently,
The next section will describe different types of SBI calls defined for RISC-V.

## SBI calls
There are mainly 5 types of SBI calls defined in the specification as per below
table.

| Type          | Function          |
| --------------|-------------------|
| Timer         | sbi_set_timer     |
| IPI           | sbi_clear_ipi<br>sbi_send_ipi  |
| Memory Model| sbi_remote_fence_i<br>sbi_remote_sfence_vma<br>sbi_remote_sfence_vma_asid
|	Console				| sbi_console_putchar <br> sbi_console_getchar |
| Shutdown         |	sbi_shutdown |

## Description
Each SBI call adheres to a specific calling convention that defines how data is provided as input to or read as output. Individual SBI call signature and its
purpose is described next.

### Timer
```C
void sbi_set_timer(uint64_t stime_value)
```
Programs the clock for next event after *stime_value* time. This function also
clears the pending timer interrupt bit. If the supervisor needs to clear the
timer interrupt without scheduling the next timer event, they may choose to do
so in timer interrupt handler or any other place in supervisor.

### IPI
```C
void sbi_send_ipi(const unsigned long *hart_mask)
```
Send an inter-processor interrupt to all the harts defined in hart_mask.

```C
void sbi_clear_ipi(void)
```
Clears any pending IPIs in the hart for which this SBI is invoked.

### Memory Model
```C
void sbi_remote_fence_i(const unsigned long *hart_mask)
```
Instruct remote harts to execute FENCE.I instruction.

```C
void sbi_remote_sfence_vma(const unsigned long *hart_mask,
                           unsigned long start,
                           unsigned long size)
```
//TODO

```C
void sbi_remote_sfence_vma_asid(const unsigned long *hart_mask,
                                unsigned long start,
                                unsigned long size,
                                unsigned long asid)
```
//TODO

### Console
```C
void sbi_console_putchar(int ch)
```
Write data present in *ch* to debug console (blocking)

```C
int sbi_console_getchar(void)
```
Read a byte from debug console; returns the byte on success, or -1 for failure.
Note. This is the only SBI call that has a non-void return type.

### Shutdown
```C
void sbi_shutdown(void)
```
Puts all the harts to shut down state from supervisor point of view.

## Conclusion
The objective of defining SBI at this point is to prevent any further changes unless absolutely necessary. Thus, we can say that It is mostly a permanent interface.
This also allows the OS developers to develop supervisor code without
worrying about modifying their code in future due to change in SBI interface.
