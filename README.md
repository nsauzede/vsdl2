# vsdl2
SDL2 V module -- libSDL2 wrapper

*IMPORTANT
vsdl2 has been integrated in V `vlib/sdl` [here](https://github.com/vlang/v/tree/master/vlib/sdl).
Not sure what will become of this legacy SDL PoC..*

In fact, the `sdl` component of upstrean vlang seems to have moved [there](https://github.com/vlang/sdl) and be pretty much out of date.
Thus, I'll continue maintaining my initial SDL2 work here, as time permits..


Current APIs available/tested in examples :
- basic graphics (2D drawing)
- [Image](image/README.md)
- TTF font (text rendering)
- input handling (keyboard/joystick events)
- sounds (WAV mixing)
- music (MOD mixing)
- more to come.. (networking ?)

# Support
vsdl2 is supported on :
- linux (major distros)
- MacOS (brew)
- windows (msys2/mingw64 only for now)

# Installation
`v install nsauzede.vsdl2`

# Examples

[tVintris](https://github.com/nsauzede/vsdl2/tree/master/examples/tvintris)

![tVintris screenshot](https://github.com/nsauzede/vsdl2/blob/master/examples/tvintris/tvintris.png)

Once you have installed nsauzede.vsdl2 (see above), you can run the example yourself like this :
On linux:
```
v run ~/.vmodules/nsauzede/vsdl2/examples/tvintris/tvintris.v
```
On Windows (MSYS2):
```
v run /c/Users/${USER}/.vmodules/nsauzede/vsdl2/examples/tvintris/tvintris.v
```

# Dependencies

## Linux
Fedora :
`$ sudo dnf install SDL2-devel SDL2_ttf-devel SDL2_mixer-devel SDL2_image-devel`

Ubuntu :
`$ sudo apt install libsdl2-ttf-dev libsdl2-mixer-dev libsdl2-image-dev`

ClearLinux :
`$ sudo swupd bundle-add devpkg-SDL2_ttf devpkg-SDL2_mixer devpkg-SDL2_image`

## MacOS
Brew :
`$ brew install sdl2 sdl2_gfx sdl2_ttf sdl2_mixer sdl2_image sdl2_net`

## Windows
Windows (MSYS2) :
`$ pacman -S mingw-w64-x86_64-SDL2_ttf mingw-w64-x86_64-SDL2_mixer mingw-w64-x86_64-SDL2_image`

# Contributions

Thanks to spytheman and adlesh for their contributions to vsdl2
