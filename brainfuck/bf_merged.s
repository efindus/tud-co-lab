.data
# 30000 pre-zeroed bytes
	program_data: .zero 30000

.text
# a big constant
	two_to_62: .quad 0x4000000000000000

# character reference:
# 3: + [43]
# 7: , [44]
# 4: - [45]
# 8: . [46]
# 2: < [60]
# 1: > [62]
# 5: [ [91]
# 6: ] [93]

# jump tables for speed (and cleanness)
# table for checking whether to collapse neighboring commands of given type
	char_repetition_table:
		.zero 43
		.byte 1    # + char
		.byte 0
		.byte 1    # - char
		.zero 14
		.byte 1    # < char
		.byte 0
		.byte 1    # > char
		.zero 192

# table for immediate jumps to revelant parsing labels
	char_parse_rep_table:
		.rept 43
			.quad brainfuck_parse_loop_end
		.endr
		.quad brainfuck_parse_loop_3     # + char [43]
		.quad brainfuck_parse_loop_7     # , char [44]
		.quad brainfuck_parse_loop_4     # - char [45]
		.quad brainfuck_parse_loop_8     # . char [46]
		.rept 13
			.quad brainfuck_parse_loop_end
		.endr
		.quad brainfuck_parse_loop_2     # < char [60]
		.quad brainfuck_parse_loop_end
		.quad brainfuck_parse_loop_1     # > char [62]
		.rept 28
			.quad brainfuck_parse_loop_end
		.endr
		.quad brainfuck_parse_loop_5     # [ char [91]
		.quad brainfuck_parse_loop_end
		.quad brainfuck_parse_loop_6     # ] char [93]
		.rept 161
			.quad brainfuck_parse_loop_end
		.endr

# subroutine to call putchar
# getting a dynamically linked offset for machine code to use proved too annoying
# we simply jump so that ret in putchar goes back to the right place, and not here
putchar_unlocked_call:
	jmp putchar_unlocked

# subroutine to call getchar
# getting a dynamically linked offset for machine code to use proved too annoying
# we simply jump so that ret in getchar goes back to the right place, and not here
getchar_unlocked_call:
	jmp getchar_unlocked


# Your brainfuck subroutine will receive one argument:
# a zero termianted string containing the code to execute.
# modification: first quad in the buffer is the length
brainfuck:
	# prologue
	pushq %rbp
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx
	pushq %rbx # stack alignment
	movq %rsp, %rbp

	movq %rdi, %r12     # store the pointer to the bf code in r12
	movq (%r12), %r13   # store the size of the memory buffer in r13
	addq $8, %r12       # skip the size for future use

	movq %r13, %r14
	imul $11, %r14      # allocate 11 bytes for every byte of the program to be certain we have enough space for the entire machine code
	addq $1, %r14       # reserve some additional bytes for the final ret to our code

	# get executable memory from the kernel
	mov $9, %rax        # sys_mmap (9)
	xor %rdi, %rdi      # addr = NULL (let the kernel choose address)
	mov %r14, %rsi      # length
	mov $7, %rdx        # prot = PROT_READ | PROT_WRITE | PROT_EXEC (7)
	mov $0x22, %r10     # flags = MAP_PRIVATE | MAP_ANONYMOUS (0x22)
	mov $-1, %r8        # fd = -1 (not backed by a file)
	xor %r9, %r9        # offset = 0
	syscall             # invoke syscall

	movq %rax, %r14     # store the pointer in r14, as we don't need the size anymore

	xor %r8, %r8        # use r8 as the loop counter
	xor %rcx, %rcx      # clear rcx before using cl in the loop
	xor %r9, %r9        # use r9 as the write counter

	# loop unrolling state registers
	xor %r10, %r10            # use r10 as *p delta counter
	movq two_to_62, %r11      # use r11 as offset counter, when preconditions fail (IO occurs) set to 2^62
	xor %r15, %r15            # use r15 to indicate that we are in unroll mode
	# use rbx as a temporary store for r8 at the last [ location

brainfuck_parse_loop:
	movq $1, %rax                           # use rax as repetition counter
	movb (%r12, %r8), %cl                   # store the current character in cl

	cmpb $1, char_repetition_table(, %ecx)  # check if we can collapse adjacent commands of this type
	jne brainfuck_parse_loop_after_rep      # skip collapsing if not

brainfuck_parse_loop_rep_loop:
	cmpb %cl, 1(%r12, %r8)                  # check if the next character is the same
	jne brainfuck_parse_loop_after_rep      # end if not

	inc %r8
	inc %rax                                # increase file index and repetition counter
	jmp brainfuck_parse_loop_rep_loop       # loop

brainfuck_parse_loop_after_rep:
	jmp *char_parse_rep_table(, %ecx, 8)    # lookup the current character in the jumptable, every character outside of brainfuck's 8 points to brainfuck_parse_loop_end

# 1: >, count                          [62]
brainfuck_parse_loop_1:
	addq %rax, %r11                         # count the offset for loop unrolls

	cmpb $0, %r15b                          # if in unroll mode we don't need to do anything else
	jne brainfuck_parse_loop_end

	movl $0x00c58149, (%r14, %r9)           # (x86 machine code for addq 4-byte imm, %r13) 49 81 c5 <4-byte imm>; we are adding an additional 00 byte in order to avoid introducing more mov instructions
	movl %eax, 3(%r14, %r9)                 # set the immediate at offset 3 (as the instruction takes just 3 bytes)

	addq $7, %r9                            # advance the machine code pointer
	jmp brainfuck_parse_loop_end

# 2: <, count                          [60]
brainfuck_parse_loop_2:
	subq %rax, %r11                         # count the offset for loop unrolls

	cmpb $0, %r15b                          # if in unroll mode we don't need to do anything else
	jne brainfuck_parse_loop_end

	movl $0x00ed8149, (%r14, %r9)           # (x86 machine code for subq 4-byte imm, %r13) 49 81 ed <4-byte imm>; we are adding an additional 00 byte in order to avoid introducing more mov instructions
	movl %eax, 3(%r14, %r9)                 # set the immediate at offset 3 (as the instruction takes just 3 bytes)

	addq $7, %r9                            # advance the machine code pointer
	jmp brainfuck_parse_loop_end

# 3: +, count                          [43]
brainfuck_parse_loop_3:
	cmpb $0, %r15b                          # if in unroll mode generate necessary instructions
	je brainfuck_parse_loop_3_normal_flow

brainfuck_parse_loop_3_unroll_loop:
	# (x86 machine code for addb %bl, <4-byte offset>(%r12, %r13)) 43 00 9c 2c <4-byte offset>
	movl $0x2c9c0043, (%r14, %r9)
	movl %r11d, 4(%r14, %r9)

	addq $8, %r9                           # advance the machine code pointer

	dec %al
	test %al, %al
	jnz brainfuck_parse_loop_3_unroll_loop

	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_3_normal_flow:
	movl $0x2c048043, (%r14, %r9)           # (x86 machine code for addb imm, (%r12, %r13)) 43 80 04 2c <imm>
	movb %al, 4(%r14, %r9)                  # set the immediate

	cmpq $0, %r11                           # if the offset of the pointer is not 0 the write does not affect *p
	jne brainfuck_parse_loop_3_next

	addq %rax, %r10                         # use r10 to calculate the loop delta for *p

brainfuck_parse_loop_3_next:
	addq $5, %r9                            # advance the machine code pointer
	jmp brainfuck_parse_loop_end

# 4: -, count                          [45]
brainfuck_parse_loop_4:
	cmpb $0, %r15b                          # if in unroll mode generate necessary instructions
	je brainfuck_parse_loop_4_normal_flow

brainfuck_parse_loop_4_unroll_loop:
	# (x86 machine code for subb %al, <4-byte offset>(%r12, %r13)) 43 28 9c 2c <4-byte offset>
	movl $0x2c9c2843, (%r14, %r9)
	movl %r11d, 4(%r14, %r9)

	addq $8, %r9                           # advance the machine code pointer

	dec %al
	test %al, %al
	jnz brainfuck_parse_loop_4_unroll_loop

	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_4_normal_flow:
	movl $0x2c2c8043, (%r14, %r9)           # (x86 machine code for subb imm, (%r12, %r13)) 43 80 2c 2c <imm>
	movb %al, 4(%r14, %r9)                  # set the immediate

	cmpq $0, %r11                           # if the offset of the pointer is not 0 the write does not affect *p
	jne brainfuck_parse_loop_4_next

	subq %rax, %r10                         # use r10 to calculate the loop delta for *p

brainfuck_parse_loop_4_next:
	addq $5, %r9                            # advance the machine code pointer
	jmp brainfuck_parse_loop_end

# 5: [, ip to set if *val == 0         [91]
brainfuck_parse_loop_5:
	# check if the loop is basically [-] (next two characters are 2d 5d), optimize to movb $0, (%r12, %r13)
	cmpw $0x5d2d, 1(%r12, %r8)
	jne brainfuck_parse_loop_5_normal

	addq $2, %r8                            # advance the file offset pointer

	# (x86 machine code for movb $0, (%r12, %r13)) 43 c6 04 2c 00
	movl $0x2c04c643, (%r14, %r9)
	movb $0x00, 4(%r14, %r9)

	movq two_to_62, %r11                    # fail loop unroll preconditions

	addq $5, %r9                            # advance the machine code pointer
	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_5_normal:
	# (x86 machine code for cmpb $0, (%r12, %r13)) 43 80 3c 2c 00
	# (x86 machine code for je <4-byte offset>) 0f 84 <4-byte offset>
	movl $0x2c3c8043, (%r14, %r9)
	movl $0x840f00, 4(%r14, %r9)            # fill everything aside from the immediate, as we do not know it yet

	pushq %r9                               # store the location on stack for reference by the closing bracket

	xor %r10, %r10                          # reset the *p delta
	xor %r11, %r11                          # reset the offset counter
	movq %r8, %rbx                          # store the char offset for re-parsing

	addq $11, %r9                           # advance the machine code pointer
	jmp brainfuck_parse_loop_end

# 6: ], ip to set if *val != 0         [93]
brainfuck_parse_loop_6:
	cmpb $0, %r15b                          # if in unroll mode generate necessary instructions
	je brainfuck_parse_loop_6_normal_flow

	movq $0, %r15                           # disable unroll mode
	movq two_to_62, %r11                    # fail loop unroll preconditions

	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_6_normal_flow:
	# verify loop unroll preconditions
	cmpq $0, %r11                           # at the end of the loop the memory offset needs to be identical as at the start
	jne brainfuck_parse_loop_6_normal

	cmpb $-1, %r10b                         # the delta of *p needs to be strictly -1
	jne brainfuck_parse_loop_6_normal

	popq %r9                                # get location for the matching opening bracket

	# (x86 machine code for movb (%r12, %r13), %bl) 43 8a 1c 2c
	movl $0x2c1c8a43, (%r14, %r9)           # store the iteration count in rbx

	addq $4, %r9                            # advance the machine code pointer
	movq $1, %r15                           # enable unroll mode
	movq %rbx, %r8                          # roll back the file offset, we will ignore the opening bracket, as r8 gets incremented at the end of this loop
	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_6_normal:
	movq two_to_62, %r11                    # fail loop unroll preconditions

	# (x86 machine code for cmpb $0, (%r12, %r13)) 43 80 3c 2c 00
	# (x86 machine code for jne <4-byte offset>) 0f 85 <4-byte offset>, negatives use two's complement
	movl $0x2c3c8043, (%r14, %r9)
	movl $0x850f00, 4(%r14, %r9)            # fill everything aside from the immediate

	popq %rax                               # get location for the matching opening bracket

	# set relative jumps to correct offsets
	mov %eax, %edx
	sub %r9d, %edx

	movl %edx, 7(%r14, %r9)                 # %eax - %r9d

	neg %edx

	movl %edx, 7(%r14, %rax)                # %r9d - %eax

	addq $11, %r9                           # advance the machine code pointer
	jmp brainfuck_parse_loop_end

# 7: , basically getchar_unlocked      [44]
brainfuck_parse_loop_7:
	# (x86 machine code for call *%r14) 41 ff d6
	# (x86 machine code for movb %al, (%r12, %r13)) 43 88 04 2c
	movl $0x43d6ff41, (%r14, %r9)
	movl $0x002c0488, 4(%r14, %r9)

	movq two_to_62, %r11                    # fail loop unroll preconditions

	addq $7, %r9                            # advance the machine code pointer
	jmp brainfuck_parse_loop_end

# 8: . basically putchar_unlocked      [46]
brainfuck_parse_loop_8:
	# (x86 machine code for movb (%r12, %r13), %dil) 43 8a 3c 2c
	# (x86 machine code for call *%r15) 41 ff d7
	movl $0x2c3c8a43, (%r14, %r9)
	movl $0x00d7ff41, 4(%r14, %r9)

	movq two_to_62, %r11                    # fail loop unroll preconditions

	addq $7, %r9                            # advance the machine code pointer
	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_end:
	inc %r8                         # advance the file index
	cmp %r13, %r8                   # and check for length
	jne brainfuck_parse_loop

# go back to our code at the end
	# (x86 machine code for ret) c3
	movb $0xc3, (%r14, %r9)

# JIT is done, now time to execute
# current register state: machine code in r14, rest irrelevant

	# machine code assumptions: r12 points to program memory, r13 is the index
	# r14 stores the address of getchar subroutine, r15 of the putchar subroutine
	# rbx should be cleared

	xor %rbx, %rbx
	movq %r14, %r9
	movq $getchar_unlocked_call, %r14
	movq $putchar_unlocked_call, %r15

	xor %r13, %r13             # use r13 as index
	movq $program_data, %r12   # use r12 as pointer to program memory

	# call the generated code
	call *%r9

	# epilogue
	movq %rbp, %rsp
	popq %rbx
	popq %rbx
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rbp
	ret

# general ideas:
# 30000 pre-zeroed bytes in data
# JIT x86 machine code based on the brainfuck code
# OPTIMIZE, OPTIMIZE, OPTIMIZE (and preferably don't overprofile)
#
# use a jump table for parsing


# inline other files

# main.s
	.global main

// .include "brainfuck.s"
// .include "read_file.s"

usage_format: .asciz "usage: %s <filename>\n"

# Our main function will be called with two arguments:
# main(int argc, char * * argv)
#   - argc holds the number of command line arguments.
#   - argv holds the address of an array of strings.
#
# Keep in mind that strings themselves are the address of their first character.
# So argv[0] holds the address of the first character of the first argument
# and argv[1] holds the address of the first character of the second argument.
#
# You always get a free argument that holds the name used to invoke the executable.
# This argument is always argv[0] and it counts for argc (which is thus always 1 or greater).
# If you are expecting exactly one additional command line argument,
# argc should be 2 and the argument in question will be at argv[1].
main:
	pushq %rbp
	movq %rsp, %rbp
	subq $16, %rsp

	# Make sure we got one argument.
	# The first argument is always the name of our program, so we want a second argument.
	cmp $2, %rdi
	jne wrong_argc

	# Read the file with the brainfuck code.
	# 8(%rsi) is argv[1], the path of the file we should read.
	# See read_file.s for details on the read_file subroutine.
	movq 8(%rsi), %rdi
	leaq -8(%rbp), %rsi
	call read_file
	test %rax, %rax
	jz failed
	movq %rax, -16(%rbp)

	# Now we're calling you.
	# Good luck.
	movq %rax, %rdi
	call brainfuck

	# Free the buffer allocated by read_file.
	movq -16(%rbp), %rdi
	call free

	# Return success.
	# Unless of course you made us segfault?
	mov $0, %rax
	movq %rbp, %rsp
	popq %rbp
	ret

wrong_argc:
	movq $usage_format, %rdi
	movq (%rsi), %rsi # %rsi still hold argv up to this point
	call printf

failed:
	movq $1, %rax

	movq %rbp, %rsp
	popq %rbp
	ret


# read_file.s
// .global read_file

# Taken from <stdio.h>
.equ SEEK_SET,  0
.equ SEEK_CUR,  1
.equ SEEK_END,  2
.equ EOF,      -1

file_mode: .asciz "r"

# MODIFIED!

# char * read_file(char const * filename, int * read_bytes)
#
# Read the contents of a file into a newly allocated memory buffer.
# The address of the allocated memory buffer is returned and
# read_bytes is set to the number of bytes read.
#
# A null byte is appended after the file contents, but you are
# encouraged to use read_bytes instead of treating the file contents
# as a null terminated string.
#
# Technically, you should call free() on the returned pointer once
# you are done with the buffer, but you are forgiven if you do not.
read_file:
	pushq %rbp
	movq %rsp, %rbp

	# internal stack usage:
	#  -8(%rbp) saved read_bytes pointer
	# -16(%rbp) FILE pointer
	# -24(%rbp) file size
	# -32(%rbp) address of allocated buffer
	subq $32, %rsp

	# Save the read_bytes pointer.
	movq %rsi, -8(%rbp)

	# Open file for reading.
	movq $file_mode, %rsi
	call fopen
	testq %rax, %rax
	jz _read_file_open_failed
	movq %rax, -16(%rbp)

	# Seek to end of file.
	movq %rax, %rdi
	movq $0, %rsi
	movq $SEEK_END, %rdx
	call fseek
	testq %rax, %rax
	jnz _read_file_seek_failed

	# Get current position in file (length of file).
	movq -16(%rbp), %rdi
	call ftell
	cmpq $EOF, %rax
	je _read_file_tell_failed
	movq %rax, -24(%rbp)

	# Seek back to start.
	movq -16(%rbp), %rdi
	movq $0, %rsi
	movq $SEEK_SET, %rdx
	call fseek
	testq %rax, %rax
	jnz _read_file_seek_failed

	# Allocate memory and store pointer.
	# Allocate file_size + 1 + 8 for a trailing null byte and a prefix of length
	movq -24(%rbp), %rdi
	addq $9, %rdi
	call malloc
	test %rax, %rax
	jz _read_file_malloc_failed
	movq %rax, -32(%rbp)

	# Read file contents.
	movq %rax, %rdi
	movq $1, %rsi
	movq -24(%rbp), %rdx
	movq -16(%rbp), %rcx

	# put the length at the beginning and offset the pointer given to fread by 8 bytes
	movq %rdx, (%rdi)
	addq $8, %rdi

	call fread
	movq -8(%rbp), %rdi
	movq %rax, (%rdi)

	# Add a trailing null byte, just in case.
	movq -32(%rbp), %rdi
	movb $0, 8(%rdi, %rax)

	# Close file descriptor
	movq -16(%rbp), %rdi
	call fclose

	# Return address of allocated buffer.
	movq -32(%rbp), %rax
	movq %rbp, %rsp
	popq %rbp
	ret

_read_file_malloc_failed:
_read_file_tell_failed:
_read_file_seek_failed:
	# Close file descriptor
	movq -16(%rbp), %rdi
	call fclose

_read_file_open_failed:
	# Set read_bytes to 0 and return null pointer.
	movq -8(%rbp), %rax
	movq $0, (%rax)
	movq $0, %rax
	movq %rbp, %rsp
	popq %rbp
	ret
