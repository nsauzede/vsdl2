// Copyright(C) 2019 Nicolas Sauzede. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.

module vsdl2

#flag linux `sdl2-config --cflags --libs`  -lSDL2_ttf -lSDL2_mixer
//#flag windows `sdl2-config --cflags`
//#flag windows `sdl2-config --libs`  -lSDL2_ttf -lSDL2_mixer
//#flag `sdl2-config --cflags --libs`  -lSDL2_ttf -lSDL2_mixer

#flag -DSDL_DISABLE_IMMINTRIN_H

// following kludge until `sdl2-config ...` is supported also on windows
#flag windows -I/msys64/mingw64/include/SDL2
#flag windows -Dmain=SDL_main
#flag windows -L/mingw64/lib -lmingw32 -lSDL2main -lSDL2

#include <SDL.h>
#include <SDL_ttf.h>
#include <SDL_mixer.h>


//struct C.SDL_Color{
pub struct SdlColor{
pub:
        r byte
        g byte
        b byte
        a byte
}
//type SdlColor C.SDL_Color

pub struct C.SDL_Color{
pub:
        r byte
        g byte
        b byte
        a byte
}

//struct C.SDL_Rect {
pub struct SdlRect {
pub:
        x int
        y int
        w int
        h int
}
//type SdlRect C.SDL_Rect

//pub struct C.SDL_Surface {
pub struct SdlSurface {
pub:
        flags u32
        format voidptr
        w int
        h int
        pitch int
        pixels voidptr
        userdata voidptr
        locked int
        lock_data voidptr
        clip_rect SdlRect
        map voidptr
        refcount int
}
//type SdlSurface C.SDL_Surface
//type SdlSurface SdlSurface

/////////////////////////////////////////////////////////

struct SdlQuitEvent {
        _type u32
        timestamp u32
}
struct SdlKeysym {
pub:
        scancode int
        sym int
        mod u16
        unused u32
}
struct SdlKeyboardEvent {
pub:
        _type u32
        timestamp u32
        windowid u32
        state byte
        repeat byte
        padding2 byte
        padding3 byte
        keysym SdlKeysym
}
struct SdlJoyButtonEvent {
pub:
        _type u32
        timestamp u32
        which int
        button byte
        state byte
}
struct SdlJoyHatEvent {
pub:
        _type u32
        timestamp u32
        which int
        hat byte
        value byte
}

//pub union SdlEventU {
pub union SdlEvent {
pub:
        _type u32
        quit SdlQuitEvent
        key SdlKeyboardEvent
        jbutton SdlJoyButtonEvent
        jhat SdlJoyHatEvent
        _pad56 [56]byte
}
//type SdlEvent SdlEventU


//struct C.SDL_AudioSpec {
pub struct SdlAudioSpec {
pub:
mut:
        freq int
        format u16
        channels byte
        silence byte
        samples u16
        size u32
        callback voidptr
        userdata voidptr
}
//type SdlAudioSpec C.SDL_AudioSpec

//////////////////////////////////////////////////////////

fn C.SDL_MapRGB(fmt voidptr, r byte, g byte, b byte) u32
fn C.SDL_CreateRGBSurface(flags u32, width int, height int, depth int, Rmask u32, Gmask u32, Bmask u32, Amask u32) voidptr
fn C.SDL_PollEvent(&SdlEvent) int
fn C.SDL_NumJoysticks() int
fn C.SDL_JoystickNameForIndex(device_index int) voidptr
fn C.SDL_RenderCopy(renderer voidptr, texture voidptr, srcrect voidptr, dstrect voidptr) int
fn C.SDL_CreateWindowAndRenderer(width int, height int, window_flags u32, window &voidptr, renderer &voidptr) int

//////////////////////////////////////////////////////////

pub fn create_window_and_renderer(width int, height int, window_flags u32, window voidptr, renderer voidptr) int {
	return C.SDL_CreateWindowAndRenderer(width, height, window_flags, window, renderer)
}

pub fn joystick_name_for_index(device_index int) byteptr {
	return byteptr(C.SDL_JoystickNameForIndex(device_index))
}

pub fn fill_rect(screen &SdlSurface, rect &SdlRect, _col &SdlColor) {
	col := C.SDL_MapRGB(screen.format, _col.r, _col.g, _col.b)
	_screen := voidptr(screen)
	_rect := voidptr(rect)
	C.SDL_FillRect(_screen, _rect, col)
}

pub fn create_rgb_surface(flags u32, width int, height int, depth int, rmask u32, gmask u32, bmask u32, amask u32) &SdlSurface {
	res := C.SDL_CreateRGBSurface(flags, width, height, depth, rmask, gmask, bmask, amask)
	return res
}

pub fn render_copy(renderer voidptr, texture voidptr, srcrect &SdlRect, dstrect &SdlRect) int {
	_srcrect := voidptr(srcrect)
	_dstrect := voidptr(dstrect)
	return C.SDL_RenderCopy(renderer, texture, _srcrect, _dstrect)
}

pub fn poll_event(event &SdlEvent) int {
	return C.SDL_PollEvent(voidptr(event))
}

pub fn destroy_texture(text voidptr) {
        C.SDL_DestroyTexture(text)
}

pub fn free_surface(surf &SdlSurface) {
        C.SDL_FreeSurface(surf)
}

//////////////////////////////////////////////////////////
// SDL_Timer.h
//////////////////////////////////////////////////////////
fn C.SDL_GetTicks() u32
fn C.SDL_TICKS_PASSED(a,b u32) bool
fn C.SDL_GetPerformanceCounter() u64
fn C.SDL_GetPerformanceFrequency() u64
fn C.SDL_Delay(ms u32)

pub fn get_ticks() u32 {
        return C.SDL_GetTicks()
}

pub fn ticks_passed(a, b u32) bool {
        return C.SDL_TICKS_PASSED(a,b)
}

pub fn get_perf_counter() u64 {
        return C.SDL_GetPerformanceCounter()
}

pub fn get_perf_frequency() u64 {
        return C.SDL_GetPerformanceFrequency()
}

pub fn delay(ms u32) {
        C.SDL_Delay(ms)
}

pub const (
  version = '0.2' // hack to avoid unused module warning in the main program
)

