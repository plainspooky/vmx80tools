;
;   DDX80reg versão 0.1
;   pasmo -d -v ddx80reg.asm ddx80reg.bin
;
include "../library/msx1bios.asm"
include "../library/msx1variables.asm"

TARGET      equ 0                       ; DDX80
; TARGET      equ 1                       ; VMX-80

if TARGET=0
    ; Monta um binário para o DDX80
    indexReg:   equ $6000
    dataReg:    equ $6001
    screenAddr: equ $7000
else
    ; Monta um binário para o VMX-80
    indexReg:   equ $7000
    dataReg:    equ $7001
    screenAddr: equ $6000
endif


;
;   Configura automaticamente os DEF USR<n> do MSX-BASIC.
;
macro   ____defUser, index, address
            ld hl, address
            ld (USRTAB ##index),hl
            endm

            org $c000-7
            db	$fe
            dw 	start
            dw	stop
            dw	exec
start:
;
;   área de trabalho
;
mc6845RegTable:
            ds 16, $00

;
;   valores padrão
;
mc6845Registers:
            db 0x71                     ; Horizontal Total = 113
            db 0x50                     ; Horizontal Displayed = 80
            db 0x58                     ; Sync Position = 88
            db 0x0a                     ; Horizontal Sync Width = 10
            db 0x1f                     ; Vertical Total = 31
            db 0x06                     ; Vertical Total Adjust = 6
            db 0x19                     ; Vertical Displayed = 25
            db 0x1b                     ; Vertical Sync Position = 27
            db 0x00                     ; Interlace Mode = 0
            db 0x07                     ; Max Scan Line Address = 7
            db 0x00                     ; Cursor Start + Blink (bit 5) = 0
            db 0x08                     ; Cursor End (scanline) = 8
            db 0x00                     ; Start Address (Hi)
            db 0x00                     ; Start Address (Lo) = 0x0000
            db 0x00                     ; Cursor (Hi)
            db 0x00                     ; Cursor (Lo) = 0x0000


mc6845reg:
            db 0                        ; registrador a ser alterado
mc6845value:
            db 0                        ; valor a ser utilizado

slotID:                                 ; identificação do slot onde o
            db 2                        ; cartão de 80 colunas está
                                        ; conectado.
exec:
            proc
        ____defUser "0", resetRegisters
        ____defUser "1", mainMenu
        ____defUser "2", displayRegisters
        ____defUser "3", updateRegister
        ____defUser "4", printCharset

            call resetRegisters         ; copia os registradores

            ret                         ; retorna ao MSX-BASIC

;
;   Copia os valores padrão dos registradores do MC6845 para a área
;   de trabalho.
;
resetRegisters:
            ld bc,16                    ; registradores a copiar
            ld de,mc6845RegTable        ; de...
            ld hl,mc6845Registers       ; ...para
            ldir
            ret                         ; sai da rotina


;
;   Menu principal do programa
;
mainMenu:
            proc

            ld bc,40*24                 ; tamanho da tela
            ld de,0                     ; posição da VRAM
            ld hl,mainMenuData          ; dados do menu do programa
            call LDIRVM                 ; copia o menu para a tela

            call KILBUF                 ; limpa o buffer do teclado

            ret                         ; sai da rotina
            endp


;
;   Exibe o valor dos registadores do MC6845 em hexadecimal.
;
displayRegisters:
            proc
            local displayRegsLoop
            local valueBuffer

            ld b,16                     ; número de registradores
            ld de,mc6845RegTable        ; registrador na memória
            ld hl,3*40+33               ; registrador na tela

    displayRegsLoop:
            push bc                     ; salva 'BC'
            push hl                     ; salva 'HL'

            ld a,(de)                   ; lê valor do registrador
            call byteToHex              ; converte para hexa (ASCII)
            ld (valueBuffer),hl         ; salva a string na memória
            pop hl                      ; recupera 'HL'

            ld a,(valueBuffer)          ; recupera o Hi
            call WRTVRM                 ; escreve na VRAM

            inc hl                      ; incrementa 'HL'
            ld a,(valueBuffer+1)        ; recupera o Lo
            call WRTVRM                 ; escreve na VRAM

            ld bc,39                    ; aponta para a próxima linha
            add hl,bc                   ; da tela

            inc de                      ; próximo registrador

            pop bc                      ; recupera 'BC'

            djnz displayRegsLoop        ; se 'B' != 0, faz o laço

            ret

    valueBuffer:
            db '--'

            endp


;
;   Atualiza um registrador específico.
;
updateRegister:
            proc
            ld a,(mc6845reg)            ; lê o registrador a alterar
            ld e,a                      ; coloca em 'E'

            ld a,(slotID)               ; localização da DDX80
            ld hl,indexReg              ; índide do registrador
            call WRSLT                  ; escreve na RAM do cartucho

            ld a,(mc6845value)          ; valor a ser escrito
            ld e,a                      ; coloca em 'E'

            ld a,(slotID)               ; localização da DDX80
            ld hl,dataReg               ; valor do registrador
            call WRSLT                  ; escreve na RAM do cartucho

            ret                         ; sai da rotina
            endp

;
;   Imprime a tabela ASCII na RAM da DDX80.
;
printCharset:
            proc
            local printCharset0


            ld bc,2048                  ; quantidade de bytes a copiar
            ld e,0                      ; ASCII 0
            ld hl,screenAddr            ; começo da memória de video
printCharset0:
            push bc                     ; salva 'BC'

            ld a,(slotID)               ; localização da DDX80
            call WRSLT                  ; escreve na RAM do cartucho

            inc e                       ; incrementa valor ASCII
            inc hl                      ; incremenata a memória de vídeo

            pop bc                      ; recupera 'BC'
            dec bc                      ; decrementa 'BC'
            ld a,b                      ; 'A' = 'B'
            or c                        ; 'A' or 'C'
            jr nz,printCharset0         ; se A or C != 0, faz o laço

            ret                         ; sai da rotina
            endp


;
;   Converte 'A' em um número em hexadecimal em ASCII armazenado em 'HL'
;
byteToHex:
            proc
            local hexTable
            local _first, _second

            ld h,a                      ; salva o valor de 'A' em 'H'
            ld ix,hexTable              ; aponta em 'IX' o array de caracteres

			srl a						; .xxxx...    rotaciona 'A' para
			srl a						; ..xxxx..    pegar só os 4-bits
			srl a						; ...xxxx.    mais significativos
			srl a						; ....xxxx    dele.

            ld (_first+2),a            ; alteao o 'IX+1' que está abaixo
    _first:
            ld a,(ix+1)                 ; o 1 é apenas pra referência
            ld l,a                      ; e salva este sujeito em 'L'

            ld a,h                      ; recupera o 'A' previamente salvo e
            and 0x0f                    ; descarta os 4-bits mais significativos

            ld (_second+2),a           ; altera o 'IX+1' que está abaixo
    _second:
            ld a,(ix+1)                 ; o 1 é apenas para referência
            ld h,a                      ; e salva este sujeito em 'H'

            ret                         ; sai da rotina
hexTable:
            db "0123456789ABCDEF"
            endp


mainMenuData:
            db $18
            ds 38,$17
            db $19

            db $16,"    DDX80/VMX80 : MC6845 Registers    ",$16
            db $16,"                                      ",$16
            db $16,"   #0  Horizontal Total        [  ]   ",$16
            db $16,"   #1  Horizontal Displayed    [  ]   ",$16
            db $16,"   #2  Sync Position           [  ]   ",$16
            db $16,"   #3  Horizontal Sync Width   [  ]   ",$16
            db $16,"   #4  Vertical Total          [  ]   ",$16
            db $16,"   #5  Vertical Total Adjust   [  ]   ",$16
            db $16,"   #6  Vertical Displayed      [  ]   ",$16
            db $16,"   #7  Vertical Sync Position  [  ]   ",$16
            db $16,"   #8  Interlace Mode          [  ]   ",$16
            db $16,"   #9  Max Scan Line Address   [  ]   ",$16
            db $16,"   #A  Cursor Start + Blink    [  ]   ",$16
            db $16,"   #B  Cursor End (scanline)   [  ]   ",$16
            db $16,"   #C  Start Address (Hi)      [  ]   ",$16
            db $16,"   #D  Start Address (Lo)      [  ]   ",$16
            db $16,"   #E  Cursor (Hi)             [  ]   ",$16
            db $16,"   #F  Cursor (Lo)             [  ]   ",$16
            db $16,"                                      ",$16
            db $16," Use: <up> and <down> to move, <left> ",$16
            db $16," and <right> to change, <spc> to set, ",$16
            db $16," <slct> to default and <esc> to exit. ",$16

            db $1a
            ds 38,$17
            db $1b

stop:
            endp
