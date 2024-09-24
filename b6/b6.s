.data
	retvalid: .asciz "valid"
	retinvalid: .asciz "invalid"

.text

.include "basic.s"

.global main

# *******************************************************************************************
# Subroutine: check_validity                                                                *
# Description: checks the validity of a string of parentheses as defined in Assignment 6.   *
# Parameters:                                                                               *
#   first: the string that should be check_validity                                         *
#   return: the result of the check, either "valid" or "invalid"                            *
# *******************************************************************************************
check_validity:
	# prologue
	pushq	%rbp 				# push the base pointer (and align the stack)
	movq	%rsp, %rbp			# copy stack pointer value to base pointer

	mov $0, %r8				# set 0 to r8 to count the number of brackets

iterate:
	movb (%rdi), %al			# load the first character of the input to rax

	testb %al, %al				# check if the character is null terminator
	je end_iter				# finish the iteration if the string has ended

	cmpb $')', %al				# compare the character with different closing brackets
	je closing_paren			# jump to appropriate label

	cmpb $']', %al
	je closing_square

	cmpb $'}', %al
	je closing_curly

	cmpb $'>', %al
	je closing_angle

	jmp opening				# jump to label for opening brackets


closing_paren:
	dec %r8					# descrease the bracket counter
	pop %rdx				# load the last opening bracket to rdx
	cmpb $'(', %dl				# compare it with the appropriate opening bracket
	jne invalid				# if not equal, input is invalid
	jmp continue				# else continue iterating


closing_square:
	dec %r8
	pop %rdx
	cmpb $'[', %dl
	jne invalid
	jmp continue


closing_curly:
	dec %r8
	pop %rdx
	cmpb $'{', %dl
	jne invalid
	jmp continue


closing_angle:
	dec %r8
	pop %rdx
	cmpb $'<', %dl
	jne invalid
	jmp continue


opening:
	inc %r8					# increase the bracket counter
	push %rax				# push the current chracter on the stack
	jmp continue				# continue iterating


continue:
	inc %rdi				# move to the next character in the string
    jmp iterate					# continue iterating


invalid:
	mov $retinvalid, %rax			# load the address of the "invalid" string
	jmp epilogue				# jump to the end of the function


end_iter:
	cmp $0, %r8				# check if all brackets are matched
	jne invalid				# if not, go to "invalid"

	mov $retvalid, %rax			# load the address of the "valid" string
	jmp epilogue				# jumo to the end of the function

epilogue:
	# epilogue
	movq	%rbp, %rsp			# clear local variables from stack
	popq	%rbp				# restore base pointer location
	ret					# return from the function


main:
	pushq	%rbp 				# push the base pointer (and align the stack)
	movq	%rsp, %rbp			# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi			# first parameter: address of the message
	call	check_validity			# call check_validity

	popq	%rbp				# restore base pointer location
	movq	$0, %rdi			# load program exit code
	call	exit				# exit the program
