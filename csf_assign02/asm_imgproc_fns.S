/*
 * x86-64 assembly language implementations of functions
 */

	.section .text

/* Offsets of struct Image fields */
#define IMAGE_WIDTH_OFFSET   0
#define IMAGE_HEIGHT_OFFSET  4
#define IMAGE_DATA_OFFSET    8

/*
 * TODO: define your helper functions here.
 * Don't forget to use the .globl directive to make
 * them visible to the test code.
 */

/*
 * Definitions of image transformation functions
 */

/*
 *  Transform the color component values in each input pixel
 *  by applying the bitwise complement operation. I.e., each bit
 *  in the color component information should be inverted
 *  (1 becomes 0, 0 becomes 1.) The alpha value of each pixel should
 *  be left unchanged.
 * 
 *  Parameters:
 *  %rdi - pointer to the input Image
 *  %rsi - pointer to the output Image (in which the
 *         transformed pixels should be stored)
 *
 *  Register use:
 *  %r12 - pointer for our input pixel array
 *  %r13 - pointer for our output pixel array
 *  %r14d - pixel count that remains
 *  %ebx - working register + current pixel val
 *  %ecx - alpha part
 *  %edx - rgb part
 */
	.globl imgproc_complement
imgproc_complement:
	pushq %rbp                       /* save the old base pointer on our stack */
	movq %rsp, %rbp                  /* sets up our new stack frame */

	pushq %r12                       /* save callee-saved register (input pointer) */
    pushq %r13                       /* save callee-saved register (output pointer) */
    pushq %r14                       /* save callee-saved register (pixel counter) */
    pushq %rbx                       /* save callee-saved register (scratch/pixel) */

	/* assembly to load the width and height, multiply for size */
	movl IMAGE_WIDTH_OFFSET(%rdi), %r14d /* load the input->width */
	movl IMAGE_HEIGHT_OFFSET(%rdi), %ebx /* load the input->height */
	imull %ebx, %r14d                /* multiply for size */

	/* pointers for our data */
	movq IMAGE_DATA_OFFSET(%rdi), %r12 /* establish a pointer to the input pixels */
	movq IMAGE_DATA_OFFSET(%rsi), %r13 /* establish a pointer to the output pixels */

.Lloop:
	testl %r14d, %r14d               /* check remaining pixel count and if it's 0 */
	jz .Ldone_complement             /* if 0 then jump to the done section */

	movl (%r12), %ebx                /* from input put 32-bit pixel into eax */
	
	/* save the alpha */
	movl %ebx, %ecx                  /* copy the pixel into ecx */
	andl $0x000000FF, %ecx           /* only keep alpha bits through masking */

	/* save the rgb */
	movl %ebx, %edx                  /* copy the pixel into ecx */
	andl $0xFFFFFF00, %edx           /* only keep rgb bits through masking */

	/* flip the rgb */
	notl %edx                        /* on rgb part perform a bitwise not */
	andl $0xFFFFFF00, %edx           /* make sure only the rgb bits stay by clearing bottom 8 bits */ 

	/* calculate the result then store */
	orl %ecx, %edx                   /* add the original alpha with our newly flipped rgb */
	movl %edx, (%r13)                /* this new pixel now written into output */

	/* advance the pointers */
	addq $4, %r12                    /* input pointer to next pixel now, 4 bytes */
	addq $4, %r13                    /* output pointer to next pixel now, 4 bytes */
	decl %r14d                       /* pixel counter is decremented here */
	jmp .Lloop                       /* repeat this loop */

.Ldone_complement:
	popq %rbx                        /* restore caller's %rbx */
    popq %r14                        /* restore caller's %r14 */
    popq %r13                        /* restore caller's %r13 */
    popq %r12                        /* restore caller's %r12 */
    popq %rbp                        /* restore the old base pointer */

	ret                              /* just return from func */

/*
 *  Transform the input image by swapping the row and column
 *  of each source pixel when copying it to the output image.
 *  E.g., a pixel at row i and column j of the input image
 *  should be copied to row j and column i of the output image.
 *  Note that this transformation can only be applied to square
 *  images (where the width and height are identical.)
 * 
 *  Parameters:
 *  %rdi - pointer to the input Image
 *  %rsi - pointer to the output Image (in which the
 *                    transformed pixels should be stored)
 *
 *  Register use:
 *  %r12d - the width of the image
 *  %r13d - the height of the image
 *  %r10 - the pointer to input->data
 *  %r11 - the pointer to output->data
 *  %r14d - row index
 *  %r15d - col index
 *  %eax - temporary for the index computation and return val
 *  %ecx - other index computation
 *  %edx - the pixel val
 * 
 *  @return 1 if the transformation succeeded, or 0 if the
 *          transformation can't be applied because the image
 *          width and height are not the same
 */
	.globl imgproc_transpose
imgproc_transpose:
	pushq   %rbp			/* save caller's frame pointer */
    movq    %rsp, %rbp		/* set up frame pointer */

	/* save callee saved registers */
	pushq %r12				
    pushq %r13
    pushq %r14
    pushq %r15
	
	movl (%rdi), %r12d		/* load width into r12 */
	movl 4(%rdi), %r13d		/* load height into r13 */

	cmpl %r13d, %r12d 		/* check if square */ 
	jne .Lnot_square		/* jump to return case */

	movq 8(%rdi), %r10		/* load input_img->data into r10 */
	movq 8(%rsi), %r11		/* load output_img->data into r11 */

	xorl %r14d, %r14d		/* initialize i to 0 */

.Louter_loop:
	cmpl %r13d, %r14d		/* compares i with height */
	jge .Ldone_transpose	/* jump to return case if i >= height */

	xorl %r15d, %r15d		/* initialize j to 0 */

.Linner_loop:
	cmpl %r12d, %r15d		/* compare j to width */
	jge .Lnext_i			/* if j >= width increment i */

	movl %r14d, %eax     	/* move i to eax */
    imull %r12d, %eax     	/* multiply i * width */
    addl %r15d, %eax    	/* i * width + j */

    movl (%r10,%rax,4), %edx  /* load pixel from input_data */
	
	movl %r15d, %ecx		/* ecx = j */
    imull %r12d, %ecx		/* ecx = j * width */
    addl %r14d, %ecx		/* ecx = j * width + i */

	movl %edx, (%r11,%rcx,4)	/* write pixel data to output_data */

	incl %r15d              /* j++ */
    jmp .Linner_loop			/* repeat loop */

.Lnext_i:
    incl %r14d           	/* i++ */
    jmp .Louter_loop			/* repeat outer loop */

.Ldone_transpose:
    movl $1, %eax        /* return 1 */

/* Restore saved registers and return */
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbp
    ret


.Lnot_square:
	xorl %eax, %eax			/* return 0 */

/* Restore saved registers and return */
	popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbp
    ret

	

/*
 *  Transform the input image by copying only those pixels that are
 *  within an ellipse centered within the bounds of the image.
 *  Pixels not in the ellipse should be left unmodified, which will
 *  make them opaque black.
 * 
 *  Let w represent the width of the image and h represent the
 *  height of the image. Let a=floor(w/2) and b=floor(h/2).
 *  Consider the pixel at row b and column a is being at the
 *  center of the image. When considering whether a specific pixel
 *  is in the ellipse, x is the horizontal distance to the center
 *  of the image and y is the vertical distance to the center of
 *  the image. The pixel at the coordinates described by x and y
 *  is in the ellipse if the following inequality is true:
 * 
 *    floor( (10000*x*x) / (a*a) ) + floor( (10000*y*y) / (b*b) ) <= 10000
 * 
 *  Parameters:
 *  %rdi - pointer to the input Image
 *  %rsi - pointer to the output Image (in which the
 *                    transformed pixels should be stored)
 */
	.globl imgproc_ellipse
imgproc_ellipse:
	/* TODO: implement */
	ret

/*
 *  Transform the input image using an "emboss" effect. The pixels
 *  of the source image are transformed as follows.
 * 
 *  The top row and left column of pixels are transformed so that their
 *  red, green, and blue color component values are all set to 128,
 *  and their alpha values are not modified.
 * 
 *  For all other pixels, we consider the pixel's color component
 *  values r, g, and b, and also the pixel's upper-left neighbor's
 *  color component values nr, ng, and nb. In comparing the color
 *  component values of the pixel and its upper-left neighbor,
 *  we consider the differences (nr-r), (ng-g), and (nb-b).
 *  Whichever of these differences has the largest absolute value
 *  we refer to as diff. (Note that in the case that more than one
 *  difference has the same absolute value, the red difference has
 *  priority over green and blue, and the green difference has priority
 *  over blue.)
 * 
 *  From the value diff, compute the value gray as 128 + diff.
 *  However, gray should be clamped so that it is in the range
 *  0..255. I.e., if it's negative, it should become 0, and if
 *  it is greater than 255, it should become 255.
 * 
 *  For all pixels not in the top or left row, the pixel's red, green,
 *  and blue color component values should be set to gray, and the
 *  alpha value should be left unmodified.
 * 
 *  Parameters:
 *  %rdi - pointer to the input Image
 *  %rsi - pointer to the output Image (in which the
 *                    transformed pixels should be stored)
 */
	.globl imgproc_emboss
imgproc_emboss:
	/* TODO: implement */
	ret

/*
vim:ft=gas:
*/


.globl get_a
get_a:
    /* TODO: implement */
    ret

	.globl get_r
get_r:
    /* TODO: implement */
    ret

	.globl get_g
get_g:
    /* TODO: implement */
    ret

	.globl get_b
get_b:
    /* TODO: implement */
    ret

	.globl make_pixel
make_pixel:
    /* TODO: implement */
    ret