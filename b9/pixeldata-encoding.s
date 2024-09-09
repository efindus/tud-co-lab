.include "run-length-encoding.s"
.include "barcode.s"

# **************************************************************************
# Subroutine: encode_message_in_pixeldata                                  *
# Description: prefix and suffix the message with the pattern, run it      *
#              through RLE-8 and XOR it into the barcode pixeldata         *
# Parameters:                                                              *
#   first: the address of the null-terminated message string               *
#   return: malloc'd buffer with the pixeldata containing encoded message  *
# **************************************************************************
encode_message_in_pixeldata:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	# calculate the length of message
	movq $-1, %rax                  # start from negative to simplify the loop
em_calc_msg_size_loop:
	inc %rax
	cmpb $0, (%rdi, %rax, 1)        # check for null-terminator
	jne em_calc_msg_size_loop       # loop if not the case

	addq $61, %rax                  # space for null-terminator and two patterns (2*30 + 1)

	subq %rax, %rsp                 # make room for the concatenated string on the stack

	# align to 16 bytes
	movq $0b1111, %rax
	and %rsp, %rax                  # mask to get misaligned byte count
	subq %rax, %rsp                 # align rsp

	movq %rsp, %rax                 # save base location for concatenated string

	# preserve callee-preserved registers
	pushq %r12
	pushq %r13

	movq %rdi, %r12                 # store pointer to message in r12
	movq %rax, %r13                 # store pointer to stack-allocated space for concatenated string in r13

	movq $pattern, %rcx             # store pointer to address in rcx

	xor %rax, %rax                  # use rax as inner iterator
	xor %rbx, %rbx                  # use rbx as global iterator
	# set the prefix to pattern
em_pattern_push_loop:
	movb (%rcx, %rax, 1), %dl       # load pattern[rax] into dl
	movb %dl, (%r13, %rbx, 1)       # put dl into res[rbx]
	cmpb $0, %dl                    # check for null-terminator
	je em_pattern_push_loop_end     # loop if not found

	inc %rax
	inc %rbx
	jmp em_pattern_push_loop

em_pattern_push_loop_end:
	xor %rax, %rax                  # clear inner iterator

	# put the string in the middle
em_message_push_loop:
	movb (%r12, %rax, 1), %dl       # load message[rax] into dl
	movb %dl, (%r13, %rbx, 1)       # put dl into res[rbx]
	cmpb $0, %dl                    # check for null-terminator
	je em_message_push_loop_end     # loop if not found

	inc %rax
	inc %rbx
	jmp em_message_push_loop

em_message_push_loop_end:
	xor %rax, %rax                  # clear inner iterator

	# set the suffix to pattern
em_pattern2_push_loop:
	movb (%rcx, %rax, 1), %dl       # load pattern[rax] into dl
	movb %dl, (%r13, %rbx, 1)       # put dl into res[rbx]
	cmpb $0, %dl                    # check for null-terminator
	je em_pattern2_push_loop_end    # loop if not found

	inc %rax
	inc %rbx
	jmp em_pattern2_push_loop

em_pattern2_push_loop_end:
	movq %r13, %rdi                 # set the stack-allocated string as the RLE source
	call run_length_encode

	movq %rax, %r13                 # put pointer to the encoded string in r13

	call generate_barcode

	# xor encoded string with pixeldata
	movq $-1, %rbx                  # start from negative to simplify loop
em_encode_msg_loop:
	inc %rbx
	movb (%r13, %rbx, 1), %dl       # load string[rbx] into dl
	xorb %dl, (%rax, %rbx, 1)       # xor dl with pixeldata[rbx] and store the result there
	cmpb $0, %dl                    # check for null-terminator
	jne em_encode_msg_loop          # loop if not found

	movq %rax, %r12                 # preserve rax across free call

	# free the string allocated by RLE subroutine
	movq %r13, %rdi                 # put the pointer to allocated string as first argument for free
	call free

	movq %r12, %rax

	# restore callee-preserved registers
	popq %r13
	popq %r12

	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location
	ret


# **************************************************************************
# Subroutine: decode_message_from_pixeldata                                *
# Description: XOR the message out, decode RLE-8, strip prefix and suffix  *
# Parameters:                                                              *
#   first: the address of pixeldata containing the encoded message         *
#   return: malloc'd buffer the null-terminated decoded message            *
# **************************************************************************
decode_message_from_pixeldata:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)

	# callee-preserved registers
	pushq   %r12
	pushq   %r13

	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq %rdi, %r12                 # store the provided pixel data in r12

	call generate_barcode           # get a fresh barcode to xor with

	# xor fresh pixeldata with the one containing a message
	movq $-1, %rbx                  # start from negative to simplify loop
dm_decode_msg_loop:
	inc %rbx
	movb (%r12, %rbx, 1), %dl       # load old_pixeldata[rbx] into dl
	xorb %dl, (%rax, %rbx, 1)       # xor dl with fresh_pixeldata[rbx] and store the result there
	cmpb $0, (%rax, %rbx, 1)        # check for null-terminator
	jne dm_decode_msg_loop          # loop if not found

	movq %rax, %r13                 # store the

	movq %r13, %rdi
	call run_length_decode

	movq %rax, %r12

	movq %r13, %rdi
	call free

	# calculate the length of the message with the prefix and suffix
	movq $-1, %rax                  # start from negative to simplify the loop
dm_calc_msg_size_loop:
	inc %rax
	cmpb $0, (%r12, %rax, 1)        # check for null-terminator
	jne dm_calc_msg_size_loop       # loop if not the case

	subq $60, %rax                  # (invalid) space for null-terminator and two patterns (2*30 + 1)

	movq %rax, %r13

	movq %rax, %rdi
	call malloc

	xor %rbx, %rbx
dm_msg_extract_loop:
	movb 30(%r12, %rbx, 1), %dl     # load message[rbx + 30] into dl
	movb %dl, (%rax, %rbx, 1)       # put dl into res[rbx]

	inc %rbx
	cmpq %rbx, %r13                 # check if we are done
	jne dm_msg_extract_loop         # loop if not

	movb $0, (%rax, %rbx, 1)

	movq %rax, %r13

	movq %r12, %rdi
	call free

	movq %r13, %rax

	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack

	# callee-preserved registers
	popq    %r13
	popq    %r12

	popq	%rbp			# restore base pointer location
	ret
