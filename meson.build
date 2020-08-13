project(
  'libmali', 'c',
  version : '1.9.0',
  meson_version : '>=0.49.0',
  default_options: ['b_asneeded=false'],
)

pkgconfig = import('pkgconfig')

if get_option('arch') != 'auto'
  arch = get_option('arch')
else
  arch = host_machine.cpu_family()
endif

gpu = get_option('gpu')
version = get_option('version')
subversion = get_option('subversion')
platform = get_option('platform')

# Grab libraries with specified configs
c = run_command('grabber.sh', arch, gpu, version, subversion, platform)
libs = c.stdout().strip().split('\n')

# Use the first one as default library
default_lib = libs[0]
if default_lib == ''
  error('failed to find matched library.')
endif

message('building for @0@'.format(libs))

# Wrap library name : version
mali_wrappers = {'Mali' : '1'}
gbm_wrappers = {'gbm' : '1'}
egl_wrappers = {'EGL' : '1'}
glesv1_wrappers = {'GLESv1_CM' : '1'}
glesv2_wrappers = {'GLESv2' : '2'}
wayland_wrappers = {'wayland-egl' : '1'}
cl_wrappers = {'OpenCL' : '1', 'MaliOpenCL' : '1'}

# Subdir : headers
mali_headers = {
  'KHR' : ['include/KHR/mali_khrplatform.h'],
}
egl_headers = {
  'EGL' : [
    'include/EGL/eglplatform.h',
    'include/EGL/eglext.h',
    'include/EGL/egl.h',
  ],
}
glesv1_headers = {
  'GLES' : [
    'include/GLES/gl.h',
    'include/GLES/glplatform.h',
    'include/GLES/glext.h',
    'include/GLES/egl.h',
  ],
}
glesv2_headers = {
  'GLES2' : [
    'include/GLES2/gl2ext.h',
    'include/GLES2/gl2.h',
    'include/GLES2/gl2platform.h',
  ],
  'GLES3' : [
    'include/GLES3/gl3.h',
    'include/GLES3/gl32.h',
    'include/GLES3/gl3platform.h',
    'include/GLES3/gl31.h',
  ],
}
cl_headers = {
  'CL': [
    'include/CL/cl_gl.h',
    'include/CL/cl.h',
    'include/CL/cl_dx9_media_sharing_intel.h',
    'include/CL/cl_ext_intel.h',
    'include/CL/cl_d3d10.h',
    'include/CL/opencl.h',
    'include/CL/cl_d3d11.h',
    'include/CL/cl_platform.h',
    'include/CL/cl_ext.h',
    'include/CL/cl_egl.h',
    'include/CL/cl_dx9_media_sharing.h',
    'include/CL/cl_va_api_media_sharing_intel.h',
    'include/CL/cl_gl_ext.h',
  ],
}

# Package name : required symbol, wrappers, headers, package version
map = {
  'mali' : ['', mali_wrappers, mali_headers, meson.project_version()],
  'gbm' : ['gbm_create_device', gbm_wrappers, {'' : 'include/gbm.h'}, '10.4.0'],
  'egl' : ['eglCreateContext', egl_wrappers, egl_headers, '7.10'],
  'glesv1_cm' : ['eglCreateContext', glesv1_wrappers, glesv1_headers, '7.10'],
  'glesv2' : ['eglCreateContext', glesv2_wrappers, glesv2_headers, '7.10'],
  'wayland-egl' : ['wl_egl_window_create', wayland_wrappers, {}, '18.1.0'],
  'OpenCL' : ['clCreateContext', cl_wrappers, cl_headers, '1.2'],
}

# Create dummy source for building libraries
run_command('touch', join_paths(meson.current_build_dir(), 'dummy.c'))

# Create a dummy library for building wrappers
libmali = shared_library(
  'mali',
  join_paths(meson.current_build_dir(), 'dummy.c'),
  install : true,
  version : meson.project_version())

foreach name, values : map
  symbol = values[0]
  wrappers = values[1]
  headers = values[2]
  pkg_version = values[3]
  mali_cflags = []

  # TODO: Use readelf -s ?
  if run_command('grep', '-q', symbol, default_lib).returncode() != 0
    continue
  endif

  if name == 'egl' and platform != 'x11'
    mali_cflags += '-DMESA_EGL_NO_X11_HEADERS'
  endif

  foreach wrapper, version : wrappers
    shared_library(
      wrapper,
      join_paths(meson.current_build_dir(), 'dummy.c'),
      link_with : libmali,
      install : true,
      version : version)
  endforeach

  foreach dir, files : headers
    install_headers(files, subdir : dir)
  endforeach

  pkgconfig.generate(
    libraries : ['-L${libdir} -lmali'],
    extra_cflags : mali_cflags,
    version : pkg_version,
    name : name,
    description : 'Mali GPU User-Space Binary Drivers'
  )

  if name == 'OpenCL'
    install_data('include/mali.icd', install_dir : get_option('sysconfdir') / 'OpenCL' / 'vendors')
  endif
endforeach

# Install optional overlay
if get_option('with-overlay')
  if gpu == 'utgard-400' and subversion == 'r3p0'
    install_data('overlay/S10libmali_px3se', install_dir : get_option('sysconfdir') / 'init.d')
    install_data('overlay/px3seBase', install_dir : get_option('bindir'))
  endif

  if gpu == 'midgard-t76x' and subversion == 'all'
    install_data('overlay/S10libmali_rk3288', install_dir : get_option('sysconfdir') / 'init.d')
  endif
endif

# Install target libraries and replace the dummy one
install_data(libs, install_dir : get_option('libdir'))
meson.add_install_script('postinst.sh', get_option('libdir'), default_lib)
