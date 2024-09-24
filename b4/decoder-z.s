.text
	printf_efect: .asciz "\033[%dm%c"	# format string for printf to apply effect and print a character
	printf_template: .asciz "\033[38;5;%dm\033[48;5;%dm%c"	# format string for printf to set foreground and background colors and print a character

	effects_map:		# map of effects indexed by their respective codes
		.byte 0			# 0 (reset)
		.rept 36
			.byte 0
		.endr
		.byte 25		# 37 (stop blinking)
		.rept 4
			.byte 0
		.endr
		.byte 1			# 42 (bold)
		.rept 23
			.byte 0
		.endr
		.byte 2			# 66 (faint)
		.rept 38
			.byte 0
		.endr
		.byte 8			# 105 (conceal)
		.rept 47
			.byte 0
		.endr
		.byte 28		# 153 (reveal)
		.rept 28
			.byte 0
		.endr
		.byte 5			# 182 (blink)
		.rept 73
			.byte 0
		.endr


.include "final.s"		# include external file

.global main

# ************************************************************
# Subroutine: decode                                         *
# Description: decodes message as defined in Assignment 3    *
#   - 2 byte unknown                                         *
#   - 4 byte index                                           *
#   - 1 byte amount                                          *
#   - 1 byte character                                       *
# Parameters:                                                *
#   first: the address of the message to read                *
#   return: no return value                                  *
# ************************************************************
decode:
	# prologue
	pushq	%rbp 					# push the base pointer (and align the stack)
	movq	%rsp, %rbp				# copy stack pointer value to base pointer

	# preserve, as these are callee-preserved (we are using them so we don't need to restore them after every printf call)
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15

	xor %r13, %r12                  # clear offset register (r12)
	movq %rdi, %r13                 # put message location in r13

# decodes the section at offset (%r13, %r12, 8)
decode_at:
	xor %r14, %r14                  # use r14 as loop index
decode_print_loop:
	# setup printf
	movq $0, %rax                   # clear rax (no vector registers are used)
	movq $printf_template, %rdi     # load the printf template as the first argument

	xor %rsi, %rsi                  # clear rsi
	movb 6(%r13, %r12, 8), %sil     # load the text color as the second argument

	xor %rdx, %rdx					# clear rdx
	movb 7(%r13, %r12, 8), %dxl		# load the background as the third argument

	xor %rcx, %rcx					# clear rcx
	movb (%r13, %r12, 8), %cxl		# load the character as the fourth argument

	cmp %rsi, %rdx					# compare the text color and the background color
	jne print						# jump to printing if they are equal

	# in case they are different, change printing arguments to print effects instead of colors
	mov $printf_efect, %rdi			# change printf format
	movb effects_map(, %rsi), %sil	# set the effect as the second argument
	mov %rcx, %rdx					# move the character to hte third argument

print:
	call printf

	incq %r14                       # increment loop counter
	cmpb %r14b, 1(%r13, %r12, 8)    # check against specified repetition count
	jne decode_print_loop           # loop if we aren't finished

	movl 2(%r13, %r12, 8), %r12d    # fetch next offset
	cmpq $0, %r12
	jne decode_at                   # if the next memory offset is zero we are done, otherwise loop again

end:
	# epilogue
	popq %r15						# restore the saved registers
	popq %r14
	popq %r13
	popq %r12

	movq	%rbp, %rsp				# clear local variables from stack
	popq	%rbp					# restore base pointer location
	ret

main:
	pushq	%rbp 					# push the base pointer (and align the stack)
	movq	%rsp, %rbp				# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi			# first parameter: address of the message
	call	decode					# call decode

	popq	%rbp					# restore base pointer location
	movq	$0, %rdi				# load program exit code
	call	exit					# exit the program

