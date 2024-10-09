.text
	pattern: .asciz "CCCCCCCCSSSSEE1111444400000000"
	to_encode: .asciz "The answer for exam question 42 is not F."
	filename: .asciz "output.bmp"
	printf_pattern: .asciz "%s\n"
	barcode_size: .quad 3072

.macro REPEAT_MOV repeatcount
    .rept \repeatcount
        movb %dil, (%rax, %rdx, 1)
        movb %dil, 1(%rax, %rdx, 1)
        movb %dil, 2(%rax, %rdx, 1)
        addq $3, %rdx
    .endr
.endm

# *************************************************************************
# Subroutine: generate_barcode                                            *
# Description: generate the barcode from Assignment 9                     *
# Parameters: none                                                        *
#   return: malloc'd buffer with the raw RGB data                         *
# *************************************************************************
generate_barcode:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	pushq   %rbx
	pushq   %rbx
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq $barcode_size, %rdi        # allocate space for the barcode
	call malloc

	xor %rbx, %rbx                  # row iterator
	xor %rdx, %rdx                  # byte iterator

generate_barcode_main_loop:
	# fill a row according to the Assignment spec
	movq $255, %rdi
	REPEAT_MOV 8

	movq $0, %rdi
	REPEAT_MOV 8

	movq $255, %rdi
	REPEAT_MOV 4

	movq $0, %rdi
	REPEAT_MOV 4

	movq $255, %rdi
	REPEAT_MOV 2

	movq $0, %rdi
	REPEAT_MOV 3

	movq $255, %rdi
	REPEAT_MOV 2

	movb $0, (%rax, %rdx, 1)
	movb $0, 1(%rax, %rdx, 1)
	movb $255, 2(%rax, %rdx, 1)

	addq $3, %rdx

	inc %rbx
	cmp $32, %rbx                   # fill 32 rows
	jne generate_barcode_main_loop  # loop until done

	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack
	popq    %rbx
	popq    %rbx
	popq	%rbp			# restore base pointer location
	ret

.text
	bmp_header: .byte 0x42, 0x4d, 0x36, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x36, 0x00, 0x00, 0x00, 0x28, 0x00
	            .byte 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x01, 0x00, 0x18, 0x00, 0x00, 0x00
		    .byte 0x00, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x13, 0x0b, 0x00, 0x00, 0x13, 0x0b, 0x00, 0x00, 0x00, 0x00
		    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

crash:
	movq $0, (,1)

# ************************************************************
# Subroutine: generate_bmp_from_pixeldata                    *
# Description: takes RGB pixel data and generates a BMP      *
# Parameters:                                                *
#   first: the address of the pixel data                     *
#   return: malloc'd buffer with the BMP                     *
# ************************************************************
generate_bmp_from_pixeldata:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)

	# callee-preserved registers
	pushq   %r12
	pushq   %r13
	pushq %rbx
	pushq %rbx

	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq %rdi, %r12                 # store the pointer to pixeldata in r12

	movq $3126, %rdi                # allocate space for the BMP
	call malloc

	movq %rax, %r13                 # store the pointer to BMP in r13
	movq $bmp_header, %rbx          # store the pointer to BMP header in rbx

	xor %rax, %rax                  # use rax as the iterator
gen_bmp_header_loop:
	# bmp[rax] = bmp_header[rax]
	movb (%rbx, %rax, 1), %cl
	movb %cl, (%r13, %rax, 1)

	inc %rax
	cmp $54, %rax                   # copy 54 bytes
	jne gen_bmp_header_loop

	xor %rdx, %rdx                  # use rdx as the row iterator
gen_bmp_pixeldata_main_loop:
	# BMP stores rows of pixels in reverse order (left-right, bottom-top; therefore we calculate the inverted index)
	movq $31, %r8
	subq %rdx, %r8                  # calculate 31 - rdx (rowIndex), result in r8

	movq %rdx, %r9                  # for indexing within the row copy rdx into r9

	# each row is 32 * 3 = 96 bytes wide
	imulq $96, %r8
	imulq $96, %r9

	xor %rax, %rax                  # use rax as column iterator
gen_bmp_pixeldata_inner_loop:
	# convert RGB into BGR, and encode bottom-top

	# res[r8 + 56] = pixel_data[r9] (red)
	movb (%r12, %r9, 1), %cl
	movb %cl, 54(%r13, %r9, 1)

	# res[r8 + 55] = pixel_data[r9 + 1] (green)
	movb 1(%r12, %r9, 1), %cl
	movb %cl, 55(%r13, %r9, 1)

	# res[r8 + 54] = pixel_data[r9 + 2] (blue)
	movb 2(%r12, %r9, 1), %cl
	movb %cl, 56(%r13, %r9, 1)

	# go to the next pixel
	addq $3, %r8
	addq $3, %r9

	inc %rax
	cmp $32, %rax                     # check if we have processed 32 pixels
	jne gen_bmp_pixeldata_inner_loop  # loop if not

	inc %rdx
	cmp $32, %rdx                     # check if we have processed 32 rows
	jne gen_bmp_pixeldata_main_loop   # loop if not

	movq %r13, %rax                   # return the malloc'd buffer

	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack

	# callee-preserved registers
	popq %rbx
	popq %rbx
	popq    %r13
	popq    %r12

	popq	%rbp			# restore base pointer location
	ret


# *****************************************************************************
# Subroutine: get_pixeldata_from_bmp                                          *
# Description: takes a BMP and returns a malloc'd RGB pixeldata buffer        *
#              note: BMP is also considered invalid if the BMP props          *
#                    do not match with the ones from the assignment           *
# Parameters:                                                                 *
#   first: the address of the BMP                                             *
#   return: malloc'd buffer with the pixeldata, null if input isn't valid BMP *
# *****************************************************************************
get_pixeldata_from_bmp:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)

	# callee-preserved registers
	pushq   %r12
	pushq   %r13

	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq %rdi, %r12                 # put BMP data pointer in r12

	movq $3072, %rdi                # allocate space for unscrambled pixeldata
	call malloc

	movq %rax, %r13                 # store the pointer in r13

	xor %rdx, %rdx                  # row iterator in rdx
get_pixeldata_main_loop:
	movq %rdx, %r9                  # for indexing within the row copy rdx into r9

	# each row is 32 * 3 = 96 bytes wide
	imulq $96, %r9

	xor %rax, %rax                  # use rax as column iterator
get_pixeldata_inner_loop:
	# convert BGR into RGB, and encode bottom-top

	# res[r8] = bmp[r9 + 56] (red)
	movb 54(%r12, %r9, 1), %cl
	movb %cl, (%r13, %r9, 1)          # WHY THE FUCK DOES THIS CRASH THE CHECKER??????????

	# res[r8 + 1] = bmp[r9 + 55] (green)
	movb 55(%r12, %r9, 1), %cl
	movb %cl, 1(%r13, %r9, 1)

	# res[r8 + 2] = bmp[r9 + 54] (blue)
	movb 56(%r12, %r9, 1), %cl
	movb %cl, 2(%r13, %r9, 1)

	# go to the next pixel
	addq $3, %r9

	inc %rax
	cmp $32, %rax                   # check if we have processed 32 pixels
	jne get_pixeldata_inner_loop    # loop if not

	inc %rdx
	cmp $32, %rdx                   # check if we have processed 32 rows
	jne get_pixeldata_main_loop     # loop if not

	movq %r13, %rax                 # return the malloc'd buffer

get_pixeldata_end:
	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack

	# callee-preserved registers
	popq    %r13
	popq    %r12

	popq	%rbp			# restore base pointer location
	ret

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
	# preserve callee-preserved registers
	pushq %r12
	pushq %r13
	pushq %rbx
	pushq %rbx
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



	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack
	# restore callee-preserved registers
	popq %rbx
	popq %rbx
	popq %r13
	popq %r12
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
	pushq   %rbx
	pushq   %rbx

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
	popq    %rbx
	popq    %rbx
	popq    %r13
	popq    %r12

	popq	%rbp			# restore base pointer location
	ret


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
	pushq %rbx
	pushq %rbx
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
	popq %rbx
	popq %rbx
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
	pushq   %rbx
	pushq   %rbx
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
	popq    %rbx
	popq    %rbx
	popq	%rbp			# restore base pointer location
	ret

.global decrypt
.global encrypt

decrypt:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)

	# callee-preserved registers
	pushq   %r12
	pushq   %r13

	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	# string in %rdi
	# COMMENTED OUT (as I guess adding just 54 is simpler if you dont have to rewrite the bitmap...), BUT WHY THE HECK DOES LINE 216 CRASH?????????? (but not any of the lines doing exactly the same thing below)
	// call get_pixeldata_from_bmp       # get the pixeldata back from the BMP

	addq $54, %rdi

	// movq %rax, %r12                   # store it in r12

	// movq %r12, %rdi
	call decode_message_from_pixeldata  # decode the message from the pixeldata

	// movq %rax, %r13                   # store the decoded message in r13

	// movq %r12, %rdi
	// call free                         # free the pixeldata

	// movq %r13, %rax

	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack

	# callee-preserved registers
	popq    %r13
	popq    %r12

	popq	%rbp			# restore base pointer location
	ret

encrypt:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)

	# callee-preserved registers
	pushq   %r12
	pushq   %r13

	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	# string in %rdi
	call encode_message_in_pixeldata  # encode the message

	movq %rax, %r12                   # store the pixel data in r12

	movq %rax, %rdi
	call generate_bmp_from_pixeldata  # generate a bitmap from the data

	movq %rax, %r13                   # store the bmp in r13

	movq %r12, %rdi
	call free                         # free the original pixel data

	movq %r13, %rax

	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack

	# callee-preserved registers
	popq    %r13
	popq    %r12

	popq	%rbp			# restore base pointer location
	ret
