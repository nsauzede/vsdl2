module image
#flag linux -lSDL2_image
#include <SDL_image.h>


//////////////////////////////////////////////////////////
// SDL_Image.h
//////////////////////////////////////////////////////////

pub fn img_init(flags int) int {
        return C.IMG_Init(flags)
}

pub fn quit() {
        C.IMG_Quit()
}

pub fn load(file byteptr) &vsdl2.SdlSurface {
        return C.IMG_Load(file)
}