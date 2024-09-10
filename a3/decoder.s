.text
	printf_template: .asciz "%c"

.include "final.s"

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
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	# preserve, as these are callee-preserved (we are using them so we don't need to restore them after every printf call)
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15

	xor %r12, %r12                  # clear offset register (r12)
	movq %rdi, %r13                 # put message location in r13

# decodes the section at offset (%r13, %r12, 8)
decode_at:
	xor %r14, %r14                  # use r14 as loop index
decode_print_loop:
	# setup printf
	movq $0, %rax                   # we aren't using vector registers
	movq $printf_template, %rdi     # printf template as the first argument

	xor %rsi, %rsi                  # clear rsi
	movb (%r13, %r12, 8), %sil      # put current character in the lower 8 bits of rsi

	call printf

	incq %r14                       # increment loop counter
	cmpb %r14b, 1(%r13, %r12, 8)    # check against specified repetition count
	jne decode_print_loop           # loop if we aren't finished

	movl 2(%r13, %r12, 8), %r12d    # fetch next offset
	cmpq $0, %r12
	jne decode_at                   # if the next memory offset is zero we are done, otherwise loop again

end:
	# epilogue
	popq %r15
	popq %r14
	popq %r13
	popq %r12

	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location
	ret

main:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi	# first parameter: address of the message
	call	decode			# call decode

	popq	%rbp			# restore base pointer location
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program

