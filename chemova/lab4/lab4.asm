MY_STACK SEGMENT STACK
	DW 64 DUP (?)
MY_STACK ENDS

ASTACK SEGMENT STACK
	DW 64 DUP (?)
ASTACK ENDS
;������
;--------------------------------------------------------------------------------------------
DATA SEGMENT
interrupt_already_loaded  db 'Interrupt already loaded!', 0DH, 0AH, '$'
interrupt_was_unloaded    db 'Interrupt was unloaded!', 0DH, 0AH, '$'
interrupt_was_loaded      db 'Interrupt was loaded!', 0DH, 0AH, '$'
DATA ENDS
;--------------------------------------------------------------------------------------------
CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK
;���������
;--------------------------------------------------------------------------------------------
PRINT PROC NEAR
;����� ������ 
	mov	AH,  0009h
	int	21h
	ret
PRINT ENDP
;--------------------------------------------------------------------------------------------
SET_CURS PROC
;��������� ������� �������; ��������� �� ������ 25 ������ ������ ���������
	push	AX
	push	BX
	push	CX
	mov	AH,  0002h
	mov	BH,  0000h
	int	0010h       ;���������� ������� 0002h
	pop	CX          ;����: BH = ����� ��������
	pop	BX          ;DH, DL = ������, ������� (������ �� 0)
	pop	AX
	ret
SET_CURS ENDP
;--------------------------------------------------------------------------------------------
GET_CURS PROC
;�������, ������������ ������� � ������ ������� 
	push	AX
	push	BX
	push	CX
	mov	AH,  0003h  ;0003h ������ ������� � ������ �������
	mov	BH,  0000h  ;����: BH = ����� ��������
	int	10h         ;���������� ������� 0003h
	pop	CX          ;�����: DH, DL = ������� ������, ������� �������
	pop	BX          ;CH, CL = ������� ���������, �������� ������ �������
	pop	AX
	ret
GET_CURS ENDP
;--------------------------------------------------------------------------------------------
ROUT PROC FAR
;���������� ����������
	jmp	ROUT_BEGINNING 
;������
;--------------------------------------------------------------------------------------------
	signature  db  '0000'                        ;��������� ���, ������� �������������� ���������
	keep_cs    dw  0                             ;��� �������� ��������
	keep_ip    dw  0                             ;� �������� ����������
	keep_psp   dw  0                             ;PSP
	check      dw  0                             ;���� ��������� ���������� ��� ���
	keep_ss    dw  0                             ;�������� �����
	keep_ax    dw  0	                     
	keep_sp    dw  0                             
	timer      db  'Interrupt call 1Ch: 0000 $'  ;�������
;--------------------------------------------------------------------------------------------
ROUT_BEGINNING:
	mov	keep_ax,  AX    
	mov	keep_ss,  SS    
	mov	keep_sp,  SP    
	mov	AX,  MY_STACK   ;������������� ����������� ����
	mov	SS,  AX
	mov	SP,  64h
	mov	AX,  keep_ax
	push	DX              ;��������� ���������� ��������
	push	DS
	push	ES
	cmp	check,  1
	je	ROUT_REC
	call	GET_CURS        ;�������� ������� ��������� ������� 
	push	DX              ;��������� ��������� ������� � �����
	mov	DH,  17h        ;DH, DL - ������, ������� (������ �� 0) 
	mov	DL,  1Ah        ;���������� �������������� �������
	call	SET_CURS        ;������������� ������
;********************************************************************************************    
ROUT_COUNT:
;������� ���������� ����������
	push	SI                 ;��������� ��� ���������� ��������
	push	CX 
	push	DS
	mov	AX,  seg timer
	mov	DS,  AX
	mov	SI,  offset timer 
	add	SI,  0017h         ;�������� �� ��������� �����
;********************************************************************************************    
count:
	mov	AH,  [SI]   ;�������� �����
	inc	AH          
	mov	[SI],  AH   ;����������
	cmp	AH,  3Ah    ;���� �� ����� 9
	jne	END_COUNT   ;���������� � ����� ����������
	mov	AH,  30h    ;��������
	mov	[SI],  AH
        dec	SI
        loop	count			
;********************************************************************************************		
END_COUNT:
;������ ��������-������ �� �����
	pop	DS
	pop	CX
	pop	SI
	push	ES 
	push	BP
	mov	AX,  seg timer
	mov	ES,  AX
	mov	AX,  offset timer
	mov	BP,  AX            ;����: ES:BP ��������� ������ 
	mov	AH,  00013h        ;����� ������ � ������� �������
	mov	AL,  0000h         ;����� ������
	mov	CX,  0019h         ;����� ������ = 25 ��������
	mov	BH,  0000h         ;����� ��������, � �����
	mov	BL,  0002h         ;��������� ��������
	int	10h                                      
	pop	BP
	pop	ES
	pop	DX                 ;����������� �������
	call	SET_CURS
	jmp	ROUT_END
;********************************************************************************************
ROUT_REC:
;�������������� ������� ����������
	CLI                    ;���������� ����������, ���� ����������� ����� IF
	mov	DX,  keep_ip
	mov	AX,  keep_cs
	mov	DS,  AX        ;������ ����������: ����� ��������� ��������� ����������
	mov	AH,  25h       ;������������� ������ ����������
	mov	AL,  1Ch       ;����� ������� ����������
	int	21h                                       
	mov	ES,  keep_psp                              
	mov	ES,  ES:[2Ch]  ;���������� ����� (��������) �������������� ����� ������ 
	mov	AH,  49h       ;����������� ������������� ���� ������   
	int	21h                                       
	mov	ES,  keep_psp                              
	mov	AH,  49h                                   
	int	21h	                                      
	STI                    ;���������� ����������
;********************************************************************************************		
ROUT_END:
	pop	ES            ;�������������� ���������
	pop	DS
	pop	DX
	mov	SS,  keep_ss
	mov	SP,  keep_sp
	mov	AX,  keep_ax
	iret
		
LAST_BYTE:
        ROUT ENDP
;--------------------------------------------------------------------------------------------
CHECK_INT PROC
;��������, ����������� �� ���������������� ���������� � �������� 1Ch
	mov	AH,  35h               ;��� ������ ����������
	mov	AL,  1Ch               ;����� ����������
	int	21h                    ;�����: ES:BX = ����� ����������� ����������	
	mov	SI,  offset signature                          
	sub	SI,  offset ROUT       ;�������� signature ������������ ������ ������� ����������
	mov	AX,  '00'              ;���������� ���������� �������� ���������
	cmp	AX,  ES:[BX+SI]        ;� �������� �����, ����������� � ���������
	jne	NOT_LOADED             ;���� �������� ������, �� �������� �� ����������
	cmp	AX,  ES:[BX+SI+2]
	jne	NOT_LOADED
	jmp	LOADED                                        
;********************************************************************************************		
NOT_LOADED:                                       
	call	MY_INT                 ;��������� ����������������� ����������
	mov 	DX,  offset LAST_BYTE  ;������ � ������ �� ������
	mov	CL,  4                 ;������� � ���������
	shr	DX,  CL                ;����� �� 4 ������� ������
	inc	DX	                                     
	add	DX,  CODE              ;���������� ����� �������� CODE
	sub	DX,  keep_psp                           
	xor	AL,  AL
	mov	AH,  31h               ;��������� ������ ���������� ������
	int	21h                                      	      
;********************************************************************************************	
LOADED:
;�������, ���� �� � ������ /un , ����� ����� ���������
	push	ES
	push	AX
	mov	AX, keep_psp 
	mov	ES, AX
	cmp	byte ptr ES:[0082h],  '/' 
	jne	NOT_UNLOAD 
	cmp	byte ptr ES:[0083h],  'u' 
	jne	NOT_UNLOAD 
	cmp	byte ptr ES:[0084h],  'n' 
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
	mov	byte ptr ES:[BX+SI+10], 1          ;check = 1
	mov	DX, offset interrupt_was_unloaded 
	call	PRINT
	ret
CHECK_INT ENDP
;--------------------------------------------------------------------------------------------
MY_INT PROC
;��������� ����������� ���������� � ���� �������� ����������
	push	DX
	push	DS
	mov	AH,  35h                          ;������� ��������� �������
	mov	AL,  1Ch                          ;����� �������
	int	21h
	mov	keep_ip,  BX                      ;����������� ��������
	mov	keep_cs,  ES 
	mov	DX,  offset ROUT                  ;�������� ��� ��������� � DX
	mov	AX,  seg ROUT 
	mov	DS,  AX 
	mov	AH,  25h                          ;������� ��������� �������
	mov	AL,  1Ch                          ;����� �������
	int	21h                                          
	pop	DS
	mov	DX,  offset interrupt_was_loaded 
	call	PRINT
	pop	DX
	ret
MY_INT ENDP 
;--------------------------------------------------------------------------------------------
MAIN  PROC  near
	mov	AX,  DATA
	mov	DS,  AX
	mov	keep_psp,  ES 
	call	CHECK_INT 
	xor	AL,  AL
	mov	AH,  4Ch 
	int	21H
MAIN  ENDP
CODE ENDS
	END  MAIN