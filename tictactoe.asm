bits 64

%macro write 1-2 1
    mov rax, 1  ; use "write" syscall
    mov rdi, 1  ; stdout
    mov rsi, %1 ; string
    mov rdx, %2 ; length
    syscall
%endmacro

section .text
    global _start
_start:
    ; game loop
    make_move:
        call draw_board
        call draw_prompt
        call get_move
        call update_game_status
    mov al, [game_state]
    cmp al, 0
    je make_move

    ; exit with 0 exit code
    mov rax, 60
    xor rdi, rdi
    syscall

draw_board:
    mov rcx, 9
    idx:
        push rcx
    loop idx

    ; move cursor back except first time
    mov al, [should_move_cursor]
    cmp al, 1
    jne dont_move_cursor
        write clear, clear_len                
    dont_move_cursor:
    mov byte [should_move_cursor], 1

    write board_line_empty, board_width   ;      |     |
    call print_board_line_played          ;   X  |  X  |  X
    write board_line_divider, board_width ; _____|_____|_____
    write board_line_empty, board_width   ;      |     |
    call print_board_line_played          ;   X  |  X  |  X
    write board_line_divider, board_width ; _____|_____|_____
    write board_line_empty, board_width   ;      |     |
    call print_board_line_played          ;   X  |  X  |  X
    write board_line_empty, board_width   ;      |     |     
    write line_break
ret

draw_prompt:
    write move_msg1, move_msg1_len

    ; get number of player to move right now
    mov al, [player_to_move]
    add al, '0'
    mov [tmp_buf], al
    write tmp_buf

    write move_msg2, move_msg2_len
    write clear_prompt, clear_prompt_len
    write prompt, prompt_len
ret

print_board_line_played:
    pop r9
    write boarder_gap, boarder_gap_len
    call choose_symbol
    write tmp_buf
    write middle_gap, middle_gap_len
    call choose_symbol
    write tmp_buf
    write middle_gap, middle_gap_len
    call choose_symbol
    write tmp_buf
    write line_break
    push r9
ret

choose_symbol:
    pop r10
    pop rax
    mov bl, [board + rax - 1]
    cmp bl, 0
    je square_empty
    cmp bl, 1
    je square_1
    square_2:
        mov al, [player_2]
        mov [tmp_buf], al
        jmp done
    square_1:
        mov al, [player_1]
        mov [tmp_buf], al
        jmp done
    square_empty:
        add rax, '0'
        mov [tmp_buf], rax
    done:
        push r10
ret

get_move:
    xor rax, rax         ; use "read" syscall
    xor rdi, rdi         ; stdin
    mov rsi, tmp_buf     ; buffer
    mov rdx, tmp_buf_len ; length
    syscall

    ; exit on ctrl-D with exit code 130 (SIGINT)
    cmp rax, 0
    jne read_successfully
        write line_break
        mov rax, 60
        mov rdi, 130
        syscall
    read_successfully:

    movzx rbx, byte [tmp_buf] ; move first byte of tmp_buf and zero other bits
    sub rbx, '0'              ; convert char to int basically

    cmp rbx, 1
    jl incorrect_input ; if less than 1
    cmp rbx, 9
    jg incorrect_input ; if greater than 9
    mov al, byte [board + rbx - 1]
    cmp al, 0
    jne incorrect_input ; if chosen square is already taken
    jmp correct_input
    incorrect_input:
        ; write clear, clear_len
        call draw_board
        call draw_prompt
        jmp get_move
    correct_input:

    mov al, [player_to_move]
    cmp al, 2
    je player2_to_move
    player1_to_move:
        mov byte [board + rbx - 1], 1
        jmp move
    player2_to_move:
        mov byte [board + rbx - 1], 2
    move:
        xor byte [player_to_move], 3 ; toggle player_to_move between 1 and 2
ret

update_game_status:

ret

section .bss
    tmp_buf: resb 256
    tmp_buf_len: equ $ - tmp_buf
    board: resb 9 ; reserve 9 bytes for 9 squares on the board
                  ; 0 - empty
                  ; 1 - x
                  ; 2 - o
section .data
    should_move_cursor: db 0
    game_state: db 0 ;  0 - playing,
                     ; -1 - draw,
                     ;  1 - player1 won,
                     ;  2 - player2 won
    player_to_move: db 1 ; 1 - player_1 to move
                         ; 2 - player_2 to move
section .rodata
    clear: db `\033[12A`
    clear_len: equ $ - clear
    line_break: db 10

    player_1: db "X"
    player_2: db "O"
    move_msg1: db "Player "
    move_msg1_len: equ $ - move_msg1
    move_msg2: db " to move (enter any empty square):", 10
    move_msg2_len: equ $ - move_msg2
    prompt: db "> "
    prompt_len: equ $ - prompt
    clear_prompt: db `                 \r` ; TODO: better way to clear a line
    clear_prompt_len: equ $ - clear_prompt

    boarder_gap: db "  "
    boarder_gap_len: equ $ - boarder_gap
    middle_gap: db "  |  "
    middle_gap_len: equ $ - middle_gap
    board_line_divider: db "_____|_____|_____", 10
    board_line_empty:   db "     |     |     ", 10
    board_width: equ $ - board_line_empty

