
## Introduction:
This is a proposal to make SBI a flexible and extensible interface.
It is based on the foundation policy of RISC-V i.e. modularity and
openness. The proposal tries to introduces very few new mandatory SBI Functions,
that are absolutely required to maintain backward compatibility. Everything else
is optional so that it remains an open standard yet robust.

The current RISC-V SBI only defines a few mandatory functions such as
inter-processor interrupts (IPI) interface, reprogramming timer, serial
console, and memory barrier instructions. The existing SBI documentation
can be found here [1]. Many important functionalities such as power
management/cpu-hotplug are not yet defined due to difficulties in
accommodating modifications without breaking the backward compatibility
with the current interface.

The proposed design is inspired by Power State Coordination Interface (PSCI) from
ARM world. However, it adds only two new mandatory SBI calls providing
version information and supported Functions, unlike PSCI where a significant
number of functions are mandatory. The version of the existing SBI will
be defined as a minimum version(0.1) which will always be backward compatible.
Similarly, any Linux kernel with a newer feature will fall back if an older
version of SBI does not support the updated capabilities. Both the operating
system and SEE can be implemented to be two way backward compatible.

## SBI Calling Conventions (TODO)
There are some suggestions[3] to distinguish between SBI function return value and
SBI calling sequence return value. Here are the few possible discussed ideas.

1. Return a single value, but values in the range {-511, -1} are considered
errors, whereas return values in the range {0, 2^XLEN-512} are considered success.

2. Every SBI function call may return the following structure
```
struct valerr {
  long value;
  long error;
};
```
According to the RISC-V ABI spec[4], both a0 & a1 registers can be used for function
return values.

3. Introduce an extra argument that can return error by reference.
```
/* Returns the CPU that was started.
 * @err indicates an error ID if one occurred, otherwise 0.
 * @err can be NULL if no error detection is required.
*/
int start_cpu(int cpu_num,..., Error *err);
```
Both approaches (2 & 3) will work, but there will be two versions of existing SBI
functions to maintain the compatibility.

## SBI Functions:

A SBI function is an individual feature that SBI interface provides to supervisor
mode from machine mode. Each function ID is assigned as per below section.

#### SBI Function ID numbering scheme:
A Function Set is a group of SBI functions which collectively implement similar
kind of feature/functionality. The function ID numbering scheme need to be scalable
in the future. At the same time, function validation check should be as quick as possible.
Keeping these two requirements in mind, a hybrid function ID scheme is proposed.

SBI Function ID is u32 type.

```
31            24                        0
-----------------------------------------
|O|            |                        |
-----------------------------------------
Function Set   | Function Type          |
```
Bit[31]    =  ID overflow bit

Bit[30:24] =  Function Set

Bit[23:0]  =  Function Type within Function Set

The Function set is Bits [31:24] describing both function set number and overflow
bit. In the beginning, the overflow bit should be set to **zero** and the function
Type per function set can be assigned by left shifting 1 bit at a time. The overflow
bit can be set to one **only** when we need to allocate more than 24 functions per
function set in future. Setting the overflow bit will indicate an integer function
type scheme. Thus, there will more than enough function IDs available to use in the
future. Refer appendix 1 for examples.

Here are few Function Sets for SBI v0.2:

| Function Set         | Value  | Description                                  |
| -------------------  |:------:| :--------------------------------------------|
| Base Functions       | 0x00   | Base Functions mandatory for any SBI version |
| HART PM Functions    | 0x01   | Hart UP/Down/Suspend Functions for per-Hart power management|
| System PM Functions  | 0x02   | System Shutdown/Reboot/Suspend for system-level power management|
| Vendor Functions     | 0x7f   | Vendor specific Functions|

N.B. There is a possibility that different vendors can choose to assign the same function
numbers for different functionality. That's why vendor specific strings in
Device Tree/ACPI or any other hardware description document can be used to verify
if a specific Function belongs to the intended vendor or not.

# SBI Function List in both SBI v0.2 and v0.1

|Function Type              | Function Set      | ID(v0.2)     |ID (v0.1)  |
|---------------------------| ------------------|:------------:|:---------:|
| sbi_set_timer             | Base              | 0x00 000000  |0          |
| sbi_console_putchar       | Base              | 0x00 000001  |1          |
| sbi_console_getchar       | Base              | 0x00 000002  |2          |
| sbi_clear_ipi             | Base              | 0x00 000004  |3          |
| sbi_send_ipi              | Base              | 0x00 000008  |4          |
| sbi_remote_fence_i        | Base              | 0x00 000010  |5          |
| sbi_remote_sfence_vma     | Base              | 0x00 000020  |6          |
| sbi_remote_sfence_vma_asid| Base              | 0x00 000040  |7          |
| sbi_shutdown              | System PM         | 0x02 000000  |8          |
| sbi_system_reset          | System PM         | 0x02 000001  |-          |
| sbi_get_version           | Base              | 0x00 000080  |-          |
| sbi_get_function_mask     | Base              | 0x00 000100  |-          |
| sbi_get_function_count    | Base              | 0x00 000200  |-          |
| sbi_hart_up               | Hart PM           | 0x01 000000  |-          |
| sbi_hart_down             | Hart PM           | 0x01 000001  |-          |
| sbi_hart_suspend          | Hart PM           | 0x01 000002  |-          |
| sbi_hart_state            | Hart PM           | 0x01 000004  |-          |

#### Function Description

This section describes every newly introduced(in v0.2) function in details.
Please refer to [1] for any v0.1 functions.

```
u32 sbi_get_version(void):
```
Returns the current SBI version implemented by the firmware.
version: uint32: Bits[31:16] Major Version
             Bits[15:0] Minor Version

The existing SBI version can be 0.1. The proposed version will be at 0.2
A different major version may indicate possible incompatible functions.
A different minor version must be compatible with each other even if
they have a higher number of features.

```
u32 sbi_get_function_mask(u32 ftype)
```
Given a function set type, it returns a bitmask of all functions IDs that are
implemented for that function set.

```
u32 sbi_get_function_count(u32 ftype, u32 start_fid, unsigned long count):
```

This is a **reserved** function that should only be used if overflow bit in SBI
function ID is set.

Accepts a start_Function_id as an argument and returns if start_Function_id to
(start_Function_id + count - 1) are supported or not.
The Function numbering scheme is described in section 3.

A count can help in minimizing the number of the M-mode traps by checking a range
of SBI functions together.

```
int sbi_hart_up(unsigned long hartid, unsigned long start, unsigned
long priv)
```
Brings up "hartid" either during initial boot or after a sbi_hart_down
SBI call.

"start" points to a runtime-specified address where a hart can enter
into supervisor mode. This must be a physical address.

"priv" is a private data that caller can use to pass information about
execution context.

Return the appropriate SBI error code.

```
int sbi_hart_suspend(u32 state, unsigned long resume_entry, unsigned
long priv)
```
Suspends the calling hart to a particular power state. Suspended hart
will automatically wake-up based on some wakeup events at resume_entry
physical address.

"priv" is a private data that caller can use to pass information about
execution context. The SBI implementation must save a copy so that
caller can reuse while restoring hart from suspend.

Return the appropriate SBI error code.

```
int sbi_hart_down()
```
It powers off the hart and will be used in cpu-hotplug.
Only individual hart can remove itself from supervisor mode. It can be
moved to normal state only by sbi_hart_up function.

Return the appropriate SBI error code.

```
u32 sbi_hart_state(unsigned long hartid)
```
Returns the RISCV_POWER_STATE for a specific hartid. This will help make
kexec like functionality more robust.

```
void sbi_system_reset(u32 reset_type)
```
Reset the entire system.

## Return error code Table:
Here are the SBI return error codes defined.

| Error Type               | Value  |
| -------------------------|:------:|
|  SBI_ERR_SUCCESS         |  0     |
|  SBI_ERR_FAILURE         | -1     |
|  SBI_ERR_NOT_SUPPORTED   | -2     |
|  SBI_ERR_INVALID_PARAM   | -3     |
|  SBI_ERR_DENIED          | -4     |
|  SBI_ERR_INVALID_ADDRESS | -5     |


## Power State
A RISC-V core can exist in any of the following power states.

| Power states         | Value  | Description                                  |
| -------------------  |:------:|:---------------------------------------------|
| RISCV_HART_ON        | 0      | Powered up & operational.                    |
| RISCV_HART_STANDBY   | 1      | Powered up but at reduced energy <br> consumption WFI instruction can be used to achieve this state|
| RISCV_HART_RETENTION | 2      | Deeper low power state. No reset <br> required but higher wakeup latency|
| RISCV_HART_OFF       | 3      | Powered off. Reset of the core required after power restore|

**_TODO_**:

We probably also need deeper hart power states or system-level power state reporting
at some point, and non-HART components (caches, memory, etc).  Likely aligned with
platform specs, once those start to show up.

## Implementation
Currently, SBI is implemented as a part of BBL. There is a different SBI implementation
available in coreboot as well.

Alternatively, a separate open BSD/MIT licensed SBI project can be created that
can be used by anybody to avoid this kind of SBI fragmentation. This project can
generate both a firmware binary (to be executed directly in M mode) or a static library
that can be used by different boot loaders. It will also help individual bootloaders
to either work from M or S mode without a separate SBI implementation.

## Conclusion
This proposal is far from perfect and absolutely any suggestion is welcome.
Obviously, there are many other functionalities that can be added to this proposal.
However, I just wanted to start with something that is an incremental change at
best to kick off the discussion. The aim here is to initiate a discussion that
can lead to a robust SBI specification.

## Reference:

[1] http://infocenter.arm.com/help/topic/com.arm.doc.den0022d/Power_State_Coordination_Interface_PDD_v1_1_DEN0022D.pdf

[2] https://github.com/riscv/riscv-sbi-doc/blob/master/riscv-sbi.md

[3] https://github.com/riscv/riscv-sbi-doc/pull/9

[4] https://github.com/riscv/riscv-elf-psabi-doc/blob/master/riscv-elf.md

## Appendix

1. Overflow Reserved bit example.

Let's choose function set type as Hart PM (0x1)

Function1 : 0x01 000001<br>
Function2 : 0x01 000002<br>
Function3 : 0x01 000004<br>
.<br>
.<br>
.<br>
Function24:0x01 800000<br>

At this point in future, Let's say we need more function IDs for Hart PM.
The scheme can be switched to an integer scheme by setting the overflow bit.

Function25: 0x81 000001<br>
Function26: 0x81 000002<br>
Function27: 0x81 000003<br>
Function28: 0x81 000004<br>
.<br>
.<br>
Function34: 0x81 00000A<br>
.<br>
