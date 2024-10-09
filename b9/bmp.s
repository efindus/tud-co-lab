.text
	bmp_header: .byte 0x42, 0x4d, 0x36, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x36, 0x00, 0x00, 0x00, 0x28, 0x00
	            .byte 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x01, 0x00, 0x18, 0x00, 0x00, 0x00
		    .byte 0x00, 0x00, 0x00, 0x0c, 0x00, 0x00, 0x13, 0x0b, 0x00, 0x00, 0x13, 0x0b, 0x00, 0x00, 0x00, 0x00
		    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

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
	# BMP stores rows of pixels in reverse order (left-right, bottom-top; therefore we calculate the inverted index)
	movq %rdx, %r9                  # for indexing within the row copy rdx into r9

	# each row is 32 * 3 = 96 bytes wide
	imulq $96, %r9

	xor %rax, %rax                  # use rax as column iterator
get_pixeldata_inner_loop:
	# convert BGR into RGB, and encode bottom-top

	# res[r8] = bmp[r9 + 56] (red)
	movb 54(%r12, %r9, 1), %cl
	movb %cl, (%r13, %r9, 1)

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
