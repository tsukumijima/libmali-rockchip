prefix=/usr
exec_prefix=${prefix}
libdir=${prefix}/@CMAKE_INSTALL_LIBDIR@
includedir=${prefix}/@CMAKE_INSTALL_INCLUDEDIR@

Name: glesv2
Description: Mali GLESV2 library
Requires.private:
Version:
Libs: -L${libdir} -lGLESv2
Libs.private: -lm -lpthread
Cflags: -I${includedir} 
