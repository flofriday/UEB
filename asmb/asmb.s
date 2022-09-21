	.file	"asmb.s"
	.section .rodata
mask:
	.quad 0x08090a0b0c0d0e0f
	.quad 0x0001020304050607
	.text
	.globl	asmb
	.type	asmb, @function
asmb:
.LFB0:
	.cfi_startproc

	# Register documentation:
	# rdi -> Arugment char x[]
	# rsi -> Argument int n
	# rbx -> loop counter i
	# rcx -> remaining loop iterations
	# r8 -> next left segment to move
	# r9 -> next right segment to move

	# Calculate the number of iteration so in rcx so that we can use the loop 
	movq %rsi, %rcx
	sarq $5, %rcx # Divide by 32 (= 2^5)

	# Jump to end if nothing to do
	# A test instruction is not necessary here as the sarq already sets all 
	# necessary flags.
	jle .end

	# Set the xmm2 register so that we can use it later to reverse 16bytes at 
	# once
	movdqu mask(%rip), %xmm2

	# Pre loop setup
	movq %rdi, %r8 # Set the pointer to the most left segmetn to be processed
	leaq -16(%rdi, %rsi), %r9 # Set the pointer to the most right segment to be processed

	# The loop 
	.loop:

	# Load the segments
	movdqu (%r8), %xmm1
	movdqu (%r9), %xmm3

	# Reverse the segmeents
	pshufb %xmm2, %xmm1
	pshufb %xmm2, %xmm3

	# Write the segments
	movdqu %xmm1, (%r9) 
	movdqu %xmm3, (%r8) 

	# Prepare for next iteration
	addq $16, %r8
	subq $16, %r9
	loop .loop

	# End of the loop
	.end:
	rep ret

	.cfi_endproc
.LFE0:
	.size	asmb, .-asmb
	.ident	"GCC: (Debian 6.3.0-18+deb9u1) 6.3.0 20170516"
	.section	.note.GNU-stack,"",@progbits
