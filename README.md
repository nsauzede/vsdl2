# vsdl2
SDL2 V module -- libSDL2 wrapper

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

You can run the example yourself with:
```
v install nsauzede.vsdl2
v run ~/.vmodules/nsauzede/vsdl2/examples/tvintris/tvintris.v
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
Windows/MSYS2 :
`$ pacman -S mingw-w64-x86_64-SDL2_ttf mingw-w64-x86_64-SDL2_mixer mingw-w64-x86_64-SDL2_image`
