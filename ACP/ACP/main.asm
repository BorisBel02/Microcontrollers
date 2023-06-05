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

; Interrupts ==============================================
         .CSEG
         .ORG $000      ; (RESET) 
         RJMP   Reset
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
         RETI	     ;  TimerCounter0 Compare Match A
         .ORG $01E
         RETI             ; TimerCounter0 Compare Match B
         .ORG $020
         RETI             ;  Timer/Counter0 Overflow
         .ORG $022
         RETI             ; SPI Serial Transfer Complete
         .ORG $024
        RETI             ; USART Rx Complete
         .ORG $026
         RETI             ; USART, Data Register Empty
         .ORG $028
         RETI             ; USART Tx Complete
		 .ORG $02A
		 RJMP ADC_conversion_handler			  ; ADC Conversion Complete
		 .ORG $02C
		 RETI			  ; EEPROM Ready
		 .ORG $02E		 
		 RETI			  ; Analog Comparator
		 .ORG $030
		 RETI			  ; Two-wire Serial Interface
		 .ORG $032
		 RETI			  ; Store Program Memory Read
 
	 .ORG   INT_VECTORS_SIZE      	; Конец таблицы прерываний


; Interrupts handlers
	ADC_conversion_handler:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	LDI		R26, low(ADCL)
	LDI		R27, high(ADCL)
	LD		R18, X
	LDI		R26, low(ADCH)
	LDI		R27, high(ADCH)
	LD		r19, X

	OUTI	ADCSRA, (1 << ADEN) | (1 << ADIE) | (1 << ADSC) ; restart conversion

	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI

; End Interrupts ==========================================


Reset:
		LDI R16,Low(RAMEND)		; Инициализация стека
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
	
	OUTI	ADMUX, (3 << REFS0)	
	OUTI	ADCSRB, (1 << ACME)
	OUTI	ADCSRA, (1 << ADEN) | (1 << ADIE) | (1 << ADSC) ; enable ADC and conversion, enable interrupt
	
	SEI
; End Internal Hardware Init ===================================
 
; External Hardware Init  ======================================
 
; End Internal Hardware Init ===================================
 
; Run ==========================================================
 
; End Run ======================================================


; Main =========================================================

Main:
		NOP
		JMP	Main
; End Main =====================================================

; Procedure ====================================================
Init_conversion:
	LDI		R26, low(ADCSRA)
	LDI		R27, high(ADCSRA)
	LD		r20, X
	ORI		r20, (1 << ADSC)
	ST		X, r20
	RET
; End Procedure ================================================