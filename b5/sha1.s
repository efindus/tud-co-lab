
.global sha1_chunk

sha1_chunk:
	# prologue
	pushq %rbp

	push %r10
	push %r11
	push %r12
	push %r13
	push %r14

	movq %rsp, %rbp


	mov $16, %rdx
loop:
	mov %rdx, %rcx
	sub $3, %rcx
	mov (%rsi, %rcx, 4), %r8
	mov %r8, (%rsi, %rdx, 4)


	mov %rdx, %rcx
	sub $8, %rcx
	mov (%rsi, %rcx, 4), %r8
	xor %r8, (%rsi, %rdx, 4)


	mov %rdx, %rcx
	sub $14, %rcx
	mov (%rsi, %rcx, 4), %r8
	xor %r8, (%rsi, %rdx, 4)


	mov %rdx, %rcx
	sub $16, %rcx
	mov (%rsi, %rcx, 4), %r8
	xor %r8, (%rsi, %rdx, 4)



	mov (%rsi, %rdx, 4), %r8d
	rol $1, %r8d
	mov %r8, (%rsi, %rdx, 4)

	inc %rdx
	cmp $80, %rdx
	jl loop



mid:

	mov $0, %rdx
	mov (%rdi, %rdx, 4), %r10d
	mov $1, %rdx
	mov (%rdi, %rdx, 4), %r11d
	mov $2, %rdx
	mov (%rdi, %rdx, 4), %r12d
	mov $3, %rdx
	mov (%rdi, %rdx, 4), %r13d
	mov $4, %rdx
	mov (%rdi, %rdx, 4), %r14d
	mov $0, %rdx

loop2:
	mov $0, %r8 # f
	mov $0, %r9 # k

	cmp $19, %rdx
	jle case1

	cmp $39, %rdx
	jle case2

	cmp $59, %rdx
	jle case3

	cmp $79, %rdx
	jle case4


case1:
	mov %r11d, %r8d
	and %r12d, %r8d # b and c

	mov %r11d, %eax
	not %eax
	and %r13d, %eax # (not b) and d

	or %eax, %r8d # (b and c) or ((not b) and d)

	mov $0x5A827999, %r9d

	jmp last


case2:
	mov %r11d, %r8d
	xor %r12d, %r8d
	xor %r13d, %r8d

	mov $0x6ED9EBA1, %r9d

	jmp last


case3:
	mov %r11d, %r8d
	and %r12d, %r8d	# b and c

	mov %r11d, %eax
	and %r13d, %eax	# b and d

	mov %r12d, %ecx
	and %r13d, %ecx	# c and d

	or %eax, %r8d
	or %ecx, %r8d

	mov $0x8F1BBCDC, %r9d

	jmp last

case4:
	mov %r11d, %r8d
	xor %r12d, %r8d
	xor %r13d, %r8d

	mov $0xCA62C1D6, %r9d

	jmp last


last:
	mov %r10d, %ecx
	rol $5, %ecx

	add %r8d, %ecx
	add %r14d, %ecx
	add %r9d, %ecx
	add (%rsi, %rdx, 4), %ecx

	mov %r13d, %r14d # mov d to e

	mov %r12d, %r13d # mov c to d

	rol $30, %r11d
	mov %r11d, %r12d

	mov %r10d, %r11d

	mov %ecx, %r10d

	inc %rdx

	cmp $80, %rdx

	jl loop2



end:
	mov $0, %rdx
	add %r10d, (%rdi, %rdx, 4)

	mov $1, %rdx
	add %r11d, (%rdi, %rdx, 4)

	mov $2, %rdx
	add %r12d, (%rdi, %rdx, 4)

	mov $3, %rdx
	add %r13d, (%rdi, %rdx, 4)

	mov $4, %rdx
	add %r14d, (%rdi, %rdx, 4)



	movq %rbp, %rsp
	pop %r14
	pop %r13
	pop %r12
	pop %r11
	pop %r10

	popq %rbp
	ret

