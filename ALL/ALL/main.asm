.include "m168def.inc"   ; ATMega168
 
;= Start macro.inc ========================================
   	.macro    OUTI 
		PUSH R16         	
      	LDI    R16,@1
   	.if @0 < 0x40
      	OUT    @0,R16       
   	.else
      	STS      @0,R16
   	.endif
		POP R16
   	.endm
 
   	.macro    UOUT        
   	.if	@0 < 0x40
      	OUT	@0,@1         
	.else
      	STS	@0,@1
   	.endif
   	.endm

	.macro FLASH2RAM ;copy memory from flash to RAM
		PUSH R0
		FLASH2RAM_loop:
			LPM R0, Z+
			ST Y+, R0
			DEC @0 ; @0 - size in bytes
			BRNE FLASH2RAM_loop
		POP R0
	.endm
;= End 	macro.inc =======================================

; RAM ===================================================
		.DSEG
	
; END RAM ===============================================

; FLASH ======================================================
         .CSEG
         .ORG $000      ; (RESET) 
         RJMP   Init
         .ORG $002
         RETI             ; (INT0) External Interrupt Request 0
         .ORG $004
         RETI             ; (INT1) External Interrupt Request 1
         .ORG $006
         RETI	          ; Pin Change Interrupt Request 0
         .ORG $008
         RETI             ; Pin Change Interrupt Request 0
         .ORG $00A
         RETI			  ; Pin Change Interrupt Request 1
         .ORG $00C 
         RETI             ; Watchdog Time-out Interrupt
         .ORG $00E
         RETI             ; Timer/Counter2 Compare Match A
         .ORG $010
         RETI             ; Timer/Counter2 Compare Match A
         .ORG $012
         RETI       ; Timer/Counter2 Overflow
         .ORG $014
         RETI             ; Timer/Counter1 Capture Event
         .ORG $016
         RETI    	     ; Timer/Counter1 Compare Match A
         .ORG $018
         RETI             ; Timer/Counter1 Compare Match B
         .ORG $01A
         RETI             ; Timer/Counter1 Overflow
         .ORG $01C
         RJMP TC0_CM	     ;  TimerCounter0 Compare Match A
         .ORG $01E
         RETI             ; TimerCounter0 Compare Match B
         .ORG $020
         RJMP TC0_OV             ;  Timer/Counter0 Overflow
         .ORG $022
         RETI             ; SPI Serial Transfer Complete
         .ORG $024
         RJMP RX_Complete             ; USART Rx Complete
         .ORG $026
         RETI             ; USART, Data Register Empty
         .ORG $028
         RJMP TX_Complete             ; USART Tx Complete
		 .ORG $02A
		 RETI			  ; ADC Conversion Complete
		 .ORG $02C
		 RETI			  ; EEPROM Ready
		 .ORG $02E		 
		 RETI			  ; Analog Comparator
		 .ORG $030
		 RETI			  ; Two-wire Serial Interface
		 .ORG $032
		 RETI			  ; Store Program Memory Read
 
	 .ORG   INT_VECTORS_SIZE      	; Конец таблицы прерываний

; Interrupts ==============================================
; Interrupts handlers
	TC0_OV:
		OUTI OCR0A, 1 << 7
		;INC R25
	RETI
	TC0_CM:
		
		;INC R26
	RETI
	RX_Complete:
		LDS R10, UCSR0A

		LDS R16, UCSR0A
		SBRS R16, FE0 ;in if error was not occured
		LDS R16, UDR0
		LDI R26, 255
		EOR R16, R26
		MOV R15, R16
		CALL Send
	RETI

	TX_Complete:
		LDS R16, UCSR0A
		SBRC R16, UDRE0
		STS UDR0, R16
	RETI

; End Interrupts ==========================================


Reset:   	LDI R16,Low(RAMEND)		; Инициализация стека
	  	OUT SPL,R16			
 
	  	LDI R16,High(RAMEND)
	  	OUT SPH,R16
 
; Start coreinit.inc
RAM_Flush:	LDI	ZL,Low(SRAM_START)	
		LDI	ZH,High(SRAM_START)
		CLR	R16			
Flush:		ST 	Z+,R16			
		CPI	ZH,High(RAMEND)		
		BRNE	Flush			
 
		CPI	ZL,Low(RAMEND)		
		BRNE	Flush
 
		CLR	ZL			
		CLR	ZH
		CLR	R0
		CLR	R1
		CLR	R2
		CLR	R3
		CLR	R4
		CLR	R5
		CLR	R6
		CLR	R7
		CLR	R8
		CLR	R9
		CLR	R10
		CLR	R11
		CLR	R12
		CLR	R13
		CLR	R14
		CLR	R15
		CLR	R16
		CLR	R17
		CLR	R18
		CLR	R19
		CLR	R20
		CLR	R21
		CLR	R22
		CLR	R23
		CLR	R24
		CLR	R25
		CLR	R26
		CLR	R27
		CLR	R28
		CLR	R29
; End coreinit.inc

; Internal Hardware Init  ======================================
	;usart init
Init:
	OUTI UBRR0H, 0
	OUTI UBRR0L, 25

	OUTI UCSR0B, (1 << RXEN0) | (1 << TXEN0) | (1 << RXCIE0) | (1 << TXCIE0);enable receiver, transmitter and interrupts

	OUTI UCSR0C, (3 << UCSZ00); 8-bit frame

	;timer out
	OUTI DDRD, 1 << DDD6; | 1 << DDD5 | 1 << DDD7
	;OUTI PORTD, 1 << PORTD6

	;timer init
	OUTI TIMSK0, 1 << TOIE0 | 1 << OCIE0A
	
	OUTI OCR0A, 1 << 7

	OUTI TCCR0A, 1<<COM0A1 | 1<<WGM01 | 1<<WGM00
	
	OUTI TCCR0B, 1 << CS00
	
	SEI
; End Internal Hardware Init ===================================
 
; External Hardware Init  ======================================
 
; End Internal Hardware Init ===================================
 
; Run ==========================================================
 
; End Run ======================================================






; Main =========================================================
Main:
		CALL DIV8

		OUTI EEARL, 0
		OUTI EEARH, 0
		CALL Write2EEPROM
		CLR R15
		CALL ReadFromEEPROM
		JMP	Main
; End Main =====================================================

; Procedure ====================================================
DIV8:
	LDI R17, 48
	LDI R19, 4
	CLR R15
	DIV8loop:
		SUB R17, R19
		BRMI DIV8end
		INC R15
		RJMP DIV8loop
	DIV8end:
		RET

Send:
	LDS R16, UCSR0A
	SBRS R16, UDRE0
	RJMP Send

	STS UDR0, R15
	RET
Recv:
	LDS R16, UCSR0A
	SBRS R16, RXC0
	RJMP Recv

	LDS R15, UDR0
	RET


	;Address must be set before read/write call
Write2EEPROM:
	CLI
	SBIC EECR, EEPE
	RJMP Write2EEPROM

	OUT EEDR, R15

	SBI EECR, EEMPE
	SBI EECR, EEPE
	SBI EECR, EEPE
	SBI EECR, EEPE
	SBI EECR, EEPE
	SEI
	RET
ReadFromEEPROM:
	SBIC EECR, EEPE
	RJMP ReadFromEEPROM

	SBI EECR, EERE
	IN R15, EEDR
	RET
; End Procedure ================================================