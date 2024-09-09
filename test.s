.section .data
    filename: .asciz "output.txt"         # Null-terminated file name
    message:  .asciz "Hello, World!\n"    # Null-terminated message

.section .text
    .global main

main:
    // # Open the file (sys_open)
    // mov $2, %rax                          # sys_open system call number
    // lea filename(%rip), %rdi               # Filename (first argument)
    // mov $577, %rsi                         # Flags (O_WRONLY | O_CREAT | O_TRUNC = 577)
    // mov $0644, %rdx                        # Mode (0644 in octal)
    // syscall                                # Make system call
    // mov %rax, %rdi                         # Store the returned file descriptor in %rdi

    // # Write to the file (sys_write)
    // mov $1, %rax                           # sys_write system call number
    // mov %rdi, %rdi                         # File descriptor (first argument)
    // lea message(%rip), %rsi                # Message to write (second argument)
    // mov $13, %rdx                          # Number of bytes to write (third argument)
    // syscall                                # Make system call

    // # Close the file (sys_close)
    // mov $3, %rax                           # sys_close system call number
    // syscall                                # Make system call

    movq	$48, %rdi
	call	putchar_unlocked@PLT

    movl	$0, %eax
	// popq	%rbp
	ret                         # Make system call
