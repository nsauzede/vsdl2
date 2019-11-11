// Copyright (c) 2019 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.

// SDL2 port+wrapper, Twintris-like dual-game logic,
// and more, by Nicolas Sauzede 2019.

module main

import rand
import time
import os
import math
import vsdl2
import vsdl2.image as img
[inline] fn sdl_fill_rect(s &vsdl2.Surface,r &vsdl2.Rect,c &vsdl2.Color){vsdl2.fill_rect(s,r,c)}

const (
	Title = 'Vyper'
	FontName = 'RobotoMono-Regular.ttf'
	MusicName = 'sounds/TwintrisThosenine.mod'
	SndBlockName = 'sounds/block.wav'
	SndLineName = 'sounds/single.wav'
	SndDoubleName = 'sounds/triple.wav'
	VLogo = 'images/v-logo_30_30.png'
	BackgroundImage = 'images/sand_600_400.png'
	SnakeHeadImage = 'images/snakeHead_t[20x20].png'
	SnakeTorsoImage = 'images/snakeBody[20x20].png'
	SnakeTailImage = 'images/snakeTail[20x20].png'
	BlockSize = 20 // pixels
	FieldHeight = 20 // # of blocks
	FieldWidth = 10
	TetroSize = 4
	WinWidth = 600
	WinHeight = 400
	TimerPeriod = 250 // ms
	TextSize = 16
	AudioBufSize = 1024

	P1FIRE = C.SDLK_l
	P1UP = C.SDLK_UP
	P1DOWN = C.SDLK_DOWN
	P1LEFT = C.SDLK_LEFT
	P1RIGHT = C.SDLK_RIGHT

	// P1FIRE = C.SDLK_s
	// P1UP = C.SDLK_w
	// P1DOWN = C.SDLK_x
	// P1LEFT = C.SDLK_a
	// P1RIGHT = C.SDLK_d

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
)

const (
	// Each tetro has its unique color
	Colors = [
		vsdl2.Color{byte(0), byte(0), byte(0), byte(0)},		// unused ?
		vsdl2.Color{byte(0), byte(0x62), byte(0xc0), byte(0)},	// quad : darkblue 0062c0
		vsdl2.Color{byte(0xca), byte(0x7d), byte(0x5f), byte(0)},	// tricorn : lightbrown ca7d5f
		vsdl2.Color{byte(0), byte(0xc1), byte(0xbf), byte(0)},	// short topright : lightblue 00c1bf
		vsdl2.Color{byte(0), byte(0xc1), byte(0), byte(0)},	// short topleft : lightgreen 00c100
		vsdl2.Color{byte(0xbf), byte(0xbe), byte(0), byte(0)},	// long topleft : yellowish bfbe00
		vsdl2.Color{byte(0xd1), byte(0), byte(0xbf), byte(0)},	// long topright : pink d100bf
		vsdl2.Color{byte(0xd1), byte(0), byte(0), byte(0)},	// longest : lightred d10000
		vsdl2.Color{byte(0), byte(170), byte(170), byte(0)},	// unused ?
	]
	// Background color
	BackgroundColor = vsdl2.Color{byte(0), byte(0), byte(0), byte(0)}
//	BackgroundColor = vsdl2.Color{byte(255), byte(255), byte(255), byte(0)}
	// Foreground color
	ForegroundColor = vsdl2.Color{byte(0), byte(170), byte(170), byte(0)}
//	ForegroundColor = vsdl2.Color{byte(0), byte(0), byte(0), byte(0)}
	// Text color
	TextColor = vsdl2.Color{byte(0xca), byte(0x7d), byte(0x5f), byte(0)}
//	TextColor = vsdl2.Color{byte(0), byte(0), byte(0), byte(0)}
)

enum BodyPartType {
	head torso tail
}

enum Direction {
	north south east west
}

// TODO: type Tetro [TetroSize]struct{ x, y int }
struct Block {
	mut:
	x int
	y int
	part_type BodyPartType
	surface &vsdl2.Surface
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

struct Context {
pub:
mut:
//      VIDEO
	w		int
	h		int
	window          voidptr
	renderer        voidptr
	screen          &vsdl2.Surface
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
	snake            []Block
	// SDL2 context for drawing
	sdl             Context
	// TTF context for font drawing
	font            voidptr
}

fn (sdl mut Context) set_sdl_context(w int, h int, title string) {
	C.SDL_Init(C.SDL_INIT_VIDEO | C.SDL_INIT_AUDIO | C.SDL_INIT_JOYSTICK)
	C.atexit(C.SDL_Quit)
	C.TTF_Init()
	C.atexit(C.TTF_Quit)
	bpp := 32
	vsdl2.create_window_and_renderer(w, h, 0, &sdl.window, &sdl.renderer)
//	C.SDL_CreateWindowAndRenderer(w, h, 0, voidptr(&sdl.window), voidptr(&sdl.renderer))
	C.SDL_SetWindowTitle(sdl.window, title.str)
	sdl.w = w
	sdl.h = h
	sdl.screen = vsdl2.create_rgb_surface(0, w, h, bpp, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
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
		jn := tos_clone(vsdl2.joystick_name_for_index(i))
		println('JOY NAME $jn')
		for j := 0; j < NJOYMAX; j++ {
			if sdl.jnames[j] == jn {
				println('FOUND JOYSTICK $j $jn ID=$i')
				sdl.jids[j] = i
			}
		}
	}
	flags := C.IMG_INIT_PNG
	imgres := img.img_init(flags)
	if ((imgres & flags) != flags) {
		println('error initializing image library.')
	}
	C.SDL_JoystickEventState(C.SDL_ENABLE)
}

fn main() {
	println('Viper ------ V implementation of Snake')
	mut game := &Game{}
	game.sdl.jnames[0] = JOYP1NAME
	game.sdl.jids[0] = -1
	game.sdl.set_sdl_context(WinWidth, WinHeight, Title)
	game.font = C.TTF_OpenFont(FontName.str, TextSize)

	game.joy_id = game.sdl.jids[0]
//	println('JOY1 id=${game.joy_id}')
//	println('JOY2 id=${game2.joy_id}')

	// delay uses milliseconds so 1000 ms / 30 frames (30fps) roughly = 33.3333 ms/frame
	time_per_frame := 1000.0 / 30.0 
	//bg_img := img.load()
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
	game.init_game()
	game.state = .running
	go game.run() // Run the game loop in a new thread

	// game2.k_fire = P2FIRE
	// game2.k_up = P2UP
	// game2.k_down = P2DOWN
	// game2.k_left = P2LEFT
	// game2.k_right = P2RIGHT
	// game2.jb_fire = JBP2FIRE
	// game2.jh_up = JHP2UP
	// game2.jh_down = JHP2DOWN
	// game2.jh_left = JHP2LEFT
	// game2.jh_right = JHP2RIGHT
	// game2.ofs_x = WinWidth * 2 / 3
	// game2.seed_ini = seed
	// game2.init_game()
	// game2.state = .running
	// go game2.run() // Run the game loop in a new thread

	mut g := Game{}
	mut should_close := false
	mut total_frame_ticks := u64(0)
	mut total_frames := u32(0)
	bg_img := img.load(BackgroundImage.str)
	v_logo := img.load(VLogo.str)
	head_s := img.load(SnakeHeadImage.str)
	torso_s := img.load(SnakeTorsoImage.str)
	tail_s := img.load(SnakeTailImage.str)

	game.snake << Block{ x : 40, y : 20, part_type : .head, surface : head_s }

	for {
		head := game.snake[0]
		total_frames += 1
		start_ticks := vsdl2.get_perf_counter()

		g1 := game
		g = *g1

		g.draw_begin()

		g.draw_surface(bg_img, 0, 0)
		g.draw_surface(v_logo, 20, 20)
		g.draw_surface(head.surface, head.x, head.y)
		//g.draw_v_logo()
		g.draw_end()

//		game.handle_events()            // CRASHES if done in function ???
		ev := vsdl2.Event{}
		for 0 < vsdl2.poll_event(&ev) {
			match int(ev._type) {
				C.SDL_QUIT { should_close = true }
				C.SDL_KEYDOWN {
					println('.....')
					key := int(ev.key.keysym.sym)
					if key == C.SDLK_ESCAPE {
					        should_close = true
					        break
					}
					game.handle_key(key)
				}
				C.SDL_JOYBUTTONDOWN {
					jb := int(ev.jbutton.button)
					joyid := int(ev.jbutton.which)
//					println('JOY BUTTON $jb $joyid')
					game.handle_jbutton(jb, joyid)
				}
				C.SDL_JOYHATMOTION {
					jh := int(ev.jhat.hat)
					jv := int(ev.jhat.value)
					joyid := int(ev.jhat.which)
//					println('JOY HAT $jh $jv $joyid')
					game.handle_jhat(jh, jv, joyid)
				}
			}
		}
		if should_close {
			break
		}
		end_ticks := vsdl2.get_perf_counter()
		
		total_frame_ticks += end_ticks-start_ticks
		elapsed_time := f64(end_ticks - start_ticks) / f64(vsdl2.get_perf_frequency())
		// current_fps := 1.0 / elapsed_time
		
		// should limit system to (1 / time_per_frame) fps
		vsdl2.delay(u32(math.floor(time_per_frame - elapsed_time)))  
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
        idle space fire
}
fn (game mut Game) handle_key(key int) {
	// global keys
	mut action := Action(.idle)
	match key {
		C.SDLK_SPACE { action = .space }
		game.k_fire { action = .fire }
	}

	if action == .space {
			match game.state {
				.running {
					C.Mix_PauseMusic()
					game.state = .paused
				}
				.paused {
					C.Mix_ResumeMusic()
					game.state = .running
				}
			}
	}

	if action == .fire {
			match game.state {
				.gameover {
					game.init_game()
					game.state = .running
				}
			}
	}
	if game.state != .running { return }
	//mut head := game.snake[0]
	println('x: ${game.snake[0].x} y: ${game.snake[0].y} type: ${game.snake[0].part_type}')
	// keys while game is running
	match key {
		game.k_up { game.snake[0].move(.north) }
		game.k_left { game.snake[0].move(.west) }
		game.k_right { game.snake[0].move(.east) }
		game.k_down { game.snake[0].move(.south) } // drop faster when the player presses <down>
	}
}

fn (game mut Game) handle_jbutton(jb int, joyid int) {
	if joyid != game.joy_id {
		return
	}
	// global buttons
	mut action := Action(.idle)
	match jb {
		game.jb_fire { action = .fire }
	}

	if action == .fire {
			match game.state {
				.gameover {
					game.init_game()
					game.state = .running
				}
			}
	}
}

fn (game  Game) handle_jhat(jh int, jv int, joyid int) {
	if joyid != game.joy_id {
		return
	}
	if game.state != .running { return }
//	println('testing hat values.. joyid=$joyid jh=$jh jv=$jv')
	// hat values while game is running
	match jv {
		game.jh_up   { }//game.rotate_tetro() }
		game.jh_left { }//game.move_right(-1) }
		game.jh_right{ }//game.move_right(1) }
		game.jh_down { }//game.move_tetro() } // drop faster when the player presses <down>
	}
}


fn (g mut Game) init_game() {
	g = g
	g.score = 0
	// g.tetro_total = 0
	// g.tetro_stats = [0, 0, 0, 0, 0, 0, 0]
	// g.parse_tetros()
	// g.seed = g.seed_ini
	// g.generate_tetro()
	// g.field = []array_int // TODO: g.field = [][]int
	// // Generate the field, fill it with 0's, add -1's on each edge
	// for i := 0; i < FieldHeight + 2; i++ {
	// 	mut row := [0].repeat(FieldWidth + 2)
	// 	row[0] = - 1
	// 	row[FieldWidth + 1] = - 1
	// 	g.field << row
	// }
	// mut first_row := g.field[0]
	// mut last_row := g.field[FieldHeight + 1]
	// for j := 0; j < FieldWidth + 2; j++ {
	// 	first_row[j] = - 1
	// 	last_row[j] = - 1
	// }
}

fn (b mut Block) move(dir Direction) bool {
	println('match')
	match dir {
		.west {
			if b.x - BlockSize < 0 {
				return false
			}
			b.x -= BlockSize
		}
		.east {
			if b.x + BlockSize > WinWidth {
				return false
			}
			b.x += BlockSize
		}
		.north {
			if b.y - BlockSize < 0 {
				return false
			}
			b.y -= BlockSize
		}
		.south {
			if b.y + BlockSize > WinHeight {
				return false
			}
			b.y += BlockSize
		}
	}	
	println('moving')
	return true
}

fn (g mut Game) run() {
	g.state = g.state
	for {
		if g.state == .running {
			// g.move_tetro()
			// n := g.delete_completed_lines()
			// if n > 0 {
			// 	g.lines += n
			// } else {
			// 	if g.lines > 0 {
			// 		if g.lines > 1 {
			// 			C.Mix_PlayChannel(0, g.sdl.actx.waves[2], 0)
			// 		} else if g.lines == 1 {
			// 			C.Mix_PlayChannel(0, g.sdl.actx.waves[1], 0)
			// 		}
			// 		g.score += 10 * g.lines * g.lines
			// 		g.lines = 0
			// 	}
			// }
		}
		time.sleep_ms(TimerPeriod)      // medium delay between game step
	}
}

fn (g &Game) draw_surface(bg_img &vsdl2.Surface, x, y int) {
	tbg_img := C.SDL_CreateTextureFromSurface(g.sdl.renderer, bg_img)
	texw := 0
	texh := 0

	C.SDL_QueryTexture(tbg_img, 0, 0, &texw, &texh)
	
	dstrect := vsdl2.Rect { x, y, texw, texh }
	
	C.SDL_RenderCopy(g.sdl.renderer, tbg_img, 0, &dstrect)
	
	vsdl2.destroy_texture(tbg_img)
}

fn (g &Game) draw_text(x int, y int, text string, tcol vsdl2.Color) {
	_tcol := C.SDL_Color{tcol.r, tcol.g, tcol.b, tcol.a}
	tsurf := C.TTF_RenderText_Solid(g.font, text.str, _tcol)
	ttext := C.SDL_CreateTextureFromSurface(g.sdl.renderer, tsurf)
	texw := 0
	texh := 0
	C.SDL_QueryTexture(ttext, 0, 0, &texw, &texh)
	dstrect := vsdl2.Rect { x, y, texw, texh }
//	vsdl2.render_copy(g.sdl.renderer, ttext, 0, &dstrect)
	C.SDL_RenderCopy(g.sdl.renderer, ttext, voidptr(0), voidptr(&dstrect))
	C.SDL_DestroyTexture(ttext)
	C.SDL_FreeSurface(tsurf)
}

[inline] fn (g &Game) draw_ptext(x int, y int, text string, tcol vsdl2.Color) {
	g.draw_text(g.ofs_x + x, y, text, tcol)
}

[live]
fn (g &Game) draw_begin() {
//	println('about to clear')
	C.SDL_RenderClear(g.sdl.renderer)
	
}

fn (g &Game) draw_middle() {
	C.SDL_UpdateTexture(g.sdl.texture, 0, g.sdl.screen.pixels, g.sdl.screen.pitch)
//	vsdl2.render_copy(g.sdl.renderer, g.sdl.texture, voidptr(0), voidptr(0))
	C.SDL_RenderCopy(g.sdl.renderer, g.sdl.texture, voidptr(0), voidptr(0))
}

fn (g &Game) draw_score() {
	if g.font != voidptr(0) {
		//g.draw_ptext(1, 2, 'score: ' + g.score.str() + ' nxt=' + g.tetro_next.str(), TextColor)
		if g.state == .gameover {
			g.draw_ptext(1, WinHeight / 2 + 0 * TextSize, 'Game Over', TextColor)
			g.draw_ptext(1, WinHeight / 2 + 2 * TextSize, 'FIRE to restart', TextColor)
		} else if g.state == .paused {
			g.draw_ptext(1, WinHeight / 2 + 0 * TextSize, 'Game Paused', TextColor)
			g.draw_ptext(1, WinHeight / 2 + 2 * TextSize, 'SPACE to resume', TextColor)
		}
	}
}

fn (g &Game) draw_end() {
	C.SDL_RenderPresent(g.sdl.renderer)
}