#include <avr/io.h>
#include <util/twi.h>

LINE	= 24
PARAM	= 24
PWM	= 25
I2C_OFF	= 26

.equiv I2C_WAI	, 0xf0
.equiv I2C_VER	, 0xf1
.equiv I2C_KEYS	, 0xf2
.equiv I2C_EE_WP, 0xf3
.equiv I2C_ID	, 's'
.equiv VERSION	, 0

; PORTB
.equiv EE_WP	, PB0
.equiv KEYS_INT	, PB6
.equiv FRAME_INT, PB7

; PORTC
.equiv LED_SDO	, PC0
.equiv LED_CLKR	, PC1
.equiv LED_LE	, PC2
.equiv LED_SDI	, PC3
.equiv SDA	, PC4
.equiv SCL	, PC5
.equiv LED_OE_N	, PC7

.macro CLOCK_OUT
	SBI	_SFR_IO_ADDR(PORTC), LED_CLKR			; SET BIT
	CBI	_SFR_IO_ADDR(PORTC), LED_CLKR			; CLEAR BIT
.endm

.macro COL_OUT reg						; send color out to serial digital input
	CP	PWM, \reg					; copy register to PWM
	BRSH	lclear\reg					; branch if same or higher to lclear with reg
	SBI	_SFR_IO_ADDR(PORTC), LED_SDI			; set bit PORTC with LED_SDI
	RJMP	ldone\reg					; relative jump to ldone with reg
lclear\reg:
	CBI	_SFR_IO_ADDR(PORTC), LED_SDI			; clear bit PORTC LED_SDI
ldone\reg:
	CLOCK_OUT						; macro CLOCK_OUT
.endm

.global draw_loop						; function declaration of drawloop
.global delay							; function declaration of delay
.global read_data						; function declaration of readdata
.global write_data						; function declaration of write data
.global TWI_vect						; function declaration of TWI_vect

.extern pixels							 
.extern id							
.extern key								
.extern i2c_reg							; I2C register

.section .text
.func draw_loop							; function draw_loop
draw_loop:							; begin draw_loop function
Lframe_loop:
	CBI	_SFR_IO_ADDR(PORTC), FRAME_INT			; clear bit PORTC, FRAME_INT
	LDI	YL, lo8(pixels)					; Push pixel value to YL
	LDI	YH, hi8(pixels)					; Push pixel value to YH
	LDI	LINE, 0xFE					; Load immediate 0xFE to line
Lline_loop:
	OUT	_SFR_IO_ADDR(PORTD), LINE			; store register Line to PORTD
	LDI	PWM, 0 						; Load immediate 0 to PWM

	;Automatically increment Y register load the value to the corresponding r register
	LD	r0, Y+							
	LD	r1, Y+							
	LD	r2, Y+							
	LD	r3, Y+							 
	LD	r4, Y+							 
	LD	r5, Y+							 
	LD	r6, Y+							 
	LD	r7, Y+							 
	LD	r8, Y+							
	LD	r9, Y+							
	LD	r10, Y+							
	LD	r11, Y+							
	LD	r12, Y+						
	LD	r13, Y+					
	LD	r14, Y+							
	LD	r15, Y+							
	LD	r16, Y+							
	LD	r17, Y+							
	LD	r18, Y+							
	LD	r19, Y+							
	LD	r20, Y+							
	LD	r21, Y+							
	LD	r22, Y+							
	LD	r23, Y+						
Lpwm_loop:

	; use the COL_OUT macro for the corresponding r register
	COL_OUT	r0							
	COL_OUT	r1							
	COL_OUT	r2							
	COL_OUT	r3							
	COL_OUT	r4							
	COL_OUT	r5							
	COL_OUT	r6							
	COL_OUT	r7							
	COL_OUT	r8							
	COL_OUT	r9							
	COL_OUT	r10							
	COL_OUT	r11							
	COL_OUT	r12							
	COL_OUT	r13							
	COL_OUT	r14							
	COL_OUT	r15							
	COL_OUT	r16							
	COL_OUT	r17							
	COL_OUT	r18							
	COL_OUT	r19							
	COL_OUT	r20							
	COL_OUT	r21							

	SBI	_SFR_IO_ADDR(PORTC), LED_LE		; Set bit PORTC LED_LE (LED LATCH ENABLE) HIGH
	COL_OUT	r22					; use the COL_OUT macro for r0 register
	COL_OUT	r23					; use the COL_OUT macro for r0 register
	CBI	_SFR_IO_ADDR(PORTC), LED_LED		; Clear bit PORTC LED_LE (LED LATCH ENABLE)
	INC	PWM					; Increment PWM by one (1)
	SBRS	PWM, 6					; Skip next instruction if bit in PWM is 6
	RJMP	Lpwm_loop				; Relative jump to Lpwm_loop
	ROL	LINE					; Rotate left through carry with LINE
	BRCC	lframeend				; branch if carry cleared and go to lframeend
	INC	LINE 					; Increment line by one (1)
	RJMP	Lline_loop				; relative jump to Lline_loop
lframeend:
	SBI	_SFR_IO_ADDR(PORTB), FRAME_INT		; Set bit PORTB FRAME_INT
	CBI	_SFR_IO_ADDR(PORTD), 7			; Clear PORTD
	
	SBI	_SFR_IO_ADDR(PORTB), LED_OE_N		; start Scan 
	LDI	PARAM, 0xF8				; load immediate 0xF8 to PARAM
	OUT	_SFR_IO_ADDR(PORTD), PARAM		; send PARAM to PORTD
	COM	PARAM					; Get the compliment of param i.e. FF - value of PARAM
	OUT	_SFR_IO_ADDR(DDRD), PARAM		; send PARAM to data direction register D (DDRD)
	LDS	PWM, keys				; load keys directly from data space to PWM
	IN	PARAM, _SFR_IO_ADDR(PIND)		; load an IO location to a register
	COM	PARAM					; get the compliment of PARAM
	LSR	PARAM					; logical shift right of PARAM
	LSR	PARAM					; logical shift right of PARAM
	LSR	PARAM					; logical shift right of PARAM
	STS	keys, PARAM				; store PARAMS directly to data space keys
	CPSE	PARAM, PWM				; Compare PWM with PARAM and skip next instruction if equal
	SBI     _SFR_IO_ADDR(PORTB), KEYS_INT 		; Set bit PORTB KEYS_INT
	LDI	PARAM, 0xFF				; Load 0xFF to PARAM
	OUT	_SFR_IO_ADDR(DDRD), PARAM		; send PARAM to data direction register D (DDRD) 
	COM	PARAM					; Get compliment from PARAM (THANKS YOU!!)
	OUT	_SFR_IO_ADDR(PORTD), PARAM		; send PARAM TO PORTB
	CBI	_SFR_IO_ADDR(PORTB), LED_OE_N		; end Scan
	RJMP	Lframe_loop				; relative jump to Lframe_loop
	RET						; return
.endfunc

.func delay
delay:
	PUSH	r19					; push register r19 to the stack
	PUSH	r20					; push register r20 to the stack;
	IN	r20, _SFR_IO_ADDR(TCNT0)		; put TCNT0 (Timer Counter Register) into register r20 : start = TCNT0;
lloop:						
	IN	r19, _SFR_IO_ADDR(TCNT0)		; put TCNT0 (Timer Counter Register) into register r19 
	SUB	r19, r20				; Substract r20 register from r19 register value	
	CP	r19, LINE				; Compare LINE with the r19 register
	BRLO	lloop					; Branch if lower instruction. Goto lloop if LINE was smaller than the r19 register
	POP	r20					; POP r20 off the stack
	POP	r19					; POP r19 off the stack
	RET						; return
 .endfunc

.func write_data					; Cal the write_data function
; r20-23 DATA
; r24 TYPE
write_data:						; Write_data loop
	PUSH	r18					; PUSH r18 on the stack
	;PUSH	r20					
	PUSH	r21					; PUSH r21 on the stack
	PUSH	r22					; PUSH r22 on the stack
	PUSH	r23					; PUSH r23 on the stack
	PUSH	r24					; PUSH r24 on the stack
	LDI	r18, 24					; Load literal 24 into r18
1:							; do 
	SBRS	r23, 0					; Execute binary AND operation on r23 and 1. (check of LSB is SET) -- if (data&1)
	RJMP	2f					; If bit is not set, relative jump to 2
	SBI	_SFR_IO_ADDR(PORTC), LED_SDI		; If bit is set -> set LED_SDI
	RJMP	3f					; relative jump to 3
2:							
	CBI	_SFR_IO_ADDR(PORTC), LED_SDI		; clear LED_SDI;
3:
	ASR	r23					; data (r23) <<= 1;
	ROR	r22					; Rotate right r22
	ROR	r21					; Rotate right r21 
	;ROR	r20					
	CP	r24, r18				; Compare r18 with r24 -- C code: if (type == i)
	BRNE	4f					; Branch if not equal, if r18 is equal to r24 then goto 4
	SBI	_SFR_IO_ADDR(PORTC), LED_LE		; if not -> set LED_LE;
4:
	CLOCK_OUT					 
	DEC	r18					; Decrement r18 -- C code: i--;
	BRNE	1b					; Branch if not equal -- C code: while (i!=0);
	CBI	_SFR_IO_ADDR(PORTC), LED_LE		; clear LED_LE
	POP	r24					; POP r24 off the stack
	POP	r23					; POP r23 off the stack
	POP	r22					; POP r22 off the stack
	POP	r21					; POP r21 off the stack
	;POP	r20
	POP	r18					; POP r18 off the stack
	RET						; return
.endfunc						; end function

.func read_data						; Function read_data
; r22-25 RETURN
; r24 TYPE
read_data:
	PUSH	r18					; Push r18 onto the stack
	PUSH	r19					; Push r19 onto the stack
	;PUSH	r20
	PUSH	r21					; Push r21 onto the stack
	PUSH	r22					; Push r22 onto the stack
	PUSH	r23					; Push r23 onto the stack
	PUSH	r24					; Push r24 onto the stack
	LDI	r18, 24					; Load literal 24 in r18 			
1:							; do {
	IN	r19, _SFR_IO_ADDR(PORTC)		; ret (r19) |= PINC&1;
	ANDI	r19, LED_SDI				; Logical AND operation on LED_SDI bit and r19
	SBRS	r23, 0					; Skip next instruction if the LSB bit is r19 (data) is set: if (data&1)
	RJMP	2f					; If not set -> goto 2
	SBI	_SFR_IO_ADDR(PORTC), LED_SDI		; If set -> set LED_SDI;
	RJMP	3f
2:							; else
	CBI	_SFR_IO_ADDR(PORTC), LED_SDI		; clear LED_SDI;
3:
	ASR	r23					; data (r23) <<= 1;
	ROR	r22					; Rotate Right r22
	ROR	r21					; Rotate right r21
	;ROR	r20					
	CP	r24, r18				; Compare r24 with r18 -- if (type == i)
	BRNE	4f					; Branch if not equal, if type is not i -> goto 4
	SBI	_SFR_IO_ADDR(PORTC), LED_LE		; If type is i -> set LDE_LE;
4:
	CLOCK_OUT
	DEC	r18					; Decrement r18 -- i--;
	BRNE	1b					; Branch if not equal to 0 -- while (i!=0);
	CBI	_SFR_IO_ADDR(PORTC), LED_LE		; if i!=0 -> clr LDE_LE
	POP	r24					; POP r24 off the stack
	POP	r23					; POP r23 off the stack
	POP	r22					; POP r22 off the stack
	POP	r21					; POP r21 off the stack
	;POP	r20
	POP	r19					; POP r19 off the stack
	POP	r18					; POP r18 off the stack
	RET						; Return
.endfunc

;TODO: Add reads and NACK bad addresses.
;PARAM (r24) - TWSR
;PWM (r25) - SREG
;DI2C/XL (r26) - Address
.func TWI_vect
TWI_vect:
	PUSH	PARAM				; Push PARAM onto the stack
	PUSH	PWM				; Push PWM onto the stack
	PUSH	YL				; Push YL onto the stack
	PUSH	YH				; Push YH onto the stack
	PUSH	I2C_OFF				; Push I2C_OFF onto the stack
	IN	PWM, _SFR_IO_ADDR(SREG)		 
	LDS	PARAM, TWSR			; Load direct from data space: Loads PARAM to TWSR (TWI Status Register) 
	ANDI	PARAM, 0xF8			; AND operation hex 0xF8 and PARAM
	LDS	I2C_OFF, i2c_reg		; Load direct from data space: Loads I2C_OFF to i2c_reg 
	CPI	PARAM, TW_ST_SLA_ACK		; Compare PARAM with Slave Receive ACK Address
	BREQ	ltsend				; Branch if the above registers are equal 
	CPI	PARAM, TW_SR_DATA_ACK		; Compare PARAM with Slave Receive Data
	BREQ	lreceive			; Branch if the above registers are equal
	CPI	PARAM, TW_SR_SLA_ACK		; Compare PARAM with Slave Receive ACK Address
	BREQ	lrack				; Branch if the above registers are equal
	CPI	PARAM, TW_ST_DATA_ACK		; Compare PARAM with Slave Transmit Data
	BREQ	ltsend				; Branch if the above registers are equal
	CPI	PARAM, TW_ST_DATA_NACK		  
	BREQ	ltdnack
	LDI	PARAM,  (1<<TWEA) | (1<<TWEN) | (1<<TWIE) | (1<<TWINT) ;ELSE
	RJMP	ldone				; Relative jump to ldone loop
lreceive:
	LDS	PARAM, TWDR			; Load direct from data space: Loads PARAM to TWDR Data
	CPI	I2C_OFF, 193			; Compare I2C_OFF with literal 193 -> if address<=192
	BRLO	lrspixel			; Branch if address is lower than 193
	CPI	I2C_OFF, 0xff			; Compare I2C_OFF with hex 0xFF -> if address==0xff
	BREQ	lrsreg				; Branch if address equals 255
	CPI	I2C_OFF, I2C_EE_WP		; Compare I2C_OFF with I2C_EE_WP
	BREQ	lree				; Branch if the address equals I2C_EE_WP
	; NACK here
	RJMP	lrdone				; Relative jump to lrdone loop.
lree:
	SBI	_SFR_IO_ADDR(PORTB), EE_WP 	; Set EE_WP bit in PORTB
	CPSE	PARAM, 0			; Compare skip if equal -> If PARAM equals 0, skip next instruction
	CBI	_SFR_IO_ADDR(PORTB), EE_WP	; If param is not 0, Clear EE_WP bit in PORTB
	RJMP	lrdone				; if param is 0 -> relative jump lrdone loop
lrsreg:				
	STS	i2c_reg, PARAM			; Store data into data space: Loads contents of i2c_reg to PARAM -> C code: address = DATA
	RJMP	lrdone				; Relative jump to lrdone loop
lrspixel:
	LDI	YL, lo8(pixels)			; 
	LDI	YH, hi8(pixels)
	ADD	YL, I2C_OFF
	INC	I2C_OFF				; Increment I2C_OFF
	STS	i2c_reg, I2C_OFF		; Store data into data space: Loads contents of i2c_reg to I2C_OFF
	CLR	I2C_OFF				; Clear I2C_OFF register
	ADC	YH, I2C_OFF			; Add contents of YH, I2C_OFF and the carry to YH
	ST	Y, PARAM			; Store the contents of Y indirect to PARAM
lrdone:
	LDI	PARAM,  (1<<TWEA) | (1<<TWEN) | (1<<TWIE) | (1<<TWINT)
ldone:
	STS	TWCR, PARAM			; Loads contents of TWCR to PARAM
	OUT	_SFR_IO_ADDR(SREG), PWM		; Write data
	POP	I2C_OFF				; POP I2C_OFF off the stack
	POP	YH				; POP YH off the stack
	POP	YL				; POP YL off the stack
	POP	PWM				; POP PWM off the stack
	POP	PARAM				; POP PARAM off the stack
	RETI					; Return
lrack:
	LDI	PARAM, 0xff			; Load PARAM with hex 255 -> Address = 0xff
	STS	i2c_reg, PARAM			; Store PARAM in i2c_Reg
	LDI	PARAM,  (1<<TWEA) | (1<<TWEN) | (1<<TWIE) | (1<<TWINT)
	RJMP	ldone				; Relative jump to ldone
ltdnack:
	RJMP	ltdone				; Relative jump to ldone
ltsend:
	CPI     I2C_OFF, 193                    ; Compare I2C_OFF with literal 193 -> if address<=192
        BRLO    ltspixel			; Branch if address is lower then 193
        CPI     I2C_OFF, I2C_KEYS		; Compare I2C_OFF with I2C_KEYS
        BREQ    ltskeys				; Branch if the above registers are equal
        CPI     I2C_OFF, I2C_WAI                ; Compare I2C_OFF with I2C_WAI -> if address==I2C_WAI
        BREQ    ltswai				; Branch if the above regsiters are equal
        CPI     I2C_OFF, I2C_EE_WP		; Compare I2C_OFF with I2C_EE_WP
        BREQ    ltsee				; Branch if the above registers are equal
	CPI     I2C_OFF, I2C_VER		; Compare I2C_PFF with I2C_VER
        BREQ    ltsver				; Branch if the above registers are equal
	LDI	PARAM, 0xff			; Load hex 0xFF into PARAM
	STS	TWDR, PARAM			; Store PARAM into TWDR
	RJMP	ltdone				; Relative jump to ltdone
ltswai:	
        LDI     PARAM, I2C_ID			; Load I2C_IC into PARAM
        STS     TWDR, PARAM			; Store PARAM into TWDR
        RJMP    ltdone				; Relative jump to ltdone
ltsver:
        LDI     PARAM, VERSION			; Load VERSION into PARAM
        STS     TWDR, PARAM			; Store PARAM into TWDR
        RJMP    ltdone				; Relative jump to ltdone
ltskeys:
        CBI     _SFR_IO_ADDR(PORTB), KEYS_INT	; Clear KEYS_INT bit
        LDS	PARAM, keys			; Load directy from data space -> Load keys into PARAM
        STS     TWDR, PARAM			; Sotre PARAM into TWDR
	RJMP    ltdone				; Relative jump to ltdone
ltsee:
        LDI     PARAM, 0			; Load 0 to PARAM
        SBIS    _SFR_IO_ADDR(PORTB), EE_WP	; Skip if bit in IO register is set -> Skip next instruction if EE_WP bit is set
        LDI     PARAM, 1			; IF EE_WP is not set, load 1 into PARAM
        STS     TWDR, PARAM			; if EE_WP is set, store PARAM into TWDR
        RJMP    ltdone				; relative jump to ltdone
ltspixel:
        LDI     YL, lo8(pixels)			; Load low 8 bits into YL
        LDI     YH, hi8(pixels)			; Load high 8 bits into YH
        ADD     YL, I2C_OFF			; ADD I2C_OFF to YL and put the result into YL
        INC     I2C_OFF				; Increment I2C_OFF
        STS     i2c_reg, I2C_OFF		; Store I2C_OFF to i2c_reg
        CLR     I2C_OFF				; Clear i2c_OFF register
        ADC     YH, I2C_OFF			; perfrom ADD i2C_OFF, YH and the CARRY, put the result in YH 
        LD      I2C_OFF, Y			; Load Y to I2C_OFF
        STS     TWDR, I2C_OFF			; Store I2C_OFF to TWDR
ltdone:
	LDI	PARAM,  (1<<TWEA) | (1<<TWEN) | (1<<TWIE) | (1<<TWINT) ; Load PARAM
	RJMP	ldone				; Relative jump to ldone
.endfunc
