// Copyright (c) 2019 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.

// SDL2 port+wrapper, Twintris-like dual-game logic,
// and more, by Nicolas Sauzede 2019.

module main

import rand
import time
import math
import nsauzede.vsdl2

const (
	Title = 'tVintris'
	FontName = 'RobotoMono-Regular.ttf'
	MusicName = 'sounds/TwintrisThosenine.mod'
	SndBlockName = 'sounds/block.wav'
	SndLineName = 'sounds/single.wav'
	SndDoubleName = 'sounds/triple.wav'
	BlockSize = 20 // pixels
	FieldHeight = 20 // # of blocks
	FieldWidth = 10
	TetroSize = 4
	WinWidth = BlockSize * FieldWidth * 3
	WinHeight = BlockSize * FieldHeight
	TimerPeriod = 250 // ms
	TextSize = 16
	AudioBufSize = 1024

	P2FIRE = C.SDLK_l
	P2UP = C.SDLK_UP
	P2DOWN = C.SDLK_DOWN
	P2LEFT = C.SDLK_LEFT
	P2RIGHT = C.SDLK_RIGHT

	P1FIRE = C.SDLK_s
	P1UP = C.SDLK_w
	P1DOWN = C.SDLK_x
	P1LEFT = C.SDLK_a
	P1RIGHT = C.SDLK_d

	NJOYMAX = 2
	// joystick name => enter your own device name
	JOYP1NAME = 'Generic X-Box pad'
	// following are joystick button number
	JBP1FIRE = 1
	// following are joystick hat value
	JHP1UP = 1
	JHP1DOWN = 4
	JHP1LEFT = 8
	JHP1RIGHT = 3

	// joystick name => enter your own device name
	JOYP2NAME = 'RedOctane Guitar Hero X-plorer'
	// following are joystick button number
	JBP2FIRE = 0
	// following are joystick hat value
	JHP2UP = 4
	JHP2DOWN = 1
	JHP2LEFT = 8
	JHP2RIGHT = 2
)

const (
	// Tetros' 4 possible states are encoded in binaries
	BTetros = [
		// 0000 0
		// 0000 0
		// 0110 6
		// 0110 6
		[66, 66, 66, 66],
		// 0000 0
		// 0000 0
		// 0010 2
		// 0111 7
		[27, 131, 72, 232],
		// 0000 0
		// 0000 0
		// 0011 3
		// 0110 6
		[36, 231, 36, 231],
		// 0000 0
		// 0000 0
		// 0110 6
		// 0011 3
		[63, 132, 63, 132],
		// 0000 0
		// 0011 3
		// 0001 1
		// 0001 1
		[311, 17, 223, 74],
		// 0000 0
		// 0011 3
		// 0010 2
		// 0010 2
		[322, 71, 113, 47],
		// Special case since 15 can't be used
		// 1111
		[1111, 9, 1111, 9],
	]
	// Each tetro has its unique color
	Colors = [
		SdlColor{byte(0), byte(0), byte(0), byte(0)},		// unused ?
		SdlColor{byte(0), byte(0x62), byte(0xc0), byte(0)},	// quad : darkblue 0062c0
		SdlColor{byte(0xca), byte(0x7d), byte(0x5f), byte(0)},	// tricorn : lightbrown ca7d5f
		SdlColor{byte(0), byte(0xc1), byte(0xbf), byte(0)},	// short topright : lightblue 00c1bf
		SdlColor{byte(0), byte(0xc1), byte(0), byte(0)},	// short topleft : lightgreen 00c100
		SdlColor{byte(0xbf), byte(0xbe), byte(0), byte(0)},	// long topleft : yellowish bfbe00
		SdlColor{byte(0xd1), byte(0), byte(0xbf), byte(0)},	// long topright : pink d100bf
		SdlColor{byte(0xd1), byte(0), byte(0), byte(0)},	// longest : lightred d10000
		SdlColor{byte(0), byte(170), byte(170), byte(0)},	// unused ?
	]
)

// TODO: type Tetro [TetroSize]struct{ x, y int }
struct Block {
	mut:
	x int
	y int
}

enum GameState {
        paused running gameover
}

struct AudioContext {
mut:
	music voidptr
	volume int
        waves [3]voidptr
}

struct SdlContext {
pub:
mut:
//      VIDEO
	w		int
	h		int
	window          voidptr
	renderer        voidptr
	screen          &SdlSurface
	texture         voidptr
//      AUDIO
        actx		AudioContext
//	JOYSTICKS
	jnames		[2]string
	jids		[2]int
}

struct Game {
mut:
	// Score of the current game
	score        int
	// Count consecutive lines for scoring
	lines        int
	// State of the current game
	state    GameState
	// X offset of the game display
	ofs_x           int
	// keys
	k_fire          int
	k_up            int
	k_down          int
	k_left          int
	k_right         int
	// joystick ID
	joy_id           int
	// joystick buttons
	jb_fire          int
	// joystick hat values
	jh_up            int
	jh_down          int
	jh_left          int
	jh_right         int
	// game rand seed
	seed            int
	seed_ini            int
	// Position of the current tetro
	pos_x        int
	pos_y        int
	// field[y][x] contains the color of the block with (x,y) coordinates
	// "-1" border is to avoid bounds checking.
	// -1 -1 -1 -1
	// -1  0  0 -1
	// -1  0  0 -1
	// -1 -1 -1 -1
	field       [][]int
	// TODO: tetro Tetro
	tetro       []Block
	// TODO: tetros_cache []Tetro
	tetros_cache []Block
	// Index of the current tetro. Refers to its color.
	tetro_idx    int
	// Index of the next tetro. Refers to its color.
	tetro_next    int
	// tetro stats : buckets of drawn tetros
	tetro_stats []int
	// total number of drawn tetros
	tetro_total int
	// Index of the rotation (0-3)
	rotation_idx int
	// SDL2 context for drawing
	sdl             SdlContext
	// TTF context for font drawing
	font            voidptr
}

fn (sdl mut SdlContext) set_sdl_context(w int, h int, title string) {
	C.SDL_Init(C.SDL_INIT_VIDEO | C.SDL_INIT_AUDIO | C.SDL_INIT_JOYSTICK)
	C.atexit(C.SDL_Quit)
	C.TTF_Init()
	C.atexit(C.TTF_Quit)
	bpp := 32
	C.SDL_CreateWindowAndRenderer(w, h, 0, &sdl.window, &sdl.renderer)
	C.SDL_SetWindowTitle(sdl.window, title.str)
	sdl.w = w
	sdl.h = h
	sdl.screen = C.SDL_CreateRGBSurface(0, w, h, bpp, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
	sdl.texture = C.SDL_CreateTexture(sdl.renderer, C.SDL_PIXELFORMAT_ARGB8888, C.SDL_TEXTUREACCESS_STREAMING, w, h)

	C.Mix_Init(0)
	C.atexit(C.Mix_Quit)
	if C.Mix_OpenAudio(48000,C.MIX_DEFAULT_FORMAT,2,AudioBufSize) < 0 {
		println('couldn\'t open audio')
	}
	sdl.actx.music = C.Mix_LoadMUS(MusicName.str)
	sdl.actx.waves[0] = C.Mix_LoadWAV(SndBlockName.str)
	sdl.actx.waves[1] = C.Mix_LoadWAV(SndLineName.str)
	sdl.actx.waves[2] = C.Mix_LoadWAV(SndDoubleName.str)
	sdl.actx.volume = C.SDL_MIX_MAXVOLUME
	if C.Mix_PlayMusic(sdl.actx.music, 1) != -1 {
		C.Mix_VolumeMusic(sdl.actx.volume)
	}
	njoy := C.SDL_NumJoysticks()
	for i := 0; i < njoy; i++ {
		C.SDL_JoystickOpen(i)
		jn := tos_clone(C.SDL_JoystickNameForIndex(i))
		println('JOY NAME $jn')
		for j := 0; j < NJOYMAX; j++ {
			if sdl.jnames[j] == jn {
				println('FOUND JOYSTICK $j $jn ID=$i')
				sdl.jids[j] = i
			}
		}
	}
	C.SDL_JoystickEventState(C.SDL_ENABLE)
}

fn main() {
	println('tVintris -- tribute to venerable Twintris')
	mut game := &Game{}
	game.sdl.jnames[0] = JOYP1NAME
	game.sdl.jnames[1] = JOYP2NAME
	game.sdl.jids[0] = -1
	game.sdl.jids[1] = -1
	game.sdl.set_sdl_context(WinWidth, WinHeight, Title)
	game.font = C.TTF_OpenFont(FontName.str, TextSize)
	seed := time.now().uni
	mut game2 := &Game{}
	game2.sdl = game.sdl
	game2.font = game.font

	game.joy_id = game.sdl.jids[0]
//	println('JOY1 id=${game.joy_id}')
	game2.joy_id = game.sdl.jids[1]
//	println('JOY2 id=${game2.joy_id}')

	game.k_fire = P1FIRE
	game.k_up = P1UP
	game.k_down = P1DOWN
	game.k_left = P1LEFT
	game.k_right = P1RIGHT
	game.jb_fire = JBP1FIRE
	game.jh_up = JHP1UP
	game.jh_down = JHP1DOWN
	game.jh_left = JHP1LEFT
	game.jh_right = JHP1RIGHT
	game.ofs_x = 0
	game.seed_ini = seed
	game.init_game()
	game.state = .running
	go game.run() // Run the game loop in a new thread

	game2.k_fire = P2FIRE
	game2.k_up = P2UP
	game2.k_down = P2DOWN
	game2.k_left = P2LEFT
	game2.k_right = P2RIGHT
	game2.jb_fire = JBP2FIRE
	game2.jh_up = JHP2UP
	game2.jh_down = JHP2DOWN
	game2.jh_left = JHP2LEFT
	game2.jh_right = JHP2RIGHT
	game2.ofs_x = WinWidth * 2 / 3
	game2.seed_ini = seed
	game2.init_game()
	game2.state = .running
	go game2.run() // Run the game loop in a new thread

	mut g := Game{}
        mut should_close := false
	for {
		g1 := game
		g2 := game2
		// here we determine which game contains most recent state
		if g1.tetro_total > g.tetro_total {
			g = *g1
		}
		if g2.tetro_total > g.tetro_total {
			g = *g2
		}
		g.draw_begin()

		g1.draw_tetro()
		g1.draw_field()

		g2.draw_tetro()
		g2.draw_field()

		g.draw_middle()

		g1.draw_score()
		g2.draw_score()

		g.draw_stats()

		g.draw_end()

//		game.handle_events()            // CRASHES if done in function ???
		ev := SdlEvent{}
		for !!C.SDL_PollEvent(&ev) {
			switch ev._type {
				case C.SDL_QUIT:
					should_close = true
					break
				case C.SDL_KEYDOWN:
					key := int(ev.key.keysym.sym)
					if key == C.SDLK_ESCAPE {
					        should_close = true
					        break
					}
					game.handle_key(key)
					game2.handle_key(key)
				case C.SDL_JOYBUTTONDOWN:
					jb := int(ev.jbutton.button)
					joyid := int(ev.jbutton.which)
//					println('JOY BUTTON $jb $joyid')
					game.handle_jbutton(jb, joyid)
					game2.handle_jbutton(jb, joyid)
				case C.SDL_JOYHATMOTION:
					jh := int(ev.jhat.hat)
					jv := int(ev.jhat.value)
					joyid := int(ev.jhat.which)
//					println('JOY HAT $jh $jv $joyid')
					game.handle_jhat(jh, jv, joyid)
					game2.handle_jhat(jh, jv, joyid)
			}
		}
		if should_close {
			break
		}
		C.SDL_Delay(20)         // short delay between redraw
	}
	if game.font != voidptr(0) {
		C.TTF_CloseFont(game.font)
	}
	if game.sdl.actx.music != voidptr(0) {
		C.Mix_FreeMusic(game.sdl.actx.music)
	}
	C.Mix_CloseAudio()
	if game.sdl.actx.waves[0] != voidptr(0) {
		C.Mix_FreeChunk(game.sdl.actx.waves[0])
	}
	if game.sdl.actx.waves[1] != voidptr(0) {
		C.Mix_FreeChunk(game.sdl.actx.waves[1])
	}
	if game.sdl.actx.waves[2] != voidptr(0) {
		C.Mix_FreeChunk(game.sdl.actx.waves[2])
	}
}

enum Action {
        none space fire
}
fn (game mut Game) handle_key(key int) {
	// global keys
	mut action := Action(.none)
	switch key {
		case C.SDLK_SPACE:
			action = .space
		case game.k_fire:
			action = .fire
	}

	if action == .space {
			switch game.state {
				case .running:
					game.state = .paused
				case .paused:
					game.state = .running
			}
	}

	if action == .fire {
			switch game.state {
				case .gameover:
					game.init_game()
					game.state = .running
			}
	}
	if game.state != .running { return }
	// keys while game is running
	switch key {
		case game.k_up:
			game.rotate_tetro()
		case game.k_left:
			game.move_right(-1)
		case game.k_right:
			game.move_right(1)
		case game.k_down:
			game.move_tetro() // drop faster when the player presses <down>
	}
}

fn (game mut Game) handle_jbutton(jb int, joyid int) {
	if joyid != game.joy_id {
		return
	}
	// global buttons
	mut action := Action(.none)
	switch jb {
		case game.jb_fire:
			action = .fire
	}

	if action == .fire {
			switch game.state {
				case .gameover:
					game.init_game()
					game.state = .running
			}
	}
}

fn (game mut Game) handle_jhat(jh int, jv int, joyid int) {
	if joyid != game.joy_id {
		return
	}
	if game.state != .running { return }
//	println('testing hat values.. joyid=$joyid jh=$jh jv=$jv')
	// hat values while game is running
	switch jv {
		case game.jh_up:
//			println('UP')
			game.rotate_tetro()
		case game.jh_left:
//			println('LEFT')
			game.move_right(-1)
		case game.jh_right:
//			println('RIGHT')
			game.move_right(1)
		case game.jh_down:
//			println('DOWN')
			game.move_tetro() // drop faster when the player presses <down>
	}
}

fn (g mut Game) init_game() {
	g.score = 0
	g.tetro_total = 0
	g.tetro_stats = [0, 0, 0, 0, 0, 0, 0]
	g.parse_tetros()
	g.seed = g.seed_ini
	g.generate_tetro()
	g.field = []array_int // TODO: g.field = [][]int
	// Generate the field, fill it with 0's, add -1's on each edge
	for i := 0; i < FieldHeight + 2; i++ {
		mut row := [0; FieldWidth + 2]
		row[0] = - 1
		row[FieldWidth + 1] = - 1
		g.field << row
	}
	mut first_row := g.field[0]
	mut last_row := g.field[FieldHeight + 1]
	for j := 0; j < FieldWidth + 2; j++ {
		first_row[j] = - 1
		last_row[j] = - 1
	}
}

fn (g mut Game) parse_tetros() {
	for b_tetros in BTetros {
		for b_tetro in b_tetros {
			for t in parse_binary_tetro(b_tetro) {
				g.tetros_cache << t
			}
		}
	}
}

fn (g mut Game) run() {
	for {
		if g.state == .running {
			g.move_tetro()
			n := g.delete_completed_lines()
			if n > 0 {
				g.lines += n
			} else {
				if g.lines > 0 {
					if g.lines > 1 {
						C.Mix_PlayChannel(0, g.sdl.actx.waves[2], 0)
					} else if g.lines == 1 {
						C.Mix_PlayChannel(0, g.sdl.actx.waves[1], 0)
					}
					g.score += 10 * g.lines * g.lines
					g.lines = 0
				}
			}
		}
		time.sleep_ms(TimerPeriod)      // medium delay between game step
	}
}

fn (game mut Game) rotate_tetro() {
	// Rotate the tetro
	old_rotation_idx := game.rotation_idx
	game.rotation_idx++
	if game.rotation_idx == TetroSize {
		game.rotation_idx = 0
	}
	game.get_tetro()
	if !game.move_right(0) {
		game.rotation_idx = old_rotation_idx
		game.get_tetro()
	}
	if game.pos_x < 0 {
		game.pos_x = 1
	}
}

fn (g mut Game) move_tetro() {
	// Check each block in current tetro
	for block in g.tetro {
		y := block.y + g.pos_y + 1
		x := block.x + g.pos_x
		// Reached the bottom of the screen or another block?
		// TODO: if g.field[y][x] != 0
		//if g.field[y][x] != 0 {
		row := g.field[y]
		if row[x] != 0 {
			// The new tetro has no space to drop => end of the game
			if g.pos_y < 2 {
				g.state = .gameover
				g.tetro_total = 0
				return
			}
			// Drop it and generate a new one
			g.drop_tetro()
			g.generate_tetro()
			C.Mix_PlayChannel(0, g.sdl.actx.waves[0], 0)
			return
		}
	}
	g.pos_y++
}

fn (g mut Game) move_right(dx int) bool {
	// Reached left/right edge or another tetro?
	for i := 0; i < TetroSize; i++ {
		tetro := g.tetro[i]
		y := tetro.y + g.pos_y
		x := tetro.x + g.pos_x + dx
		row := g.field[y]
		if row[x] != 0 {
			// Do not move
			return false
		}
	}
	g.pos_x += dx
	return true
}

fn (g mut Game) delete_completed_lines() int {
	mut n := 0
	for y := FieldHeight; y >= 1; y-- {
		n += g.delete_completed_line(y)
	}
	return n
}

fn (g mut Game) delete_completed_line(y int) int {
	for x := 1; x <= FieldWidth; x++ {
		f := g.field[y]
		if f[x] == 0 {
			return 0
		}
	}
	// Move everything down by 1 position
	for yy := y - 1; yy >= 1; yy-- {
		for x := 1; x <= FieldWidth; x++ {
			mut a := g.field[yy + 1]
			b := g.field[yy]
			a[x] = b[x]
		}
	}
	return 1
}

// Ported from https://git.musl-libc.org/cgit/musl/diff/src/prng/rand_r.c?id=0b44a0315b47dd8eced9f3b7f31580cf14bbfc01
// Thanks spytheman
fn myrand_r(seed &int) int {
  mut rs := seed
  ns := ( *rs * 1103515245 + 12345 )
  *rs = ns
  return ns & 0x7fffffff
}

// Draw a rand tetro index
fn (g mut Game) rand_tetro() int {
	cur := g.tetro_next
	g.tetro_next = myrand_r(&g.seed)
	g.tetro_next = g.tetro_next % BTetros.len
	return cur
}

// Place a new tetro on top
fn (g mut Game) generate_tetro() {
	g.pos_y = 0
	g.pos_x = FieldWidth / 2 - TetroSize / 2
	g.tetro_idx = g.rand_tetro()
//	println('idx=${g.tetro_idx}')
	g.tetro_stats[g.tetro_idx] += 1
	g.tetro_total++
	g.rotation_idx = 0
	g.get_tetro()
}

// Get the right tetro from cache
fn (g mut Game) get_tetro() {
	idx := g.tetro_idx * TetroSize * TetroSize + g.rotation_idx * TetroSize
	g.tetro = g.tetros_cache.slice(idx, idx + TetroSize)
}

fn (g mut Game) drop_tetro() {
	for i := 0; i < TetroSize; i++ {
		tetro := g.tetro[i]
		x := tetro.x + g.pos_x
		y := tetro.y + g.pos_y
		// Remember the color of each block
		// TODO: g.field[y][x] = g.tetro_idx + 1
		mut row := g.field[y]
		row[x] = g.tetro_idx + 1
	}
}

fn (g &Game) draw_tetro() {
	for i := 0; i < TetroSize; i++ {
		tetro := g.tetro[i]
		g.draw_block(g.pos_y + tetro.y, g.pos_x + tetro.x, g.tetro_idx + 1)
	}
}

fn (g &Game) draw_block(i, j, color_idx int) {
	rect := SdlRect {g.ofs_x + (j - 1) * BlockSize, (i - 1) * BlockSize,
		BlockSize - 1, BlockSize - 1}
	scol := Colors[color_idx]
	rr := scol.r
	gg := scol.g
	bb := scol.b
	col := C.SDL_MapRGB(g.sdl.screen.format, rr, gg, bb)
	C.SDL_FillRect(g.sdl.screen, &rect, col)
}

fn (g &Game) draw_field() {
	for i := 1; i < FieldHeight + 1; i++ {
		for j := 1; j < FieldWidth + 1; j++ {
			f := g.field[i]
			if f[j] > 0 {
				g.draw_block(i, j, f[j])
			}
		}
	}
}

fn (g &Game) draw_text(x int, y int, text string, rr int, gg int, bb int) {
	tcol := SdlColor {byte(3), byte(2), byte(1), byte(0)}
	tsurf := C.TTF_RenderText_Solid(g.font, text.str, tcol)
	ttext := C.SDL_CreateTextureFromSurface(g.sdl.renderer, tsurf)
	texw := 0
	texh := 0
	C.SDL_QueryTexture(ttext, 0, 0, &texw, &texh)
	dstrect := SdlRect { x, y, texw, texh }
	C.SDL_RenderCopy(g.sdl.renderer, ttext, 0, &dstrect)
	C.SDL_DestroyTexture(ttext)
	C.SDL_FreeSurface(tsurf)
}

fn (g &Game) draw_ptext(x int, y int, text string, rr int, gg int, bb int) {
	g.draw_text(g.ofs_x + x, y, text, rr, gg, bb)
}

fn (g &Game) draw_score() {
	if g.font != voidptr(0) {
		g.draw_ptext(1, 2, 'score: ' + g.score.str() + ' nxt=' + g.tetro_next.str(), 0, 0, 0)
		if g.state == .gameover {
			g.draw_ptext(1, WinHeight / 2 + 0 * TextSize, 'Game Over', 0, 0, 0)
			g.draw_ptext(1, WinHeight / 2 + 2 * TextSize, 'FIRE to restart', 0, 0, 0)
		} else if g.state == .paused {
			g.draw_ptext(1, WinHeight / 2 + 0 * TextSize, 'Game Paused', 0, 0, 0)
			g.draw_ptext(1, WinHeight / 2 + 2 * TextSize, 'SPACE to resume', 0, 0, 0)
		}
	}
}

fn (g &Game) draw_stats() {
	if g.font != voidptr(0) {
		g.draw_text(WinWidth / 3 + 10, WinHeight * 3 / 4 + 0 * TextSize, 'stats: ' + g.tetro_total.str() + ' tetros', 0, 0, 0)
		mut stats := ''
		for st in g.tetro_stats {
			mut s := 0
			if g.tetro_total > 0 {
				s = 100 * st / g.tetro_total
			}
			stats += ' '
			stats += s.str()

//	h := s * 20 / 100
	h := 40
//	rect := SdlRect {WinWidth / 3 + 10 + idx * 4, WinHeight * 3 / 4 - h, 4, h}
	rect := SdlRect {10, 10, h, h}
//	scol := Colors[idx]
//	col := C.SDL_MapRGB(g.sdl.screen.format, scol.r, scol.g, scol.b)
	col := C.SDL_MapRGB(g.sdl.screen.format, 255, 0, 0)
	C.SDL_FillRect(g.sdl.screen, &rect, col)
//	idx++

		}
		g.draw_text(WinWidth / 3 - 8, WinHeight * 3 / 4 + 2 * TextSize, stats, 0, 0, 0)
	}
}

fn (g &Game) draw_begin() {
	mut rect := SdlRect {0,0,g.sdl.w,g.sdl.h}
	mut col := C.SDL_MapRGB(g.sdl.screen.format, 255, 255, 255)
	C.SDL_FillRect(g.sdl.screen, &rect, col)

	col = C.SDL_MapRGB(g.sdl.screen.format, 0, 0, 0)
	rect = SdlRect {BlockSize * FieldWidth + 2,0,2,g.sdl.h}
	C.SDL_FillRect(g.sdl.screen, &rect, col)
	rect = SdlRect {WinWidth - BlockSize * FieldWidth - 4,0,2,g.sdl.h}
	C.SDL_FillRect(g.sdl.screen, &rect, col)

	mut idx := 0
	for st in g.tetro_stats {
		mut s := 10
		if g.tetro_total > 0 {
			s += 90 * st / g.tetro_total
		}
		w := BlockSize
		h := s * 4 * w / 100
		rect = SdlRect {(WinWidth - 7 * (w + 1)) / 2 + idx * (w + 1), WinHeight * 3 / 4 - h, w, h}
//		rect = SdlRect {10 + 5 * idx, 100 - h, 4, h}
		scol := Colors[idx + 1]
		col = C.SDL_MapRGB(g.sdl.screen.format, scol.r, scol.g, scol.b)
//		col = C.SDL_MapRGB(g.sdl.screen.format, 255, 0, 0)
		C.SDL_FillRect(g.sdl.screen, &rect, col)
		idx++
	}
}

fn (g &Game) draw_scene() {
	g.draw_tetro()
	g.draw_field()
}

fn (g &Game) draw_middle() {
	C.SDL_UpdateTexture(g.sdl.texture, 0, g.sdl.screen.pixels, g.sdl.screen.pitch)
	C.SDL_RenderClear(g.sdl.renderer)
	C.SDL_RenderCopy(g.sdl.renderer, g.sdl.texture, 0, 0)
}

fn (g &Game) draw_end() {
	C.SDL_RenderPresent(g.sdl.renderer)
}

fn parse_binary_tetro(t_ int) []Block {
	mut t := t_
	res := [Block{} ; 4]
	mut cnt := 0
	horizontal := t == 9// special case for the horizontal line
	for i := 0; i <= 3; i++ {
		// Get ith digit of t
		p := int(math.pow(10, 3 - i))
		mut digit := int(t / p)
		t %= p
		// Convert the digit to binary
		for j := 3; j >= 0; j-- {
			bin := digit % 2
			digit /= 2
			if bin == 1 || (horizontal && i == TetroSize - 1) {
				// TODO: res[cnt].x = j
				// res[cnt].y = i
				mut point := &res[cnt]
				point.x = j
				point.y = i
				cnt++
			}
		}
	}
	return res
}
