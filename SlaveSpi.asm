.include "m8515def.inc"

init:
	ldi r17, high(RAMEND)
	out sph, r17
	ldi r17, low(RAMEND)
	out spl, r17
	ldi r18, 48
	ldi r19, 86
	ldi r20, 46
	ldi r21, 0
	ldi r22, 0		
	ldi r24, 51			;1v is equal to 51 in the adc register
	ldi r25, 47			;converts to to ascii
	ldi r27, 0
	ldi r28, 5
	ldi r29, 0x0D		;carriage return

SPI_SlaveInit:
	; Set MISO output, all others input
	ldi r17,(1<<DDB6)
	out DDRB,r17

	; Enable SPI
	ldi r17,(1<<SPE) 
	out SPCR,r17

USART_Init:
	; Set baud rate 9.6kHz
	ldi r16, 0x00
	ldi r17, 0x19
	out UBRRH, r16
	out UBRRL, r17
	; Enable receiver and transmitter 
	ldi r16, (1<<RXEN)|(1<<TXEN) 
	out UCSRB,r16
	; Set frame format: 8data, 1stop bit, no parity
	ldi r16, (1<<URSEL)|(0<<UPM0)|(0<<USBS)|(3<<UCSZ0)
	out UCSRC,r16
	
main:
	rcall SPI_SlaveReceive
	rcall disp
	rcall usart_transmit
	rjmp main

SPI_SlaveReceive:
	; Wait for reception complete
	sbis SPSR,SPIF
	rjmp SPI_SlaveReceive
	; Read received data and return
	in r26,SPDR
	ret

usart_transmit:
j:	;transmits carriage return
	sbis UCSRA,UDRE
	rjmp j
	out UDR, r29

k:	;transmits the voltage value
	sbis UCSRA,UDRE
	rjmp k
	out UDR,r21
	ldi r21, 0

l:	;transmits a decimal
	sbis UCSRA,UDRE
	rjmp l
	out UDR, r20

m:	;transmits the 100mv
	sbis UCSRA,UDRE
	rjmp m
	cpi r27, 58
	brne cont
	ldi r27, 57
cont:
	out UDR,r27
	ldi r27, 0
	ldi r22, 0

n:	;transmits the letter v
	sbis UCSRA,UDRE
	rjmp n
	out UDR, r19
	ret

disp:
loop:
	inc r21
	add r22, r24	;add 51
	cp r22, r26		;compare 1v with the received value
	brlo loop		;if not equal, check if equal with 2v, etc
	sub r22, r24	
	sub r26, r22	;subtract the voltage from the value in the register
	add r21, r25	;add 47
	ldi r22, 0
loop1:
	inc r27
	add r22, r28	;add 5
	cp r22, r26		;compare 100mv with remainder of value
	brlo loop1		;if not equal check if equal to 200mv, etc
	add r27, r25	;add 47
	ret

