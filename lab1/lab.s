section .data
res	    dq	    0
a           dw      5
b           dw      10
c           dd      200
d           dw      30
e           dd      1000

section .text
global _start
		;res=(a*e-c*b+d/b)/((b+c)*a)
_start:
    movzx   eax, word[a]
    mul    dword[e]       ; Multiply e with a
    mov     rbx, rax

    movzx   rax, word[b]
    mul    dword[c]       ; Multiply c with b
    cmp    rbx, rax
    jl    sign
    sub     rbx, rax       ;(a*e-c*b)

    movzx     eax, word[d]
    movzx     ecx, word[b]
    cmp ecx, 0
    je error
    div    ecx		; d/b
    add     rbx, rax   ; Add d/b to ebx

    mov  eax, dword[c]
    movzx ecx, word[b]
    add     eax, ecx       ; Add b to c
    movzx ecx, word[a]
    mul     rcx       ; (b+c)*a
    mov rcx, rax
    mov rax, rbx
    cmp rcx, 0
    je error
    xor rdx, rdx
    div    rcx		;(a*e-c*b+d/b)/((b+c)*a)

    mov     qword[res], rax     ; Store the result in memory
    mov     rax, 60
    mov     rdi, 0
    syscall
error:
    mov rax, 60
    mov rdi, 1
    syscall
sign:
    mov rax, 60
    mov rdi, 2
    syscall
