# parameter order:         rdi, rsi, rdx, rcx, r8, r9, rest in reverse order on stack
# return value location:   rax
# instruction suffixes:    b - 8, w - 16, l - 32, q - 64

.text
	scanf_template: .asciz "%lld"

	res_template: .asciz "%lld\n"

.global main

# ************************************************************
# Subroutine: factorial                                      *
# Description: computes a factorial (n!)                     *
# Parameters:                                                *
#   first: the value of n (as 64 bit integer)                *
#   return: the factorial of n (n!)                          *
# ************************************************************
factorial:
	# prologue
	pushq %rbp
	movq %rsp, %rbp

	cmp $1, %rdi
	jne fact_continue  # if n != 1 compute the factorial

	movq $1, %rax      # in case n == 1, return 1
	jmp fact_end       # go to function end

fact_continue:
	pushq %rdi         # preserve original n

	decq %rdi
	call factorial     # recursive call with n - 1

	popq %rdi          # restore original n
	mulq %rdi          # result of factorial call is in rax, multiply with n

fact_end:
	# epilogue
	movq %rbp, %rsp
	popq %rbp

	ret                # result in rax

main:
	# prologue
	pushq %rbp
	movq %rsp, %rbp

	subq $16, %rsp     # reserve space for variables

	# read n
	movq $0, %rax
	movq $scanf_template, %rdi
	leaq -8(%rbp), %rsi         # n location
	call scanf

	movq -8(%rbp), %rdi         # setup factorial argument
	call factorial

	movq %rax, %rsi             # move factorial result to second printf argument

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
