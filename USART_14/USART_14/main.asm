	.include "m168def.inc"   ; Используем ATMega168
.def RECV_COUNT = R25
.def DATA = R24
.def PREV_DATA = R23
;= Start macro.inc ========================================
   	.macro    OUTI          	
      	LDI    R16,@1
   	.if @0 < 0x40
      	OUT    @0,R16       
   	.else
      	STS      @0,R16
   	.endif
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
			DEC @0
			BRNE FLASH2RAM_loop
		POP R0
	.endm
;= End 	macro.inc =======================================

; RAM ===================================================
		.DSEG
		Array: .byte 10
; END RAM ===============================================

; FLASH ======================================================
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
         RETI             ; Timer/Counter2 Overflow
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
         RETI             ;  Timer/Couner0 Overflow
         .ORG $022
         RETI             ; SPI Serial Transfer Complete
         .ORG $024
         RJMP Recv_handler             ; USART Rx Complete
         .ORG $026
         RJMP Transm_ready             ; USART, Data Register Empty
         .ORG $028
         RJMP Transm_done              ; USART Tx Complete
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
Transm_ready:
	LDI XL, low(UDR0)
	LDI XH, high(UDR0)
	ST X, DATA

	OUTI UCSR0B, (1 << TXEN0) | (1 << TXCIE0)

	RETI


Recv_handler:
	INC R1
	LDI XL, low(UDR0)
	LDI XH, high(UDR0)
	LD DATA, X

	INC RECV_COUNT

	CPI RECV_COUNT, 1
	BREQ Recv_first
;RECV SECOND
	LDI YL, low(Array)
	LDI YH, high(Array)

	ADD YL, PREV_DATA
	ADC YH, R0
	
	ST Y, DATA ; put new value in the array

	LDI RECV_COUNT, 0

	RJMP Send


Recv_first:
	CPI DATA, 9
	BRLO Find_and_send
	
	MOV PREV_DATA, DATA
	RJMP Recv_out

Find_and_send:
	LDI YL, low(Array)
	LDI YH, high(Array)

	ADD YL, DATA
	ADC YH, R0

	LD DATA, Y

	CLR RECV_COUNT

Send:
	LDI XL, low(UDR0)
	LDI XH, high(UDR0)
	ST X, DATA
	OUTI UCSR0B, (1 << TXEN0) | (1 << UDRIE0)
	
Recv_out:
	RETI

Transm_done:
	OUTI UCSR0B, (1 << RXEN0) | (1 << RXCIE0)
	
	RETI

; End Interrupts ==========================================

ArrayFLASH: .DB 12, 13, 4, 5, 32, 7, 90, 134, 2, 87

Reset:   	
		LDI R16,Low(RAMEND)		; Инициализация стека
	  	OUT SPL,R16			
 
	  	LDI R16,High(RAMEND)
	  	OUT SPH,R16
 
; Start coreinit.inc
RAM_Flush:	
	LDI	ZL,Low(SRAM_START)	
	LDI	ZH,High(SRAM_START)
	CLR	R16			; Очищаем R16
Flush:
	ST 	Z+,R16			; Сохраняем 0 в ячейку памяти
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
	LDI R22, 10
	LDI ZL, low(ArrayFLASH * 2)
	LDI ZH, high(ArrayFLASH * 2)
	LDI YL, low(Array)
	LDI YH, high(Array)

	FLASH2RAM R22

OUTI	UCSR0A, 0
OUTI	UCSR0C, (3 << UCSZ00); 8 bit packet
OUTI	UBRR0L, 103
OUTI	UCSR0B, (1 << RXEN0) | (1 << RXCIE0)

; End Internal Hardware Init ===================================
 
; External Hardware Init  ======================================
 
; End Internal Hardware Init ===================================
 
; Run ==========================================================
 
; End Run ======================================================




SEI

; Main =========================================================
Main:
	
		
	Loop:
	NOP
	NOP
	NOP
	RJMP	Loop
; End Main =====================================================

; Procedure ====================================================

; End Procedure ================================================
