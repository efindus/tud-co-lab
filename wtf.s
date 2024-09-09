.text
	.globl	main

main:
	pushq	%rbp
	movq	%rsp, %rbp

	movl	$108, %edi
	call	putchar_unlocked@PLT
	movl	$0, %eax
	popq	%rbp
	ret
