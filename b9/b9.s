# parameter order:         rdi, rsi, rdx, rcx, r8, r9, rest in reverse order on stack
# return value location:   rax
# instruction suffixes:    b - 8, w - 16, l - 32, q - 64

.text
	pattern: .asciz "CCCCCCCCSSSSEE1111444400000000"
	to_encode: .asciz "The quick brown fox jumps over the lazy dog"
	filename: .asciz "output.bmp"
	printf_pattern: .asciz "%s\n"

.global main

.include "bmp.s"
.include "pixeldata-encoding.s"

# note: the example in the assignment manual presents an incorrectly encoded BMP
#       (the XOR encoding has been done on the BGR array (against instuctions), and the image has been encoded top-bottom,
#        which causes the changed pixels to appear at the bottom)

main:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)

	# callee-preserved registers
	pushq   %r12
	pushq   %r13

	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq $to_encode, %rdi
	call encode_message_in_pixeldata  # encode the message

	movq %rax, %r12                   # store the pixel data in r12

	movq %rax, %rdi
	call generate_bmp_from_pixeldata  # generate a bitmap from the data

	movq %rax, %r13                   # store the bmp in r13

	movq %r12, %rdi
	call free                         # free the original pixel data


# store the BMP on disk for previewing
	# open the file (sys_open)
	mov $2, %rax                      # sys_open system call number
	movq $filename, %rdi
	movq $577, %rsi                   # flags (O_WRONLY | O_CREAT | O_TRUNC = 577)
	movq $0644, %rdx                  # mode (0644 in octal)
	syscall                           # make system call
	movq %rax, %rdi                   # store the returned fd in %rdi

	# write to the file (sys_write)
	movq $1, %rax                     # sys_write system call number
	movq %r13, %rsi                   # message to write (second argument)
	movq $3126, %rdx                  # number of bytes to write
	syscall                           # make system call

	# close the file (sys_close)
	mov $3, %rax                      # sys_close system call number
	syscall                           # make system call


	movq %r13, %rdi
	call get_pixeldata_from_bmp       # get the pixeldata back from the BMP

	movq %rax, %r12                   # store it in r12

	movq %r13, %rdi
	call free                         # free the bmp

	movq %r12, %rdi
	call decode_message_from_pixeldata  # decode the message from the pixeldata

	movq %rax, %r13                   # store the decoded message in r13

	movq %r12, %rdi
	call free                         # free the pixeldata

	# print the decoded message
	movq $printf_pattern, %rdi
	movq %r13, %rsi
	call printf

	movq %r13, %rdi
	call free                         # free the message

	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack

	# callee-preserved registers
	popq    %r13
	popq    %r12

	popq	%rbp			# restore base pointer location
	movq	$0, %rdi		# load program exit code

	call	exit			# exit the program
