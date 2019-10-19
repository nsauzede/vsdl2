// Copyright(C) 2019 Nicolas Sauzede. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.

module vsdl2

#flag linux `sdl2-config --cflags --libs`  -lSDL2_ttf -lSDL2_mixer
//#flag windows `sdl2-config --cflags`
//#flag windows `sdl2-config --libs`  -lSDL2_ttf -lSDL2_mixer
//#flag `sdl2-config --cflags --libs`  -lSDL2_ttf -lSDL2_mixer

// following kludge until `sdl2-config ...` is supported also on windows
#flag windows -I/msys64/mingw64/include/SDL2
#flag windows -Dmain=SDL_main
#flag windows -L/mingw64/lib -lmingw32 -lSDL2main -lSDL2

#include <SDL.h>
#include <SDL_ttf.h>
#include <SDL_mixer.h>


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

union SdlEventU {
pub:
        _type u32
        quit SdlQuitEvent
        key SdlKeyboardEvent
        jbutton SdlJoyButtonEvent
        jhat SdlJoyHatEvent
        _pad56 [56]byte
}
type SdlEvent SdlEventU


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

//////////////////////////////////////////////////////////

fn C.SDL_MapRGB(fmt voidptr, r byte, g byte, b byte) u32
fn C.SDL_CreateRGBSurface(flags u32, width int, height int, depth int, Rmask u32, Gmask u32, Bmask u32, Amask u32) &SdlSurface
fn C.SDL_PollEvent(&SdlEvent) int

//////////////////////////////////////////////////////////

pub fn fill_rect(screen &SdlSurface, rect &SdlRect, _col &SdlColor) {
	col := C.SDL_MapRGB(screen.format, _col.r, _col.g, _col.b)
	C.SDL_FillRect(screen, rect, col)
}

const (
  version = '0.2' // hack to avoid unused module warning in the main program
)

