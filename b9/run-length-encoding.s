
# ***********************************************************************
# Subroutine: run_length_encode                                         *
# Description: compresses the given string until a null byte using RLE  *
# Parameters:                                                           *
#   first: the address of the null-terminated-string to compress        *
#   return: malloc'd buffer with rle string                             *
# ***********************************************************************
run_length_encode:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	xor %rax, %rax                  # index the loop
	xor %rbx, %rbx                  # push counter

rle_loop:
	xor %r8, %r8                    # clear r8
	movb (%rdi, %rax, 1), %r8b      # store current character in r8 (low 8 bits)

	xor %rcx, %rcx                  # use rcx as the current repetition counter

rle_inner_loop:
	inc %rcx                        # increment repetition counter
	inc %rax                        # increment array index

	cmpb %r8b, (%rdi, %rax, 1)      # check if character repeated
	je rle_inner_loop               # loop if true

rle_overflow_loop:
	cmpq $255, %rcx                 # check if we would overflow the byte
	jle rle_overflow_loop_continue  # continue normally if not

	subq $255, %rcx                 # subtract max 8-bit integer
	pushq $255                      # push repetition count to the stack
	pushq %r8                       # push the repeated character to the stack
	addq $2, %rbx                   # count the number of pushes to stack
	jmp rle_overflow_loop           # loop until no longer overflows

rle_overflow_loop_continue:
	pushq %rcx                      # push the repetition count to the stack
	pushq %r8                       # push the repeated character to the stack
	addq $2, %rbx                   # count the number of pushes to stack

	cmpb $0, (%rdi, %rax, 1)        # check for end of string
	jne rle_loop                    # loop if not the case

	pushq $0                        # indicate end of string
	inc %rbx

	pushq %rbx                      # preserve the push count

	movq %rbx, %rdi                 # number of bytes to malloc
	call malloc                     # malloc the buffer to return

	popq %rbx                       # restore push count

rle_pop_loop:
	popq %r8                        # take a byte from the stack (to preserve alignment we are using just 8 bits of the 64 in qword)

	dec %rbx
	movb %r8b, (%rax, %rbx, 1)      # put the value into the malloc'd area in stack order

	cmp $0, %rbx                    # check if we are done
	jne rle_pop_loop                # loop otherwise

	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location
	ret


# *************************************************************************
# Subroutine: run_length_decode                                           *
# Description: uncompresses the given string until a null byte using RLE  *
# Parameters:                                                             *
#   first: the address of the null-terminated-string to decompress        *
#   return: malloc'd buffer with the uncompressed string                  *
# *************************************************************************
run_length_decode:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	xor %rax, %rax                  # index the loop
	xor %rbx, %rbx                  # push counter

	xor %r8, %r8                    # clear r8
	xor %r9, %r9                    # clear r9
rld_loop:
	movb (%rdi, %rax, 1), %r8b      # store repetition count in r8 (low 8 bits)
	inc %rax
	movb (%rdi, %rax, 1), %r9b      # store current character in r9 (low 8 bits)
	inc %rax

	xor %rcx, %rcx                  # use rcx as the inner index

rld_inner_loop:
	pushq %r9
	inc %rcx                        # increment inner index

	cmpq %rcx, %r8                  # check if we are done
	jne rld_inner_loop              # loop otherwise

	addq %r8, %rbx                  # count the number of pushes to stack

	cmpb $0, (%rdi, %rax, 1)        # check for end of string
	jne rld_loop                    # loop if not the case

	pushq $0                        # indicate end of string
	inc %rbx

	pushq %rbx                      # preserve the push count

	movq %rbx, %rdi                 # number of bytes to malloc
	call malloc                     # malloc the buffer to return

	popq %rbx                       # restore push count

rld_pop_loop:
	popq %r8                        # take a byte from the stack (to preserve alignment we are using just 8 bits of the 64 in qword)

	dec %rbx
	movb %r8b, (%rax, %rbx, 1)      # put the value into the malloc'd area in stack order

	cmp $0, %rbx                    # check if we are done
	jne rld_pop_loop                # loop otherwise

	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location
	ret
