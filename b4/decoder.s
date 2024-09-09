# parameter order:         rdi, rsi, rdx, rcx, r8, r9, rest in reverse order on stack
# return value location:   rax
# instruction suffixes:    b - 8, w - 16, l - 32, q - 64

.text
	# this takes three arguments, first one is the foreground color, second the background color and third the character
	printf_template_fgbg: .asciz "\x1b[38;5;%dm\x1b[48;5;%dm%c"
	# this takes two, first being the SGR parameter, second the character to print
	printf_template_special: .asciz "\x1b[%dm%c"

.global main

.include "final.s"

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

	xor %r12, %r12                  # clear offset register (r12)
	movq %rdi, %r13                 # put message location in r13

# decodes the section at offset (%r13, %r12, 8)
decode_at:
	xor %r14, %r14                  # use r14 as loop index
decode_print_loop:
	# setup printf
	movq $0, %rax                   # we aren't using vector registers

	xor %rsi, %rsi                  # clear rsi
	mov 6(%r13, %r12, 8), %sil      # put the foreground color in rsi (low 8 bits)     (printf argument 2)
	xor %rdx, %rdx                  # clear rdx
	mov 7(%r13, %r12, 8), %dl       # put the background color in rdx (low 8 bits)     (printf argument 3)

	cmp %rsi, %rdx
	je decode_loop_eq               # if they are the same we need to use a different template

	movq $printf_template_fgbg, %rdi     # printf template as the first argument       (printf argument 1)

	xor %rcx, %rcx                  # clear rcx
	movb (%r13, %r12, 8), %cl       # put current character in the lower 8 bits of rcx (printf argument 4)

	jmp decode_loop_post

decode_loop_eq:
	movq $printf_template_special, %rdi     # printf template as the first argument    (printf argument 1)

	# switch statement, jump array not feasible as numbers are quite random
	cmp $37, %rsi
	je decode_loop_eq_37

	cmp $42, %rsi
	je decode_loop_eq_42

	cmp $66, %rsi
	je decode_loop_eq_66

	cmp $105, %rsi
	je decode_loop_eq_105

	cmp $153, %rsi
	je decode_loop_eq_153

	cmp $182, %rsi
	je decode_loop_eq_182

	# default case
	jmp decode_loop_eq_switch_end

decode_loop_eq_37: # stop blinking
	mov $25, %rsi
	jmp decode_loop_eq_switch_end

decode_loop_eq_42: # bold
	mov $1, %rsi
	jmp decode_loop_eq_switch_end

decode_loop_eq_66: # faint
	mov $2, %rsi
	jmp decode_loop_eq_switch_end

decode_loop_eq_105: # conceal
	mov $8, %rsi
	jmp decode_loop_eq_switch_end

decode_loop_eq_153: # reveal
	mov $28, %rsi
	jmp decode_loop_eq_switch_end

decode_loop_eq_182: # blink
	mov $5, %rsi
	jmp decode_loop_eq_switch_end

decode_loop_eq_switch_end:
	movb (%r13, %r12, 8), %dl       # put current character in the lower 8 bits of rdx (printf argument 3, we don't care about the previous value)

decode_loop_post:
	call printf

	incq %r14                       # increment loop counter
	cmpb %r14b, 1(%r13, %r12, 8)    # check against specified repetition count
	jne decode_print_loop           # loop if we aren't finished

	movl 2(%r13, %r12, 8), %r12d    # fetch next offset
	cmpq $0, %r12
	jne decode_at                   # if the next memory offset is zero we are done, otherwise loop again

end:
	# epilogue
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

