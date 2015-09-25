*************************************************************************
*
* Title:        LED Light Blinking
*
* Objective:    CMPEN 472 Homework 2
*
* Revision:     V2.1.4
*
* Date:         Sept. 5, 2015
*
* Programmer:   Raquel Alvarez
*
* Company:      The Pennsylvania State University
*               Department of Computer Science and Engineering
*
* Algorithm:    Simple Parallel I/O in a nested delay-loop, demo
*
* Register Use: A: Light on/off state and Switch SW1 on/off state
*               X,Y: Delay loop counters
*
* Memory Use:   RAM locations from $3000 for data,
*                                  $3100 for program
*
* Input:        Parameters hard coded in the program,
*               Switch SW1 at PORTP bit 0
*
* Output:       LED 1,2,3,4 at PORTB bit 4,5,6,7
*
* Observation:  This is a program that blinks LEDs and blinking period
*               can be changed with the delay loop counter value.
*
* Note:         There is a workaround for this program. Start the simulation
*               And then turn on all the LEDs (they all should be green).
*       
*               You will see the following pattern, when you push the button: 
*                     
*                     LED:  4   3   2   1
*                          off off off off
*                          on  off off off
*                          off on  off off
*                          off off on  off
*                          off off off on
*
*
* Comments:     This program is developed and simulated using CodeWarrior
*               development software.
*
*************************************************************************

*************************************************************************
* LED Mapping:                                                          *
* -----------------------------------------                             *
* |  LED  | 4   3   2   1   x   x   x   x |                             *
* -----------------------------------------                             *
* | PORTB | 7   6   5   4   3   2   1   0 |                             *
* -----------------------------------------                             *
*                                                                       *
* PUSH SWITCH Mapping:                                                  *
*   SW1 -> bit 0 of PORT P                                              *
*************************************************************************

*************************************************************************
* Parameter Declaration Section
*
* Export Symbols
          XDEF        pgstart       ; export 'pgstart' symbol
          ABSENTRY    pgstart       ; for assembly entry point
                                    ; this is the first instruction of the
                                    ; program, up on the start of simulation

* Symbols and Macros
PORTA     EQU         $0000         ; i/o port addresses (port A not used)
DDRA      EQU         $0002       

PORTB     EQU         $0001         ; port B is connected with LEDs   (port = 1 is PORT B)
DDRB      EQU         $0003         
PUCR      EQU         $000C         ; enable pull-up mode for PORT A,B,E,K
                                    ; this leaves the pins logic high

PTP       EQU         $0258         ; PORT P data register, used for Push switch
PTIP      EQU         $0259         ; PORT P input register           (port = 259 is PORT P)
DDRP      EQU         $025A         ; PORT P data direction register
PERP      EQU         $025C         ; PORT P pull-up/down enable
PPSP      EQU         $025D         ; PORT P pull-up/down selection

*
*************************************************************************

*************************************************************************
* Data Section
*
          ORG         $3000         ; reserve RAM memory starting address
                                    ; memory $3000 - $30FF are for data

Counter1  DC.W        $4FFF         ; initial X register count number (define constant. 2bytes)
Counter2  DC.W        $0020         ; initial Y register count number

StackSP                             ; remaining memory space for stack data
                                    ; initial stack pointer position set
                                    ; to $3100 (pgstart)
*
*************************************************************************

*************************************************************************
* Program Section
*
          ORG         $3100         ; program start address in RAM
pgstart   LDS         #pgstart      ; loads stack pointer with address of pgstart
                                    ; initialize stack pointer

          LDAA        #%11110000    ; set PORT B bit 7-4 as output, and 3-0 as input
          STAA        DDRB          ; LED 1-4 on PORT B bit 4-7
                                    ; DIP switch 1-4 on PORT B bit 0-3
                                    
          BSET        PUCR, %00000010 ; enable PORT B pull-up/down feature for the
                                      ; DIP switch 1-4 on PORT B bits 0-3                                   
                      
          BCLR        DDRP, %00000011 ; set PORT P bit 0 and 1 as input(DDRP[0] = 0)
                                      ; set PORT P bit 0 and 1 as Push Button Switch
          
          BSET        PERP, %00000011 ; enable pull up/down on PORT P bit 0 and 1
          BCLR        PPSP, %00000011 ; select PORT P bit 0 and 1 as pull up
          
          LDAA        #%10010000      ; load reg A with F0 to set output of LEDs as 1
          STAA        PORTB           ; 0=on 1=off, this turns LEDs 1 and 4 off in PORT B
          


mainLoop ; blink LED 4 and LED 1 alternatively when SW1 not pushed, change pattern otherwise          
          LDAA        PTIP              ; load value on PORT P input register into A
          ANDA        #%00000001        ; & value of A with A, this gives us only 
                                        ; the value of bit 0 from PORT P, which is SW 1
          BEQ         sw1notpsh         ; if SW1 == 1, then button is being pushed


          ; keep alterante blinking pattern if button not pushed
sw1pushed BSET        PORTB, %11110000  ; turn LEDS OFF  (ON = 0), leave the rest OFF
          JSR         delay1sec
          BCLR        PORTB, %10000000  ; turn LED 4 ON
          JSR         delay1sec
          BSET        PORTB, %11110000  ; TURN LEDS OFF
          JSR         delay1sec
          BCLR        PORTB, %01000000  ; turn LED 3 ON
          JSR         delay1sec
          BSET        PORTB, %11110000  ; TURN LEDS OFF
          JSR         delay1sec
          BCLR        PORTB, %00100000  ; turn LED 2 ON
          JSR         delay1sec       
          BSET        PORTB, %11110000  ; TURN LEDS OFF
          JSR         delay1sec 
          BCLR        PORTB, %00010000  ; turn LED 1 ON
          JSR         delay1sec
          BRA         mainLoop          ; loop forever



          ; change pattern if button is pushed - pattern: *000 0*00 00*0 000*
sw1notpsh BSET        PORTB, %10010000  ; LED 4 OFF
          JSR         delay1sec         ; wait 1 sec
          BCLR        PORTB, %11100000  ; LED 4 ON
          JSR         delay1sec
          BSET        PORTB, %10010000  ; LED 1 ON
          JSR         delay1sec         ; wait 1 sec
          BCLR        PORTB, %01110000  ; LED 1 OFF
          JSR         delay1sec
          BRA         mainLoop          ; loop forever
*
*************************************************************************

*************************************************************************
* Subroutine Section
*
*             ----------------------------------------------- 
*
* + Subroutine: delay1sec
*   - Description: delay of 1 second
*   - Input: a 16 bit number in 'Counter2', stored in register Y
*   - Output: cpu cycles wasted to delay 1 second
*   - Registers in use: Y register, as counter
*   - Memory locations in use: a 16 bit input number in 'Counter2' originally set to $20 

delay1sec
            LDY         Counter2    ; long delay by
dly1Loop    JSR         delayMS     ; Y * delayMS
            DEY                     ; Y - 1
            BNE         dly1Loop    ; keep looping until counter = 0
            RTS

*             -----------------------------------------------          
*
* + Subroutine: delayMS
*   - Description: delay a few msec.
*   - Input: a 16 bit number in 'Counter1', stored in register X
*   - Output: cpu cycles wasted to delay a few msec.
*   - Registers in use: X register, as counter
*   - Memory locations in use: a 16 bit input number in 'Counter1' originally set to $4FFF = 20479

delayMS
            LDX         Counter1    ; short delay
dlyMSLoop   NOP
            DEX                     ; decrease X by 1
            BNE         dlyMSLoop   ; keep looping if counter is not 0
            RTS
            
*
*************************************************************************

*****************************   End of File   ***************************
            end                     ; last line of a file
*************************************************************************