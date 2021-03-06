/* 
 * Kernel linker script
 *
 * Copyright (C) 2009-2010 Ahmed S. Darwish <darwish.07@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, version 2.
 *
 * Refer to official LD documentation "Using LD - the GNU linker"
 * for more information.
 *
 * Symbols prefixed by `__' are used by our C and assembly files;
 * modify them cautiously
 */

#include <paging.h>

OUTPUT_FORMAT("elf64-x86-64")
OUTPUT_ARCH(i386:x86-64)

ENTRY(startup_32)

SECTIONS
{
	/* Where the bootsector loads us */
	. = 0x100000;

	/* The global GDT is loaded in all CPU modes, including 16-
	 * bit code where the GDT base addr must not exceed 3 bytes. */
	ASSERT(global_gdt >> 24 == 0,
	       "Error: The 'global_gdt' must reside in a 3-byte address")

	/*
	 * Bootstrap sections can't be merged with the rest
	 * of the kernel as they're physical-addresses based
	 */

	.text.head : {
	      arch/ia64/head.o(.text)
	      arch/ia64/rmcall.o(.text)
	      arch/ia64/_e820.o(.text)
	      arch/ia64/load_ramdisk.o(.text)
	}

	.data.head : {
	      arch/ia64/head.o(.data)
	      arch/ia64/rmcall.o(.data)
	      arch/ia64/e820.o(.data)
	      arch/ia64/load_ramdisk.o(.data)
	}

	/* Putting the bootstrap BSS in the middle will force
	 * the linker to reserve section size in the executable.
	 * If you are interested in absolutely saving executable
	 * size, you may like the trickery used in commit
	 * cd618e752a which led to 0 executable bytes wasted,
	 * with the tradeoff price of much extra complexity */
	.bss.head (NOLOAD) : {
	      arch/ia64/head.o(.bss)
	      arch/ia64/rmcall.o(.bss)
	      arch/ia64/_e820.o(.bss)
	      arch/ia64/load_ramdisk.o(.bss)
	}

	/*
	 * Use virtual addresses for the rest of the kernel
	 */

	. += KTEXT_PAGE_OFFSET;

	.text : AT(ADDR(.text) - KTEXT_PAGE_OFFSET) {
	       __text_start = .;
	       *(EXCLUDE_FILE (*arch/ia64/head.o *arch/ia64/rmcall.o \
			       *arch/ia64/_e820.o *arch/ia64/load_ramdisk.o)
			       .text)
	       __text_end = .;
	}

	.data : {
	       __data_start = .;
	       *(EXCLUDE_FILE (*arch/ia64/head.o *arch/ia64/rmcall.o \
			       *arch/ia64/_e820.o *arch/ia64/load_ramdisk.o)
			       .data)
	       *(.rodata)
	       __data_end = .;
        }

	.bss : {
		__bss_start = .;
	       *(EXCLUDE_FILE (*arch/ia64/head.o */rmcall.o \
			       *arch/ia64/_e820.o *arch/ia64/load_ramdisk.o)
			       .bss)
	       *(EXCLUDE_FILE (*arch/ia64/head.o *arch/ia64/rmcall.o \
			       *arch/ia64/_e820.o *arch/ia64/load_ramdisk.o)
			       COMMON)
		__bss_end = .;
	}

	.init.arrays : {
		__stage1_start = .;
		*(.init.array.stage1)
		__stage1_end = .;

		__stage2_start = .;
		*(.init.array.stage2)
		__stage2_end = .;

		__stage3_start = .;
		*(.init.array.stage3)
		__stage3_end = .;

		__stage4_start = .;
		*(.init.array.stage4)
		__stage4_end = .;
	}

	__kernel_end = .;

	/*
	 * The ramdisk header is loaded directly after the kernel.
	 */

	/DISCARD/ : {
		*(.eh_frame)
		*(.comment)
		*(.note)
	}
}
