# **************************************************************
# Assignment 2, CSE1400                                        *
# by: Zofia Krok, Michał Olszewski                             *
#                                                              *
# Description:                                                 *
# This code computes the factorial of the first passed number. *
# Arguments are supplied through stdin.                        *
# **************************************************************


.data
	input: .asciz "%ld" 	# format string for scanf
	output: .asciz "%ld\n"	# format string for printf

.text
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
	pushq %rbp 			# save the base pointer
	pushq %r12
	pushq %r13
	mov %rsp, %rbp			# set up the new base pointer

	movq %rdi, %r12

	cmp $1, %r12
	jg continue			# if n != 1 compute the factorial

	movq $1, %rax			# in case n == 1, return 1
	jmp fact_end			# go to function end

continue:
	decq %rdi
	call factorial			# recursive call with n - 1

	mulq %r12			# result of factorial call is in rax, multiply with n

fact_end:
	# epilogue
	mov %rbp, %rsp			# restore the previous stack pointer
	popq %r13
	popq %r12
	pop %rbp			# restore the previous base pointer
	ret				# return from the function


main:
	# prologue
	pushq %rbp			# save the base pointer on the stack
	mov %rsp, %rbp			# set up the new base pointer

	# allocating memory
	subq $16, %rsp			# allocate 16 bytes on the stack (move the stack pointer)

	# reading the number
	movq $0, %rax			# required cleanign for scanf
	movq $input, %rdi		# move input format into %rdi (first argument)
	leaq -16(%rbp), %rsi		# set the address where to read the first number
	call scanf			# read the first number

	# setting the arguments to call the function
	mov -16(%rbp), %rdi		# move the saved number into %rdi (first argument)

	# computing the result
	call factorial			# call factorial to compute the result in %rax

	# printing the result
	mov %rax, %rsi			# move the result into the second argument
	mov $output, %rdi		# move the output format into the first argument
	mov $0, %rax			# required clearing for printf
	call printf			# print the result

	# epilogue
	mov %rbp, %rsp 			# restore the previous stack pointer
	pop %rbp			# restore the previous base pointer

	mov $0, %rdi			# set the exit status code
	call exit			# terminate the program
