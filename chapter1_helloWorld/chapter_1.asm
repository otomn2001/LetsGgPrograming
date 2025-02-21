;========================================
 ; 1.WLA-DX バンク設定
;========================================
 .memorymap
    defaultslot 0
    slotsize $8000
    slot 0 $0000
 .endme

 .rombankmap
    bankstotal 1
    banksize $8000
    banks 1
.endro

;;========================================
; 2.変数定義
;========================================
.define VDPControl $bf
.define VDPData $be
.define VRAMWrite $4000
.define CRAMWrite $c000

;========================================
; 3.SDSCタグ　SMSロムヘッダー
;========================================
.sdsctag 0.1,"Hello World!", "GG Programing Tutorial 1","SEGA-YAROW"

;========================================
; 4.バンク指定
;========================================
.bank 0 slot 0

.org $0000
;========================================
; 5.割り込みモードの指定
;========================================
    di
    im 1
    jp main

.org $0066
;========================================
; 6.ポーズボタン制御
;========================================
    ;割り込み時になにもしない
    retn

;========================================
; 7.プログラム本体
;========================================
main:
    ld sp, $dff0    ; スタックポインタ初期化

    ;======================================== 
    ; VDP設定
    ;======================================== 
    ld hl, VDPInitData
    ld b, VDPInitDataEnd-VDPInitData
    ld c, VDPControl
    otir

    ;======================================== 
    ; VRAMを初期化
    ;======================================== 
    ld hl, $0000 | VRAMWrite    ; VRAMの先頭アドレスをVRAMへセット
    call SetVDPAddress
    
    ld bc, $4000 ;16KBをクリア
clear_vram:
    xor a
    out (VDPData), a
    dec bc
    ld a, b
    or c
    jr nz, clear_vram

    ;======================================== 
    ; パレットデータの書き込み
    ;======================================== 
    ld hl, $0000 | CRAMWrite        ; パレットデータの先頭アドレスをVRAMへセット
    call SetVDPAddress

    ld hl, PaletteData      ; パレットデータの書き込み
    ld bc, PaletteDataEnd-PaletteData
    call CopyToVDP

    ;======================================== 
    ; タイルパターンを書き込み（フォント）
    ;======================================== 
    ld hl, $0000 | VRAMWrite       ; タイルパターンの先頭アドレスをVRAMへセット
    call SetVDPAddress

    ld hl, FontData     ; タイルパターンの書き込み
    ld bc, FontDataSize
    call CopyToVDP

    ;==============================================================
    ; ネームテーブルの書き込み
    ;==============================================================
    ld hl,$3AD4 | VRAMWrite      ; ネームテーブルのアドレス3AD64をVRAMへセット（真ん中あたり）
    call SetVDPAddress

    ld hl, Message      ; ネームテーブルを書き込み
write_nametable:
    ld a, (hl)
    cp $ff
    jr z, end_nametable
    out (VDPData), a
    xor a
    out (VDPData), a
    inc hl
    jr write_nametable

end_nametable:

    ;========================================
    ; スクリーン起動
    ;========================================
    ld a, %01000000
;           ||||||`- ズームスプライト -> 16x16 pixels
;           |||||`-- ダブルスプライト -> １スプライトにつき2タイル利用（8x16）
;           ||||`--- メガドライブモード
;           |||`---- 30 row/240 ラインモード
;           ||`----- 28 row/224 ラインモード
;           |`------ VBlank 割り込み
;           `------- ディスプレイ起動

    out (VDPControl), a
    ld a, $81
    out (VDPControl), a

    ; プログラム停止ループ
-:  jr -

;==============================================================
; 補助関数
;==============================================================
SetVDPAddress:
; VDPアドレスをセットします
; パラメータ： hl = アドレス
    push af
    ld a, l
    out (VDPControl), a
    ld a, h
    out (VDPControl), a
    pop af
    ret

CopyToVDP:
; VDPへデータを書き込み
; パラメータ：　hl = データのアドレス、bc = データ長
; a, hl, bcに設定 
copy_loop:
    ld a, (hl)          ;アドレス内のデータを取得
    out (VDPData), a
    inc hl              ;次のアドレスへ
    dec bc
    ld a, b
    or c
    jr nz, copy_loop
    ret

;==============================================================
; Data
;==============================================================

Message:
    .db "H", "E", "L", "L", "O", ","
    .db "W", "O", "R", "L", "D", "!"
    .db $ff

PaletteData:
    .dw $fff, $000        ; 白と黒
PaletteDataEnd:

;VDPの設定データ
VDPInitData:
    .db $04,$80,$00,$81,$ff,$82,$ff,$85,$ff,$86,$ff,$87,$00,$88,$00,$89,$ff,$8a
VDPInitDataEnd:

FontData:
.incbin "chardata.bin" fsize FontDataSize