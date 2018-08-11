;
;   READDATA.ASM
;   pasmo -d -v readdata.asm readdata.bin
;

RDSLT:      equ 0x000c
CHPUT:	    equ 0x00a2

slotID:     equ 2                       ; cartucho no slot 2


            org 0x9000-7
            proc

            db	0xfe                     ; arquivo binário do MSX-BASIC
            dw 	start
            dw	stop
            dw	exec
start:
exec:
            ld hl,0x4000                ; endereço de origem
            ld b,0                      ; 256 bytes para ler
loop:
            push bc                     ; salva 'BC' na pilha
            ld a,slotID                 ; slot a ser lido
            call RDSLT                  ; lê endereço 'HL' no slot.

            cp 32                       ; compara 'A' com 32
            jr nc, print                ; se a>=32, vai para a "print"
            ld a,"."                    ; muda 'A' para "."
print:
            call CHPUT                  ; escreve o caractere na tela

            pop bc                      ; recupera 'BC' da pilha
            inc hl                      ; incrementa 'HL'
            djnz loop                   ; 'B'--, se 'B'>0 vá para "loop"

            ret                         ; sai do programa
stop:
            endp
