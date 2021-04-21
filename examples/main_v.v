// Copyright(C) 2019 Nicolas Sauzede. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE_v.txt file.
module main

import nsauzede.vsdl2
import time
import os

const (
	colors = [
		vsdl2.Color{byte(255), byte(255), byte(255), byte(0)},
		vsdl2.Color{byte(255), byte(0), byte(0), byte(0)},
	]
)

struct AudioContext {
mut:
	//        audio_pos *byte
	audio_pos   voidptr
	audio_len   u32
	wav_spec    vsdl2.AudioSpec
	wav_buffer  &byte = voidptr(0)
	wav_length  u32
	wav2_buffer &byte = voidptr(0)
	wav2_length u32
}

fn acb(userdata voidptr, stream &byte, _len int) {
	mut ctx := &AudioContext(userdata)
	//        println('acb!!! wav_buffer=${ctx.wav_buffer} audio_len=${ctx.audio_len}')
	if ctx.audio_len == u32(0) {
		unsafe { C.memset(stream, 0, _len) }
		return
	}
	mut len := u32(_len)
	if len > ctx.audio_len {
		len = ctx.audio_len
	}
	unsafe{C.memcpy(stream, ctx.audio_pos, len)}
	ctx.audio_pos = voidptr(u64(ctx.audio_pos) + u64(len))
	ctx.audio_len -= len
}

[live]
fn livemain() {
	println('hello SDL 2 [v]\n')
	w := 200
	h := 400
	bpp := 32
	sdl_window := voidptr(0)
	sdl_renderer := voidptr(0)
	C.SDL_Init(C.SDL_INIT_VIDEO | C.SDL_INIT_AUDIO)
	C.atexit(C.SDL_Quit)
	C.TTF_Init()
	C.atexit(C.TTF_Quit)
	font := C.TTF_OpenFont('fonts/RobotoMono-Regular.ttf', 16)
	//        println('font=$font')
	C.SDL_CreateWindowAndRenderer(w, h, 0, &sdl_window, &sdl_renderer)
	//        println('renderer=$sdl_renderer')
	screen := vsdl2.create_rgb_surface(0, w, h, bpp, 0x00FF0000, 0x0000FF00, 0x000000FF,
		0xFF000000)
	sdl_texture := C.SDL_CreateTexture(sdl_renderer, C.SDL_PIXELFORMAT_ARGB8888, C.SDL_TEXTUREACCESS_STREAMING,
		w, h)
	mut actx := AudioContext{}
	//        C.SDL_zero(actx)
	C.SDL_LoadWAV('sounds/door2.wav', &actx.wav_spec, &actx.wav_buffer, &actx.wav_length)
	//        C.SDL_LoadWAV('sounds/block.wav', &actx.wav_spec, &actx.wav_buffer, &actx.wav_length)
	//        println('got wav_buffer=${actx.wav_buffer}')
	C.SDL_LoadWAV('sounds/single.wav', &actx.wav_spec, &actx.wav2_buffer, &actx.wav2_length)
	actx.wav_spec.callback = voidptr(acb)
	actx.wav_spec.userdata = &actx
	if C.SDL_OpenAudio(&actx.wav_spec, 0) < 0 {
		println("couldn't open audio")
		return
	}
	mut quit := false
	mut ballx := 0
	bally := h / 2
	balld := 10
	ballm := 1
	mut balldir := ballm
	for !quit {
		ev := vsdl2.Event{}
		for 0 < C.SDL_PollEvent(&ev) {
			match int(unsafe{ev.@type}) {
				C.SDL_QUIT {
					quit = true
				}
				C.SDL_KEYDOWN {
					match int(unsafe{ev.key.keysym.sym}) {
						C.SDLK_ESCAPE {
							quit = true
						}
						C.SDLK_SPACE {
							actx.audio_pos = actx.wav2_buffer
							actx.audio_len = actx.wav2_length
							C.SDL_PauseAudio(0)
						}
						else {}
					}
				}
				else {}
			}
		}
		if quit {
			break
		}
		//                rect := vsdl2.Rect {x: 0, y: 0, w: w, h: h }     // TODO doesn't compile ???
		mut rect := vsdl2.Rect{0, 0, w, h}
		mut col := vsdl2.Color{byte(255), byte(255), byte(255), byte(0)}
		vsdl2.fill_rect(screen, &rect, col)

		rect = vsdl2.Rect{ballx, bally, balld, balld}
		col = vsdl2.Color{colors[1].r, colors[1].g, colors[1].b, 0}
		vsdl2.fill_rect(screen, &rect, col)
		ballx += balldir
		if balldir == ballm {
			if ballx == w - balld * 4 {
				//                                println('+1WAV =>')
				actx.audio_pos = actx.wav2_buffer
				//                                actx.audio_len = actx.wav2_length
				C.SDL_PauseAudio(0)
			} else if ballx >= w - balld {
				//                                println('+1WAV <= -1')
				balldir = -ballm
				actx.audio_pos = actx.wav_buffer
				actx.audio_len = actx.wav_length
				C.SDL_PauseAudio(0)
			}
		} else {
			if ballx == balld * 4 {
				//                                println('-1WAV2 <=')
				actx.audio_pos = actx.wav2_buffer
				//                                actx.audio_len = actx.wav2_length
				C.SDL_PauseAudio(0)
			} else if ballx <= 0 {
				//                                println('-1WAV => 1')
				balldir = ballm
				actx.audio_pos = actx.wav_buffer
				actx.audio_len = actx.wav_length
				C.SDL_PauseAudio(0)
			}
		}

		C.SDL_UpdateTexture(sdl_texture, 0, screen.pixels, screen.pitch)
		C.SDL_RenderClear(sdl_renderer)
		C.SDL_RenderCopy(sdl_renderer, sdl_texture, 0, 0)

		//                tcol := C.SDL_Color {u32(0), u32(0), u32(0)}    // TODO doesn't compile ?
		//                tcol := [byte(0), byte(0), byte(0), byte(0)]
		tcol := C.SDL_Color{byte(3), byte(2), byte(1), byte(0)}
		//                tsurf := C.TTF_RenderText_Solid(font,'Hello SDL_ttf', tcol)
		//                tsurf := *voidptr(0xdeadbeef)
		//                println('tsurf=$tsurf')
		//                C.stubTTF_RenderText_Solid(font,'Hello SDL_ttf V !', &tcol, &tsurf)
		tsurf := C.TTF_RenderText_Solid(font, 'Hello SDL_ttf V !', tcol)
		//                println('tsurf=$tsurf')
		//                tsurf := C.TTF_RenderText_Solid(font,'Hello SDL_ttf', 0)
		//                println('tsurf=$tsurf')
		//                println('tsurf=' + $tsurf')
		ttext := C.SDL_CreateTextureFromSurface(sdl_renderer, tsurf)
		//                println('ttext=$ttext')
		texw := 0
		texh := 0
		C.SDL_QueryTexture(ttext, 0, 0, &texw, &texh)
		dstrect := vsdl2.Rect{0, 0, texw, texh}
		C.SDL_RenderCopy(sdl_renderer, ttext, 0, &dstrect)
		C.SDL_DestroyTexture(ttext)
		vsdl2.free_surface(tsurf)

		C.SDL_RenderPresent(sdl_renderer)
		C.SDL_Delay(10)
	}
	if !isnil(font) {
		C.TTF_CloseFont(font)
	}
	C.SDL_CloseAudio()
	if voidptr(actx.wav_buffer) != voidptr(0) {
		C.SDL_FreeWAV(actx.wav_buffer)
	}
}

fn main() {
	// these 3 lines just silence the v unused modules warnings (errors when -prod is given)
	println('vsdl2 version: $vsdl2.version')
	println('current time: $time.now().format_ss()')
	println('executable: $os.executable()')
	livemain()
}
