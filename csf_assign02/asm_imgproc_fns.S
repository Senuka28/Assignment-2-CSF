
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
 *
 *  Register use:
 *  %rbx - row index
 *  %r12d - width of image measured in pixels
 *  %r13d - height of image measured in pixels
 *  %r14 - the pointer to input_img->data
 *  %r15 - the pointer to output_img->data
 *  %ecx - col index
 *  %eax - temporary register for any computation
 *  %edx - temporary register for x, x^2, and pixel vals
 *  %esi - holds the vertical distance from image's center
 *  %edi - holds calculated linear pixel index and divisor vals
 *  %r9d - holds result of first ellipse term (10000*x^2 / a^2) for future addition\
 *
 *  Local variables in stack frame:
 *  -4(%rbp) - value of a
 *  -8(%rbp) - value of b
 *  -12(%rbp) - value of center_x
 *  -16(%rbp) - value of center_y
 */
	.globl imgproc_ellipse
imgproc_ellipse:
	/* TODO: implement */
	pushq %rbp                       /* save the caller base pointer */
	movq %rsp, %rbp                  /* sets up new base pointer for this func */
	subq $32, %rsp                   /* save 32 bytes on the stack for locals: a, b, center_x, center_y */

	pushq %rbx                       /* save callee-saved register (row counter) */
    pushq %r12                       /* save callee-saved register (width) */
    pushq %r13                       /* save callee-saved register (height) */
    pushq %r14                       /* save callee-saved register (input pointer) */
    pushq %r15                       /* save callee-saved register (output pointer) */

	/* assembly to load the width and height */
	movl IMAGE_WIDTH_OFFSET(%rdi), %r12d  /* load the input->width */
	movl IMAGE_HEIGHT_OFFSET(%rdi), %r13d /* load the input->height */

	/* compute a */
	movl %r12d, %eax                 /* copy the width above into eax */
    shrl $1, %eax                    /* take width and cut in half with right shift */
    movl %eax, -4(%rbp)              /* store a at stack offset */

	/* compute b */
    movl %r13d, %eax                 /* copy the height above into eax */
    shrl $1, %eax                    /* take height and cut in half with right shift */
    movl %eax, -8(%rbp)              /* store b at stack offset */

	/* compute center_x */
	movl -4(%rbp), %eax              /* load a from stack */
    movl %eax, -12(%rbp)             /* save this as center_x */

	/* compute center_y */
	movl -8(%rbp), %eax              /* load b from stack */
    movl %eax, -16(%rbp)             /* save this as center_y */

	/* get pointers for the pixel arrays */
	movq IMAGE_DATA_OFFSET(%rdi), %r14 /* extract input image data into r14 */
    movq IMAGE_DATA_OFFSET(%rsi), %r15 /* extract output image data into r15 */

	xorl %ebx, %ebx                  /* initialize row loop counter with row = 0 */

.Lrow_looping:
    cmpl %r13d, %ebx                 /* compare row with the height */
    jge .Lfinished_ellipse               /* if row greater than or equal to height then exit outer loop */

    xorl %ecx, %ecx                  /* initialize col loop counter with col = 0 */

.Lcol_looping:
    cmpl %r12d, %ecx                 /* compare col with the width */
    jge .Lnext_row                   /* if col greater than or equal to width then exit inner loop */

	/* compute horizontal distance from center, x */
	movl %ecx, %eax                  /* col index into %eax */
    subl -12(%rbp), %eax             /* subtract center_x from col for horizontal dist */
    movl %eax, %edx                  /* x into %edx */

	/* compute vertical disance from center, y */
	movl %ebx, %eax                  /* row index into %eax */
    subl -16(%rbp), %eax             /* subtract center_y from row for vertical dist */
    movl %eax, %esi                  /* y into %esi */
	
	/* compute the inequality needed for ellipse function */
	/* first part is (10000 * x^2) / a^2 */
	movl %edx, %eax                  /* put x into %eax */
    imull %edx, %eax                 /* find x^2 or x * x with imull */
    imull $10000, %eax               /* multiply instruction again but with 10000 */  
    movl -4(%rbp), %edi              /* load this into %edi */ 
    imull %edi, %edi                 /* find a^2 or a * a with imull */
    xorl %edx, %edx                  /* clear out %edx before any division */
    divl %edi                        /* take both fraction parts above and divide */
    movl %eax, %r9d                  /* save first part result into r9d */

	/* second part is (10000 * y^2) / b^2 */
	movl %esi, %eax                  /* put y into %eax */
    imull %esi, %eax                 /* find y^2 or y * y with imull */
    imull $10000, %eax               /* multiply instruction again but with 10000 */
    movl -8(%rbp), %edi              /* load this into %edi */ 
    imull %edi, %edi                 /* find b^2 or b * b with imull */ 
    xorl %edx, %edx                  /* clear out %edx before any division */ 
    divl %edi                        /* take both fraction parts above and divide */ 
    addl %r9d, %eax                  /* add first and second part result together */ 

	/* check the ellipse inequality now */
	cmpl $10000, %eax                /* compare calculated above sum with 10000 */
    jg .Lblack_set_pixel             /* if found greater, then pixel outside ellipse */

	/* the pixel is inside the ellipse so copy original pixel */
	movl %ebx, %edi                  /* copy row into %edi */
    imull %r12d, %edi                /* take row multiply by width */
    addl %ecx, %edi                  /* add col for linear index computation */
    movl (%r14,%rdi,4), %edx         /* load input pixel val at this computed index */
    movl %edx, (%r15,%rdi,4)         /* store in output arr */
    jmp .Lnext_col                   /* continue on with next col */

.Lblack_set_pixel:
	movl %ebx, %edi                  /* copy row into %edi */
    imull %r12d, %edi                /* take row multiply by width */
    addl %ecx, %edi                  /* add col for linear index computation */
    movl $0x000000FF, (%r15,%rdi,4)  /* now write an opaque black pixel */ 

.Lnext_col:
	incl %ecx                        /* increment col count */
	jmp .Lcol_looping                /* go back and repeat inner loop */

.Lnext_row:
	incl %ebx                        /* increment row count */
	jmp .Lrow_looping                /* go back and repeat outer loop */

.Lfinished_ellipse:
	popq    %r15                     /* restore caller's %r15 */
    popq    %r14                     /* restore caller's %r14 */
    popq    %r13                     /* restore caller's %r13 */
    popq    %r12                     /* restore caller's %r12 */
    popq    %rbx                     /* restore caller's %rbx */
    addq    $32, %rsp                /* free the 32 bytes for locals */
    popq    %rbp                     /* restore the old base pointer */
    ret                              /* just return from func */
/*
 * Transform the input image using an "emboss" effect.
 *
 * This version CALLS the helper functions (get_a, get_r, etc.)
 *
 * Register usage in imgproc_emboss (before function calls):
 * %r9    = pointer to input->data
 * %r10   = pointer to output->data
 * %r12d  = image width (W) (Callee-saved, preserved across calls)
 * %r13d  = image height (H) (Callee-saved, preserved across calls)
 * %r14d  = row index i (Callee-saved, preserved across calls)
 * %r15d  = column index j (Callee-saved, preserved across calls)
 * %ebx   = current index (i*W+j) (Callee-saved, preserved across calls)
 *
 * %eax   = result of function calls (dr, dg, db, gray_value)
 * %edx   = Current pixel (input)
 *
 * 
 */
.globl imgproc_emboss
imgproc_emboss:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $32, %rsp           /* Allocate space for local variables */

    /* Load image dimensions and data pointers */
    movl IMAGE_WIDTH_OFFSET(%rdi), %r12d   /* width */
    movl IMAGE_HEIGHT_OFFSET(%rdi), %r13d  /* height */
    movq IMAGE_DATA_OFFSET(%rdi), %r9      /* input->data */
    movq IMAGE_DATA_OFFSET(%rsi), %r10     /* output->data */

    xorl %r14d, %r14d        /* i = 0 */

.L_outer_loop:
    cmpl %r13d, %r14d        /* i < height? */
    jge .L_done_emboss

    xorl %r15d, %r15d        /* j = 0 */

.L_inner_loop:
    cmpl %r12d, %r15d        /* j < width? */
    jge .L_inner_loop_end

    /* Calculate linear index: index = i * W + j */
    movl %r14d, %eax
    imull %r12d, %eax
    addl %r15d, %eax
    movl %eax, %ebx          /* %ebx = index */

    /* Load input pixel */
    movl (%r9,%rbx,4), %edx  /* %edx = current_pixel */
    
    /* Extract and save alpha */
    movl %edx, %edi
    call get_a
    movl %eax, -4(%rbp)      /* Save alpha */

    /* Check if top row (i == 0) or left column (j == 0) */
    testl %r14d, %r14d
    je .L_gray_128
    testl %r15d, %r15d
    je .L_gray_128

    /* --- Emboss calculation for non-edge pixels --- */
    
    /* Calculate neighbor index: n_index = (i-1) * W + (j-1) */
    movl %r14d, %eax
    decl %eax
    imull %r12d, %eax
    addl %r15d, %eax
    decl %eax
    movl (%r9,%rax,4), %esi  /* %esi = neighbor_pixel */

    /* Get current pixel colors */
    movl %edx, %edi
    call get_r
    movl %eax, -8(%rbp)      /* r */
    
    movl %edx, %edi
    call get_g
    movl %eax, -12(%rbp)     /* g */
    
    movl %edx, %edi
    call get_b
    movl %eax, -16(%rbp)     /* b */

    /* Get neighbor pixel colors */
    movl %esi, %edi
    call get_r
    movl %eax, -20(%rbp)     /* nr */
    
    movl %esi, %edi
    call get_g
    movl %eax, -24(%rbp)     /* ng */
    
    movl %esi, %edi
    call get_b
    movl %eax, -28(%rbp)     /* nb */

    /* Calculate differences */
    movl -20(%rbp), %eax     /* nr */
    subl -8(%rbp), %eax      /* nr - r */
    movl %eax, -32(%rbp)     /* dr */
    
    movl -24(%rbp), %eax     /* ng */
    subl -12(%rbp), %eax     /* ng - g */
    movl %eax, %ecx          /* dg */
    
    movl -28(%rbp), %eax     /* nb */
    subl -16(%rbp), %eax     /* nb - b */
    movl %eax, %edx          /* db */

    /* Find diff with largest absolute value */
    movl -32(%rbp), %eax     /* diff = dr */
    movl %eax, %r8d
    movl %eax, %r11d         /* abs_diff = |dr| */
    testl %r11d, %r11d
    jns .L_abs_dr_ok
    negl %r11d
.L_abs_dr_ok:

    /* Compare with dg */
    movl %ecx, %edi          /* temp = dg */
    movl %ecx, %esi          /* abs_dg = |dg| */
    testl %esi, %esi
    jns .L_abs_dg_ok
    negl %esi
.L_abs_dg_ok:

    cmpl %r11d, %esi
    jg .L_set_dg
    jl .L_check_db
    /* Equal absolute values - red has priority */
    cmpl -32(%rbp), %r8d
    je .L_check_db           /* current is red, keep it */
    
.L_set_dg:
    movl %ecx, %r8d          /* diff = dg */
    movl %esi, %r11d         /* abs_diff = |dg| */
    
.L_check_db:
    /* Compare with db */
    movl %edx, %edi          /* temp = db */
    movl %edx, %esi          /* abs_db = |db| */
    testl %esi, %esi
    jns .L_abs_db_ok
    negl %esi
.L_abs_db_ok:

    cmpl %r11d, %esi
    jg .L_set_db
    jmp .L_compute_gray
    
.L_set_db:
    movl %edx, %r8d          /* diff = db */
    
.L_compute_gray:
    /* gray = 128 + diff */
    movl %r8d, %eax
    addl $128, %eax

    /* Clamp gray to [0, 255] */
    testl %eax, %eax
    jns .L_check_upper
    xorl %eax, %eax
    jmp .L_create_pixel
.L_check_upper:
    cmpl $255, %eax
    jle .L_create_pixel
    movl $255, %eax
    jmp .L_create_pixel

.L_gray_128:
    movl $128, %eax          /* gray = 128 */

.L_create_pixel:
    /* Save critical registers before calling make_pixel */
    pushq %rcx
    pushq %rdx
    pushq %r8
    pushq %r9
    pushq %r10
    pushq %r11

    /* Call make_pixel(gray, gray, gray, alpha) */
    movl %eax, %edi          /* r = gray */
    movl %eax, %esi          /* g = gray */
    movl %eax, %edx          /* b = gray */
    movl -4(%rbp), %ecx      /* a = saved alpha */
    call make_pixel

    /* Restore critical registers */
    popq %r11
    popq %r10
    popq %r9
    popq %r8
    popq %rdx
    popq %rcx

    /* Store result */
    movl %eax, (%r10,%rbx,4)

    incl %r15d               /* j++ */
    jmp .L_inner_loop

.L_inner_loop_end:
    incl %r14d               /* i++ */
    jmp .L_outer_loop

.L_done_emboss:
    addq $32, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

.globl get_a
get_a:
    /* uint8_t get_a(uint32_t px) */
    mov %edi, %eax
    and $0xFF, %eax
    ret

    .globl get_b
get_b:
    /* uint8_t get_b(uint32_t px) */
    mov %edi, %eax
    shr $8, %eax
    and $0xFF, %eax
    ret

    .globl get_g
get_g:
    /* uint8_t get_g(uint32_t px) */
    mov %edi, %eax
    shr $16, %eax
    and $0xFF, %eax
    ret

    .globl get_r
get_r:
    /* uint8_t get_r(uint32_t px) */
    mov %edi, %eax
    shr $24, %eax
    and $0xFF, %eax
    ret

    .globl make_pixel
make_pixel:
    /* uint32_t make_pixel(uint8_t r, uint8_t g, uint8_t b, uint8_t a) */
    shl $24, %edi                /* shift r up */
    shl $16, %esi                /* shift g up */
    shl $8,  %edx                /* shift b up */
    or %esi, %edi
    or %edx, %edi
    or %ecx, %edi
    mov %edi, %eax
    ret