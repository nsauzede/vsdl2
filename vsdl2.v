// Copyright(C) 2019 Nicolas Sauzede. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.

module vsdl2

// apparently, following line also works on non-linux ? o_O
#flag linux `sdl2-config --cflags --libs`  -lSDL2_ttf -lSDL2_mixer
#include <SDL.h>
#include <SDL_ttf.h>
#include <SDL_mixer.h>

fn C.SDL_CreateRGBSurface(flags u32, width int, height int, depth int, Rmask u32, Gmask u32, Bmask u32, Amask u32) &SdlSurface
fn C.SDL_PollEvent(&SdlEvent) int

struct C.SDL_Color{
pub:
        r byte
        g byte
        b byte
        a byte
}
type SdlColor C.SDL_Color

struct C.SDL_Rect {
pub:
        x int
        y int
        w int
        h int
}
type SdlRect C.SDL_Rect

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
union SdlEventU {
pub:
        _type u32
        quit SdlQuitEvent
        key SdlKeyboardEvent
        jbutton SdlJoyButtonEvent
        jhat SdlJoyHatEvent
}
type SdlEvent SdlEventU

struct C.SDL_Surface {
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
type SdlSurface C.SDL_Surface

struct C.SDL_AudioSpec {
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
type SdlAudioSpec C.SDL_AudioSpec

pub fn fill_rect(screen &SdlSurface, rect &SdlRect, _col &SdlColor) {
	col := C.SDL_MapRGB(screen.format, _col.r, _col.g, _col.b)
	C.SDL_FillRect(screen, rect, col)
}
