project(
  'libmali', 'c',
  version : '1.9.0',
  meson_version : '>=0.53.0')

mali_version = meson.project_version()

fs = import('fs')
pkgconfig = import('pkgconfig')

cc = meson.get_compiler('c')

if get_option('arch') != 'auto'
  arch = get_option('arch')
else
  arch = host_machine.cpu_family()
endif

gpu = get_option('gpu')
version = get_option('version')
subversion = get_option('subversion')
platform = get_option('platform')
opencl_icd = get_option('opencl-icd')
vendor_package = get_option('vendor-package')
build_hook = get_option('hooks')
wrappers_opts = get_option('wrappers')
optimize = get_option('optimize-level')

message('Building for ' + '|'.join([arch, gpu, version, subversion,
  platform, optimize]))

# Grab libraries with specified configs
cmd = run_command('scripts/grabber.sh',
  arch, gpu, version, subversion, platform, optimize, check : false)
libs = cmd.stdout().strip().split(' ')

# Use the first one as default library
default_lib = libs[0]
if default_lib == ''
  error('Failed to find matched library')
endif

message('Source libraries: @0@'.format(libs))

# Load original mali library for later function checks and linking
run_command('ln', '-rsf', meson.current_source_dir() / default_lib,
  meson.current_build_dir() / 'libmali-prebuilt.so', check : false)
mali = cc.find_library('mali-prebuilt', dirs : meson.current_build_dir())

is_rk3288 = gpu == 'midgard-t76x'
is_utgard = gpu.split('-')[0] == 'utgard'
is_px3se = gpu == 'utgard-400' and subversion == 'r3p0'

# Parse platforms
has_gbm = run_command('grep', '-wq', 'gbm_create_device', default_lib,
  check : false).returncode() == 0
has_x11 = run_command('grep', '-wq', 'XSync', default_lib,
  check : false).returncode() == 0
has_wayland = run_command('grep', '-wq', 'wl_egl_window_create', default_lib,
  check : false).returncode() == 0

message('Using ' + default_lib + ' with' + (has_x11 ? ' x11' : '') +
  (has_wayland ? ' wayland' : '') + (has_gbm ? ' gbm' : ''))

# Required packages
requires = []
if has_gbm or has_wayland or has_x11
  requires = ['libdrm']
endif
if has_wayland
  requires += ['wayland-client', 'wayland-server']

  if is_px3se
    requires += ['libffi', 'libcrypto']
  endif
endif
if has_x11
  requires += ['x11', 'xcb']

  if is_utgard
    requires += ['xfixes', 'xext', 'xau', 'xdmcp', 'xdamage']
  else
    requires += ['x11-xcb', 'xcb-dri2']
  endif
endif

# Required dependencies
foreach require : requires
  dependency(require)
endforeach

if wrappers_opts.auto() and is_utgard
  wrappers = false
  warning('Wrappers are disabled for utgard by default')
else
  wrappers = not wrappers_opts.disabled()
endif

if wrappers
  message('Provide wrappers')

  # Wrappers would link to the real library.
  add_project_link_arguments('-Wl,--no-as-needed', language : 'c')
else
  # The vendor package requires soname of wrappers.
  if vendor_package
    error('Cannot provide vendor package without wrappers')
  endif
endif

# Install wrapper libraries into vendor dir
if vendor_package
  message('Build vendor package')
  wrapper_libdir = get_option('libdir') / 'mali'
else
  wrapper_libdir = get_option('libdir')
endif

# Wrap library name : version
gbm_wrappers = {'gbm' : '1'}
egl_wrappers = {'EGL' : '1'}
glesv1_wrappers = {'GLESv1_CM' : '1'}
glesv2_wrappers = {'GLESv2' : '2'}
wayland_wrappers = {'wayland-egl' : '1'}
cl_wrappers = opencl_icd ? {'MaliOpenCL' : '1'} : {'OpenCL' : '1'}
vk_wrappers = {'MaliVulkan' : '1'}

# Provide newer GBM version with hook library
if build_hook
  gbm_version = '23.1.3'
elif cc.has_function('gbm_bo_get_fd_for_plane', dependencies : mali)
  gbm_version = '21.1.0'
elif cc.has_function('gbm_bo_get_modifier', dependencies : mali)
  gbm_version = '17.1.0'
else
  gbm_version = '10.4.0'
endif

# Source dir : dest dir
gbm_headers = {
  'include/GBM' / gbm_version : '',
}
egl_headers = {
  'include/KHR' : 'KHR',
  'include/EGL' : 'EGL',
}
glesv1_headers = {
  'include/KHR' : 'KHR',
  'include/GLES' : 'GLES',
}
glesv2_headers = {
  'include/KHR' : 'KHR',
  'include/GLES2' : 'GLES2',
  'include/GLES3' : 'GLES3',
}
wayland_egl_headers = {
  'include/WAYLAND' : '',
}
cl_headers = {
  'include/CL' : 'CL',
}

if cc.has_function('clCreateBufferWithProperties', dependencies : mali)
  cl_version = '3.0'
  cl_target_version = '300'
elif cc.has_function('clSetProgramReleaseCallback', dependencies : mali)
  cl_version = '2.2'
  cl_target_version = '220'
elif cc.has_function('clCloneKernel', dependencies : mali)
  cl_version = '2.1'
  cl_target_version = '210'
elif cc.has_function('clCreatePipe', dependencies : mali)
  cl_version = '2.0'
  cl_target_version = '200'
else
  cl_version = '1.2'
  cl_target_version = '120'
endif

# Package name : required symbol, wrappers, headers, package version
map = {
  'gbm' : ['gbm_create_device', gbm_wrappers, gbm_headers, gbm_version],
  'egl' : ['eglCreateContext', egl_wrappers, egl_headers, '7.10'],
  'glesv1_cm' : ['eglCreateContext', glesv1_wrappers, glesv1_headers, '7.10'],
  'glesv2' : ['eglCreateContext', glesv2_wrappers, glesv2_headers, '7.10'],
  'wayland-egl' : ['wl_egl_window_create', wayland_wrappers,
    wayland_egl_headers, '18.1.0'],
  'OpenCL' : ['clCreateContext', cl_wrappers, cl_headers, cl_version],
  'vulkan' : ['vk_icdGetInstanceProcAddr', vk_wrappers, {}, mali_version],
}

libhook = []
if build_hook
  # Build hook library
  subdir('hook')

  # Recommend to link hook library before libmali
  mali_ldflags = libhook_ldflags
else
  mali_ldflags = []
endif

# Create dummy source for building dummy libraries
dummy_source = join_paths(meson.current_build_dir(), 'dummy.c')
run_command('touch', dummy_source, check : false)

# Create a dummy library which will be replaced by the prebuilt mali library
libmali = shared_library(
  'mali',
  dummy_source,
  install : true,
  version : mali_version)

mali_ldflags += ['-L${libdir}', '-lmali']

pkgconfig.generate(
  libraries : mali_ldflags,
  requires : requires,
  name : 'mali',
  description : 'Mali GPU User-Space Binary Driver')

if is_utgard
  # The utgard DDK requires libMali.so
  custom_target(
    'libMali',
    output : 'libMali.so',
    command : ['echo'],
    capture : true,
    install_dir : get_option('libdir'),
    install : true)
endif

foreach name, values : map
  symbol = values[0]
  wrapper_libs = values[1]
  headers = values[2]
  pkg_version = values[3]
  pkg_cflags = []
  is_opencl_icd = opencl_icd and name == 'OpenCL'
  is_vulkan_icd = name == 'vulkan'

  if not cc.has_function(symbol, dependencies : mali)
    continue
  endif

  foreach wrapper, version : wrapper_libs
    shared_library(
      wrapper,
      dummy_source,
      link_with : [libhook, libmali],
      install : true,
      install_dir : wrapper_libdir,
      install_rpath : '$ORIGIN',
      version : version)
  endforeach

  # Install ICD OpenCL vendor config
  if is_opencl_icd
    custom_target(
      'OpenCL vendor icd',
      output : 'mali.icd',
      command : ['echo', 'libMaliOpenCL.so.1'],
      capture : true,
      install_dir : get_option('sysconfdir') / 'OpenCL' / 'vendors',
      install : true)
  endif

  # Install ICD Vulkan vendor config
  if is_vulkan_icd
    custom_target(
      'Vulkan vendor icd',
      input : 'data/vulkan/mali.json.in',
      output : 'mali.json',
      command : ['sed', 's/@LIB@/libMaliVulkan.so.1/', '@INPUT@'],
      capture : true,
      install_dir : get_option('datadir') / 'vulkan' / 'icd.d',
      install : true)
  endif

  # No {headers, pkgconfig} for {ICD, vendor packages}
  if is_opencl_icd or is_vulkan_icd or vendor_package
    continue
  endif

  foreach src, dst : headers
    install_subdir(
      src,
      install_dir : get_option('includedir') / dst,
      install_mode : ['rw-r--r--', 'root'],
      strip_directory : true)
  endforeach

  if name == 'gbm'
    # Hack unsupported gbm_bo flags
    meson.add_install_script('scripts/fixup_gbm.sh', get_option('includedir'))
  endif

  if name == 'egl' and not has_x11
    # Disable X11 in EGL header
    meson.add_install_script('scripts/fixup_egl_nox11.sh',
      get_option('includedir'))
  endif

  if name == 'OpenCL'
    pkg_cflags += ['-DCL_TARGET_OPENCL_VERSION=' + cl_target_version]

    meson.add_install_script('scripts/fixup_cl.sh',
      get_option('includedir'), cl_version)
  endif

  pkgconfig.generate(
    libraries : mali_ldflags,
    extra_cflags : pkg_cflags,
    requires : requires,
    version : pkg_version,
    name : name,
    description : 'Mali GPU User-Space Binary Driver Wrappers')
endforeach

# Install optional overlay
if get_option('with-overlay')
  if is_px3se
    install_data('overlay/S10libmali_px3se',
      install_dir : get_option('sysconfdir') / 'init.d')
    install_data('overlay/px3seBase', install_dir : get_option('bindir'))
  endif

  if is_rk3288 and subversion == 'all'
    install_data('overlay/S10libmali_rk3288',
      install_dir : get_option('sysconfdir') / 'init.d')
  endif
endif

# Install firmwares
if gpu == 'valhall-g610'
  install_data('firmware/g610/mali_csffw.bin',
    install_dir : get_option('firmware-dir'))
endif

if vendor_package
  # Install vendor ld config
  custom_target(
    'vendor ld config',
    output : '00-' + arch + '-mali.conf',
    command : ['echo', get_option('prefix') / wrapper_libdir],
    capture : true,
    install_dir : '/etc/ld.so.conf.d',
    install : true)
elif get_option('khr-header')
  # Install optional KHR header
  install_data(
    'include/KHR/mali_khrplatform.h',
    install_dir : get_option('includedir') / 'KHR',
    install_mode : ['rw-r--r--', 'root'],
    rename : 'khrplatform.h')
endif

# Install target libraries
install_data(libs, install_dir : get_option('libdir'))

# Replace dummy libmali library
meson.add_install_script('scripts/fixup_dummy.sh',
  get_option('libdir'), default_lib)

if not wrappers
  # Disable wrappers
  meson.add_install_script('scripts/fixup_nowrap.sh', get_option('libdir'))
endif
