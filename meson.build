project(
  'libmali', 'c',
  version : '1.9.0',
  meson_version : '>=0.49.0',
  default_options: ['b_asneeded=false', 'b_lundef=false'],
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

if get_option('opencl-icd')
  cl_wrappers = {'MaliOpenCL' : '1'}
else
  cl_wrappers = {'OpenCL' : '1'}
endif

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
  'gbm' : ['gbm_create_device', gbm_wrappers, {'' : 'include/gbm.h'}, '20.1.5'],
  'egl' : ['eglCreateContext', egl_wrappers, egl_headers, '7.10'],
  'glesv1_cm' : ['eglCreateContext', glesv1_wrappers, glesv1_headers, '7.10'],
  'glesv2' : ['eglCreateContext', glesv2_wrappers, glesv2_headers, '7.10'],
  'wayland-egl' : ['wl_egl_window_create', wayland_wrappers, {}, '18.1.0'],
  'OpenCL' : ['clCreateContext', cl_wrappers, cl_headers, '1.2'],
}

# Create dummy source for building libraries
dummy_source = join_paths(meson.current_build_dir(), 'dummy.c')
run_command('touch', dummy_source)

# Create a dummy library for building wrappers
libmali = shared_library(
  'mali',
  dummy_source,
  install : true,
  version : meson.project_version())

# The gbm functions might be missing
gbm_check_funcs = [
  'gbm_bo_map',
  'gbm_bo_unmap',
  'gbm_bo_get_offset',
  'gbm_bo_get_plane_count',
  'gbm_device_get_format_modifier_plane_count',
  'gbm_bo_get_handle_for_plane',
  'gbm_bo_get_stride_for_plane',
  'gbm_bo_get_modifier',
  'gbm_bo_create_with_modifiers',
  'gbm_surface_create_with_modifiers',
  'gbm_bo_get_bpp',
  'gbm_format_get_name',
]

# Create libgbm wrapper for missing functions
libgbm = []
gbm_symbol = map['gbm'][0]
if run_command('grep', '-q', gbm_symbol, default_lib).returncode() == 0
  libgbm_version = gbm_wrappers['gbm']
  libgbm_cflags = []

  libdrm_dep = dependency('libdrm', version : '>= 2.4.0')
  if not libdrm_dep.found()
    error('libdrm not found.')
  endif

  foreach symbol : gbm_check_funcs
    if run_command('grep', '-q', symbol, default_lib).returncode() == 0
      libgbm_cflags += '-DHAS_' + symbol
    endif
  endforeach

  libdl_dep = meson.get_compiler('c').find_library('dl', required : false)
  libgbm = shared_library(
    'gbm',
    'gbm_wrapper.c',
    c_args : libgbm_cflags,
    include_directories : include_directories('include'),
    dependencies : [libdl_dep, libdrm_dep],
    link_with : libmali,
    install : true,
    version : libgbm_version)
endif

foreach name, values : map
  symbol = values[0]
  wrappers = values[1]
  headers = values[2]
  pkg_version = values[3]
  mali_cflags = []
  wrapper_ldflags = []

  # TODO: Use readelf -s ?
  if run_command('grep', '-q', symbol, default_lib).returncode() != 0
    continue
  endif

  if name == 'egl' and platform != 'x11'
    mali_cflags += '-DMESA_EGL_NO_X11_HEADERS'
  endif

  foreach wrapper, version : wrappers
    wrapper_ldflags += '-l' + wrapper

    if wrapper != 'gbm'
      shared_library(
        wrapper,
        dummy_source,
        link_with : [libgbm, libmali],
        install : true,
        version : version)
    endif
  endforeach

  if name == 'OpenCL' and get_option('opencl-icd')
    custom_target(
      'vendor icd',
      output: 'mali.icd',
      command : ['echo', 'libMaliOpenCL.so.1'],
      capture : true,
      install_dir : get_option('sysconfdir') / 'OpenCL' / 'vendors',
      install: true)

    # ICD package doesn't provide headers and pkgconfig
    continue
  endif

  foreach dir, files : headers
    install_headers(files, subdir : dir)
  endforeach

  pkgconfig.generate(
    libraries : ['-L${libdir} -lmali', wrapper_ldflags],
    extra_cflags : mali_cflags,
    version : pkg_version,
    name : name,
    description : 'Mali GPU User-Space Binary Drivers'
  )
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
