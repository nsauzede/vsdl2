# vsdl2
SDL2 V module -- libSDL2 wrapper

Current APIs available/tested in examples :
- basic graphics (2D drawing)
- TTF font (text rendering)
- input handling (keyboard/joystick events)
- sounds (WAV mixing)
- music (MOD mixing)
- more to come.. (networking ?)

# Examples

[tVintris](https://github.com/nsauzede/vsdl2/tree/master/examples/tvintris)

![tVintris screenshot](https://github.com/nsauzede/vsdl2/blob/master/examples/tvintris/tvintris.png)

# Dependencies
Ubuntu :
`$ sudo apt install libsdl2-ttf-dev libsdl2-mixer-dev`

ClearLinux :
`$ sudo swupd bundle-add devpkg-SDL2_ttf devpkg-SDL2_mixer`

Windows/MSYS2 :
`$ pacman -S mingw-w64-x86_64-SDL2_ttf mingw-w64-x86_64-SDL2_mixer`
