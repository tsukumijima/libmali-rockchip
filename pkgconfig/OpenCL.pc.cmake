prefix=/usr
exec_prefix=${prefix}
libdir=${prefix}/@CMAKE_INSTALL_LIBDIR@
includedir=${prefix}/@CMAKE_INSTALL_INCLUDEDIR@

Name: OpenCL
Description: Mali OpenCL library
Requires.private:
Version: 1.2
Libs: -L${libdir} -lMaliOpenCL
Cflags: -I${includedir} 
