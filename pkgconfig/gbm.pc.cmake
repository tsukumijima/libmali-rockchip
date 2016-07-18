prefix=/usr
exec_prefix=${prefix}
libdir=${prefix}/@CMAKE_INSTALL_LIBDIR@
includedir=${prefix}/@CMAKE_INSTALL_INCLUDEDIR@

Name: gbm
Description: Mali GBM library
Requires.private: 
Version: 10.4.0
Libs: -L${libdir} -lgbm
Libs.private: 
Cflags: -I${includedir} 
