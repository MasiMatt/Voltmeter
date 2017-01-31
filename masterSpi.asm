.include "m8def.inc"

.org 0
RESET: rjmp init
.org 0x00E 
acd_int: rjmp adcstart	;ADC interrupt vector

init:
	ldi r17, high(RAMEND)
	out sph, r17
	ldi r17, low(RAMEND)
	out spl, r17
	ldi r17, 0x80			;global interrupt enable (bit7 - I flag)
	out $3f, r17
	ldi r17, 0xff
	out DDRD, r17
	ldi r18, 0
	ldi r19, 0xff
	ldi r20, 0x00
	ldi r21, 0
	ldi r22, 0

SPI_MasterInit:
	; Set MOSI and SCK output, all others input
	ldi r17,(1<<DDB3)|(1<<DDB5)
	out DDRB,r17

	; Enable SPI, Master, set clock rate fck/16
	ldi r17,(1<<SPE)|(1<<MSTR)|(1<<SPR0)
	out SPCR,r17

adcinit:
	;enable ADC, free running, set division factor to 2, start conversion, interrupt flag, interrupt enable
	ldi r17,(1<<ADEN)|(1<<ADFR)|(1<<ADPS0)|(1<<ADSC)|(1<<ADIF)|(1<<ADIE)
	out ADCSRA,r17
	
	;result is left adjusted, using external refernece
	ldi r17,(1<<ADLAR)|(1<<REFS0)
	out ADMUX,r17
	sei
	
main:
	out PORTD, r19	//square wave high
	rcall delay
	out PORTD, r20	//square wave low
	rcall delay
	rcall SPI_MasterTransmit
	rjmp main

SPI_MasterTransmit:
cli
	; Start transmission of data (r16)
	out SPDR,r16
	Wait_Transmit:
	; Wait for transmission complete
	sbis SPSR,SPIF
	rjmp Wait_Transmit
sei
	ret

adcstart:
	;read output from ADC
	in r16,ADCH
	reti

delay:	;delay is based on data received from ADC conversion
cli
	inc r21
	cp r21, r16
	brne delay
	ldi r21, 0
sei
	ret
