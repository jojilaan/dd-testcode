#include<avr/io.h>
#include<avr/interrupt.h>
#include <util/twi.h>

.text
.global main

LINE	= 24
PARAM	= 24
PWM	= 25
I2C_OFF	= 26	; XL

.equiv PIXEL , 0xFF
.equiv I2C_REG , 0xFF
.equiv KEYS, 0x00

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

.func main
main:
	LDI	PARAM, 0x00
	OUT	_SFR_IO_ADDR(PORTA), PARAM
	LDI	PARAM, 0x01
	OUT	_SFR_IO_ADDR(PORTB), PARAM
	LDI 	PARAM, 0x00
	OUT	_SFR_IO_ADDR(PORTC), PARAM
	LDI 	PARAM, 0xFF 
	OUT	_SFR_IO_ADDR(PORTD), PARAM
	RJMP	TWI_vect
.endfunc

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
	LDS	I2C_OFF, I2C_REG
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
	STS 	I2C_REG, PARAM			; address = DATA
	RJMP	lrdone
lrspixel:
	LDI	YL, lo8(PIXEL)
	LDI	YH, hi8(PIXEL)
	ADD	YL, I2C_OFF
	INC	I2C_OFF
	STS	I2C_REG, I2C_OFF
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
	STS	I2C_REG, PARAM
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
        LDS	PARAM, KEYS
        STS     TWDR, PARAM
	RJMP    ltdone
ltsee:
        LDI     PARAM, 0
        SBIS    _SFR_IO_ADDR(PORTB), EE_WP
        LDI     PARAM, 1
        STS     TWDR, PARAM
        RJMP    ltdone
ltspixel:
        LDI     YL, lo8(PIXEL)
        LDI     YH, hi8(PIXEL)
        ADD     YL, I2C_OFF
        INC     I2C_OFF
        STS	I2C_REG, I2C_OFF
        CLR     I2C_OFF
        ADC     YH, I2C_OFF
        LD      I2C_OFF, Y
        STS     TWDR, I2C_OFF
ltdone:
	LDI	PARAM,  (1<<TWEA) | (1<<TWEN) | (1<<TWIE) | (1<<TWINT)
	RJMP	ldone
.endfunc
