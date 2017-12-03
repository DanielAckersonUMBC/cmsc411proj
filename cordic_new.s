@ Elia Deppe
@ cdeppe1@umbc.edu
@ CMSC 411 -- Computer Architecture
@ Group Project
@   Members:
@       Elia Deppe
@       Dylan Demchuk
@       Brad Harmening
@       Daniel Ackerson

@ cordic algorithm to find cos(theta), sin(theta), and tan(theta)
@ this program gets precision to the 6th decimal point
@ this program is only meant to handle angles from 0 to 90 degrees

@ this mostly imitates a program from this document http://bsvi.ru/uploads/CORDIC--_10EBA/cordic.pdf
@   as well as helped me better understand how the cordic equation as a whole

@ data segment

        .data
        
@ arctan table, values multiplied by a factor of 2^20
arctan:
        .word 47185920, 27855475, 14718068, 7471121, 3750058
        .word 1876857, 938658, 469357, 234682, 117342
        .word 58671, 29335, 14668, 7334, 3669
        .word 1833, 917, 458, 229, 115
        .word 57, 29, 14, 7, 4
        .word 2, 1
        
@ 2^20
factor:
        .word 1048576

x:
        .word 636750                @2^20 * 0.6072529350089 (cordic gain)

y:
        .word 0
        
cos:
        .float 0
        
sin:
        .float 0
        
tan:
        .float 0
        
angle:
        .word 0
        
true_angle:
        .word 31457280              @30 * 2^20



        .text
        .global _start
        .align 2
        
_start:
        ldr r9, =x
        ldr r0, [r9]                @ x -- 2^20 * 0.6072529350089 (cordic gain for 2^20)
        mov r1, #0                  @ y
        mov r2, #0                  @ angle
        ldr r9, =true_angle
        ldr r3, [r9]                @ desired_angle -- 30 * 2^20
        ldr r8, =arctan             @ r8 holds arctan address
        ldr r4, [r8]                @ get first arctan value
        mov r5, #0                  @ i
        
sincos_cordic:
        cmp r3, r2                  @ find if angle is currently > or <
        blo less_than
        
greater_than:
        mov r6, #0                  @ x_new -- set to 0
        mov r7, #0                  @ y_new -- set to 0
        
        sub r6, r0, r1, lsr r5      @ rotation of x -- x_new = x - (y >> i)
        add r7, r1, r0, lsr r5      @ rotation of y -- y_new = y + (x >> i)
        add r2, r4                  @ add the current observed angle to total angle
        
        add r5, #1                  @ increment i
        add r8, #4                  @ move up a word in memory to next arctan value
        ldr r4, [r8]                @   and load value into r4
        
        mov r0, r6                  @ set x and y values equal to new rotations
        mov r1, r7
        
        b check

@ less than function essentially same as above, only difference is the change of equations
@   x_new = x + (y >> i)
@   y_new = y - (x >> i)
less_than:
        mov r6, #0
        mov r7, #0
        
        add r6, r0, r1, lsr r5
        sub r7, r1, r0, lsr r5
        sub r2, r4
        
        add r5, #1
        add r8, #4
        ldr r4, [r8]
        
        mov r0, r6
        mov r1, r7
        
check:
        cmp r5, #27                 @ check if at end of loop
        bne sincos_cordic           @ if not then jump back to sincos_cordic

@ the current values in r0 and r1 are the integer values that if divided by 2^20, grants
@   cos(theta) and sin(theta) respectively        
find_cos_sin_tan:
        ldr r9, =x
        str r0, [r9]
        ldr r9, =y
        str r1, [r9]

        vmov s0, r0                 @ load x and y into single float point registers
        vmov s1, r1
        ldr r9, =factor             @ load factor (2^20)
        vldr s2, [r9]
        vdiv.f32 s3, s0, s2         @ cos(theta) = x / 2^20
        vdiv.f32 s4, s1, s2         @ sin(theta) = y / 2^20
        vdiv.f32 s5, s4, s3         @ tan(theta) = sin(theta) / cos(theta)

@ store the values of cos(theta), sin(theta), and tan(theta) into their respective memory locations        
store:
        ldr r0, =cos
        ldr r1, =sin
        ldr r2, =tan
        vstr.32 s3, [r0]
        vstr.32 s4, [r1]
        vstr.32 s5, [r2]
        
finish:
        .end