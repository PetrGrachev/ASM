bits 64

section	.data
; Standard constants:
	SYS_exit  equ   60 ; terminate
	EXIT_SUCCESS equ 0 ; success code

	LF    equ 10 ; line feed
	NULL  equ 0  ; end of string

	STDIN equ  0 ; standard input
	STDOUT equ 1 ; standard output

	SYS_read  equ 0 ; read
	SYS_write equ 1 ; write
	SYS_open  equ 2 ; file open
	SYS_close equ 3 ; file close
	O_WRONLY equ 000001q ; file mode: read only

	S_IRUSR equ 00400q
	S_IWUSR equ 00200q
; My constants:
	l_str equ 1024

msgEnter:
	db " Enter the string ", LF, NULL
msgRepeat:
	db " Repeat! ", LF, NULL
errMsgLength:
	db " Error!: Len ", LF, NULL
errorNoArg:
	db " Error!: No argument", LF, NULL

vowels:
	db "AEIOUYaeiouy", NULL
lineFeed:
	db LF, NULL
chr:
	db 0
is_empty:
	db 1
is_first:
	db 1
is_word:
	db 0
filename:
	times l_str db NULL

mainString:
	times l_str db	NULL
finalString:
	times l_str db NULL
fileDescriptor:
	times l_str db NULL
	
section	.text
global	_start
_start:
	pop rax
	cmp rax, 1
	je error_no_arg
	pop rax
	pop rax

; Получаем первый параметр командной строки
    mov rsi, rax
    mov rdi, filename
    mov ecx, l_str
	rep movsb

	call open_file
	
new_str:
	call dialog

	cmp eax, -5	;EOF?
	je last

	mov ebx, mainString
	call split_string
	mov esi, mainString
	mov edi, 0
	jmp processing
	word_loop_start:
		mov al, byte[esi]
		cmp eax, 0
		je find_word
		inc esi
		jmp word_loop_start

		find_word:
			inc esi
			mov al, byte[esi]
			cmp eax, 0
			jne processing
			jmp end_of_loop

		processing:
			call deleteConsonants
			call appendString
			jmp word_loop_start

end_of_loop:
	mov rax, [is_first]
	cmp rax, 1
	je removeFirst
	call removeLastChar
	mov rsi, lineFeed
	call appendString
	call write_string
	mov esi, finalString
	mov edi, l_str
	call clearString
	
	mov rax, 0
	mov [is_empty], rax
	jmp new_str
		
last:
	call close_file	
	mov rax, SYS_exit
	mov rdi, EXIT_SUCCESS
	syscall

removeFirst:
	call removeFirstChar
	mov rax, 0
	mov [is_first], rax
	jmp end_of_loop

error_no_arg:
	mov rdi, errorNoArg
	call printString
	jmp last

global clearString
clearString:
	xor ecx, ecx
	mov al, 0
	clearLoop:
		cmp ecx, edi
		jge clearEnd

		mov byte[esi+ecx], al
		inc ecx
		jmp clearLoop

	clearEnd:
		ret

global removeFirstChar
removeFirstChar:
    push rbx
    push rcx
    push rdx

    mov rdi, finalString ; адрес строки finalString
    mov rbx, rdi         ; сохраняем адрес для использования в цикле

    ; Найти конец строки finalString
    xor rcx, rcx
    mov cl, byte [rdi]
    cmp cl, 0
    je removeFDone

    ; Сдвинуть все символы на одну позицию влево
    mov rcx, rbx
    inc rcx

shiftLeft:
    mov dl, byte [rcx]
    mov byte [rdi], dl
    inc rdi
    inc rcx
    cmp dl, 0
    jne shiftLeft

removeFDone:
    pop rdx
    pop rcx
    pop rbx

    ret

global removeLastChar
removeLastChar:
    push rbx
    push rcx
    push rdx

    mov rdi, finalString ; адрес строки finalString
    mov rbx, rdi         ; сохраняем адрес для использования в цикле

    ; Найти конец строки finalString
    xor rcx, rcx
    mov cl, byte [rdi]
    cmp cl, 0
    je removeLDone

    ; Найти предпоследний символ строки
    mov rcx, rbx

findSecondLast:
    inc rcx
    mov dl, byte [rcx]
    cmp dl, 0
    je removeLast

    jmp findSecondLast

removeLast:
    mov byte [rcx], 0 ; установить нулевой символ в конец строки

removeLDone:
    pop rdx
    pop rcx
    pop rbx

    ret
    
global deleteConsonants
deleteConsonants:
; Сохраняем адрес списка гласных букв в регистре edi
    mov edi, vowels

    ; Проходим по каждому символу строки
    mov ecx, 0  ; Счетчик символов
    mov eax, 0  ; Флаг наличия согласной буквы
    jmp check_vowel
loop_start:
    ; Проверяем, является ли текущий символ согласной буквой
    cmp al, 0  ; Проверяем достигнут ли конец строки
    je end_loop

check_vowel:
    ; Сравниваем текущий символ с каждой гласной буквой
    mov al, [esi+ecx]  ; Загружаем текущий символ строки в регистр al
    cmp al, 0  ; Проверяем достигнут ли конец строки
    je end_loop

    mov edx, edi  ; Сохраняем адрес списка гласных букв в регистр edx
    mov ebx, 0  ; Счетчик гласных букв

check_next_vowel:
    ; Сравниваем текущий символ с текущей гласной буквой
    cmp al, [edx+ebx]
    je vowel_found

    ; Переходим к следующей гласной букве
    inc ebx
    cmp byte [edx+ebx], 0  ; Проверяем достигнут ли конец списка гласных букв
    jne check_next_vowel

    ; Если символ не является гласной буквой, устанавливаем флаг
    mov eax, 1

vowel_found:
	;push rbx
	;mov rbx, 1
	;mov [is_word], rbx
	;pop rbx
    ; Если символ является гласной буквой, пропускаем его
    cmp eax, 0
    je skip_vowel

    ; Копируем текущий символ в новую строку
    mov [esi+ecx], al

skip_vowel:
    ; Увеличиваем счетчик символов и переходим к следующему символу
    inc ecx
    jmp loop_start

end_loop:
    ; Устанавливаем нулевой байт в конце строки
    mov byte [esi+ecx], 0

	;mov rdi, rsi
	;call printString
	ret

global split_string
split_string:
    ; Разделяем строку на отдельные слова
    mov esi, ebx  ; Сохраняем указатель на начало строки
    mov edi, 0    ; Счетчик слов
    mov ecx, 0    ; Флаг: 0 - вне слова, 1 - внутри слова

split_loop_start:
    mov al, byte [ebx]  ; Загружаем текущий символ

    cmp al, ' '  ; Проверяем, является ли символ пробелом
    je space_found

    cmp al, 0  ; Проверяем, является ли символ концом строки
    je end_of_string

    cmp ecx, 0  ; Проверяем флаг
    jne continue_word

    inc edi  ; Увеличиваем счетчик слов
    mov ecx, 1  ; Устанавливаем флаг внутри слова

continue_word:
    inc ebx  ; Переходим к следующему символу
    jmp split_loop_start

space_found:
    mov ecx, 0  ; Устанавливаем флаг вне слова
    mov byte [ebx], 0  ; Заменяем пробел нулевым символом
    inc ebx  ; Переходим к следующему символу
    jmp split_loop_start

end_of_string:
    mov byte [ebx], 0  ; Заменяем конец строки нулевым символом
    ret
    
global appendString
appendString:
    push rbx
    push rcx
    push rdx
    ;push rsi
    push rdi

    mov rdi, finalString ; адрес строки finalString
    mov rbx, rdi         ; сохраняем адрес для использования в цикле
    ;mov rsi, esi         ; адрес строки для добавления

    ; Найти конец строки finalString
    xor rcx, rcx
    mov cl, byte [rdi]
    cmp cl, 0
    jne findEnd

findEnd:
	push rcx
	mov rcx, [is_empty]
	cmp rcx, 1
	je skip_inc
	 
    inc rdi	
skip_inc:
	mov rcx, 0
	mov [is_empty], rcx
	pop rcx
	
    mov cl, byte [rdi]
    cmp cl, 0
    jne findEnd

    ; Добавить пробел перед новым словом (если нужно)
    cmp byte [rsi], 0
    je appendDone

    cmp byte [rdi], 0
    je noSpace

    mov byte [rdi], ' ' ; добавить пробел
    inc rdi

noSpace:
    ; Добавить символы нового слова в finalString
    cmp byte[rdi], 0
    je copyChars
copyChars:
    mov dl, byte [rsi]
    cmp dl, 0
    je appendDone

    mov byte [rdi], dl ; копирование символа в finalString
    inc rsi
    inc rdi
    jmp copyChars

appendDone:
	;mov rcx, [is_word]
	;cmp rcx, 1
	;jne skipSpace
	mov byte [rdi], ' '
	inc rdi
	
skipSpace:
    mov byte [rdi], 0 ; добавление нулевого символа в конец строки
	;mov rcx, 0
	;mov [is_word], rcx
    pop rdi
;    pop rsi
    pop rdx
    pop rcx
    pop rbx

    ret


global open_file	
open_file:
    ; Открываем файл для записи
    mov eax, 85
    mov edi, filename
    mov esi, S_IRUSR | S_IWUSR  ; Флаги: O_CREAT | O_WRONLY
    mov edx, 0x777  ; Разрешения: 0777
    syscall
    mov [fileDescriptor], eax  ; Сохраняем дескриптор файла в регистре esi
    ret


global write_string
write_string:
    ; Записываем строку в файл
    mov eax, SYS_write
    mov edi, [fileDescriptor]
    mov esi, finalString
    mov edx, l_str
    syscall
    ret

global close_file
close_file:
    ; Закрываем файл
    mov eax, SYS_close
    mov edi, [fileDescriptor]
    syscall
    ret



; void printString(&string)
global printString
printString:
	push rbx
	mov rbx, rdi
	mov rdx, 0 			; drop counter
						; Count characters in string (exclude NULL)
	strCountLoop:
		cmp byte [rbx], NULL
		je strCountDone
		inc rdx 	; count symbols
		inc rbx		; make an offset
		jmp strCountLoop

	strCountDone:
		cmp rdx, 0
		je printDone
	
		mov rax, SYS_write  ; system code for write()
		mov rsi, rdi 		; address of chars to write
		mov rdi, STDOUT 	; standard out
							; RDX = counter to write, set above
		syscall

	printDone:
		pop rbx
		ret

; int readConsoleString(&string, size_buff) : return -1 if entered string bigger than given buffer
global readConsoleString
readConsoleString:
	push rbx
	push r12
	push r15
	mov r15, rsi ; length_str
	mov rbx, rdi
	mov r12, 0  ; char counter
	readCharacters:
		mov rax, SYS_read  ; system code for read
		mov rdi, STDIN     ; standard in
		lea rsi, byte[chr] ; address of chr, result: [rsi+1], [rsi+1 + 1] e.c
		mov rdx, 1         ; count (how many to read)
		syscall

		cmp rax, 0
		je eofReached

		mov al, byte [chr] ; get character just read
		cmp al, LF 		   ; if \n, input done
		je readStrDone

		inc r12 		   ; count++
		cmp r12, r15 	   ; if chars >= length_str
		jae errLength ; stop placing in buffer

		mov byte [rbx], al ; filename[i] = chr
		inc rbx ;  offset
		jmp readCharacters

	eofReached:
		pop r15
		pop r12
		pop rbx

		mov eax, -5
		ret

	readStrDone:
		mov byte[rbx], NULL ; add NULL termination
		pop r15
		pop r12
		pop rbx
		ret

	errLength:
		pop r15
		pop r12
		pop rbx

		mov rdi, errMsgLength
		call printString
		mov rdi, msgRepeat
		call printString
		mov eax, -1
		
		ret
		
global dialog
dialog:
	read_text:
		mov rdi, msgEnter
		call printString
		
		mov rdi, mainString
		mov rsi, l_str
		call readConsoleString
		cmp eax, -1
		je read_text
		
		cmp byte[mainString], -1
		jle last
		
	dialog_end:
		ret
