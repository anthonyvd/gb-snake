INCLUDE  "hardware.inc"

DEF HEAD_X 		  EQU $C000
DEF HEAD_Y 		  EQU $C001
DEF FRAME_COUNTER EQU $C002

DEF HEAD 		  EQU $C003 ; 2 bytes
DEF TAIL 		  EQU $C005 ; 2 bytes

DEF QUEUE		  EQU $D000 ; 360 pairs of bytes -> 0x2D0

DEF BODY_TILE	  EQU $00
DEF EMPTY_TILE	  EQU $08

SECTION "vblank", ROM0[$40]
	jp vblank_handler

SECTION "Header", ROM0[$100]
	
	jp EntryPoint

	ds $150 - @, 0

EntryPoint:
WaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank

	; LCD off
	ld a, 0
	ld [rLCDC], a

	; copy tile data
	ld de, Tiles
	ld hl, $9000
	ld bc, TilesEnd - Tiles
	call memcpy

	; copy tile map
	ld de, Tilemap
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap
	call memcpy

	; Initialize the player position and state
	ld a, 10
	ld [HEAD_X], a
	ld a, 9
	ld [HEAD_Y], a

	ld b, 9
	ld c, 10
	call get_tile_address

	ld a, $00
	ld e, a
	ld [HEAD], a
	ld a, $D0
	ld d, a
	ld [HEAD + 1], a

	ld a, l
	ld [de], a
	ld a, h
	inc de
	ld [de], a 

	ld a, $00
	ld e, a
	ld [TAIL], a
	ld a, $D0
	ld d, a
	ld [TAIL + 1], a

	ld a, [HEAD_Y]
	ld b, a
	ld a, [HEAD_X]
	ld c, a

	call get_tile_address

	ld a, BODY_TILE
	ld [hl], a

	; LCD on
	ld a, LCDCF_ON | LCDCF_BGON
	ld [rLCDC], a

	ld a, %11100100
	ld [rBGP], a

	; Enable VBLANK interrupt
	ld a, IEF_VBLANK
	ld [rIE], a
	ei

loop:
	jp loop

vblank_handler:
	ld a, [FRAME_COUNTER]
	add a, 2
	ld [FRAME_COUNTER], a
	call z, move_player

	reti

move_player:
	ld hl, HEAD_X
	inc [hl]
	call move_head
	call erase_tail
	ret

move_head:
	ld a, [HEAD_Y]
	ld b, a
	ld a, [HEAD_X]
	ld c, a

	call get_tile_address

	ld a, BODY_TILE
	ld [hl], a

	ld a, [HEAD]
	ld e, a
	ld a, [HEAD + 1]
	ld d, a
	inc de
	inc de
	ld a, l
	ld [de], a
	ld a, e
	ld [HEAD], a
	inc de
	ld a, h
	ld [de], a
	ld a, d
	ld [HEAD + 1], a

	ret

erase_tail:
	ld a, [TAIL]
	ld e, a
	ld a, [TAIL + 1]
	ld d, a

	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	ld h, a

	ld a, EMPTY_TILE
	ld [hl], a

	inc de
	ld a, e
	ld [TAIL], a
	ld a, d
	ld [TAIL + 1], a

	ret

; in
; 	b: y
; 	c: x
; out
; 	hl: tile address
get_tile_address:
	ld hl, 0
	ld de, 32
	; rows in the tilemap are 32 tiles wide
	y_offset:
		ld a, 0
		cp a, b
		jp z, x_offset
		add hl, de
		dec b
		jp y_offset

	x_offset:
		; b is 0 here, so BC == C
		add hl, bc

	; add the tilemap base address
	ld bc, $9800
	add hl, bc

	ret

; de: source
; hl: dest
; bc: length
memcpy:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, memcpy
	ret

Tiles:
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33322222
	dw `33322222
	dw `33322222
	dw `33322211
	dw `33322211
	dw `33333333
	dw `33333333
	dw `33333333
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11111111
	dw `11111111
	dw `33333333
	dw `33333333
	dw `33333333
	dw `22222333
	dw `22222333
	dw `22222333
	dw `11222333
	dw `11222333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `22222222
	dw `20000000
	dw `20111111
	dw `20111111
	dw `20111111
	dw `20111111
	dw `22222222
	dw `33333333
	dw `22222223
	dw `00000023
	dw `11111123
	dw `11111123
	dw `11111123
	dw `11111123
	dw `22222223
	dw `33333333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `11001100
	dw `11111111
	dw `11111111
	dw `21212121
	dw `22222222
	dw `22322232
	dw `23232323
	dw `33333333
	; Paste your logo here:
TilesEnd:

Tilemap:
	ds $400, 8
TilemapEnd: