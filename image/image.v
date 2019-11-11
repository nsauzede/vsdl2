module image

import nsauzede.vsdl2

#flag linux -lSDL2_image
#include <SDL_image.h>

//////////////////////////////////////////////////////////
// SDL_Image.h
//////////////////////////////////////////////////////////
//fn C.IMG_Load_RW(logo &vsdl2.RwOps, free_src int) &vsdl2.Surface
fn C.IMG_Init(flags int) int
fn C.IMG_Quit()
fn C.IMG_Load(file byteptr) voidptr

pub fn img_init(flags int) int {
	return C.IMG_Init(flags)
}

pub fn quit() {
	C.IMG_Quit()
}

pub fn load(file string) &vsdl2.Surface {
	res := C.IMG_Load(file.str)
	return res
}
