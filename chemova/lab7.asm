ASTACK SEGMENT STACK
	DW 64 DUP (?)
ASTACK ENDS
;������
;--------------------------------------------------------------------------------------------
DATA SEGMENT
	Load_1    db  0DH, 0AH,'The overlay was not been loaded: non-existent function!', 0DH, 0AH, '$'
	Load_10   db  0DH, 0AH,'The overlay was not been loaded: incorrect environment!', 0DH, 0AH, '$'
	Load_4    db  0DH, 0AH,'The overlay was not been loaded: too many open files!', 0DH, 0AH, '$'
	Load_3    db  0DH, 0AH,'The overlay was not been loaded: route not found!', 0DH, 0AH, '$'
	Load_2    db  0DH, 0AH,'The overlay was not been loaded: file not found!', 0DH, 0AH, '$'
	Load_8    db  0DH, 0AH,'The overlay was not been loaded: low memory!', 0DH, 0AH, '$'
	Load_5    db  0DH, 0AH,'The overlay was not been loaded: no access!', 0DH, 0AH, '$'
	Mem_8     db  0DH, 0AH,'Not enough memory to perform the function!', 0DH, 0AH, '$'
	Err_alloc db  0DH, 0AH,'Failed to allocate memory to load overlay!', 0DH, 0AH, '$'
	Mem_9     db  0DH, 0AH,'Wrong address of the memory block!', 0DH, 0AH, '$'
	Mem_7     db  0DH, 0AH,'Memory control unit destroyed!', 0DH, 0AH, '$'
	File_3    db  0DH, 0AH,'The route was not found!', 0DH, 0AH, '$'
	File_2    db  0DH, 0AH,'The file was not found!', 0DH, 0AH, '$'
	Path      db  'Path to file: ', '$'
	Ovl1	  db  'OVL1.ovl', 0000h
	Ovl2	  db  'OVL2.ovl', 0000h	
	OvlPath   db  64 DUP (?), '$' 	
	DTA       db  43 DUP (?)
	Keep_psp  dw  0000h
	SegAdr    dw  0000h
	CallAdr	  dd  0000h
DATA ENDS
;--------------------------------------------------------------------------------------------
CODE SEGMENT
        ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK
;���������
;--------------------------------------------------------------------------------------------
PRINT  	PROC NEAR
;����� ������
	mov	AH,  0009h
	int	21h
	ret
PRINT  ENDP
;--------------------------------------------------------------------------------------------
DTA_SET PROC NEAR
;��������� ������ DTA �����
        push	DX
        lea	DX,  DTA  ;���������� ������������ ������, DS:DX �� ������, ���������� ��� ����� � ��������
        mov	AH,  1Ah  ;���������� ����� ������� ������ � ������ (DTA)
        int	21h       ;����� �������
        pop	DX
DTA_SET ENDP   	
;--------------------------------------------------------------------------------------------
FREE_MEMORY PROC NEAR                                 ;������������ ����� � ������ 
	                                              ;����� ������� ������� ���� ���������� ����� ������, ����������� lr6 
	mov	BX,  offset LAST_BYTE                     ;����� � BX ����� ����� ���������
	mov	AX,  ES                                   ;ES - ������ ���������
	sub	BX,  AX                                   ;BX = BX - ES, ����� ����������, ������� ����� ���������� ��������
	mov	CL,  0004h
	shr	BX,  CL                                   ;��������� � ���������
	mov	AH,  4Ah                                  ;������� ������ ����� ������
	int	21h
	jnc	WITHOUT_ERROR                            ;���� CF = 0, ���� ��� ������
	jmp	WITH_ERROR                               ;o�������� ������ CF=1 AX = ��� ������, ���� CF ���������� 
;********************************************************************************************    
WITHOUT_ERROR:
	ret
;********************************************************************************************    		 
WITH_ERROR:
;********************************************************************************************    
MEM_7_ERROR:	
	cmp	AX, 0007h                           ;�������� ����������� ���� ������
	jne	MEM_8_ERROR
	mov	DX, offset Mem_7
	jmp	END_ERROR
;********************************************************************************************    
MEM_8_ERROR:
	cmp	AX, 0008h                           ;������������ ������ ��� ���������� �������
	jne	MEM_9_ERROR
	mov	DX, offset Mem_8
	jmp	END_ERROR
;********************************************************************************************    
MEM_9_ERROR:
        mov	DX, offset Mem_9                    ;�������� ����� ����� ������
;********************************************************************************************    
END_ERROR:                                    ;����� ������ �� �����
	call	PRINT 
	xor	AL, AL
	mov	AH, 4Ch
	int	21h
FREE_MEMORY ENDP
;--------------------------------------------------------------------------------------------
FIND_PATH PROC NEAR                                   ;����� ���� � ����� �������
	push	ES
	mov	ES,  ES:[2CH]                            ;���������� ����� �����, ������������ ���������
	xor	SI,  SI
	lea	DI,  OvlPath
;********************************************************************************************    		
FIRST: 
	inc	SI                                  ;������ ���������� ������� ������      
        cmp	word ptr ES:[SI], 0000h             ;�������� �� ��, ��� ��� ����� ������
	jne	FIRST                               ;�������, ���� �� ����� ������
	add	SI, 0004h                           ;������ ���������� ������� ������      
;********************************************************************************************    		
SECOND:
	cmp	byte ptr ES:[SI], 0000h             ;�������� �� ��, ��� ��� ����� ������
	je	THIRD                               ;���� ����� ������ (��� ������� ����� ������)
	mov	DL, ES:[SI]
	mov	[DI], DL
	inc	SI
	inc	DI
	jmp	SECOND  
;********************************************************************************************    		
THIRD:
	dec	SI                                  ;������ ����������� ������� ������
	dec	DI
	cmp	byte ptr ES:[SI], '\'
	jne	THIRD                               ;�������, ���� ������ ������� �� "\"
	inc	DI                                  ;������ ���������� ������� ������
	mov	SI, BX
	push	DS
	pop	ES
;********************************************************************************************    		
FOURTH:
	lodsb                                    ;������ ����� �� ������ �� ������ DS:SI � AL
	stosb                                    ;������ ����� � ������, ��������� AL �� ������ ES:DI 
	cmp	AL, 0000h                           ;�������� �� ��, ��� ��� ����� ������
	jne	FOURTH                              ;�������, ���� �� ����� ������
	mov	byte ptr [DI], '$'
	mov	DX, offset Path                               
	call	PRINT
	lea	DX, OvlPath
	call	PRINT
	pop	ES
	ret
FIND_PATH ENDP	
;--------------------------------------------------------------------------------------------
ALLOCATE_MEMORY_FOR_OVL PROC NEAR                     ;���������� ������� ������� � ��������� ������ ��� ���� ����
	push	DS
	push	DX
	push	CX
	xor	CX, CX                                   ;CX - �������� ����� ��������� ��� ��������� (��� ����� 0)
	lea	DX, OvlPath                              ;���������� ������������ ������, DS:DX = ����� ASCIIZ-������ � ������ �����
	                                              ;ASCIIZ-������ - ������ ������������� ������, ��� ������� ������������ ������ ��������,� ����� - ����-������
	mov	AH, 4Eh                                  ;������� 4Eh - ����� ������� ������������ �������
	int	21h                                      ;����� �������
	jnc	FILE_IS_FOUND                            ;�������, ���� ���� CF=0 (��� ������, ������� ����������)
	cmp	AX, 0003h                                ;� AX �������� ��� ������, ���� CF ����������
	je	ERROR_3                                  ;�������, ���� ������ � ����� 0003h
	mov	DX, offset File_2                        ;���� ���� �� ��� ������
	jmp	EXIT_ERROR
;********************************************************************************************    	
ERROR_3:
	mov	DX, offset File_3                   ;���� ������� �� ��� ������
;********************************************************************************************    		 
EXIT_ERROR:                                   ;����� ������ �� �����
	call	PRINT
	pop	CX
	pop	DX
	pop	DS
	xor	AL, AL
	mov	AH, 4Ch
	int	21h
;********************************************************************************************    		 
FILE_IS_FOUND:                                ;���� ���� ��� ������
	push	ES
	push	BX
	mov	BX, offset DTA                      ;�������� �� DTA
	mov	DX, [BX + 1Ch]                      ;������� ����� ������� ������ � ������
	mov	AX, [BX + 1Ah]                      ;������� ����� ������� �����
	mov	CL, 0004h                           ;������� � ��������� �������� �����
	shr	AX, CL                              ;����� ��� �������� ������ 
	mov	CL, 000Ch 
	sal	DX, CL                              ;��������� � ����� � ���������, ����� �����
	add	AX, DX 
	inc	AX                                  ;������ �������� ������ ����� ����������
	mov	BX, AX                              ;BX - ����������� ���������� ������ � 16-�������� ����������
	mov	AH, 48h                             ;������������ ������ (���� ������ ������)
	int	21h 
	jnc	MEMORY_ALLOCATED                    ;�������, ���� CF=0 (������ ��������)
	mov	DX, offset Err_alloc                ;����� �������� �� ������
	call	PRINT
	xor	AL, AL
	mov	AH, 4Ch
	int	21h
;********************************************************************************************    		 
MEMORY_ALLOCATED:
	mov	SegAdr, AX                          ;SegAdr - ���������� ����� ��������������� �����
	pop	BX
	pop	ES
	pop	CX
	pop	DX
	pop	DS
	ret
ALLOCATE_MEMORY_FOR_OVL ENDP    
;--------------------------------------------------------------------------------------------	
PROGRAM_CALL_OVL PROC NEAR                            ;����� ��������� �������
	push	DX
	push	BX
	push	AX
	mov	BX, seg SegAdr
	mov	ES, BX
	lea	BX, SegAdr	                              ;ES:BX = ����� EPB (EXEC Parameter Block - ����� ���������� EXEC)
	lea	DX, OvlPath                              ;DS:DX = ����� ������ ASCIIZ � ������ �����, ����������� ���������	
	mov	AX, 4B03h                                ;�������, ������� ��������� ����������� �������
	int	21h
	jnc	IS_LOADED                                ;�������, ���� ��� ������
;********************************************************************************************    	
ERROR_CHECK:
	cmp	AX, 0001h                           ;�������������� ����
	lea	DX, Load_1
	je	PRINT_ERROR
	cmp	AX, 0002h                           ;���� �� ������
	lea	DX, Load_2
	je	PRINT_ERROR
	cmp	AX, 0003h                           ;������� �� ������
	lea	DX, Load_3
	je	PRINT_ERROR
	cmp	AX, 0004h                           ;������� ����� �������� ������
	lea	DX, Load_4
	je	PRINT_ERROR
	cmp	AX, 0005h                           ;��� �������
	lea	DX, Load_5
	je	PRINT_ERROR		 
	cmp	AX, 0008h                           ;���� ������
	lea	DX, Load_8
	je	PRINT_ERROR
	cmp	AX, 000Ah                           ;������������ �����
	lea	DX, Load_10                 
;********************************************************************************************		 
PRINT_ERROR:                                  ;����� ��������� �� ������ �� �����
	call	PRINT
	jmp	FINISH
;********************************************************************************************
IS_LOADED:
	mov	AX, DATA                            ;��������������� DS
	mov	DS, AX
	mov	AX, SegAdr
	mov	word ptr CallAdr + 0002h, AX
	call	CallAdr                             ;�������� ���������� ���������
	mov	AX, SegAdr
	mov	ES, AX
	mov	AX, 4900h                           ;���������� �������������� ���� ������
	int	21h
	mov	AX, DATA
	mov	DS, AX
;********************************************************************************************    		 
FINISH:
	mov	ES, Keep_psp
	pop	AX
	pop	BX
	pop	DX
	ret
PROGRAM_CALL_OVL ENDP
;--------------------------------------------------------------------------------------------
PROCESSING PROC NEAR
;��������� �������
        call	FIND_PATH
        call	ALLOCATE_MEMORY_FOR_OVL
        call	PROGRAM_CALL_OVL
	ret
PROCESSING ENDP    
;--------------------------------------------------------------------------------------------
MAIN:
        mov	AX, DATA
	mov	DS, AX
	mov	Keep_psp, ES
	call	FREE_MEMORY
	call	DTA_SET
	lea	BX, Ovl1
	call	PROCESSING
	lea	BX, Ovl2
	call	PROCESSING
	xor	AL, AL
	mov	AH, 4Ch
	int	21h
LAST_BYTE:
CODE ENDS
        END  	MAIN