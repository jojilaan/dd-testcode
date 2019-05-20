#include <avr/io.h>
#include <util/twi.h>

LINE	= 24
PARAM	= 24
PWM	= 25
I2C_OFF	= 26	; XL

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
.equiv SDA		, PC4
.equiv SCL		, PC5
.equiv LED_OE_N	, PC7

.macro CLOCK_OUT
	SBI	_SFR_IO_ADDR(PORTC), LED_CLKR	; SET BIT
	CBI	_SFR_IO_ADDR(PORTC), LED_CLKR	; CLEAR BIT
.endm

.macro COL_OUT reg 						; send color out to serial digital input
	CP	PWM, \reg 						; copy register to PWM
	BRSH	lclear\reg					; branch if same or higher to lclear with reg
	SBI	_SFR_IO_ADDR(PORTC), LED_SDI	; set bit PORTC with LED_SDI
	RJMP	ldone\reg					; relative jump to ldone with reg
lclear\reg:
	CBI	_SFR_IO_ADDR(PORTC), LED_SDI	; clear bit PORTC LED_SDI
ldone\reg:
	CLOCK_OUT							; macro CLOCK_OUT
.endm

.global draw_loop						; function declaration of drawloop
.global delay							; function declaration of delay
.global read_data						; function declaration of readdata
.global write_data						; function declaration of write data
.global TWI_vect						; function declaration of TWI_vect

.extern pixels							; ??
.extern id								; ??
.extern key								; ??
.extern i2c_reg							; I2C register

.section .text
.func draw_loop							; function draw_loop
draw_loop:								; begin draw_loop function
Lframe_loop:
	CBI	_SFR_IO_ADDR(PORTC), FRAME_INT	; clear bit PORTC, FRAME_INT
	LDI	YL, lo8(pixels)					; Push pixel value to YL
	LDI	YH, hi8(pixels)					; Push pixel value to YH
	LDI	LINE, 0xFE						; Load immediate 0xFE to line
Lline_loop:
	OUT	_SFR_IO_ADDR(PORTD), LINE		; store register Line to PORTD
	LDI	PWM, 0							; Load immediate 0 to PWM
	LD	r0, Y+							; Y+ -> r0 (??)
	LD	r1, Y+							; Y+ -> r0 (??)
	LD	r2, Y+							; Y+ -> r0 (??)
	LD	r3, Y+							; Y+ -> r0 (??)
	LD	r4, Y+							; Y+ -> r0 (??)
	LD	r5, Y+							; Y+ -> r0 (??)
	LD	r6, Y+							; Y+ -> r0 (??)
	LD	r7, Y+							; Y+ -> r0 (??)
	LD	r8, Y+							; Y+ -> r0 (??)
	LD	r9, Y+							; Y+ -> r0 (??)
	LD	r10, Y+							; Y+ -> r0 (??)
	LD	r11, Y+							; Y+ -> r0 (??)
	LD	r12, Y+							; Y+ -> r0 (??)
	LD	r13, Y+							; Y+ -> r0 (??)
	LD	r14, Y+							; Y+ -> r0 (??)
	LD	r15, Y+							; Y+ -> r0 (??)
	LD	r16, Y+							; Y+ -> r0 (??)
	LD	r17, Y+							; Y+ -> r0 (??)
	LD	r18, Y+							; Y+ -> r0 (??)
	LD	r19, Y+							; Y+ -> r0 (??)
	LD	r20, Y+							; Y+ -> r0 (??)
	LD	r21, Y+							; Y+ -> r0 (??)
	LD	r22, Y+							; Y+ -> r0 (??)
	LD	r23, Y+							; Y+ -> r0 (??)
Lpwm_loop:
	COL_OUT	r0							; use the COL_OUT macro for r0 register
	COL_OUT	r1							; use the COL_OUT macro for r0 register
	COL_OUT	r2							; use the COL_OUT macro for r0 register
	COL_OUT	r3							; use the COL_OUT macro for r0 register
	COL_OUT	r4							; use the COL_OUT macro for r0 register
	COL_OUT	r5							; use the COL_OUT macro for r0 register
	COL_OUT	r6							; use the COL_OUT macro for r0 register
	COL_OUT	r7							; use the COL_OUT macro for r0 register
	COL_OUT	r8							; use the COL_OUT macro for r0 register
	COL_OUT	r9							; use the COL_OUT macro for r0 register
	COL_OUT	r10							; use the COL_OUT macro for r0 register
	COL_OUT	r11							; use the COL_OUT macro for r0 register
	COL_OUT	r12							; use the COL_OUT macro for r0 register
	COL_OUT	r13							; use the COL_OUT macro for r0 register
	COL_OUT	r14							; use the COL_OUT macro for r0 register
	COL_OUT	r15							; use the COL_OUT macro for r0 register
	COL_OUT	r16							; use the COL_OUT macro for r0 register
	COL_OUT	r17							; use the COL_OUT macro for r0 register
	COL_OUT	r18							; use the COL_OUT macro for r0 register
	COL_OUT	r19							; use the COL_OUT macro for r0 register
	COL_OUT	r20							; use the COL_OUT macro for r0 register
	COL_OUT	r21							; use the COL_OUT macro for r0 register
	SBI	_SFR_IO_ADDR(PORTC), LED_LE		; Set bit PORTC LED_LE (LED LATCH ENABLE)
	COL_OUT	r22							; use the COL_OUT macro for r0 register
	COL_OUT	r23							; use the COL_OUT macro for r0 register
	CBI	_SFR_IO_ADDR(PORTC), LED_LE		; Clear bit PORTC LED_LE (LED LATCH ENABLE)
	INC	PWM								; Increment PWM by one (1)
	SBRS	PWM, 6						; Skip next instruction if bit in PWM is 6
	RJMP	Lpwm_loop					; Relative jump to Lpwm_loop
	ROL	LINE							; Rotate left through carry with LINE
	BRCC	lframeend					; branch if carry cleared and go to lframeend
	INC	LINE							; Increment line by one (1)
	RJMP	Lline_loop					; relative jump to Lline_loop
lframeend:
	SBI	_SFR_IO_ADDR(PORTB), FRAME_INT	; Set bit PORTB FRAME_INT
	CBI	_SFR_IO_ADDR(PORTD), 7			; Clear PORTD
	
	SBI	_SFR_IO_ADDR(PORTB), LED_OE_N	; start Scan 
	LDI	PARAM, 0xF8						; load immediate 0xF8 to PARAM
	OUT	_SFR_IO_ADDR(PORTD), PARAM		; send PARAM to PORTD
	COM	PARAM							; Get the compliment of param i.e. FF - value of PARAM
	OUT	_SFR_IO_ADDR(DDRD), PARAM		; send PARAM to data direction register D (DDRD)
	LDS	PWM, keys						; load keys directly from data space to PWM
	IN	PARAM, _SFR_IO_ADDR(PIND)		; load an IO location to a register
	COM	PARAM							; get the compliment of PARAM
	LSR	PARAM							; logical shift right of PARAM
	LSR	PARAM							; logical shift right of PARAM
	LSR	PARAM							; logical shift right of PARAM
	STS	keys, PARAM						; store PARAMS directly to data space keys
	CPSE	PARAM, PWM					; Compare PWM with PARAM and skip next instruction if equal
	SBI     _SFR_IO_ADDR(PORTB), KEYS_INT ; Set bit PORTB KEYS_INT
	LDI	PARAM, 0xFF						; Load 0xFF to PARAM
	OUT	_SFR_IO_ADDR(DDRD), PARAM		; send PARAM to data direction register D (DDRD) 
	COM	PARAM							; Get compliment from PARAM (THANKS YOU!!)
	OUT	_SFR_IO_ADDR(PORTD), PARAM		; send PARAM TO PORTB
	CBI	_SFR_IO_ADDR(PORTB), LED_OE_N	; end Scan
	RJMP	Lframe_loop					; relative jump to Lframe_loop
	RET									; return
.endfunc

.func delay
delay:
	PUSH	r19
	PUSH	r20
	IN	r20, _SFR_IO_ADDR(TCNT0)	; start = TCNT0;
lloop:
	IN	r19, _SFR_IO_ADDR(TCNT0)	; do {
	SUB	r19, r20			; diff = TCNT0 - start;
	CP	r19, LINE			; } while (diff < ticks);
	BRLO	lloop
	POP	r20
	POP	r19
	RET
 .endfunc

.func write_data
; r20-23 DATA
; r24 TYPE
write_data:
	PUSH	r18
	;PUSH	r20
	PUSH	r21
	PUSH	r22
	PUSH	r23
	PUSH	r24
	LDI	r18, 24	;
1:						; do {
	SBRS	r23, 0				; 	if (data&1)
	RJMP	2f
	SBI	_SFR_IO_ADDR(PORTC), LED_SDI	; 		set LED_SDI;
	RJMP	3f
2:						; 	else
	CBI	_SFR_IO_ADDR(PORTC), LED_SDI	;		clr LED_SDI;
3:
	ASR	r23				; 	data <<= 1;
	ROR	r22
	ROR	r21
	;ROR	r20								; Don't need?
	CP	r24, r18			; 	if (type == i)
	BRNE	4f
	SBI	_SFR_IO_ADDR(PORTC), LED_LE	; 		set LED_LE;
4:
	CLOCK_OUT
	DEC	r18				; 	i--;
	BRNE	1b				; } while (i!=0);
	CBI	_SFR_IO_ADDR(PORTC), LED_LE	; 		clr LED_LE
	POP	r24
	POP	r23
	POP	r22
	POP	r21
	;POP	r20
	POP	r18
	RET
.endfunc

.func read_data
; r22-25 RETURN
; r24 TYPE
read_data:
	PUSH	r18
	PUSH	r19
	;PUSH	r20
	PUSH	r21
	PUSH	r22
	PUSH	r23
	PUSH	r24
	LDI	r18, 24	;
1:						; do {
	IN	r19, _SFR_IO_ADDR(PORTC)	; ret |= PINC&1;
	ANDI	r19, LED_SDI


	SBRS	r23, 0				; 	if (data&1)
	RJMP	2f
	SBI	_SFR_IO_ADDR(PORTC), LED_SDI	; 		set LED_SDI;
	RJMP	3f
2:						; 	else
	CBI	_SFR_IO_ADDR(PORTC), LED_SDI	;		clr LED_SDI;
3:
	ASR	r23				; 	data <<= 1;
	ROR	r22
	ROR	r21
	;ROR	r20								; Don't need?


	CP	r24, r18			; 	if (type == i)
	BRNE	4f
	SBI	_SFR_IO_ADDR(PORTC), LED_LE	; 		set LDE_LE;
4:
	CLOCK_OUT
	DEC	r18				; 	i--;
	BRNE	1b				; } while (i!=0);
	CBI	_SFR_IO_ADDR(PORTC), LED_LE	; 		clr LDE_LE
	POP	r24
	POP	r23
	POP	r22
	POP	r21
	;POP	r20
	POP	r19
	POP	r18
	RET
.endfunc

;TODO: Add reads and NACK bad addresses.
;PARAM (r24) - TWSR
;PWM (r25) - SREG
;DI2C/XL (r26) - Address
.func TWI_vect
TWI_vect:
	PUSH	PARAM
	PUSH	PWM
	PUSH	YL
	PUSH	YH
	PUSH	I2C_OFF
	IN	PWM, _SFR_IO_ADDR(SREG)
	LDS	PARAM, TWSR
	ANDI	PARAM, 0xF8
	LDS	I2C_OFF, i2c_reg
	CPI	PARAM, TW_ST_SLA_ACK		; Slave Receive ACK Address
	BREQ	ltsend
	CPI	PARAM, TW_SR_DATA_ACK		; Slave Receive Data
	BREQ	lreceive
	CPI	PARAM, TW_SR_SLA_ACK		; Slave Receive ACK Address
	BREQ	lrack
	CPI	PARAM, TW_ST_DATA_ACK		; Slave Transmit Data
	BREQ	ltsend
	CPI	PARAM, TW_ST_DATA_NACK
	BREQ	ltdnack
	LDI	PARAM,  (1<<TWEA) | (1<<TWEN) | (1<<TWIE) | (1<<TWINT) ;ELSE
	RJMP	ldone
lreceive:
	LDS	PARAM, TWDR			; Data
	CPI	I2C_OFF, 193			; if address<=192
	BRLO	lrspixel
	CPI	I2C_OFF, 0xff			; if address==0xff
	BREQ	lrsreg
	CPI	I2C_OFF, I2C_EE_WP
	BREQ	lree
	; NACK here
	RJMP	lrdone				; else...
lree:
	SBI	_SFR_IO_ADDR(PORTB), EE_WP
	CPSE	PARAM, 0
	CBI	_SFR_IO_ADDR(PORTB), EE_WP
	RJMP	lrdone
lrsreg:
	STS	i2c_reg, PARAM			; address = DATA
	RJMP	lrdone
lrspixel:
	LDI	YL, lo8(pixels)
	LDI	YH, hi8(pixels)
	ADD	YL, I2C_OFF
	INC	I2C_OFF
	STS	i2c_reg, I2C_OFF
	CLR	I2C_OFF
	ADC	YH, I2C_OFF
	ST	Y, PARAM
lrdone:
	LDI	PARAM,  (1<<TWEA) | (1<<TWEN) | (1<<TWIE) | (1<<TWINT)
ldone:
	STS	TWCR, PARAM
	OUT	_SFR_IO_ADDR(SREG), PWM
	POP	I2C_OFF
	POP	YH
	POP	YL
	POP	PWM
	POP	PARAM
	RETI
lrack:
	LDI	PARAM, 0xff		; Address = 0xff
	STS	i2c_reg, PARAM
	LDI	PARAM,  (1<<TWEA) | (1<<TWEN) | (1<<TWIE) | (1<<TWINT)
	RJMP	ldone
ltdnack:
	RJMP	ltdone
ltsend:
	CPI     I2C_OFF, 193                    ; if address<=192
        BRLO    ltspixel
        CPI     I2C_OFF, I2C_KEYS
        BREQ    ltskeys
        CPI     I2C_OFF, I2C_WAI                ; if address==I2C_WAI
        BREQ    ltswai
        CPI     I2C_OFF, I2C_EE_WP
        BREQ    ltsee
	CPI     I2C_OFF, I2C_VER
        BREQ    ltsver
	LDI	PARAM, 0xff
	STS	TWDR, PARAM
	RJMP	ltdone
ltswai:
        LDI     PARAM, I2C_ID
        STS     TWDR, PARAM
        RJMP    ltdone
ltsver:
        LDI     PARAM, VERSION
        STS     TWDR, PARAM
        RJMP    ltdone
ltskeys:
        CBI     _SFR_IO_ADDR(PORTB), KEYS_INT
        LDS	PARAM, keys
        STS     TWDR, PARAM
	RJMP    ltdone
ltsee:
        LDI     PARAM, 0
        SBIS    _SFR_IO_ADDR(PORTB), EE_WP
        LDI     PARAM, 1
        STS     TWDR, PARAM
        RJMP    ltdone
ltspixel:
        LDI     YL, lo8(pixels)
        LDI     YH, hi8(pixels)
        ADD     YL, I2C_OFF
        INC     I2C_OFF
        STS     i2c_reg, I2C_OFF
        CLR     I2C_OFF
        ADC     YH, I2C_OFF
        LD      I2C_OFF, Y
        STS     TWDR, I2C_OFF
ltdone:
	LDI	PARAM,  (1<<TWEA) | (1<<TWEN) | (1<<TWIE) | (1<<TWINT)
	RJMP	ldone
.endfunc
