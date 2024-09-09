.data
# 30000 quads
	program_data: .zero 240000

.text
# character reference:
# 3: +, count                          [43]
# 7: , basically getchar_unlocked      [44]
# 4: -, count                          [45]
# 8: . basically putchar_unlocked      [46]
# 2: <, count                          [60]
# 1: >, count                          [62]
# 5: [, ip to set if *val === 0        [91]
# 6: ], ip to set if *val !== 0        [93]

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
# modification: first quad in the buffer is the length
# a zero termianted string containing the code to execute.
brainfuck:
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
	xor %rcx, %rcx
	xor %rdx, %rdx      # use rdx as the write counter
	xor %r15, %r15
brainfuck_parse_loop:
	movq $1, %rbx       # use rbx as repetition counter
	movb (%r12, %rax), %cl

	cmpb $1, char_repetition_table(, %ecx)
	jne brainfuck_parse_loop_after_rep

brainfuck_parse_loop_rep_loop:
	cmpb %cl, 1(%r12, %rax)
	jne brainfuck_parse_loop_after_rep

	inc %rax
	inc %rbx
	jmp brainfuck_parse_loop_rep_loop

brainfuck_parse_loop_after_rep:
	jmp *char_parse_rep_table(, %ecx, 8)

brainfuck_parse_loop_1:
	movq $1, (%r14, %rdx, 8)
	movq %rbx, 8(%r14, %rdx, 8)
	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_2:
	movq $2, (%r14, %rdx, 8)
	movq %rbx, 8(%r14, %rdx, 8)
	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_3:
	movq $3, (%r14, %rdx, 8)
	movq %rbx, 8(%r14, %rdx, 8)
	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_4:
	movq $4, (%r14, %rdx, 8)
	movq %rbx, 8(%r14, %rdx, 8)
	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_5:
	movq $5, (%r14, %rdx, 8)
	pushq %rdx
	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_6:
	movq $6, (%r14, %rdx, 8)
	popq %rbx
	movq %rdx, 8(%r14, %rbx, 8)

	addq $2, %rbx
	movq %rbx, 8(%r14, %rdx, 8)
	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_7:
	movq $7, (%r14, %rdx, 8)
	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_8:
	movq $8, (%r14, %rdx, 8)
	jmp brainfuck_parse_loop_end

brainfuck_parse_loop_end:
	addq $2, %rdx

brainfuck_parse_loop_end2:
	inc %rax
	cmp %r13, %rax
	jne brainfuck_parse_loop

	movq $0, (%r14, %rdx, 8)

# parsing done
# time to execute :)
# bytecode in r14, rest irrelevant
	xor %r15, %r15             # use r15 as instruction pointer
	xor %r13, %r13             # use r13 as memory pointer
	movq $program_data, %r12   # use r12 as pointer to program memory

brainfuck_execute_loop:
	movq (%r14, %r15, 8), %rax
	jmp *brainfuck_instuction_jt(, %rax, 8)
# 1: >, count                          [62]
# 2: <, count                          [60]
# 3: +, count                          [43]
# 4: -, count                          [45]
# 5: [, ip to set if *val === 0        [91]
# 6: ], ip to set if *val !== 0        [93]
# 7: , basically getchar_unlocked      [44]
# 8: . basically putchar_unlocked      [46]

brainfuck_execute_loop_1:
	addq 8(%r14, %r15, 8), %r13
	jmp brainfuck_execute_loop_end

brainfuck_execute_loop_2:
	subq 8(%r14, %r15, 8), %r13
	jmp brainfuck_execute_loop_end

brainfuck_execute_loop_3:
	movq 8(%r14, %r15, 8), %rax
	addq %rax, (%r12, %r13, 8)
	jmp brainfuck_execute_loop_end

brainfuck_execute_loop_4:
	movq 8(%r14, %r15, 8), %rax
	subq %rax, (%r12, %r13, 8)
	jmp brainfuck_execute_loop_end

brainfuck_execute_loop_5:
	movq 8(%r14, %r15, 8), %r15
	jmp brainfuck_execute_loop   # exception, the IP is already advanced

brainfuck_execute_loop_6:
	cmpq $0, (%r12, %r13, 8)
	je brainfuck_execute_loop_end

	movq 8(%r14, %r15, 8), %r15
	jmp brainfuck_execute_loop   # exception, the IP is already advanced

brainfuck_execute_loop_7:
	xor %rax, %rax
	call getchar_unlocked
	movq %rax, (%r12, %r13, 8)
	jmp brainfuck_execute_loop_end

brainfuck_execute_loop_8:
	movq (%r12, %r13, 8), %rdi
	call putchar_unlocked
	jmp brainfuck_execute_loop_end

brainfuck_execute_loop_end:
	addq $2, %r15
	jmp brainfuck_execute_loop

brainfuck_execute_loop_0: # end of execution
	movq %rbp, %rsp
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rbp
	ret

#
# 30000 quads in data
# convert the code into "bytecode"
#
# use a jump table, both for parsing and for the actual instructions
#
# 0-8, arg (if applicable)
# 0: halt (end of the program)
# 1: >, count                          [62]
# 2: <, count                          [60]
# 3: +, count                          [43]
# 4: -, count                          [45]
# 5: [, ip to set if *val === 0        [91]
# 6: ], ip to set if *val !== 0        [93]
# 7: , basically getchar_unlocked      [44]
# 8: . basically putchar_unlocked      [46]
#
