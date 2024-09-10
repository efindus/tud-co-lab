.data
# 30000 bytes
	program_data: .zero 30000

.text
# character reference:
# 3: +, count                          [43]
# 7: , basically getchar_unlocked      [44]
# 4: -, count                          [45]
# 8: . basically putchar_unlocked      [46]
# 2: <, count                          [60]
# 1: >, count                          [62]
# 5: [, ip to set if *val == 0         [91]
# 6: ], ip to set if *val != 0         [93]

# jump tables for speed
# table for checking whether to collapse neighbooring commands of given type
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
			.quad brainfuck_parse_loop_end2
		.endr
		.quad brainfuck_parse_loop_3     # + char [43]
		.quad brainfuck_parse_loop_7     # , char [44]
		.quad brainfuck_parse_loop_4     # - char [45]
		.quad brainfuck_parse_loop_8     # . char [46]
		.rept 13
			.quad brainfuck_parse_loop_end2
		.endr
		.quad brainfuck_parse_loop_2     # < char [60]
		.quad brainfuck_parse_loop_end2
		.quad brainfuck_parse_loop_1     # > char [62]
		.rept 28
			.quad brainfuck_parse_loop_end2
		.endr
		.quad brainfuck_parse_loop_5     # [ char [91]
		.quad brainfuck_parse_loop_end2
		.quad brainfuck_parse_loop_6     # ] char [93]
		.rept 161
			.quad brainfuck_parse_loop_end2
		.endr

# table for immediate instruction resolution
	brainfuck_instuction_jt:
		.quad brainfuck_execute_loop_0
		.quad brainfuck_execute_loop_1
		.quad brainfuck_execute_loop_2
		.quad brainfuck_execute_loop_3
		.quad brainfuck_execute_loop_4
		.quad brainfuck_execute_loop_5
		.quad brainfuck_execute_loop_6
		.quad brainfuck_execute_loop_7
		.quad brainfuck_execute_loop_8

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
	movq %rsp, %rbp

	movq %rdi, %r12     # store the pointer to the bf code in r12
	movq (%r12), %r13   # store the size of the memory buffer in r13
	addq $8, %r12       # skip the size for future use

	movq %r13, %r14
	imul $16, %r14      # allocate 2 quads for every byte of the program to definately avoid reallocations
	addq $1, %r14       # make sure we have space for the final null byte

	movq %r14, %rdi
	call malloc
	movq %rax, %r14     # store the pointer in r14, as we don't need the size anymore

	xor %rax, %rax      # use rax as the loop counter
	xor %rcx, %rcx      # clear rcx before using cl in the loop
	xor %rdx, %rdx      # use rdx as the write counter
brainfuck_parse_loop:
	movq $1, %rbx       # use rbx as repetition counter
	movb (%r12, %rax), %cl                  # store the current character in cl

	cmpb $1, char_repetition_table(, %ecx)  # check if we can collapse adjacent commands of this type
	jne brainfuck_parse_loop_after_rep      # skip collapsing if not

brainfuck_parse_loop_rep_loop:
	cmpb %cl, 1(%r12, %rax)                 # check if the next character is the same
	jne brainfuck_parse_loop_after_rep      # end if not

	inc %rax
	inc %rbx                                # increase file index and repetition counter
	jmp brainfuck_parse_loop_rep_loop       # loop

brainfuck_parse_loop_after_rep:
	jmp *char_parse_rep_table(, %ecx, 8)    # lookup the current character in the jumptable, every character outside of brainfuck's 8 points to brainfuck_parse_loop_end2, which doesn't increase the bytecode pointer

# 1: >, count                          [62]
brainfuck_parse_loop_1:
	movq $1, (%r14, %rdx, 8)                # bytecode 1
	movq %rbx, 8(%r14, %rdx, 8)             # store repetiton count
	jmp brainfuck_parse_loop_end

# 2: <, count                          [60]
brainfuck_parse_loop_2:
	movq $2, (%r14, %rdx, 8)                # bytecode 2
	movq %rbx, 8(%r14, %rdx, 8)             # store repetiton count
	jmp brainfuck_parse_loop_end

# 3: +, count                          [43]
brainfuck_parse_loop_3:
	movq $3, (%r14, %rdx, 8)                # bytecode 3
	movq %rbx, 8(%r14, %rdx, 8)             # store repetiton count
	jmp brainfuck_parse_loop_end

# 4: -, count                          [45]
brainfuck_parse_loop_4:
	movq $4, (%r14, %rdx, 8)                # bytecode 4
	movq %rbx, 8(%r14, %rdx, 8)             # store repetiton count
	jmp brainfuck_parse_loop_end

# 5: [, ip to set if *val == 0         [91]
brainfuck_parse_loop_5:
	movq $5, (%r14, %rdx, 8)                # bytecode 5
	pushq %rdx                              # store the location on stack for reference by the closing bracket
	jmp brainfuck_parse_loop_end

# 6: ], ip to set if *val != 0         [93]
brainfuck_parse_loop_6:
	movq $6, (%r14, %rdx, 8)                # bytecode 6
	popq %rbx                               # get location for the matching opening bracket
	movq %rdx, 8(%r14, %rbx, 8)             # set the jump location for the opening bracket to itself, opening brackets always jump to the end as I believe the branch prediction will optimize that better than having another compare in the opening bracket handler

	addq $2, %rbx                           # offset the jump-back pointer to point at the first instuction after the opening bracket
	movq %rbx, 8(%r14, %rdx, 8)             # set the jump location
	jmp brainfuck_parse_loop_end

# 7: , basically getchar_unlocked      [44]
brainfuck_parse_loop_7:
	movq $7, (%r14, %rdx, 8)                # bytecode 7
	jmp brainfuck_parse_loop_end

# 8: . basically putchar_unlocked      [46]
brainfuck_parse_loop_8:
	movq $8, (%r14, %rdx, 8)                # bytecode 8
	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_end:
	addq $2, %rdx                   # each instruction in the bytecode consists of two quads, hence we advance by two (if the current character was a valid brainfuck command)

brainfuck_parse_loop_end2:
	inc %rax                        # advance the file index
	cmp %r13, %rax                  # and check for length
	jne brainfuck_parse_loop

	movq $0, (%r14, %rdx, 8)        # bytecode 0 halts execution

# parsing is done, now time to execute
# current register state: bytecode in r14, rest irrelevant
	xor %r15, %r15             # use r15 as instruction pointer
	xor %r13, %r13             # use r13 as memory pointer
	movq $program_data, %r12   # use r12 as pointer to program memory

brainfuck_execute_loop:
	movq (%r14, %r15, 8), %rax               # fetch current instruction
	jmp *brainfuck_instuction_jt(, %rax, 8)  # go to the correct branch based on the jumptable

# 1: >, count                          [62]
brainfuck_execute_loop_1:
	addq 8(%r14, %r15, 8), %r13              # add the argument to the memory pointer
	jmp brainfuck_execute_loop_end

# 2: <, count                          [60]
brainfuck_execute_loop_2:
	subq 8(%r14, %r15, 8), %r13              # subtract the argument from the memory pointer
	jmp brainfuck_execute_loop_end

# 3: +, count                          [43]
brainfuck_execute_loop_3:
	movq 8(%r14, %r15, 8), %rax              # fetch the argument into a register
	addb %al, (%r12, %r13)                   # add the argument at the memory pointer
	jmp brainfuck_execute_loop_end

# 4: -, count                          [45]
brainfuck_execute_loop_4:
	movq 8(%r14, %r15, 8), %rax              # fetch the argument into a register
	subb %al, (%r12, %r13)                   # subtract the argument at the memory pointer
	jmp brainfuck_execute_loop_end

# 5: [, ip to set if *val == 0         [91]
brainfuck_execute_loop_5:
	cmpb $0, (%r12, %r13)                    # check if current cell equal to zero
	jne brainfuck_execute_loop_end           # fall through if false

	movq 8(%r14, %r15, 8), %r15              # move IP to the end bracket
	jmp brainfuck_execute_loop               # skip loop end, the IP is already advanced

# 6: ], ip to set if *val != 0         [93]
brainfuck_execute_loop_6:
	cmpb $0, (%r12, %r13)                    # check if current cell equal to zero
	je brainfuck_execute_loop_end            # fall through if true

	movq 8(%r14, %r15, 8), %r15              # move IP to after the start bracket
	jmp brainfuck_execute_loop               # skip loop end, the IP is already advanced

# 7: , basically getchar_unlocked      [44]
brainfuck_execute_loop_7:
	call getchar_unlocked                    # quickest way to get a single character from stdin
	movb %al, (%r12, %r13)                   # set the current cell to the output
	jmp brainfuck_execute_loop_end

# 8: . basically putchar_unlocked      [46]
brainfuck_execute_loop_8:
	movb (%r12, %r13), %dil                  # fetch current cell into the argument of putchar
	call putchar_unlocked                    # quickest way to print a single character to stdout
	jmp brainfuck_execute_loop_end

brainfuck_execute_loop_end:
	addq $2, %r15                            # advance the instruction pointer
	jmp brainfuck_execute_loop

brainfuck_execute_loop_0: # end of execution

	# epilogue
	movq %rbp, %rsp
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rbp
	ret

#
# general ideas:
# 30000 pre-zeroed bytes in data
# convert the code into "bytecode"
#
# use a jump table, both for parsing and for the actual instructions
#
# bytecode definition: (ASCII character number in brackets)
# 0-8, arg (if applicable)
# 0: halt (end of the program)
# 1: >, count                          [62]
# 2: <, count                          [60]
# 3: +, count                          [43]
# 4: -, count                          [45]
# 5: [, ip to set if *val == 0         [91]
# 6: ], ip to set if *val != 0         [93]
# 7: , basically getchar_unlocked      [44]
# 8: . basically putchar_unlocked      [46]
#
