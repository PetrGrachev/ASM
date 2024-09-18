
section .data
n:
    dq 0
x:
    dq 0
y:
    dd 0
sum:
    dd 0.0
tmp:
    dq 0
pixel:
    db 0
section .text
global gaussianBlur_asm
gaussianBlur_asm:
    push rbp
    mov rbp, rsp

    ; Регистр RDI содержит адрес исходного массива src
    ; Регистр ESI содержит значение переменной x
    ; Регистр EDX содержит значение переменной y
    ; Регистр ECX содержит значение переменной n
    ; Регистр R8 содержит адрес выходного массива dst
    ; Регистр R9 содержит адрес массива kernel

    mov dword[n], ecx
    mov dword[x], esi
    mov dword[y], edx
    mov r10, rdi
    xor rcx, rcx ; Обнуляем счетчик offset

	mov eax, dword[x]
	add eax, 2
	mov dword[tmp], eax
	
    outer_loop:
        cmp ecx, dword [n] ; Сравниваем offset с n
        jge end_outer_loop ; Если offset >= n, выходим из внешнего цикла

        xor rsi, rsi ; Обнуляем счетчик i

        inner_loop_i:
            cmp esi, dword [y] ; Сравниваем i с y
            jge end_inner_loop_i ; Если i >= y, выходим из внутреннего цикла

            xor rdi, rdi ; Обнуляем счетчик j

            inner_loop_j:
                cmp edi, dword [x] ; Сравниваем j с x
                jge end_inner_loop_j ; Если j >= x, выходим из внутреннего цикла

                xor rax, rax ; Обнуляем sum
                xorps xmm0, xmm0
                
                movss [sum], xmm0
                mov rbx, -1 ; Обнуляем счетчик k

                inner_loop_k:
                    cmp ebx, 1 ; Сравниваем k с 1
                    jg end_inner_loop_k ; Если k > 1, выходим из внутреннего цикла

                    mov rdx, -1 ; Обнуляем счетчик l

                    inner_loop_l:
                        cmp edx, 1 ; Сравниваем l с 1
                        jg end_inner_loop_l ; Если l > 1, выходим из внутреннего цикла

                        movsxd rax, ebx
                        add rax, rsi
                        imul rax, qword[tmp]
                        add rax, rdi
                        add rax, rdx
                        imul rax, qword[n]
                        add rax, rcx
                       
                        mov r11b, byte[r10+rax]
                        mov byte[pixel], r11b  ;pixel = src[n * ((i + k) * (x + 2) + (j + l)) + offset

                        mov rax, rbx
                        add rax, 1
                        imul rax, 3
                        add rax, rdx
                        add rax, 1
                        imul rax, 4
                        add rax, r9
                        
                        movss xmm0, dword[rax]
                        cvtsi2ss xmm1, [pixel]
                        mulss xmm0, xmm1
                        movss xmm1, dword[sum]
                        addss xmm1, xmm0; sum += pixel * kernel[k + 1][l + 1];
                        movss [sum], xmm1
                        inc edx ; Увеличиваем счетчик l
                        jmp inner_loop_l ; Переходим к следующей итерации внутреннего цикла l

                    end_inner_loop_l:
                    
                    inc ebx ; Увеличиваем счетчик k
                    jmp inner_loop_k ; Переходим к следующей итерации внутреннего цикла k

                end_inner_loop_k:
                 ; Записываем результат в dst
                mov rax, rsi
                imul rax, qword[x]
                add rax, rdi
                imul rax, qword[n]
                add rax, rcx
            	add rax, r8
            	cvtss2si r11, [sum]
                mov byte[rax], r11b

                inc edi ; Увеличиваем счетчик j
                jmp inner_loop_j ; Переходим к следующей итерации внутреннего цикла j

            end_inner_loop_j:
            inc esi ; Увеличиваем счетчик i
            jmp inner_loop_i ; Переходим к следующей итерации внутреннего цикла i

        end_inner_loop_i:
        inc ecx ; Увеличиваем счетчик offset
        jmp outer_loop ; Переходим к следующей итерации внешнего цикла

    end_outer_loop:
    pop rbp
    ret
