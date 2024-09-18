section .data
matrix:
	dd 8, 7, 1, 9
	dd 10, 2, 3, 12
	dd 4, 10, 13, 5
	dd 91, 92, 93, 94
n:
	dd 4 ; number of rows
m:
	dd 4 ; number of columns
mas_ptr:
	dd 0, 0, 0, 0
ind_a:
	dd 0
ind_b:
	dd 0

section .text
global _start

_start:
	mov eax, 0
	mov ecx, -1
	mov edx, 0
	mov esi, 0

columns_loop:			;for (column)
	inc ecx;
	mov ebx, matrix
	
	mov eax, ecx
	shl eax, 2
	add ebx, eax
	;mov eax, ecx
	;mov edx, 4
	;mul edx
	;add ebx, eax;
	
	mov esi, ecx

find_min_in_column:
	mov eax, [ebx]
	mov ecx, 0	;i=0
	mov edx, 0
start_find:
	inc ecx
	cmp ecx, dword[n]
	jge end_find		;int find_min_in_column(int **matrix, int rows, int column_id) {
	add edx, dword[m]	;int min_value = matrix[0][column_id]
	cmp [ebx+edx*4], eax	;for (int i = 1; i < rows; i++) {
	jg start_find			;if (matrix[i][column_id] < min_value) {
	mov eax, [ebx+edx*4]			;min_value = matrix[i][column_id]
	jmp start_find			;}
end_find:			;}
	mov ecx, esi	;mas_ptr[j]=min_value
	mov [mas_ptr+ecx*4], eax
	mov edx, dword[m]
	dec edx
	cmp ecx, edx
	jl columns_loop

	xor rax, rax
	xor rbx, rbx
	xor rcx, rcx
	xor rdx, rdx

shell_sort:
	mov eax, dword[n]
	shr eax, 1 			;s=size/2
for_s:	
	cmp eax, 0 
	jle end_s

	mov rdi, rax	;rdi-i i=s
for_i:
	cmp edi, dword[n]	;i<size
	jge end_i
	
	mov rsi, rdi
	sub esi, eax	;rsi-j j=i-s
for_j:
	cmp rsi, 0
	jl end_j
	
	mov rdx, rsi
	add edx, eax
	mov dword[ind_a], esi
	mov dword[ind_b], edx
	push rax
	push rbx
	push rcx
	push rdx
		
	jmp compare
end_j:	
	inc rdi		;i++
	jmp for_i	
end_i:
	shr eax, 1 	;s=s/2
	jmp for_s
end_s:

end:
	mov rax, 60
	mov rdi, 0
	syscall



compare:	; ind_a-index 1 col,ind_b-index 2 col !!!BERORE USE PUSH EAX,EBX,ECX
	mov eax, dword[ind_a]
	mov ebx, dword[ind_b]
	mov ecx, [mas_ptr+eax*4]
	cmp ecx, [mas_ptr+ebx*4]

	%ifdef ascending_mode
	jg swap
	%endif
	
	%ifdef descending_mode
	jle swap
	%endif
	jmp pop_all
	
swap:
	xchg ecx, [mas_ptr+ebx*4]
	mov [mas_ptr+eax*4], ecx
	xor rax, rax
	xor rbx, rbx
	xor rcx, rcx
	xor rdx, rdx
	
swap_columns:	; ind_a-index 1 col,ind_b-index 2 col !!!BEFORE USE PUSH EAX,EBX,ECX,EDX
	mov ecx, -1
swap_loop:
	inc ecx
	mov eax, dword[m]
	mul ecx
	mov edx, eax
	add eax, dword[ind_a]
	add edx, dword[ind_b]
	mov ebx, [matrix+eax*4]
	xchg ebx, [matrix+edx*4]
	mov [matrix+eax*4], ebx

	mov edx, dword[n]
	dec edx			;n-1
	cmp ecx, edx
	jl swap_loop
	jmp	pop_all

pop_all:
	pop rdx
	pop rcx
	pop rbx
	pop rax
	sub rsi, rax	;j=j-s
	jmp for_j
