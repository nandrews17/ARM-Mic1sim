/* mic1.s */

.extern fgetc
.extern fopen
.extern putchar
.extern fclose
.global main
.data

memory: .skip 32000     /* Array for the memory of our mic1 program */

.balign 4
file: .word 0           /* The file pointer */

.balign 4
fileMode: .asciz "r"    /* Read mode */

.balign 4
fmtd: .asciz "%d\n"      /* Format for printing numbers */

.balign 4
offset: .word 0         /* Offset for array */

.balign 4
errorMessage: .asciz "Error with file or arguments. Exit status: 1"

.balign 4
.text
mic1CPP .req r2
mic1LV .req r3
mic1SP .req r4
mic1PC .req r5
mic1MBR .req r6
mic1MBRU .req r7
mic1TOS .req r8
mic1H .req r9
mic1MAR .req r10
mic1MDR .req r11
mic1OPC .req r12

main:
   push {lr}

   cmp r0, #2              /* Validates there are two command-line arguments */
   bne error               /* Branches to display error and exit if wrong args */
   ldr r0, [r1, #4]
   ldr r1, =fileMode
   bl fopen                /* fopen opens file with filename and the "mode" */
   ldr r2, =file
   str r0, [r2]            /* Save the file pointer */

file_loop:
   ldr r0, =file           /* Load the address of file pointer */
   ldr r0, [r0]
   bl fgetc                /* Call fgetc on the file pointer in r0 */
   cmp r0, #-1             /* Compare returned value to -1 (EOF) */
   beq file_done
   ldr r2, =memory         /* Fill memory byte-by-byte */
   ldr r3, =offset
   ldr r4, [r3]
   add r2, r2, r4
   str r0, [r2]
   add r4, r4, #1
   str r4, [r3]
   b file_loop             /* Not EOF, branch to file_loop */

file_done:
   ldr r0, =file           /* Close the file */
   ldr r0, [r0]
   bl fclose
   mov mic1CPP, #0         /* Set up CPP register */
   ldr mic1LV, =offset     /* Set up PC, LV, and SP */
   ldr mic1PC, =memory
   ldrsb r0, [mic1PC]
   add mic1PC, mic1PC, #1
   ldrb r1, [mic1PC]
   orr r0, r1, r0, LSL #8
   add mic1SP, mic1LV, r0, LSL #2

/* Opcode Branching: */
Main1:
   add mic1PC, mic1PC, #1  /* Increment and fetch */
   ldrsb mic1MBR, [mic1PC]
   ldrb mic1MBRU, [mic1PC]

   cmp mic1MBRU, #0x00
   beq nooperation
   cmp mic1MBRU, #0x10
   beq bipush
   cmp mic1MBRU, #0x15
   beq iload
   cmp mic1MBRU, #0x36
   beq istore
   cmp mic1MBRU, #0x57
   beq pop
   cmp mic1MBRU, #0x59
   beq dup
   cmp mic1MBRU, #0x60
   beq iadd
   cmp mic1MBRU, #0x64
   beq isub
   cmp mic1MBRU, #0x68
   beq imul
   cmp mic1MBRU, #0x80
   beq ior
   cmp mic1MBRU, #0x84
   beq iinc
   cmp mic1MBRU, #0x99
   beq ifeq
   cmp mic1MBRU, #0x9B
   beq iflt
   cmp mic1MBRU, #0x9F
   beq if_icmpeq
   cmp mic1MBRU, #0x5F
   beq swap
   cmp mic1MBRU, #0x6C
   beq idiv
   cmp mic1MBRU, #0x7E
   beq iand
   cmp mic1MBRU, #0xA7
   beq goto
   cmp mic1MBRU, #0xA8
   beq jsr
   cmp mic1MBRU, #0xA9
   beq ret

   b error /* if command not found */

/* Instructions: */
nooperation:               /* Branches back to main */
   b Main1

bipush:                    /* Pushes onto mic1 stack */
   add mic1SP, mic1SP, #4  /* bipush1 */
   mov mic1MAR, mic1SP

   add mic1PC, mic1PC, #1  /* bipush2 */
   ldrsb mic1MBR, [mic1PC]
   ldrb mic1MBRU, [mic1PC]

   mov mic1MDR, mic1MBR    /* bipush3 */
   mov mic1TOS, mic1MBR
   str mic1MBR, [mic1MAR]
   b Main1

iload:                     /* Pushes local variable on stack */
   add mic1PC, mic1PC, #1  /* iload1 */
   ldrsb mic1MBR, [mic1PC]
   ldrb mic1MBRU, [mic1PC]
   mov mic1H, mic1LV

   add mic1MAR, mic1H, mic1MBRU, LSL #2
   ldr mic1MDR, [mic1MAR]  /* iload2 */

   add mic1SP, mic1SP, #4  /* iload3 */
   mov mic1MAR, mic1SP

   str mic1MDR, [mic1MAR]  /* iload4 */
   mov mic1TOS, mic1MDR    /* iload5 */
   b Main1

istore:                    /* Updates local variable */
   add mic1PC, mic1PC, #1  /* istore1 */
   ldrsb mic1MBR, [mic1PC]
   ldrb mic1MBRU, [mic1PC]
   mov mic1H, mic1LV

   add mic1MAR, mic1H, mic1MBRU, LSL #2  /* istore2 */
   mov mic1MDR, mic1TOS    /* istore3 */
   str mic1MDR, [mic1MAR]

   sub mic1SP, mic1SP, #4  /* istore4 */
   mov mic1MAR, mic1SP
   ldr mic1MDR, [mic1MAR]

   mov mic1TOS, mic1MDR    /* istore6 */
   b Main1

pop:                       /* Takes value off of stack */
   sub mic1SP, mic1SP, #4  /* pop1 */
   mov mic1MAR, mic1SP
   ldr mic1MDR, [mic1MAR]  /* pop2 */

   mov mic1TOS, mic1MDR    /* pop3 */
   b Main1

dup:                       /* Pushes copy of number on stack top */
   add mic1SP, mic1SP, #4  /* dup1 */
   mov mic1MAR, mic1SP
   
   mov mic1MDR, mic1TOS    /* dup2 */
   str mic1TOS, [mic1MAR]
   b Main1

iadd:                      /* Adds two on stack and pushes result */
   sub mic1SP, mic1SP, #4  /* iadd1 */
   mov mic1MAR, mic1SP
   ldr mic1MDR, [mic1MAR]

   mov mic1H, mic1TOS      /* iadd2 */

   add mic1TOS, mic1MDR, mic1H
   mov mic1MDR, mic1TOS    /* iadd3 */
   str mic1TOS, [mic1MAR]
   b Main1

isub:                      /* Subtracts two on stack and pushes result */
   sub mic1SP, mic1SP, #4  /* isub1 */
   mov mic1MAR, mic1SP
   ldr mic1MDR, [mic1MAR]

   mov mic1H, mic1TOS      /* isub2 */

   sub mic1TOS, mic1MDR, mic1H
   mov mic1MDR, mic1TOS    /* isub3 */
   str mic1TOS, [mic1MAR]
   b Main1

imul:                      /* Multiplies two on stack and pushes result */
   sub mic1SP, mic1SP, #4  /* imul1 */
   mov mic1MAR, mic1SP
   ldr mic1MDR, [mic1MAR]

   mov mic1H, mic1TOS      /* imul2 */

   mul mic1TOS, mic1MDR, mic1H
   mov mic1MDR, mic1TOS    /* imul3 */
   str mic1TOS, [mic1MAR]
   b Main1

ior:                       /* Boolean or two on stack and pushes result */
   sub mic1SP, mic1SP, #4  /* ior1 */
   mov mic1MAR, mic1SP
   ldr mic1MDR, [mic1MAR]

   mov mic1H, mic1TOS      /* ior2 */

   orr mic1TOS, mic1MDR, mic1H
   mov mic1MDR, mic1TOS    /* ior3 */
   str mic1TOS, [mic1MAR]
   b Main1

iinc:                      /* Add number to local variable */
   add mic1PC, mic1PC, #1  /* iinc1 */
   ldrb mic1MBRU, [mic1PC]
   mov mic1H, mic1LV

   add mic1MAR, mic1H, mic1MBRU, LSL #2  /* iinc2 */
   ldr mic1MDR, [mic1MAR]

   add mic1PC, mic1PC, #1  /* iinc3 */
   ldrsb mic1MBR, [mic1PC]

   mov mic1H, mic1MDR      /* iinc4 */
   add mic1MDR, mic1MBR, mic1H   /* iinc5 */
   str mic1MDR, [mic1MAR]  /* iinc6 */
   b Main1

ifeq:                      /* Branches if top of stack is zero */
   sub mic1SP, mic1SP, #4  /* ifeq1 */
   mov mic1MAR, mic1SP
   ldr mic1MDR, [mic1MAR]

   mov r0, mic1TOS         /* ifeq2 */
   mov mic1TOS, mic1MDR    /* ifeq3 */
   cmp r0, #0              /* ifeq4 */
   beq goto
   add mic1PC, mic1PC, #2
   b Main1

iflt:                      /* Branches if top of stack is less than zero */
   sub mic1SP, mic1SP, #4  /* iflt1 */
   mov mic1MAR, mic1SP
   ldr mic1MDR, [mic1MAR]

   mov r0, mic1TOS         /* iflt2 */
   mov mic1TOS, mic1MDR    /* iflt3 */
   cmp r0, #0              /* iflt4 */
   blt goto
   add mic1PC, mic1PC, #2
   b Main1

if_icmpeq:                 /* Branches if two on stack are equal */
   sub mic1SP, mic1SP, #4  /* if_icmpeq1 */
   mov mic1MAR, mic1SP
   ldr mic1MDR, [mic1MAR]

   mov r0, mic1TOS         /* if_icmpeq2 */
   mov mic1TOS, mic1MDR    /* if_icmpeq3 */
   cmp r0, mic1TOS         /* if_icmpeq4 */
   beq goto
   add mic1PC, mic1PC, #2
   b Main1

swap:                      /* Switches top two on stack */
   sub mic1MAR, mic1SP, #4 /* swap1 */
   ldr mic1MDR, [mic1MAR]

   mov mic1MAR, mic1SP     /* swap2 */
   mov mic1H, mic1MDR      /* swap3 */
   str mic1H, [mic1MAR]

   mov mic1MDR, mic1TOS    /* swap4 */
   sub mic1MAR, mic1SP, #4 /* swap5 */
   str mic1MDR, [mic1MAR]
   mov mic1MAR, mic1SP
   ldr mic1MDR, [mic1MAR]

   mov mic1TOS, mic1H      /* swap6 */
   b Main1

idiv:                      /* Devides second to top number by top */
   sub mic1SP, mic1SP, #4  /* Increment the Stack Pointer */
   mov mic1MAR, mic1SP
   ldr mic1MDR, [mic1MAR]

   mov mic1H, mic1TOS      /* Old top of stack put in H */
   mov r1, #0              /* Place 0 in register 1 */
   mov r0, mic1MDR
   cmp r0, #0              /* Branch to division loops */
   ble lesser
   bgt greater
   lesser:
      cmp mic1H, #0
      beq dloops_end
      blt ll
      bgt lg
   greater:
      cmp mic1H, #0
      beq dloops_end
      blt gl
      bgt gg
      ll:                  /* Both are negative */
         sub r0, r0, mic1H
         cmp r0, #0
         bgt dloops_end
         add r1, r1, #1
         b ll
      lg:                  /* Second is possitive */
         add r0, r0, mic1H
         cmp r0, #0
         bgt dloops_end
         sub r1, r1, #1
         b lg
      gl:                  /* First is possitive */
         add r0, r0, mic1H
         cmp r0, #0
         blt dloops_end
         sub r1, r1, #1
         b ll
      gg:                  /* Both are possitive */
         sub r0, r0, mic1H
         cmp r0, #0
         blt dloops_end
         add r1, r1, #1
         b gg
   dloops_end:
   mov mic1TOS, r1
   mov mic1MDR, mic1TOS    /* Update top of stack */
   str mic1TOS, [mic1MAR]
   b Main1

iand:                      /* Boolean and top two on stack */
   sub mic1SP, mic1SP, #4  /* iand1 */
   mov mic1MAR, mic1SP
   ldr mic1MDR, [mic1MAR]

   mov mic1H, mic1TOS      /* iand2 */

   and mic1TOS, mic1MDR, mic1H
   mov mic1MDR, mic1TOS    /* iand3 */
   str mic1TOS, [mic1MAR]
   b Main1

goto:                      /* Unconditional branch */
   sub r0, mic1PC, #1      /* goto1 */
   add mic1PC, mic1PC, #1  /* goto2 */
   ldrsb mic1MBR, [mic1PC]
   add mic1PC, mic1PC, #1
   ldrb mic1MBRU, [mic1PC]

   orr mic1H, mic1MBRU, mic1MBR, LSL #8   /* goto3, goto4 */
   add mic1PC, r0, mic1H   /* goto5 */
   b Main1                 /* goto6 */

jsr:                       /* Jumps to subroutine */
   add mic1PC, mic1PC, #1  /* jsr0 */
   ldrb mic1MBRU, [mic1PC]

   add mic1SP, mic1SP, #4  /* jsr1 */
   add mic1SP, mic1SP, mic1MBRU, LSL #2

   mov mic1MDR, mic1CPP    /* jsr2 */
   mov mic1CPP, mic1SP     /* jsr3 */
   mov mic1MAR, mic1CPP
   str mic1MDR, [mic1MAR]

   add mic1MDR, mic1PC, #3 /* jsr4 */
   add mic1SP, mic1SP, #4  /* jsr5 */
   mov mic1MAR, mic1SP
   str mic1MDR, [mic1MAR]

   mov mic1MDR, mic1LV     /* jsr6 */
   add mic1SP, mic1SP, #4  /* jsr7 */
   mov mic1MAR, mic1SP
   str mic1MDR, [mic1MAR]

   sub mic1LV, mic1SP, #8  /* jsr8 */
   sub mic1LV, mic1LV, mic1MBRU, LSL #2

   add mic1PC, mic1PC, #1  /* jsr9 */
   ldrb mic1MBRU, [mic1PC]

   sub mic1LV, mic1LV, mic1MBRU, LSL #2
   add mic1PC, mic1PC, #1  /* jsr12 */
   ldrsb mic1MBR, [mic1PC]

   mov mic1H, mic1MBR, LSL #8 /* jsr14 */
   add mic1PC, mic1PC, #1  /* jsr15 */
   ldrb mic1MBRU, [mic1PC]

   orr mic1H, mic1H, mic1MBRU /* jsr17 */
   sub mic1PC, mic1PC, #5
   add mic1PC, mic1PC, mic1H

   b Main1                 /* jsr18 */

ret:                       /* Return from subroutine or end */
   cmp mic1CPP, #0         /* ret0 */
   beq end

   mov mic1MAR, mic1CPP    /* ret1 */
   ldr mic1MDR, [mic1MAR]  /* ret2 */
   mov mic1CPP, mic1MDR    /* ret3 */
   add mic1MAR, mic1MAR, #4/* ret4 */
   ldr mic1MDR, [mic1MAR]  /* ret5 */
   mov mic1PC, mic1MDR     /* ret6 */
   add mic1MAR, mic1MAR, #4/* ret7 */
   ldr mic1MDR, [mic1MAR]

   mov mic1MAR, mic1LV     /* ret8 */
   mov mic1SP, mic1LV

   mov mic1LV, mic1MDR     /* ret9 */
   mov mic1MDR, mic1TOS    /* ret10 */
   str mic1TOS, [mic1MAR]

   b Main1                 /* ret11 */

end:                       /* Prints top of stack and exits */
   ldr r0, =fmtd
   mov r1, mic1TOS
   bl printf
   mov r0, #0
   pop {lr}
   bx lr

error:                     /* Display error message and exit with status of 1 */
   ldr r0, =errorMessage
   bl puts
   mov r0, #1
   pop {lr}
   bx lr
