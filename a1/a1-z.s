.data
    input: .asciz "%ld"  # string format for scanf
    output: .asciz "%ld"  # string format for scanf

.global main
.text


main:
    push %rbp
    mov %rsp, %rbp # epilogue

    sub $16, %rsp

    movq $0, %rax
    movq $input, %rdi
    leaq -16(%rbp), %rsi
    call scanf

    movq $0, %rax
    movq $input, %rdi
    leaq -8(%rbp), %rsi
    call scanf

    movq -16(%rbp), %rdi
    movq -8(%rbp), %rsi

    call fastpow

    movq $0, %rax
    movq $output, %rdi
    movq %r10, %rsi
    call printf

    mov %rbp, %rsp
    pop %rbp

    mov $0, %rdi
    call exit


fastpow:
    push %rbp
    mov %rsp, %rbp #copies stack pointer into base pointer

    movq $1, %r10 # result
    movq %rsi, %r11 # exp

    cmp $0, %r11
    jg powloop
    mov %rbp, %rsp
    pop %rbp
    ret


powloop:
    mov $0, %rdx
    mov %r11, %rax
    mov $2, %r8
    idiv %r8
    cmp $1, %rdx
    jl rest


mul:
    imul %rdi, %r10


rest:
    imul %rdi, %rdi
    mov $0, %rdx
    mov %r11, %rax
    mov $2, %r8
    idiv %r8
    mov %rax, %r11
    cmp $0, %r11
    jg powloop
    mov %rbp, %rsp
    pop %rbp
    ret
