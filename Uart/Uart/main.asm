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
         RETI             ; USART Rx Complete
         .ORG $026
         RETI             ; USART, Data Register Empty
         .ORG $028
         RETI              ; USART Tx Complete
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

	.equ 	XTAL = 8000000 	
	.equ 	baudrate = 9600  
	.equ 	bauddivider = XTAL/(16*baudrate)-1
 
 
uart_init:	
	OUTI 	UBRR0L, low(bauddivider)
 

	OUTI 	UCSR0A, 0

	OUTI 	UCSR0B,  (1<<RXEN0)|(1<<TXEN0)|(0<<RXCIE0)|(0<<TXCIE0)|(0<<UDRIE0)
	OUTI 	UCSR0C, (1<<UMSEL0)|(1<<UCSZ00)|(1<<UCSZ01)
; End Internal Hardware Init ===================================
 
; External Hardware Init  ======================================
 
; End Internal Hardware Init ===================================
 
; Run ==========================================================
 
; End Run ======================================================





; Main =========================================================
Main:
	LDI R22, 10
	LDI ZL, low(ArrayFLASH * 2)
	LDI ZH, high(ArrayFLASH * 2)
	LDI YL, low(Array)
	LDI YH, high(Array)

	FLASH2RAM R22
		
	Loop:
	RJMP uart_snt
	RJMP	Loop
; End Main =====================================================

; Procedure ====================================================

uart_snt:
		LDI XL, low(UCSR0A)
		LDI XH, HIGH(UCSR0A)
		LD 	R16, X
		SBRS R16, UDRE0
		RJMP	uart_snt 	; ждем готовности - флага UDRE
		

		OUTI	UDR0, (1 << 2)	; шлем байт
		RET	
; End Procedure ================================================
