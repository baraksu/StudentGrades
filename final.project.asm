.model small
.stack 
.data
var2  db 41
var1  db 40 
 
                                                                          
LG db 13,10,'         _____ _             _            _    _____               ',13,10           
 db '        / ____| |           | |          | |  / ____|             | |             ',13,10
 db '       | (___ | |_ _   _  __| | ___ _ __ | |_| |  __ _ __ __ _  __| | ___  ___    ',13,10
 db '        \___ \| __| | | |/ _` |/ _ \ '_ \| __| | |_ | '__/ _` |/ _` |/ _ \/ __|    ',13,10
 db '        ____) | |_| |_| | (_| |  __/ | | | |_| |__| | | | (_| | (_| |  __/\__ \   ',13,10
 db '       |_____/ \__|\__,_|\__,_|\___|_| |_|\__|\_____|_|  \__,_|\__,_|\___||___/   ',13,10, '$'
                                                                         
                                                                         
                                                                         

msg1  db "supported values from -32768 to 65535", 0Dh,0Ah ; the valid range
nsg2  db "enter the number of grades: $" ; asking for a number of grades
msg3  db "enter the grade $" ; asking for the grades
msg4  db " the avg is: $"    ; presenting the average 
msg5  db  " invalid $"
sum   dw 0 ; the sum of the grades together 
enter db 13,10,'$'; dropping a line 
temp  dw 0 ; to hold the number of grades so i can do an average with it
Avg   db 0 ; average
.code

                                                                                                                                                          
mov ax,@data
mov ds,ax
xor ax,ax

lea dx,LG
mov ah,09
int 21h 

 
TryAgain:
    xor cx,cx


start:
; print the message1:
mov dx, offset msg1
mov ah, 9
int 21h




call scan_num ; get the number to cx.(the code was taken from the examples im emu8086)(Tobin.asm)   
mov temp,cx
lea dx,enter
mov ah,9
int 21h


 
gradeLoop:
    push cx
    
    ; print the message3:
    mov dx, offset msg3
    mov ah, 9
    int 21h
    
    call scan_num
    add sum,cx
    pop cx 
    lea dx,enter
    mov ah,9
    int 21h
    loop gradeLoop 
    
    
    
XOR DX,DX    
mov AX,sum
div temp
    
; prints the average
call print_ax 
mov bx,dx
mov dl,var1
mov ah,02
int 21h
mov dx,bx
mov ax,dx 
call print_ax
mov dl,var2
mov ah,02
int 21h

mov bx, cx


                                 
; wait for any key....
mov ah, 0
int 16h 


mov ah,4ch
int 21h





; this macro prints a char in al and advances the current cursor position:
putc    macro   char
        push    ax
        mov     al, char
        mov     ah, 0eh
        int     10h     
        pop     ax
endm

; this procedure gets the multi-digit signed number from the keyboard,
; and stores the result in cx register:
scan_num        proc    near
        push    dx
        push    ax
        push    si
        
        mov     cx, 0

        ; reset flag:
        mov     cs:make_minus, 0

next_digit:

        ; get char from keyboard
        ; into al:
        mov     ah, 00h
        int     16h
        ; and print it:
        mov     ah, 0eh
        int     10h

        ; check for minus: if minus then invalid
        cmp     al, '-'
        je   invalid

        ; check for enter key:
        cmp     al, 13  ; carriage return?
        jne     not_cr
        jmp     stop_input
not_cr:


        cmp     al, 8                   ; 'backspace' pressed?
        jne     backspace_checked
        mov     dx, 0                   ; remove last digit by
        mov     ax, cx                  ; division:
        div     cs:ten                  ; ax = dx:ax / 10 (dx-rem).
        mov     cx, ax
        putc    ' '                     ; clear position.
        putc    8                       ; backspace again.
        jmp     next_digit
backspace_checked:


        ; allow only digits:
        cmp     al, '0'
        jae     ok_ae_0
        jmp     remove_not_digit
ok_ae_0:        
        cmp     al, '9'
        jbe     ok_digit
remove_not_digit:       
        putc    8       ; backspace.
        putc    ' '     ; clear last entered not digit.
        putc    8       ; backspace again.        
        jmp     next_digit ; wait for next input.       
ok_digit:


        ; multiply cx by 10 (first time the result is zero)
        push    ax
        mov     ax, cx
        mul     cs:ten                  ; dx:ax = ax*10
        mov     cx, ax
        pop     ax

        ; check if the number is too big
        ; (result should be 16 bits)
        cmp     dx, 0
        jne     too_big

        ; convert from ascii code:
        sub     al, 30h

        ; add al to cx:
        mov     ah, 0
        mov     dx, cx      ; backup, in case the result will be too big.
        add     cx, ax
        jc      too_big2    ; jump if the number is too big. 
        
        
        cmp  cx,'A'
        je   TryAgain
        cmp  cx,0
        je   invalid
                
        jmp     next_digit

set_minus:
        mov     cs:make_minus, 1
        jmp     next_digit

too_big2:
        mov     cx, dx      ; restore the backuped value before add.
        mov     dx, 0       ; dx was zero before backup!
too_big:
        mov     ax, cx
        div     cs:ten  ; reverse last dx:ax = ax*10, make ax = dx:ax / 10
        mov     cx, ax
        putc    8       ; backspace.
        putc    ' '     ; clear last entered digit.
        putc    8       ; backspace again.        
        jmp     next_digit ; wait for enter/backspace.
        
        
stop_input:
        ; check flag:
        cmp     cs:make_minus, 0
        je      not_minus
        neg     cx
not_minus:

        pop     si
        pop     ax
        pop     dx
        ret
make_minus      db      ?       ; used as a flag.
ten             dw      10      ; used as multiplier. 
scan_num        endp 
 
invalid:
    lea dx,enter
    mov ah,9
    int 21h 
    lea dx, msg5 
    mov ah,09
    int 21h
    mov ah,4ch
    int 21h    

 print_ax proc   ; this procedure
;prints ax from hex to dec
cmp ax, 0
jne print_ax_r
push ax
mov al, '0'
mov ah, 0eh
int 10h
pop ax
ret
print_ax_r:
pusha
mov dx, 0
cmp ax, 0
je pn_done
mov bx, 10
div bx
call print_ax_r
mov ax, dx
add al, 30h
mov ah, 0eh
int 10h
jmp pn_done
pn_done:
popa
ret
endp print_ax
