# ******************************************************************
# Assignment 1, CSE1400                                            *
# by: Zofia Krok, Michał Olszewski                                 *
#                                                                  *
# Description:                                                     *
# This code computes the result of raising the first passed number *
# to the power of the second passed number. Arguments are supplied *
# through stdin.  Note: this program uses the fast power algorithm *
# to speed-up the process.                                         *
# ******************************************************************

.data
	input: .asciz "%ld"     # format string for scanf
	output: .asciz "%ld\n"  # format string for printf

.global main

.text

main:
	# prologue
	push %rbp                       # save the base pointer on the stack
	mov %rsp, %rbp                  # set up the new base pointer

	# allocating memory
	sub $16, %rsp                   # allocate 16 bytes on the stack (for two quads)

	# reading the first number (base)
	movq $0, %rax                   # required clearing for scanf
	movq $input, %rdi               # move input format into %rdi (first argument)
	leaq -16(%rbp), %rsi            # set the address where to read the first number
	call scanf                      # read the first number

	# reading the second number (exponent)
	movq $0, %rax
	movq $input, %rdi
	leaq -8(%rbp), %rsi
	call scanf

	# setting the argumnets to call the function
	movq -16(%rbp), %rdi            # load the first number into %rdi (first argument)
	movq -8(%rbp), %rsi             # load the second number inot %rsi (second argument)

	# computing the result
	call fastpow                    # call fastpow to compute the result (base^exponent) in %rax

	# printing the result
	movq %rax, %rsi                 # move the result into the second argument
	movq $0, %rax                   # required clearing for printf
	movq $output, %rdi              # move the output format into the first argument
	call printf                     # print the result

	# epilogue
	mov %rbp, %rsp                  # restore the previous stack pointer
	pop %rbp                        # restore the previous base pointer

	mov $0, %rdi                    # set the exit status code
	call exit                       # terminate the program


# ************************************************************
# Subroutine: fastpow                                        *
# Description: computes base ** exponent                     *
# Parameters:                                                *
#   first: the value of base (as 64 bit integer)             *
#   second: the value of exponent (as 64 bit integer)        *
#   return: base ** exponent (base to the power of e)        *
# ************************************************************
fastpow:
	push %rbp                       # save the base pointer
	mov %rsp, %rbp                  # set up the new base pointer

	movq $1, %r10                   # initialize the result
	movq %rsi, %r11                 # copy the second argument (exponent) to %r11

# checking if the exponent is odd
powloop:
	mov $0, %rdx                    # required clearing for division
	mov %r11, %rax                  # move the exponent (dividend) into %rax
	mov $2, %r8                     # move 2 (divisor) into %r8
	idiv %r8                        # divide the exponent by 2 (%rax - quotient, %rdx - remainder)
	cmp $1, %rdx                    # check if the exponent is odd (remainder is 1)
	jl rest                         # if exponent is even jump to rest (skip multiplication of the result)

	imul %rdi, %r10                 # multiply the result by the base (only if the exponent is odd)

# continuing the exponentiation
rest:
	imul %rdi, %rdi                 # square the base
	mov $0, %rdx                    # required clearing for division
	mov %r11, %rax                  # move the exponent (divident) into %rax
	mov $2, %r8                     # move 2 (divisor) into %r8
	idiv %r8                        # divide the exponent by 2 (%rax - quotient, %rdx - remainder)
	mov %rax, %r11                  # set the new exponent (previous one divided by 2)
	cmp $0, %r11                    # compare the exponent with 0
	jg powloop                      # if exponent is greater than 0, jump to powloop (continue the alghoritm)
	mov %r10, %rax                  # otherwise, the exponentiation is complete, move the result to %rax

	# epilogue
	mov %rbp, %rsp                  # restore the previous stack pointer
	pop %rbp                        # restore the previous base pointer
	ret                             # return from the function
