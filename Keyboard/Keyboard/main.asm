.include "m168def.inc"   ; ATMega168
 
 .DEF ROW_CNT = R24
 .DEF COL_CNT = R23
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
		SYMBOLS_ASCII: .BYTE 12
		SYM: .BYTE 1
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
		 RETI			  ; ADC Conversion Complete
		 .ORG $02C
		 RETI			  ; EEPROM Ready
		 .ORG $02E		 
		 RETI			  ; Analog Comparator
		 .ORG $030
		 RETI			  ; Two-wire Serial Interface
		 .ORG $032
		 RETI			  ; Store Program Memory Read
 
	 .ORG   INT_VECTORS_SIZE      	


; Interrupts handlers


; End Interrupts ==========================================

SYMBOLS_ASCII_FLASH: .DB 49, 50, 51, 52, 53, 54, 55, 56, 57, 42, 48, 35

Reset:
		LDI R16,Low(RAMEND)		; ????????????? ?????
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
	;COPY THE ARRAY INTO RAM
	LDI R22, 12
	LDI ZL, low(SYMBOLS_ASCII_FLASH * 2)
	LDI ZH, high(SYMBOLS_ASCII_FLASH * 2)
	LDI YL, low(SYMBOLS_ASCII)
	LDI YH, high(SYMBOLS_ASCII)
	FLASH2RAM R22


	OUTI DDRD, (15 << DDD0);OUTPUT
	
	;OUTI DDRC, (7  << DDC0);INPUT

	OUTI MCUCR, (1 << PUD);DISABLE PUD

	
	
	SEI
; End Internal Hardware Init ===================================
 

; Main =========================================================

Main:
		CALL Poll
		JMP	Main
; End Main =====================================================

; Procedure ====================================================
Poll:
	LDI R17, 1
	
	CLR ROW_CNT
	
	Row_cycle:
		LDI R19, 1
		CLR COL_CNT
		OUT PORTD, R17
		
		Col_cycle:
			IN R18, PINC
			 
			CP R18, R19 
			BREQ Match;SAVE VALUE OR DO SMTH
			
			LSL R19
			INC COL_CNT
			CPI COL_CNT, 3
			BRNE Col_cycle
		;END COL_CYCLE


		LSL R17
		INC ROW_CNT
		CPI ROW_CNT, 4
		BRNE Row_cycle
	;END ROW_CYCLE


Poll_stop:
	RET



Match:
	LDI XL, LOW(SYMBOLS_ASCII)
	LDI XH, HIGH(SYMBOLS_ASCII)

	LDI R22, 3
	
	MUL R22, ROW_CNT;CALCULATE POSITION IN SYMBOLS ARRAY
	MOVW R20, R0 
	ADD R20, COL_CNT;R20 = POSITION OF AN ELEMENT IN THE ARRAY
	 
	ADD XL, R20
	ADC XH, R3
	LD R10, X ;SAVE ASCII SYMBOL INTO R10
	
	RJMP Poll_stop
; End Procedure ================================================