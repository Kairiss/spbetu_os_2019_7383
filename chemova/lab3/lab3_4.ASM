TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN
;--------------------------------------------------------------------------------------------
;DATA
_avl_mem	db  'Available memory, B:       ', 0Dh, 0Ah, '$'
_ext_mem	db  'Extended memory, KB:       ', 0Dh, 0Ah, '$'
_table_MCB 	db  'Address   Type MCB     PSP         Size, B      SD/SC', 0Dh, 0Ah, '$'
result		db  '                                                                   ', 0Dh, 0Ah, '$'
_error		db  'Memory allocation error!!!', 0Dh, 0Ah, '$'	
;--------------------------------------------------------------------------------------------
;ПРОЦЕДУРЫ
;--------------------------------------------------------------------------------------------
TETR_TO_HEX  PROC near                                            
	and	AL, 0Fh                                              
	cmp	AL, 09
	jbe  	NEXT
	add	AL, 07
NEXT:   add	AL, 30h
	ret
TETR_TO_HEX  ENDP
;--------------------------------------------------------------------------------------------
BYTE_TO_HEX  PROC near
;байт в AL переводиться в два символа шестнадцатеричного числа в AX
	push  	CX
	mov   	AH,  AL
	call  	TETR_TO_HEX
	xchg  	AL,  AH
	mov   	CL,  4
	shr   	AL,  CL
	call  	TETR_TO_HEX
	pop   	CX
	ret
BYTE_TO_HEX  ENDP
;-------------------------------------------------------------------------------------------- 
WRD_TO_HEX  PROC near                                             
;перевод в 16 СС 16-ти разрядного числа
;в АХ - число, DI - адрес последнего символа
	push  	BX
	mov   	BH,AH
	call  	BYTE_TO_HEX
	mov   	[DI],  AH
	dec   	DI
	mov   	[DI],  AL
	dec   	DI
	mov   	AL,  BH
	call  	BYTE_TO_HEX
	mov   	[DI],  AH
	dec   	DI
	mov   	[DI],  AL
	pop   	BX
	ret
WRD_TO_HEX  ENDP
;--------------------------------------------------------------------------------------------
BYTE_TO_DEC  PROC near
;перевод в 10 СС, SI - адрес поля младшей цифры
	push 	CX
	push 	DX
	xor  	AH,  AH
	xor  	DX,  DX
	mov  	CX,  10
loop_bd:
	div	CX
	or    	DL,  30h
	mov  	[SI],  DL
	dec  	SI
	xor  	DX,  DX
	cmp  	AX,  10
	jae  	loop_bd
	cmp  	AL,  00h
	je   	end_l
	or   	AL,  30h
	mov  	[SI],  AL
end_l: 
	pop	DX
	pop  	CX
	ret
BYTE_TO_DEC ENDP
;--------------------------------------------------------------------------------------------
WRD_TO_DEC PROC near
	push	CX
	push	DX
	mov	CX,  10
loop_b:
	div	CX
	or	DL,  30h
	mov	[SI],  DL
	dec	SI
	xor	DX,  DX
	cmp	AX,  10
	jae	loop_b
	cmp	AL,  00h
	je	endl
	or	AL,  30h
	mov	[SI],  AL
endl:
	pop	DX
	pop	CX
	ret
WRD_TO_DEC ENDP
;--------------------------------------------------------------------------------------------
PRINT  PROC near 
;вывод строки на экран
        push 	AX
        mov  	AH, 09h
	int  	21h
	pop  	AX
	ret
PRINT  ENDP
;--------------------------------------------------------------------------------------------
GET_MCB PROC near
	mov	DI,  offset result
	mov	AX,  ES
	add	DI, 4h
	call	WRD_TO_HEX
	mov	DI,  offset result
;смещение 0h
	add	DI,  0Ch
	xor	AH,  AH
	mov	AL,  ES:[0]
	call	WRD_TO_HEX
	mov	AL,  20h
	mov	[DI],  AL
	inc	DI
	mov	[DI],  AL
	mov	DI,  offset result
;смещение 1h
	mov	AX,  ES:[1]
	add	DI,  19h
	call	WRD_TO_HEX
	mov	DI,  offset result
;смещение 3h
	mov	AX,  ES:[3]
	mov	BX,  10h
	mul	BX
	add	DI,  29h
	push	SI
	mov	SI,  DI
	call	WRD_TO_DEC
	pop	SI
	mov	DI,  offset result
	add	DI,  31h
 	mov	BX,  0h
PRINTS:
	mov	DL,  ES:[8+BX]
	mov	[DI],  DL
	inc	DI
	inc	BX
	cmp	BX,  8h
	jne	PRINTS
	mov	AX,  ES:[3]
	mov	BL,  ES:[0]
	ret
GET_MCB ENDP
;-----------------------------------------------------------------------
BEGIN:
;Доступная память
	mov	AH,  4Ah
	mov	BX,  0FFFFh
	int	21h
	mov	AX,  10h
	mul	BX
	mov	SI,  offset _avl_mem
	add	SI,  26
	call	WRD_TO_DEC
	mov	DX,  offset _avl_mem
	call	PRINT
	mov	AH,  48h
	mov	BX,  1000h
	int	21h
	jnc	NOT_ERROR
ERROR:
	mov	DX,  offset _error
	call	PRINT
NOT_ERROR:	
	mov	AH,  4Ah
	mov	BX,  offset sizepr
	int	21h

;Расширенная память
	xor	DX,  DX
	mov	AX,  30h
	out	70h,  AL
	in	AL,  71h
	mov	BL,  AL
	mov	AL,  31h
	out	70h,  AL
	in	AL,  71h
	mov	AH,  AL
	mov	AL,  BL
	mov	SI,  offset _ext_mem
	add	SI,  25
	mov 	AL,  30h
	out	70h,  AL
	in	AL,  71h
	mov	BL,  AL
	mov	AL,  31h
	out	70h, AL
	in	AL,  71h
	call	WRD_TO_DEC
	mov	DX,  offset _ext_mem
	call	PRINT
;MCB
	mov	DX,  offset _table_MCB
	call	PRINT
	mov	AH,  52h
	int	21h
	sub	BX,  2h
	mov	ES,  ES:[BX]
MCB_OUT:
	xor	AX,  AX
	xor	BX,  BX
	xor	CX,  CX
	xor	DX,  DX
	xor	DI,  DI

	call	GET_MCB
	mov	DX,  offset result
	call	PRINT
	mov	CX,  ES
	add	AX,  CX
	inc	AX
	mov	ES,  AX
	cmp	BL,  4Dh
	je	MCB_OUT

	mov	AH,  4Ch
	int	21h
	sizepr	db  0
TESTPC ENDS
	END START