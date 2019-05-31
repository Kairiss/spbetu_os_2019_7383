.286
ASTACK SEGMENT STACK
	DW 64 DUP (?)
ASTACK ENDS
;������
;--------------------------------------------------------------------------------------------
DATA SEGMENT
interrupt_already_loaded db 'Interrupt already loaded!', 0DH, 0AH, '$'
interrupt_was_unloaded   db 'Interrupt was unloaded!', 0DH, 0AH, '$'
interrupt_was_loaded     db 'Interrupt was loaded!', 0DH, 0AH,'$'
DATA ENDS
;--------------------------------------------------------------------------------------------
CODE SEGMENT
        ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK
;���������
;--------------------------------------------------------------------------------------------
PRINT PROC NEAR
;����� ������ 
	mov AH, 0009h
	int 21h
	ret
PRINT ENDP

ROUT PROC FAR
;���������� ����������
	jmp ROUT_BEGINNING 
;������
;--------------------------------------------------------------------------------------------
	signature	db  '0000'     ;������������� ���������
	keep_ip		dw  0          ;��� �������� �������� ����������
	keep_cs		dw  0          ;��� �������� �������� ����
	keep_psp	dw  0          ;��� �������� PSP
	keep_ss		dw  0          ;��� �������� �������� �����
	keep_ax		dw  0	       ;��� �������� �������� AX
	keep_sp		dw  0          ;��� �������� �������� SP
	REQ_KEY		db  38h        ;����-��� Alt Left
	MY_STACK	dw  64 DUP(?)
	END_STACK	dw  0
;--------------------------------------------------------------------------------------------
ROUT_BEGINNING:
	mov	keep_ax,  AX           ;���������� ax
	mov	keep_ss,  SS
	mov	keep_sp,  SP
	mov	AX,  CS                ;��������� ������ �����
	mov	SS,  AX
        mov	SP,  offset END_STACK		
	mov	AX,  keep_ax
	pusha                          ;��������� � ���� �������� ���� 16-������ ��������� ������ ����������
	in	AL,  60h               ;������ ����-��� ������� (� ���������� �����), ���� �������� �� ����� �����-������
	cmp	AL,  REQ_KEY           ;��� ��������� ���?
	je	PROCESSING             ;��, �������������� ��������� REQ_KEY | ���, ���� �� �������� ����������
	call	dword ptr CS: keep_ip  ;������� �� �������������� ����������
	jmp	EXIT
;********************************************************************************************			
PROCESSING:
;��������� ��� ��������� ��� ��������� ����������� ����������     	
	push	AX
	in	AL,  61h  ;����� �������� ����� ���������� ����������
	mov	AH,  AL   ;��������� ���
	or	AL,  80h  ;���������� ��� ���������� ��� ����������
	out	61h,  AL  ;� ������� ��� � ����������� ����
	xchg	AH,  AL   ;������� �������� �������� �����, ��������� �������� ���������� ���� ��������� 
	out	61h,  AL  ;� �������� ��� �������
	mov	AL,  20h  ;������� ������ "����� ����������"
	out	20h,  AL  ;����������� ���������� 8259
	pop	AX
;********************************************************************************************			
SKIP:
;�������� ������ � ����� ����������
	mov	CL,  33        ;����-��� 
	mov	AH,  05h       ;��� �������
	and	CH,  00h
	int	16h
	or	AL,  AL        ;�������� �� ������������ ������
	jz	EXIT           ;���� ������������, �� ������� ����� ����������
	CLI
	mov	AX,  ES:[1Ah]  ;������ ������ ������ ������
	mov	ES:[1Ch],  AX  ;���������� ����� ������ � �����  
	STI                    ;���������� ����������, ���� ��������� ����� IF
	jmp  SKIP
;********************************************************************************************	
EXIT:
;�������������� ���������
	popa                                  
	mov	SS,  keep_ss
	mov	SP,  keep_sp
	mov	AX,  keep_ax
        mov	AL,  20h
        out	20h, AL
        mov	AX,  keep_ax
        iret		
;********************************************************************************************	
LAST_BYTE:
	ROUT ENDP    
;--------------------------------------------------------------------------------------------
CHECK_INT PROC
;��������, ����������� �� ���������������� ���������� � �������� 09h
	mov	AH,  35h               ;��� ������ ����������
	mov	AL,  09h                                       
	int	21h                    ;�����: ES:BX = ����� ����������� ����������	
	mov	SI,  offset signature  
	sub	SI,  offset ROUT       ;�������� signature ������������ ������ ������� ����������
	mov	AX,  '00'                                      
	cmp	AX,  ES:[BX+SI]                                
	jne	NOT_LOADED                                    
	cmp	AX,  ES:[BX+SI+0002h]
	jne	NOT_LOADED
	jmp	LOADED                                        
;********************************************************************************************	
NOT_LOADED:                                       
	call	MY_INT                 ;��������� ����������������� ����������
	mov	DX,  offset LAST_BYTE  ;������ � ������ �� ������
	mov	CL,  4                 ;������� � ���������
	shr	DX,  CL                ;����� �� 4 ������� ������
	inc	DX	                                     
	add	DX,  CODE                                 
	sub	DX,  keep_psp                           
	xor	AL,  AL
	mov	AH,  31h               ;��������� ������ ���������� ������
	int	21h                                      	      
;********************************************************************************************		
LOADED:
;�������, ���� �� � ������ /un , ����� ����� ���������
	push	ES
	push	AX
	mov	AX,  CS: keep_psp 
	mov	ES,  AX
	cmp	byte ptr ES:[0082h], '/' 
	jne	NOT_UNLOAD 
	cmp	byte ptr ES:[0083h], 'u' 
	jne	NOT_UNLOAD 
	cmp	byte ptr ES:[0084h], 'n' 
	je	UNLOAD 
;********************************************************************************************		
NOT_UNLOAD:
	pop	AX
	pop	ES
	mov	DX,  offset interrupt_already_loaded
	call	PRINT
	ret
;********************************************************************************************		
UNLOAD: 
	pop	AX
	pop	ES
	call	DELETE
	mov	dx,  offset interrupt_was_unloaded 
	call	PRINT
	ret
CHECK_INT ENDP
;--------------------------------------------------------------------------------------------
DELETE PROC
;�������������� ������� ����������                                          
	push	AX
	push	DS
	push	ES
	CLI                            ;���������� ����������, ���� ����������� ����� IF
	mov	DX,  ES:[BX+SI+0004h] 
	mov	AX,  ES:[BX+SI+0006h]
	mov	DS,  AX                ;DS:DX = ������ ����������: ����� ��������� ��������� ����������
	mov	AH,  25h               ;������� 25h ���������� 21h, ������������� ������ ����������
	mov	AL,  09h                                        
	int	21h                                           
	mov	AX,  ES:[BX+SI+0008h]
	mov	ES,  AX
	mov	ES,  ES:[2Ch]          ;ES = ���������� ����� �������������� ����� ������ 
	mov	AH,  49h               ;������� 49h ���������� 21h, ���������� ������������� ���� ������    
	int	21h 
	pop	ES
	mov	ES,  ES:[BX+SI+0008h]
	mov	AH,  49h
	int	21h
	STI                            ;���������� ����������
	pop	DS
	pop	AX
	ret
DELETE ENDP  	
;--------------------------------------------------------------------------------------------
MY_INT PROC
;��������� ����������� ���������� � ���� �������� ����������
	push	DS
	mov 	AH,  35h                         ;������� ��������� �������
	mov	AL,  09h                         ;����� �������
	int	21h
	mov	keep_ip,  BX                     ;����������� ��������
	mov	keep_cs,  ES 
	mov	DX,  offset ROUT                 ;�������� ��� ��������� � DX
	mov	AX,  seg ROUT 
	mov	DS,  AX 
	mov	AH,  25h                         ;������� ��������� �������
	mov	AL,  09h                         ;����� �������
	int	21h                                          
	pop	DS
	push	DX
	mov	DX, offset interrupt_was_loaded 
	call	PRINT
	pop	DX
	ret
MY_INT ENDP 
;--------------------------------------------------------------------------------------------
MAIN:
	mov	AX, DATA
	mov	DS, AX
	mov	keep_psp, ES 
	call	CHECK_INT 
	xor	AL, AL
	mov	AH, 4Ch 
	int	21H
CODE ENDS
	END  MAIN