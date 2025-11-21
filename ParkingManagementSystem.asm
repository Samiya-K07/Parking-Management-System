.model small
.stack 100h

.data

; ---------- Messages ----------
menu db 'MENU$'
menu1 db 'Press 1 for Rikshaw$'
menu2 db 'Press 2 for Car$'
menu3 db 'Press 3 for Bus$'
menu4 db 'Press 4 to Show All Records$'
menu5 db 'Press 5 to Delete a Record (0 = All)$'
menu6 db 'Press 6 to Exit$'

msg1 db 'Parking Is Full!!$'
msg2 db 'Wrong Input!!$'
msg3 db 'The Total Amount Is = $'
msg4 db 'The Total Numbers Of Vehicles Parked = $'
msg5 db 'The Total Number Of Rikshaws Parked = $'
msg6 db 'The Total Number Of Cars Parked = $'
msg7 db 'The Total Number Of Buses Parked = $'
msg8 db '*Record Deleted Successfully*$'

msg_empty db 'Empty Slot!!$'
msg_idx db 'Enter record index (1-8) or 0 to delete ALL: $'

msg_notfound db 'No record at that index!!$'
msg_rik_fare db 'Parking Fare for Rikshaw = $'
msg_car_fare db 'Parking Fare for Car = $'
msg_bus_fare db 'Parking Fare for Bus = $'

; ---------- Constants ----------
MAX_VEHICLES equ 8

; ---------- Storage for records ----------
vehicleType db MAX_VEHICLES dup('?')
vehicleFare dw MAX_VEHICLES dup(0)

; Totals & counters
amount dw 0
count db 0
rcount db 0
ccount db 0
bcount db 0

.code

; ---------------- PrintNewline Proc ----------------
PrintNewline proc
    push ax
    push dx
    mov dl, 10
    mov ah, 02h
    int 21h
    mov dl, 13
    mov ah, 02h
    int 21h
    pop dx
    pop ax
    ret
PrintNewline endp

main proc
    mov ax, @data
    mov ds, ax

while_:
    call PrintNewline
    
    ; print menu
    mov dx, offset menu
    mov ah, 09h
    int 21h
    call PrintNewline

    mov dx, offset menu1
    mov ah, 09h
    int 21h
    call PrintNewline
    
    mov dx, offset menu2
    mov ah, 09h
    int 21h
    call PrintNewline
    
    mov dx, offset menu3
    mov ah, 09h
    int 21h
    call PrintNewline
    
    mov dx, offset menu4
    mov ah,09h
    int 21h
    call PrintNewline
    
    mov dx, offset menu5
    mov ah,09h
    int 21h
    call PrintNewline
    
    mov dx, offset menu6
    mov ah,09h
    int 21h
    call PrintNewline

    ; user input
    mov ah, 01h
    int 21h
    mov bl, al
    
    call PrintNewline
    
    mov al, bl
    
    cmp al, '1'
    je rikshw
    
    cmp al, '2'
    je car
    
    cmp al, '3'
    je bus
    
    cmp al, '4'
    je shwrec
    
    cmp al,'5'
    je delrec
    
    cmp al,'6'
    je end_

    ; invalid input
    mov dx, offset msg2
    mov ah,09h
    int 21h
    call PrintNewline
    jmp while_

; ---------------- vehicle menu labels ----------------
rikshw:
    mov al, 'R'
    mov bx, 200
    call AddVehicle
    jmp while_

car:
    mov al, 'C'
    mov bx, 300
    call AddVehicle
    jmp while_

bus:
    mov al, 'B'
    mov bx, 400
    call AddVehicle
    jmp while_

shwrec:
    call ShowRecords
    jmp while_

delrec:
    call DeleteRecord
    jmp while_

end_:
    mov ah, 4Ch
    int 21h

main endp

; ---------------- PrintNumber ----------------
PrintNumber proc
    cmp ax, 0
    jne pn_nonzero
    mov dl, '0'
    mov ah, 02h
    int 21h
    ret

pn_nonzero:
    push bp
    mov bp,sp
    push ax
    push bx
    push cx
    push dx
    mov cx,0
    mov bx, 10
    
pn_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne pn_loop

pn_print:
    pop dx
    add dl,'0'
    mov ah, 02h
    int 21h
    loop pn_print

    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret
PrintNumber endp

; ---------------- AddVehicle ----------
; Input:
;   AL = 'R'/'C'/'B' (type)
;   BX = fare (word)

AddVehicle proc
    push ax
    push bx
    push si
    push di
    push cx
    
    ; Check capacity
    mov cl, count
    cmp cl, MAX_VEHICLES
    jae add_full

    ; Find first empty slot
    xor si,si
find_slot:
    mov dl, [vehicleType + si]
    cmp dl, '?'
    je slot_found
    inc si
    cmp si, MAX_VEHICLES
    jb find_slot
    jmp add_full

slot_found:
    ; Store type
    mov [vehicleType + si], al
    
    ; Store fare
    push bx
    mov di, si
    shl di, 1
    pop bx
    mov [vehicleFare + di], bx
    
    ; Update total amount
    mov dx, amount
    add dx, bx
    mov amount, dx
    
    ; Increment counts
    inc count
    cmp al, 'R'
    je inc_rcount
    cmp al, 'C'
    je inc_ccount
    inc bcount
    jmp av_print

inc_rcount:
    inc rcount
    jmp av_print
    
inc_ccount:
    inc ccount

av_print:
    ; Print label based on type
    cmp al, 'R'
    je print_rik_label
    cmp al, 'C'
    je print_car_label
    mov dx, offset msg_bus_fare
    jmp print_label_and_fare

print_rik_label:
    mov dx, offset msg_rik_fare
    jmp print_label_and_fare

print_car_label:
    mov dx, offset msg_car_fare

print_label_and_fare:
    push ax
    mov ah,09h
    int 21h
    pop ax
    
    ; Print fare
    mov ax, bx
    call PrintNumber
    call PrintNewline

av_done:
    pop cx
    pop di
    pop si
    pop bx
    pop ax
    ret

add_full:
    mov dx, offset msg1
    mov ah,09h
    int 21h
    call PrintNewline
    pop cx
    pop di
    pop si
    pop bx
    pop ax
    ret

AddVehicle endp

; ---------------- ShowRecords ----------------
ShowRecords proc
    push ax
    push bx
    push cx
    push dx
    push si

    ; Print totals
    mov dx, offset msg3
    mov ah,09h
    int 21h
    mov ax, amount
    call PrintNumber
    call PrintNewline

    mov dx, offset msg4
    mov ah,09h
    int 21h
    xor ax, ax
    mov al, count
    call PrintNumber
    call PrintNewline
    
    mov dx, offset msg5
    mov ah, 09h
    int 21h
    xor ax, ax
    mov al, rcount
    call PrintNumber
    call PrintNewline
    
    mov dx, offset msg6
    mov ah, 09h
    int 21h
    xor ax, ax
    mov al, ccount
    call PrintNumber
    call PrintNewline
    
    mov dx, offset msg7
    mov ah, 09h
    int 21h
    xor ax, ax
    mov al, bcount
    call PrintNumber
    call PrintNewline

    call PrintNewline
    
    ; Print each record
    xor si, si
sr_loop:
    ; Print index (1-based)
    mov ax, si
    inc ax
    call PrintNumber
    mov dl, ':'
    mov ah,02h
    int 21h
    mov dl,' '
    mov ah,02h
    int 21h

    mov al, [vehicleType + si]
    cmp al, '?'
    je sr_empty

    ; Print type (R/C/B)
    mov dl, al
    mov ah,02h
    int 21h
    mov dl,' '
    mov ah,02h
    int 21h

    ; Print fare
    mov bx, si
    shl bx,1
    mov ax, [vehicleFare + bx]
    call PrintNumber
    call PrintNewline
    jmp sr_next

sr_empty:
    mov dx, offset msg_empty
    mov ah,09h
    int 21h
    call PrintNewline

sr_next:
    inc si
    cmp si, MAX_VEHICLES
    jb sr_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ShowRecords endp

; ---------------- DeleteRecord ----------------
DeleteRecord proc
    push ax
    push bx
    push cx
    push dx
    push si

    mov dx, offset msg_idx
    mov ah,09h
    int 21h

    mov ah,01h
    int 21h
    call PrintNewline
    sub al,'0'
    mov cl, al

    cmp cl, 0
    je del_all

    ; Validate range
    cmp cl, MAX_VEHICLES
    ja del_invalid
    
    ; Index = cl - 1
    dec cl
    xor ch, ch       ; Clear CH to make CX = CL
    mov si, cx

    ; Check if slot has record
    mov al, [vehicleType + si]
    cmp al, '?'
    je del_no_record
    
    ; Save vehicle type
    mov dl, al
    
    ; Subtract fare from amount
    mov bx, si
    shl bx,1
    mov ax, [vehicleFare + bx]
    
    mov cx, amount
    sub cx, ax
    mov amount, cx

    ; Decrement counters based on type
    cmp dl, 'R'
    je dec_r
    cmp dl, 'C'
    je dec_c
    dec bcount
    jmp del_cleanup

dec_r:
    dec rcount
    jmp del_cleanup
    
dec_c:
    dec ccount

del_cleanup:
    dec count
    
    ; Clear slot
    mov [vehicleType + si], '?'
    mov bx, si
    shl bx,1
    mov word ptr [vehicleFare + bx], 0

    mov dx, offset msg8
    mov ah,09h
    int 21h
    call PrintNewline
    jmp del_done

del_no_record:
    mov dx, offset msg_notfound
    mov ah,09h
    int 21h
    call PrintNewline
    jmp del_done

del_invalid:
    mov dx, offset msg2
    mov ah,09h
    int 21h
    call PrintNewline
    jmp del_done

del_all:
    xor si,si
delall_loop:
    mov [vehicleType + si], '?'
    mov bx, si
    shl bx, 1
    mov word ptr [vehicleFare + bx], 0
    inc si
    cmp si, MAX_VEHICLES
    jb delall_loop

    mov amount, 0
    mov count, 0
    mov rcount, 0
    mov ccount, 0
    mov bcount, 0

    mov dx, offset msg8
    mov ah,09h
    int 21h
    call PrintNewline

del_done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DeleteRecord endp

end main