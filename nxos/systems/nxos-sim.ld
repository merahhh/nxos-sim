/* Copyright (c) 2007,2008 the NxOS developers
 *
 * See AUTHORS for a full list of the developers.
 *
 * Redistribution of this file is permitted under
 * the terms of the GNU Public License (GPL) version 2.
 */

/* NXT linker script source to boot from a NXT firmware
 * using a modification implemented by John Hansen.
 *
 *  Notes on alignment:
 *  1) Sections should be 4-byte aligned otherwise ARM fetches will be
 *     misaligned.
 *  2) The stack should be 8-byte aligned for the APCS. That's because
 *     STRD and LDRD assume that they are on 8-byte boundaries.
 */

/*
 * Memory definitions.
 */

MEMORY {
vector_ram : ORIGIN = 0M, LENGTH = 64
ram : ORIGIN = 0M + 64, LENGTH = 64K - 64 + 21
}

ROM_BASE = 1M;
ROM_SIZE = 256k;
RAM_BASE = 2M;
RAM_SIZE = 64k;

SECTIONS {
  /*
   * Interrupt vectors. These are loaded to the bottom of memory at
   * boot time.
   */
  .vectors : {
    KEEP(vectors.o (*.text *.text.*))
  } > vector_ram

  /*
   * This section contains code that is relocated to RAM before
   * execution.
   *
   * This section is used for code that has to reside in ram to
   * function correctly (like flash writing code)
   */
  .ram_text : ALIGN(4) {
    *.oram (*.text *.text.* *.glue*)
    *.oram (*.rodata *.rodata.*)
  } > ram


  /*
   * Read/Write initialized data. Runs from RAM, gets copied there
   * from ROM if booting from flash.
   */
  .data : ALIGN(4) {
    * (*.data *.data.*)

    /* This symbol is used by the memcpy wrapper (see base/_memcpy.c) in
     * order to apply the correct writing method.
     * 0 -> mapped on flash;   1 -> mapped on ram
     * TODO: make init code depending on this flag instead of using memory
     *       comparation.
     */
    . = ALIGN(4);
    __bottom_mapped__ = .;
    LONG(1)
  } > ram


  /*
   * The main kernel executable code, as well as all the read-only
   * data. If possible, this goes into flash, to free up more RAM.
   */
  .text : ALIGN(4) {
    * (*.text *.text.* *.glue*)
    * (*.rodata *.rodata.*)
  } > ram


  /*
   * The BSS section is zero-initialized data. The section does not
   * take any space in the final image, but the linker helpfully
   * defines the symbols we need to be able to initialize the section
   * properly.
   */
  .bss : ALIGN(4) {
    * (*.bss *.bss.*)
    * (COMMON) /* this is uninitialized data, but we just place it here */
  } > ram


  /*
   * The various kernel stacks.
   *
   * Although not strictly required, this zone is zeroed out at boot
   * time to provide a clean environment for the kernel.
   */
  .stack  : ALIGN(8) {
		/* supervisor stack */
		__supervisor_stack_bottom__ = . ;
		KEEP(*(.stack.supervisor))
		__supervisor_stack__ = .;
		__supervisor_stack_top__ = . ;
		
		/* abort stack */
		__abort_stack_bottom__ = . ;
		KEEP(*(.stack.abort))
		__abort_stack__ = . ;
		__abort_stack_top__ = . ;

		/* debugger state */
		__debugger_stack_bottom__ = . ;
		KEEP(*(.stack.debugger))
		__debugger_stack__ = . ;
		__debugger_stack_top__ = . ;

		/* breakpoints */
		__breakpoints_start__ = . ;
		KEEP(*(.breakpoints))
		__breakpoints_end__ = . ;

  } > ram

  /* Discard anything not mapped at this point. */
  /* Note: Commented out to enable generation of GDB Debug symbols */
/*  /DISCARD/ : {
    * (*);
  }
*/

  /*
   * Symbol definitions for the use of the kernel code.
   */
  __vectors_ram_start__  = ADDR(.vectors);
  __vectors_ram_end__    = ADDR(.vectors) + SIZEOF(.vectors);
  __vectors_load_start__ = LOADADDR(.vectors);
  __vectors_load_end__   = LOADADDR(.vectors) + SIZEOF(.vectors);

  __ramtext_ram_start__ = ADDR(.ram_text);
  __ramtext_ram_end__   = ADDR(.ram_text) + SIZEOF(.ram_text);
  __ramtext_load_start__ = LOADADDR(.ram_text);
  __ramtext_load_end__ = __ramtext_load_start__ + SIZEOF(.ram_text) ;

  __data_ram_start__ = ADDR(.data);
  __data_ram_end__   = ADDR(.data) + SIZEOF(.data);
  __data_load_start__ = LOADADDR(.data);
  __data_load_end__ = __data_load_start__ + SIZEOF(.data) ;

  __text_start__ = ADDR(.text);
  __text_end__ = ADDR(.text) + SIZEOF(.text);

  __bss_start__ = ADDR(.bss);
  __bss_end__   = ADDR(.bss) + SIZEOF(.bss);

  __stack_start__ = ADDR(.stack);
  __stack_end__ = ADDR(.stack) + SIZEOF(.stack);

  __boot_from_samba__ = 2;

  __rom_userspace_start__ = 0;
  __rom_userspace_end__ = ROM_BASE + ROM_SIZE;

  __ram_userspace_start__ = __stack_end__;
  __ram_userspace_end__ = RAM_BASE + RAM_SIZE;

   __kernel_ram_load_size__ = __text_end__ - __vectors_ram_start__;
   __breakpoints_num__ = (__breakpoints_end__ - __breakpoints_start__) / 8;
}
