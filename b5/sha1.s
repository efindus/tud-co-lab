.global sha1_chunk

sha1_chunk:
	pushq %rbp				# save the base pointer on the stack

	push %r10				# save registers that will be used
	push %r11
	push %r12
	push %r13
	push %r14

	movq %rsp, %rbp				# set the base pointer to the current stack pointer

	mov $16, %rdx				# set %rdx to 16; (first 16 elements are fixed
						# 				   start calculating from 16th)


# for i from 16 to 79
#        w[i] = (w[i-3] xor w[i-8] xor w[i-14] xor w[i-16]) leftrotate 1

loop:
	mov %rdx, %rcx
	sub $3, %rcx
	mov (%rsi, %rcx, 4), %r8
	mov %r8, (%rsi, %rdx, 4)		# set the value of w[i] to w[i-3]


	mov %rdx, %rcx
	sub $8, %rcx
	mov (%rsi, %rcx, 4), %r8
	xor %r8, (%rsi, %rdx, 4)		# xor the value in w[i] with w[i-8]


	mov %rdx, %rcx
	sub $14, %rcx
	mov (%rsi, %rcx, 4), %r8
	xor %r8, (%rsi, %rdx, 4)		# xor the value in w[i] with w[i-14]


	mov %rdx, %rcx
	sub $16, %rcx
	mov (%rsi, %rcx, 4), %r8
	xor %r8, (%rsi, %rdx, 4)		# xor the value in w[i] with w[i-16]



	mov (%rsi, %rdx, 4), %r8d
	rol $1, %r8d
	mov %r8, (%rsi, %rdx, 4)		# leftrotate w[i] by 1 bit (32 bits)

	inc %rdx				# increase the index value
	cmp $80, %rdx				# continue for all indexes 16-79
	jl loop




#    a = h0 (r10)
#    b = h1 (r11)
#    c = h2 (r12)
#    d = h3 (r13)
#    e = h4 (r14)

initialize:

	mov $0, %rdx
	mov (%rdi, %rdx, 4), %r10d		# load h0 into r10
	mov $1, %rdx
	mov (%rdi, %rdx, 4), %r11d		# load h1 into r11
	mov $2, %rdx
	mov (%rdi, %rdx, 4), %r12d		# load h2 into r12
	mov $3, %rdx
	mov (%rdi, %rdx, 4), %r13d		# load h3 into r13
	mov $4, %rdx
	mov (%rdi, %rdx, 4), %r14d		# load h4 into r14
	mov $0, %rdx




#    for i from 0 to 79
#        if 0 ≤ i ≤ 19 then
#            f = (b and c) or ((not b) and d)
#            k = 0x5A827999
#        else if 20 ≤ i ≤ 39
#            f = b xor c xor d
#            k = 0x6ED9EBA1
#        else if 40 ≤ i ≤ 59
#            f = (b and c) or (b and d) or (c and d)
#            k = 0x8F1BBCDC
#        else if 60 ≤ i ≤ 79
#            f = b xor c xor d
#            k = 0xCA62C1D6
#

main_loop:
	mov $0, %r8				# load 0 to r8 (f)
	mov $0, %r9 				# load 0 to r9 (k)

	cmp $19, %rdx				# case1
	jle case1

	cmp $39, %rdx				# case2
	jle case2

	cmp $59, %rdx				# case3
	jle case3

	cmp $79, %rdx				# case4
	jle case4


case1:
	mov %r11d, %r8d
	and %r12d, %r8d 			# f = b & c

	mov %r11d, %eax
	not %eax
	and %r13d, %eax 			# f = (b & c) | ((~b) & d)

	or %eax, %r8d 				# (b & c) | ((~b) & d)

	mov $0x5A827999, %r9d			# set k = 0x5A827999 for this round

	jmp last				# jump to final computation


case2:
	mov %r11d, %r8d				# f = b
	xor %r12d, %r8d				# f = b ^ c
	xor %r13d, %r8d				# f = b ^ c ^ d

	mov $0x6ED9EBA1, %r9d			# set k = 0x6ED9EBA1

	jmp last				# jump to final computation


case3:
	mov %r11d, %r8d				# f = b
	and %r12d, %r8d				# f = b & c

	mov %r11d, %eax
	and %r13d, %eax				# eax = b & d

	mov %r12d, %ecx
	and %r13d, %ecx				# ecx = c & d

	or %eax, %r8d				# f = (b & c) | (b & d)
	or %ecx, %r8d				# f = (b & c) | (b & d) | (c & d)

	mov $0x8F1BBCDC, %r9d			# set k = 0x8F1BBCDC

	jmp last				# jump to final computation


case4:
	mov %r11d, %r8d				# f = b
	xor %r12d, %r8d				# f = b ^ c
	xor %r13d, %r8d				# f = b ^ c ^ d

	mov $0xCA62C1D6, %r9d			# set k = 0xCA62C1D6

	jmp last				# jump to final computation



#	temp = (a leftrotate 5) + f + e + k + w[i]
#	e = d
#	d = c
#	c = b leftrotate 30
#	b = a
#	a = temp

last:
	mov %r10d, %ecx
	rol $5, %ecx
	add %r8d, %ecx
	add %r14d, %ecx
	add %r9d, %ecx
	add (%rsi, %rdx, 4), %ecx 		# temp value is in ecx

	mov %r13d, %r14d 			# move d to e

	mov %r12d, %r13d			# move c to d

	rol $30, %r11d
	mov %r11d, %r12d			# move rotated b to c

	mov %r10d, %r11d			# move a to b

	mov %ecx, %r10d				# move temp to a

	inc %rdx				# increase the index
	cmp $80, %rdx				# continue for indexes from 16 to 79
	jl main_loop



end:
	mov $0, %rdx
	add %r10d, (%rdi, %rdx, 4)		# add a to h0

	mov $1, %rdx
	add %r11d, (%rdi, %rdx, 4)		# add b to h1

	mov $2, %rdx
	add %r12d, (%rdi, %rdx, 4)		# add c to h2

	mov $3, %rdx
	add %r13d, (%rdi, %rdx, 4)		# add d to h3

	mov $4, %rdx
	add %r14d, (%rdi, %rdx, 4)		# add e to h4



	movq %rbp, %rsp				# restore stack pointer from base pointer
	pop %r14				# restore registers
	pop %r13
	pop %r12
	pop %r11
	pop %r10

	popq %rbp				# restore the base pointer
	ret					# return from the function
