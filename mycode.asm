.model small
.stack 
.data
array db 100
NumStr db 4,0,4 dup(0) 
.code
start:
mov ax,@data
mov ds,ax

;push offset array
call EnterNumber
;loop input
exit:
        mov ah,4ch
        int 21h
 
proc EnterNumber
        push bp
        mov bp,sp
 
        lea dx,NumStr
        mov ah,0ah
        int 21h
 
        pop bp
        ret ; maybe a change will be required
        endp
  
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

        ; check for minus:
        cmp     al, '-'
        je      set_minus

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

