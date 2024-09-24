.section .data
    filename: .asciz "output.txt"         # Null-terminated file name
    message:  .asciz "Hello, World!\n"    # Null-terminated message

.section .text
    .global main

main:
//     pushq $42
//     pushq $0xC0AF1FF

//     movq %rsp, %rbp

//     pushq $10
//     pushq $123
//     pushq $0x0F15FFFF
//     pushq $13
//     pushq $2
//     pushq $666

//     movq %rbp, %rsp
//     subq $8, %rsp

//     movq $0, %rsi
//     pushq %rsi
//     call foo
//     popq %rdi
//     decq %rax
//     addq %rdi, %rax
//     pushq %rax

//     movq $0, %rdi
//     call exit

// foo:
//     pushq %rbp
//     movq %rsp, %rbp

//     addq $42, %rsi
//     pushq %rsi
//     decq %rsi
//     popq %rax
//     pushq %rsi

//     movq %rbp, %rsp
//     popq %rbp
//     ret


    movq $1, %rax
    pushq $8
    pushq $4
    pushq $7
    movq $5, %rdi
    addq $8, %rsp
    call foo
    pushq $8

foo:
    pushq %rbp
    movq %rsp, %rbp

    pushq %rdi
    mulq -8(%rbp)
    addq 16(%rbp), %rax

    movq %rbp, %rsp
    popq %rbp
    ret

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
