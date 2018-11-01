# RISC-V SBI specification

## Table of Contents
1. [Introduction](#Introduction)
2. [SBI List](#sbi-list)
3. [Types](#Types)
4. [Description](#Description)
	* [Timer](#Timer)
	* [Inter Processor Interrupt (IPI)](#IPI)
	* [Memory Model](#memory-model)
	* [Console](#Console)
	* [Shutdown](#Shutdown)
5. [Conclusion](#Conclusion)


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

The SBI may be provided by the kernel, itself, or by firmware. That does not change the nature
of the services provided.

## SBI List<a name="sbi-list" />
There are mainly 5 types of SBI calls defined in the specification as per below
table.

| Type          | Function          | Function ID |
|:--------------|:------------------|-------------|
| Timer         | sbi_set_timer     |0		  |
| IPI           | sbi_clear_ipi<br>sbi_send_ipi  | 3<br>4|
| Memory Model| sbi_remote_fence_i<br>sbi_remote_sfence_vma<br>sbi_remote_sfence_vma_asid | 5<br>6<br>7 |
|	Console				| sbi_console_putchar <br> sbi_console_getchar | 1<br>2 |
| Shutdown         |	sbi_shutdown | 8 |

## Types<a name="Types" />
Most types are defined through standards such as C99's `stdbool.h`, `stdint.h`, etc.
SBI-specific types are defined here.

## Description<a name="Description" />
Each SBI call adheres to a specific calling convention that defines how data is
provided as input to or read as output. The SBI calling convention matches the
RISC-V system call ABI. Every SBI call uses *ecall* instructions to make a request to the SEE
environment. When executed in S-mode, it generates an environment-call-from-S-mode
exception and performs no other operation. The required arguments are passed
through registers the argument registers define by the ABI 
and the SBI call type is passed via register *a7*. Once
the machine mode receives the trap, it identifies the type of SBI call from *a7*
register and perform required operation. 

SBI returns two values, in *a0* and *a1*. *a0* has a generic SBI error, and *a1* has the 
result of actually running a function. This two-value model is to avoid the classic problem of distinguishing
transport level errors, i.e. S-mode calls to an unimplemented function, and errors in the functions.
A single return value, as in the earlier proposal, has the problem that no SBI function could return
a value of -38, ever, as that could not be distinguished from the SBI error of calling an invalid function. 

The value returned in *a0* is a generic SBI error. 
For example, S-mode code may call a function with an unimplemented function, either because it really is
invalid or S-mode is running on an older firmware build and requesting a newer SBI function. In that case,
SBI will return -38. Note that the set of errors may grow over time. A return value of 0 in *a0* means
the function is supported and was called. 

Assuming a valid function is called, i.e. *a0* is 0, its return value will be in *a1*. For void functions, the value
of *a1* is undefined, else it will have a value as defined by the function.

All SBI calls should be assumed to clobber *a0* and *a1*, i.e. any return value will be passed
through register *a0* and *a1*. Individual SBI call signature and its purpose is described next.

### Timer<a name="Timer" />
```C
void sbi_set_timer(uint64_t stime_value)
```
Programs the clock for next event after *stime_value* time. This function also
clears the pending timer interrupt bit.

If the supervisor wishes to clear the timer interrupt without scheduling the next
timer event, it can either request a timer interrupt infinitely far into the
future (i.e., (uint64_t)-1), or it can instead mask the timer interrupt by
clearing sie.STIE.

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

If hart_mask is NULL, an IPI is sent to every hart in the system.

```C
void sbi_clear_ipi(void)
```
Clears the pending IPIs if any. The IPI is cleared only in the hart for which
this SBI call is invoked.

### Memory Model<a name="memory-model" />
```C
void sbi_remote_fence_i(const unsigned long *hart_mask)
```
Instruct remote harts to execute FENCE.I instruction.
N.B. hart_mask is as described in sbi_send_ipi.
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

### Console<a name="Console" />

```C
int sbi_console_getchar(void)
```
Read a byte from debug console; returns the byte on success, or -1 for failure.
Note. This is the only SBI call that has a non-void return type.

```C
void sbi_console_putchar(int ch)
```
Write data present in *ch* to debug console.

Unlike `sbi_console_getchar`, this SBI call **will block** if there
remain any pending characters to be transmitted or if the receiving terminal
is not yet ready to receive the byte. However, if the console doesn't exist
at all, then the character is thrown away.

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
It should always be possible for a newer kernel to call an older SBI implementation
and function correctly, meaning that if a newer kernel calls an SBI that does not implement
an older function, -38 is returned.
