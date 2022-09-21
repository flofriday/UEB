	.file	"asma.s"
	.section .rodata
mask:
	.quad 0x08090a0b0c0d0e0f
	.quad 0x0001020304050607
	.text
	.globl	asma
	.type	asma, @function
asma:
.LFB0:
	.cfi_startproc

	# Load the string into the xmm1 register
	movdqu (%rdi), %xmm1

	# Load the mapping order into %xmm2
	# The mapping ist stored in the data section
	movdqu mask(%rip), %xmm2

	# Reorder the bytes
	pshufb %xmm2, %xmm1

	# Store the result
	movdqu %xmm1, (%rdi)

	# Exit the function
	rep ret
	.cfi_endproc

.LFE0:
	.size	asma, .-asma
	.ident	"GCC: (Debian 6.3.0-18+deb9u1) 6.3.0 20170516"
	.section	.note.GNU-stack,"",@progbits
