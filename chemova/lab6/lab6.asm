ASTACK SEGMENT STACK
	DW 64 DUP (?)
ASTACK ENDS
;������
;--------------------------------------------------------------------------------------------													  
DATA SEGMENT
ParameterBlock     dw  0000h  ;���������� ����� �����
                   dd  0000h  ;������� � �������� ��������� ������
                   dd  0000h  ;������� � �������� ������� FCB (File Control Block)
                   dd  0000h  ;������� � �������� ������� FCB
	Mem_8      db  0DH, 0AH, 'Not enough memory to perform the function!', 0DH, 0AH, '$'
        PATH 	   db  '                                               ', 0DH, 0AH, '$', 0	
	End_2      db  0DH, 0AH, 'The completion of the device error!', 0DH, 0AH, '$'
	Mem_9      db  0DH, 0AH, 'Wrong address of the memory block!', 0DH, 0AH, '$'
	Err_1      db  0DH, 0AH, 'The number of function is wrong!', 0DH, 0AH, '$'
	Mem_7      db  0DH, 0AH, 'Memory control unit destroyed!', 0DH, 0AH, '$'
	Err_10     db  0DH, 0AH, 'Incorrect environment string!', 0DH, 0AH, '$'
	End_3      db  0DH, 0AH, 'Completion by function 31h!', 0DH, 0AH, '$'
	Err_8      db  0DH, 0AH, 'Insufficient memory!', 0DH, 0AH, '$'
	End_0      db  0DH, 0AH, 'Normal completion!', 0DH, 0AH, '$'
	End_1      db  0DH, 0AH, 'End by Ctrl-Break!', 0DH, 0AH, '$'
	Err_11     db  0DH, 0AH, 'Wrong format!', 0DH, 0AH, '$'
	Err_5      db  0DH, 0AH, 'Disk error!', 0DH, 0AH, '$'
	Err_2      db  0DH, 0AH, 'File not found!', 0DH, 0AH, '$'
	END_CODE   db  'Exit code:   ', 0DH, 0AH, '$' 	
	KEEP_SS    dw  0000h
	KEEP_SP    dw  0000h
DATA ENDS
;--------------------------------------------------------------------------------------------
CODE SEGMENT
        ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK
;���������
;--------------------------------------------------------------------------------------------
PRINT PROC NEAR
;����� ������ 
	mov  AH, 0009h
	int  21h
	ret
PRINT ENDP
;--------------------------------------------------------------------------------------------
TETR_TO_HEX PROC near
;�� �������� � ����������������� ��
	and	AL,  0Fh
	cmp	AL,  09
	jbe	NEXT
	add	AL,  07
NEXT:
	add	AL,  30h
	ret
TETR_TO_HEX ENDP
;--------------------------------------------------------------------------------------------
BYTE_TO_HEX PROC near
;�������� ����� � ����������������� ��
	push	CX
	mov	AH,  AL
	call	TETR_TO_HEX
	xchg	AL,  AH
	mov	CL,  4
	shr	AL,  CL
	call	TETR_TO_HEX
	pop	CX
	ret
BYTE_TO_HEX ENDP
;--------------------------------------------------------------------------------------------
FREE_MEMORY PROC NEAR
;������������ ����� � ������, ����� ������� ������� ���� ���������� ����� ������, ����������� lr6 
	mov	BX,  offset LAST_BYTE  ;����� � BX ����� ����� ���������
	mov	AX,  ES                ;ES - ������ ���������
	sub	BX,  AX                ;BX = BX - ES, ����� ����������, ������� ����� ���������� ��������
	mov	CL,  0004h
	shr	BX,  CL                ;��������� � ���������
	mov	AH,  4Ah               ;������� ������ ����� ������
	int	21h
	jnc	WITHOUT_ERROR          ;���� CF = 0, ���� ��� ������
	jmp	WITH_ERROR             ;o�������� ������ CF=1 AX = ��� ������, ���� CF ���������� 
;********************************************************************************************    
WITHOUT_ERROR:
	ret
;********************************************************************************************		 
WITH_ERROR:
;********************************************************************************************
MEM_7_ERROR:	
;�������� ����������� ���� ������
	cmp	AX,  0007h                           
        jne	MEM_8_ERROR
	mov	DX,  offset Mem_7
	jmp	END_ERROR
;********************************************************************************************
MEM_8_ERROR:
;������������ ������ ��� ���������� �������
	cmp	AX,  0008h
	jne	MEM_9_ERROR
	mov	DX,  offset Mem_8
	jmp	END_ERROR
;********************************************************************************************
MEM_9_ERROR:
;�������� ����� ����� ������
        mov	DX,  offset Mem_9
;********************************************************************************************
END_ERROR:
	call	PRINT 
	xor	AL,  AL
	mov	AH,  4Ch
	int	21h
FREE_MEMORY ENDP
;--------------------------------------------------------------------------------------------
PROCESSING PROC NEAR
	mov	ES,  ES:[2Ch]  ;���������� ����� �����, ������������ ���������
	mov	SI,  0000h
;********************************************************************************************
cycle:
	mov	DL, ES:[SI]
	cmp	DL, 0000h   ;����� ������? 
	je	end_cycle	
	inc	SI
	jmp	cycle
;********************************************************************************************
end_cycle:
	inc	SI
	mov	DL,  ES:[SI]
	cmp	DL,  0000h   ;����� �����?	               	
	jne	cycle
	add	SI,  0003h   ;SI ��������� �� ������ ��������	
	push	DI
	lea	DI,  PATH
;********************************************************************************************
loop_:
        mov	DL,  ES:[SI]
	cmp	DL,  0000h    ;����� ��������?               		                          
	je	end_loop	
	mov	[DI],  DL	
	inc	DI			
	inc	SI			
	jmp	loop_
;********************************************************************************************
end_loop:
	sub	DI,  0008h		 
	mov	[DI],  byte ptr 'L'	
	mov	[DI+0001h],  byte ptr 'A'
	mov	[DI+0002h],  byte ptr 'B'
	mov	[DI+0003h],  byte ptr '2'
	mov	[DI+0004h],  byte ptr '.'
	mov	[DI+0005h],  byte ptr 'C'
	mov	[DI+0006h],  byte ptr 'O'
	mov	[DI+0007h],  byte ptr 'M'
	mov	[DI+0008h],  byte ptr 0h
	pop	DI

	mov	KEEP_SP,  SP	             ;��������� ���������� ��������� SS � SP
	mov	KEEP_SS,  SS
	push	DS
	pop	ES
	mov	BX,  offset ParameterBlock
	mov	DX,  offset PATH
	mov	AX,  4B00h                   ;�������� ��������� OS
	int	21h
	jnc	is_loaded                    ;���� ���������� ��������� �� ���� ���������, 
	                                     ;�� ��������������� ���� �������� CF=1 � � AX ��������� ��� ������
	push	AX
	mov	AX,  DATA
	mov	DS,  AX
	pop	AX
	mov	SS,  KEEP_SS                 ;�������������� DS, SS, SP
	mov	SP,  KEEP_SP
	call	NOT_LOADED_ERROR

is_loaded:
	mov	AX,  4d00h                       ;� AH - �������, � AL - ��� ����������
	int 	21h
        call	RETURN_CODE 
	ret		 
PROCESSING ENDP
;--------------------------------------------------------------------------------------------
CREATE_BP PROC NEAR
        mov	AX,  ES:[2Ch]
	mov	ParameterBlock,  AX
	mov	ParameterBlock+0002h,  ES     ;���������� ����� ���������� ��������� ������ 
	mov	ParameterBlock+0004h,  0080h  ;�������� ���������� �������� ������
	ret
CREATE_BP ENDP
;--------------------------------------------------------------------------------------------
RETURN_CODE PROC NEAR
	cmp	AH,  0000h         ;���������� ����������
	mov	DX,  offset End_0       
	je	EXIT_CODE
	cmp	AH,  0001h         ;���������� �� Ctrl-Break
	mov	DX,  offset End_1
	je	EXIT_CODE
	cmp	AH,  0002h         ;���������� �� ������ ����������
	mov	DX,  offset End_2
	je	EXIT_CODE
	cmp	AH,  0003h         ;���������� �� ������� 31h, ����������� ��������� �����������
	mov	DX,  offset End_3 

EXIT_CODE:
	call	PRINT           ;������� ��� ���������� �� �����
	mov	DI,  offset END_CODE
	call	BYTE_TO_HEX
	add	DI,  000Bh
	mov	[DI],  AL
	add	DI,  0001h
	xchg	AH,  AL
	mov	[DI],  AL
	mov	DX,  offset END_CODE
	call	PRINT
	xor	AL,  AL
	mov	AH,  4Ch
	int	21h
RETURN_CODE ENDP
;--------------------------------------------------------------------------------------------
NOT_LOADED_ERROR PROC NEAR
;��������� ������, ���� ��������� �� ���� ���������
	cmp	AX,  0001h          ;���� ����� ������� �������
	mov	DX,  offset Err_1
	je	NOT_LOADED
	cmp	AX,  0002h          ;���� ���� �� ������
	mov	DX,  offset Err_2
	je	NOT_LOADED
	cmp	AX,  0005h          ;��� ������ �����
	mov	DX,  offset Err_5
	je	NOT_LOADED
	cmp	AX,  0008h          ;��� ������������� ������ ������
	mov	DX,  offset Err_8
	je	NOT_LOADED
	cmp	AX,  000Ah          ;��� ������������ ������ �����
	mov	DX,  offset Err_10
	je	NOT_LOADED
	cmp	AX,  000Bh          ;���� ������� ������
	mov	DX,  offset Err_11
	
NOT_LOADED:
	call	PRINT
	xor	AL, AL
	mov	AH, 4Ch
	int	21h
NOT_LOADED_ERROR ENDP
;--------------------------------------------------------------------------------------------
MAIN:
	mov	AX,DATA
	mov	DS,AX
	call	FREE_MEMORY
        call	CREATE_BP	
	call	PROCESSING
	xor	AL, AL
	mov	AH, 4Ch
	int	21h
LAST_BYTE:
CODE ENDS
         END MAIN   