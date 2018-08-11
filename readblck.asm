;
;   READBLCK.ASM
;   pasmo -d -v readblck.asm readblck.bin
;

RDSLT:      equ 0x000c

slotID:     equ 2                       ; cartucho no slot 2

            org 0x9000-7
            proc

            db	0xfe                    ; arquivo binário do MSX-BASIC
            dw 	start
            dw	stop
            dw	exec
start:
exec:
            ld bc,0x2000                ; tamanho do block (8192 bytes)
            ld de,0xa000                ; endereço de destino
            ld hl,0x4000                ; endereço de origem
loop:
            push bc                     ; salva 'BC' na pilha
            push de                     ; salva 'DE' na pilha

            ld a,slotID                 ; slot a ser lido
            call RDSLT                  ; lê endereço 'HL' no slot.

            pop de                      ; recupera 'DE' da pilha
            pop bc                      ; recupera 'BC' da pilha

            ld (de),a                   ; salva o valor de 'A' no
                                        ; endereço apontado por 'DE'

            dec bc                      ; decrementa 'BC'
            inc de                      ; incrementa 'DE'
            inc hl                      ; incrementa 'HL'

            ld a,b                      ; 'A' = 'B'
            or c                        ; 'A' = 'A' or 'C'
            cp 0                        ; compara com zero
            jr nz, loop                 ; se != 0, vá para "loop"

            ret                         ; sai do programa
stop:
            endp
