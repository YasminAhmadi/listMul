%ifndef SYS_EQUAL
%define SYS_EQUAL
    sys_read     equ     0
    sys_write    equ     1
    sys_open     equ     2
    sys_close    equ     3
   
    sys_lseek    equ     8
    sys_create   equ     85
    sys_unlink   equ     87
     

    sys_mmap     equ     9
    sys_mumap    equ     11
    sys_brk      equ     12
   
     
    sys_exit     equ     60
   
    stdin        equ     0
    stdout       equ     1
    stderr       equ     3

 
 
    PROT_READ     equ   0x1
    PROT_WRITE    equ   0x2
    MAP_PRIVATE   equ   0x2
    MAP_ANONYMOUS equ   0x20
   
    ;access mode
    O_RDONLY    equ     0q000000
    O_WRONLY    equ     0q000001
    O_RDWR      equ     0q000002
    O_CREAT     equ     0q000100
    O_APPEND    equ     0q002000

   
; create permission mode
    sys_IRUSR     equ     0q400      ; user read permission
    sys_IWUSR     equ     0q200      ; user write permission

    NL            equ   0xA
    Space         equ   0x20

%endif
;----------------------------------------------------
newLine:
   push   rax
   mov    rax, NL
   call   putc
   pop    rax
   ret
;---------------------------------------------------------
putc:

   push   rcx
   push   rdx
   push   rsi
   push   rdi
   push   r11

   push   ax
   mov    rsi, rsp    ; points to our char
   mov    rdx, 1      ; how many characters to print
   mov    rax, sys_write
   mov    rdi, stdout
   syscall
   pop    ax

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx
   ret
;---------------------------------------------------------
writeNum:
   push   rax
   push   rbx
   push   rcx
   push   rdx

   sub    rdx, rdx
   mov    rbx, 10
   sub    rcx, rcx
   cmp    rax, 0
   jge    wAgain
   push   rax
   mov    al, '-'
   call   putc
   pop    rax
   neg    rax  

wAgain:
   cmp    rax, 9
   jle    cEnd
   div    rbx
   push   rdx
   inc    rcx
   sub    rdx, rdx
   jmp    wAgain

cEnd:
   add    al, 0x30
   call   putc
   dec    rcx
   jl     wEnd
   pop    rax
   jmp    cEnd
wEnd:
   pop    rdx
   pop    rcx
   pop    rbx
   pop    rax
   ret
;---------------------------------------------------------
getc:
   push   rcx
   push   rdx
   push   rsi
   push   rdi
   push   r11

 
   sub    rsp, 1
   mov    rsi, rsp
   mov    rdx, 1
   mov    rax, sys_read
   mov    rdi, stdin
   syscall
   mov    al, byte [rsi]
   add    rsp, 1

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx

   ret
;---------------------------------------------------------
readNum:
   push   rcx
   push   rbx
   push   rdx

   mov    bl,0
   mov    rdx, 0
   
rAgain:
   xor    rax, rax
   call   getc
   cmp    al, '-'
   jne    sAgain
   mov    bl,1  
   jmp    rAgain
sAgain:
   cmp    al, NL
   je     rEnd
   cmp    al, ' ' ;Space
   je     rEnd
   sub    rax, 0x30
   imul   rdx, 10
   add    rdx,  rax
   xor    rax, rax
   call   getc
   jmp    sAgain
rEnd:
   mov    rax, rdx
   cmp    bl, 0
   je     sEnd
   neg    rax
sEnd:  
   pop    rdx
   pop    rbx
   pop    rcx
   ret
;-------------------------------------------
printString:
    push    rax
    push    rcx
    push    rsi
    push    rdx
    push    rdi

    mov     rdi, rsi
    call    GetStrlen
    mov     rax, sys_write  
    mov     rdi, stdout
    syscall
   
    pop     rdi
    pop     rdx
    pop     rsi
    pop     rcx
    pop     rax
    ret
;-------------------------------------------
; rsi : zero terminated string start
GetStrlen:
    push    rbx
    push    rcx
    push    rax  

    xor     rcx, rcx
    not     rcx
    xor     rax, rax
    cld
    repne   scasb
    not     rcx
    lea     rdx, [rcx -1]  ; length in rdx

    pop     rax
    pop     rcx
    pop     rbx
    ret
;-------------------------------------------

section .data
    len dq 0 ; length of the current list
    no db 'NO', 0
    lo db 'LL', 0
section .bss
    
    arr: resq 10000000 ; arr is used to store all the lists
    n: resb 4 ; Number of lists
    res: resb 4 ; result of the current list

section .text
global _start
   
_start:

_get_input:
        call readNum
        ; number of lists => the getinput loop is repeated [n] times
        mov [n], rax
        mov rcx, [n]
        mov r15, [n]
        mov r15, arr
        xor r12,r12
        cmp r12, [n]
        je ex
        ; r12 is the counter, it gets increased until it reaches rcx (which is equal to [n])
        xor r14, r14
    getinput:
        cmp r12, rcx
        je ex
        xor r14, r14
        inc r12 ; counter
        mov rax, r12
        call readNum
        ; This input is the length of the r12 th list
        mov [len], rax
        ; if the length is 0, we're done with this list --> move on to the next list
        cmp rax, r14
        je getinput
        ; storing the first number in r9
        mov r8,[len]
        ; r9 is the counter of input_loop
        xor r9, r9
        ; get input array
        mov r10, arr ; r10 points to arr
        input_loop:
            call readNum
            ; adding the array elements to arr, by r10 which points to arr
            mov [r10 + r9*8], rax
            ;push parameter (pass by val)
            push rax
            inc r9
            cmp r8,r9 ; [len] is stored in r8
            jne input_loop
        ; Push the top parameter which is the array length 
        ; push len 
        mov r13, [len]
        push r13
        ;the ith array is ready to get multiplied
        call mult
        ; print result for the current list
        mov rax, [res]
        call writeNum
        call newLine
        cmp r12, rcx ; check if we got input [n] lists so far (rcx == [n])
        jne getinput
        jmp exit
       
        
mult:
    push rbp
    mov rbp, rsp
    xor r14, r14 ; counter
    xor r13, r13 ; to store the length of the current list
    mov r13, [rbp+16] ; len is stored on top of all the list elemenets
    xor rax,rax
    inc rax ; the first element is multiplied by rax so it has to be 1
    multloop:
        inc r14
        mul qword [rbp+16+8*r14] ; [rbp+16] is the length of the current list
        cmp r14, r13 ; r14 is the counter and r13 == [len]
        jne multloop
    mov [res], rax ; the result of multiplications are stored in rax
    pop rbp
    ret 
    
ex:
   call newLine

exit:
    mov rax,1 
    mov rbx,0
    int 0x80 
