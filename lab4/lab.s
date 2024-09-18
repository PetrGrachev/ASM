bits	64

SYS_exit  equ   60 ; terminate
EXIT_SUCCESS equ 0 ; success code

section .data

msg1:
	db	"%f", 0
msg2:
	db	"ln(%.10g, %.10g)=%.10g", 10, 0
msg3:
	db	"Myln(%.10g, %.10g)=%.10g", 10, 0
msg4:
	db	"%s", 0
msg5:
	db "%.10g", 10, 0
msg6:
	db "w,0", 0

filename:
	times 15 db 0

fileDescriptor:
	dd 0	

prev:
	dd 0.0
cur:
	dd 0.0

n:
	dd 1

val:
	dd 0.5
alpha:
	dd 0.5

accuracy:
	dd 0.1
tmp:
	dd 1.0
factor:
	dd 1.0
power:
	dd 1.0
sum_a:
	dd 0.0
sum:
	dd 0.0
My_logCalc:
	dd 0.0

C_logCalc:
	dd 0.0

section	.text

extern	printf
extern	scanf
extern  logf
extern cosf
extern fopen
extern fclose
extern  fprintf

global main
main:
	push	rbp
	mov	rbp, rsp
	; ввод значения
		mov	rdi, msg1
		mov rsi, val
		xor	eax, eax
		call	scanf	
	 ; ввод угла
        mov rdi, msg1
        mov rsi, alpha
        xor eax, eax
        call scanf

	; ввод точности
		mov	rdi, msg1
		mov rsi, accuracy
		xor	eax, eax
		call	scanf
	; ввод имени файла
	enter_filename:
		mov edi, msg4
		mov rsi, filename
		xor	eax, eax
		call scanf
		mov edi, filename
		mov esi, msg6 ; write
		call fopen
		cmp eax, 0
		je enter_filename
		mov [fileDescriptor], eax
	C_ln:
		movss xmm0, [val]
		movss xmm1, [val]
		mulss xmm0, xmm1 ; xmm0 = x^2
		mov eax, 1
		cvtsi2ss xmm1, eax
		addss xmm0, xmm1 ; xmm0=x^2+1
		movss dword[tmp], xmm0
		movss xmm0, [alpha]
		call cosf

		movss xmm1, [val]
		mulss xmm0, xmm1
		mov eax, 2
		cvtsi2ss xmm1, eax 
		mulss xmm0, xmm1;xmm0=2xcos a
		movss xmm1, xmm0
		movss xmm0, dword[tmp]
		subss xmm0, xmm1
		call logf
		movss [C_logCalc], xmm0

	My_ln:
		movss xmm1, [val]
		movss dword[cur], xmm1
		call my_ln
		movss xmm0, [sum]
		
		;mov eax, 2
		;cvtsi2ss xmm1, eax 
		;mulss xmm0, xmm1
		;mov eax, -1
		;cvtsi2ss xmm1, eax
		;mulss xmm0, xmm1
		
		movss [My_logCalc], xmm0
		 
 	mov edi, msg2
	movss xmm3, [val]
	movss xmm4, [alpha]
	movss xmm5, [C_logCalc]
	cvtss2sd xmm0, xmm3
	cvtss2sd xmm1, xmm4
	cvtss2sd xmm2, xmm5
	mov eax, 2
	call printf

	mov edi, msg3
	movss xmm3, [val]
	movss xmm4, [alpha]
	movss xmm5, [My_logCalc]
	cvtss2sd xmm0, xmm3
	cvtss2sd xmm1, xmm4
	cvtss2sd xmm2, xmm5
	mov eax, 2
	call printf
	
	mov edi, [fileDescriptor]
	call fclose
	leave
	ret

global my_ln
my_ln:
	push rbp
	mov rbp, rsp
	begin:
		movss xmm1, dword[cur]
		movss dword[prev], xmm1

		movss xmm0, [sum_a]
		movss xmm1, [alpha]
		addss xmm0, xmm1
		movss [sum_a], xmm0

		movss xmm0, [factor]
		cvtsi2ss xmm1, dword[n]
		mulss xmm0, xmm1
		movss [factor], xmm0

		movss xmm0, [power]
		movss xmm1, [val]
		mulss xmm0, xmm1
		movss [power], xmm0
	processing:
		movss xmm0, [sum_a]
		call cosf
		movss xmm1, [power]
		mulss xmm0, xmm1
		movss xmm1, [factor]
		divss xmm0, xmm1
	;save
	;///
	mov eax, 2
	cvtsi2ss xmm1, eax 
	mulss xmm0, xmm1
	mov eax, -1
	cvtsi2ss xmm1, eax
	mulss xmm0, xmm1
	;///
	
	movss [cur], xmm0
	
	;sum
	movss xmm0, [sum]
	movss xmm1, [cur]
	addss xmm0, xmm1
	movss [sum], xmm0

	;запись в файл член ряда
	mov edi, [fileDescriptor]
	mov esi, msg5
	movss xmm1, [cur]
	cvtss2sd xmm0, xmm1
	mov eax, 1
	call fprintf

	; n++
	inc dword[n]

      ; если это только начало вычислений и An-1 просто не существует
	movss xmm2, [prev]
	movss xmm3, dword[val]
	ucomiss xmm2, xmm3
	je begin

	; проверка на конец
	; |An-1 - An| < E
	movss xmm0, [prev] ; Sn-1
	movss xmm1, [cur]  ; Sn
	subss xmm0, xmm1
	mov eax, 0
	cvtsi2ss xmm1, eax
	ucomiss xmm0, xmm1
	jnb if_absolute
	mov eax, -1
	cvtsi2ss xmm1, eax
	mulss xmm0, xmm1 ; if negative
	if_absolute:
		movss xmm1, [accuracy]
		ucomiss xmm0, xmm1
		jbe CalcSeriesDone
	jmp begin
	CalcSeriesDone:
		leave
		ret
