.text
	barcode_size: .quad 3072

# ****************************************************************************************************
# Subroutine: _generate_barcode_repeat_subroutine                                                    *
# Description: internal subroutine to avoid code duplication, assumes internal calling enviornment   *
# Parameters:                                                                                        *
#   first: color to fill                                                                             *
#   second: repeat count                                                                             *
#   return: nothing                                                                                  *
# ****************************************************************************************************
_generate_barcode_repeat_subroutine:
	xor %rcx, %rcx

_generate_barcode_repeat_subroutine_loop:
	movq %rdi, (%rax, %rdx, 1)
	movq %rdi, 1(%rax, %rdx, 1)
	movq %rdi, 2(%rax, %rdx, 1)

	inc %rcx
	addq $3, %rdx
	cmp %rsi, %rcx
	jne _generate_barcode_repeat_subroutine_loop
	ret

# *************************************************************************
# Subroutine: generate_barcode                                            *
# Description: generate the barcode from Assignment 9                     *
# Parameters: none                                                        *
#   return: malloc'd buffer with the raw RGB data                         *
# *************************************************************************
generate_barcode:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq $barcode_size, %rdi        # allocate space for the barcode
	call malloc

	xor %rbx, %rbx                  # row iterator
	xor %rdx, %rdx                  # byte iterator

generate_barcode_main_loop:
	# fill a row according to the Assignment spec
	movq $255, %rdi
	movq $8, %rsi
	call _generate_barcode_repeat_subroutine

	movq $0, %rdi
	movq $8, %rsi
	call _generate_barcode_repeat_subroutine

	movq $255, %rdi
	movq $4, %rsi
	call _generate_barcode_repeat_subroutine

	movq $0, %rdi
	movq $4, %rsi
	call _generate_barcode_repeat_subroutine

	movq $255, %rdi
	movq $2, %rsi
	call _generate_barcode_repeat_subroutine

	movq $0, %rdi
	movq $3, %rsi
	call _generate_barcode_repeat_subroutine

	movq $255, %rdi
	movq $2, %rsi
	call _generate_barcode_repeat_subroutine

	movq $255, (%rax, %rdx, 1)
	movq $0, 1(%rax, %rdx, 1)
	movq $0, 2(%rax, %rdx, 1)

	addq $3, %rdx

	inc %rbx
	cmp $32, %rbx                   # fill 32 rows
	jne generate_barcode_main_loop  # loop until done

	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location
	ret
