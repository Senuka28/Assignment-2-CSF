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
 */
	.globl imgproc_complement
imgproc_complement:
	pushq %rbp # save the old base pointer on our stack
	movq %rsp, %rbp # sets up our new stack frame

	# assembly to load the width and height, multiply for size
	movl IMAGE_WIDTH_OFFSET(%rdi), %r8d # load the input->width
	movl IMAGE_HEIGHT_OFFSET(%rdi), %r9d # load the input->height
	imull %r9d, %r8d # multiply for size

	# pointers for our data
	movq IMAGE_DATA_OFFSET(%rdi), %r11 # establish a pointer to the input pixels
	movq IMAGE_DATA_OFFSET(%rsi), %r12 # establish a pointer to the output pixels

.Lloop:
	testl %r8d, %r8d # check remaining pixel count and if it's 0
	jz .Ldone # if 0 then jump to the done section

	movl (%r11), %eax # from input put 32-bit pixel into eax
	
	# save the alpha
	movl %eax, %ecx # copy the pixel into ecx
	andl $0x000000FF, %ecx # only keep alpha bits through masking

	# save the rgb
	movl %eax, %edx # copy the pixel into ecx
	andl $0xFFFFFF00, %edx # only keep rgb bits through masking

	# flip the rgb
	notl %edx # on rgb part perform a bitwise not
	andl $0xFFFFFF00, %edx # make sure only the rgb bits stay by clearing bottom 8 bits 

	# calculate the result then store
	orl %ecx, %edx # add the original alpha with our newly flipped rgb
	movl %edx, (%r12) # this new pixel now written into output

	# advance the pointers
	addq $4, %r11 # input pointer to next pixel now, 4 bytes
	addq $4, %r12 # output pointer to next pixel now, 4 bytes
	decl %r8d # pixel counter is decremented here
	jmp .Lloop # repeat this loop

.Ldone:
	popq %rbp # restore the old base pointer
	ret # just return from func

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
 *  @return 1 if the transformation succeeded, or 0 if the
 *          transformation can't be applied because the image
 *          width and height are not the same
 */
	.globl imgproc_transpose
imgproc_transpose:
	movl (%rdi), %eax		/* load width into eax */
	movl 4(%rdi), %ecx		/* load height into ecx */

	cmpl $ecx, %eax 		/* check if square */ 
	jne not_square			/* jump to return case */

not_square:
	xorl %eax, %eax
	ret

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