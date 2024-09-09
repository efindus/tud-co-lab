# parameter order:         rdi, rsi, rdx, rcx, r8, r9, rest in reverse order on stack
# return value location:   rax
# instruction suffixes:    b - 8, w - 16, l - 32, q - 64

.text
	scanf_template: .asciz "%lld"

	res_template: .asciz "%lld\n"

.global main

# ************************************************************
# Subroutine: power                                          *
# Description: computes base ** exponent                     *
# Parameters:                                                *
#   first: the value of base (as 64 bit integer)             *
#   second: the value of exponent (as 64 bit integer)        *
#   return: base ** exponent (base to the power of e)        *
# ************************************************************
power:
	# prologue
	pushq %rbp
	movq %rsp, %rbp

	movq $1, %rax                # initial multiplication value

	xor %rcx, %rcx               # use rcx as loop counter

pwr_loop:
	mulq %rdi                    # rax = rax * rdi (which stores the base)

	incq %rcx                    # increment loop counter
	cmpq %rcx, %rsi              # loop to exponent
	jne pwr_loop

	# epilogue
	movq %rbp, %rsp
	popq %rbp

	ret                          # result is already stored in rax, as that's where mul puts it

main:
	# prologue
	pushq %rbp
	movq %rsp, %rbp

	subq $16, %rsp               # reserve space for variables

	# read the base
	movq $0, %rax
	movq $scanf_template, %rdi
	leaq -8(%rbp), %rsi          # base location
	call scanf

	# read the exponent
	movq $0, %rax
	movq $scanf_template, %rdi
	leaq -16(%rbp), %rsi         # exponent location
	call scanf

	# setup power arguments
	movq -8(%rbp), %rdi          # base
	movq -16(%rbp), %rsi         # exponent

	call power

	movq %rax, %rsi              # move result to second printf argument

	# print result
	movq $0, %rax
	movq $res_template, %rdi
	call printf

	# epilogue
	movq %rbp, %rsp
	popq %rbp

end:
	movq $0, %rdi # setup exit code
	call exit
