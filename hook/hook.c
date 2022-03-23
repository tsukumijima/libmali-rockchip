/*
 *  Copyright (c) 2020, Rockchip Electronics Co., Ltd
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 */

#ifndef _GNU_SOURCE
#define _GNU_SOURCE 1
#endif

#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <xf86drm.h>
#include <sys/mman.h>

#ifdef HAS_GBM
#include <gbm.h>
#endif

#ifdef HAS_X11_EGL
#include <pthread.h>

#include <EGL/egl.h>
#include <EGL/eglext.h>

#include <X11/Xlib.h>
#include <X11/Xlibint.h>
#endif

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))
#endif

#ifndef DRM_FORMAT_MOD_INVALID
#define DRM_FORMAT_MOD_INVALID ((1ULL<<56) - 1)
#endif

/* A stub symbol to ensure that the hook library would not be removed as unused */
int mali_injected = 0;

/* Override libmali symbols */

#ifdef HAS_GBM
static struct gbm_surface * (* _gbm_surface_create)(struct gbm_device *, uint32_t, uint32_t, uint32_t, uint32_t) = NULL;
static struct gbm_bo * (* _gbm_bo_create) (struct gbm_device *, uint32_t, uint32_t, uint32_t, uint32_t) = NULL;
#endif

#ifdef HAS_X11_EGL
static PFNEGLGETPROCADDRESSPROC _eglGetProcAddress = NULL;
static PFNEGLGETDISPLAYPROC _eglGetDisplay = NULL;
static PFNEGLGETPLATFORMDISPLAYPROC _eglGetPlatformDisplay = NULL;
static PFNEGLGETPLATFORMDISPLAYEXTPROC _eglGetPlatformDisplayEXT = NULL;
#endif

#define MALI_SYMBOL(func) { #func, (void **)(&_ ## func), }
static struct {
   const char *func;
   void **symbol;
} mali_symbols[] = {
#ifdef HAS_GBM
   MALI_SYMBOL(gbm_surface_create),
   MALI_SYMBOL(gbm_bo_create),
#endif
#ifdef HAS_X11_EGL
   MALI_SYMBOL(eglGetProcAddress),
   MALI_SYMBOL(eglGetDisplay),
#endif
};

__attribute__((constructor)) static void
load_mali_symbols(void)
{
   void *handle, *symbol;
   int i;

   /* The libmali should be already loaded */
   handle = dlopen(LIBMALI_SO, RTLD_LAZY | RTLD_NOLOAD);
   if (!handle) {
      /* Should not reach here */
      fprintf(stderr, "FATAL: dlopen(" LIBMALI_SO ") failed(%s)\n", dlerror());
      exit(-1);
   }

   for (i = 0; i < ARRAY_SIZE(mali_symbols); i++) {
      const char *func = mali_symbols[i].func;

      /* Clear error */
      dlerror();

      symbol = dlsym(handle, func);
      if (!symbol) {
         /* Should not reach here */
         fprintf(stderr, "FATAL: " LIBMALI_SO " dlsym(%s) failed(%s)\n",
                 func, dlerror());
         exit(-1);
      }

      *mali_symbols[i].symbol = symbol;
   }

   dlclose(handle);

#ifdef HAS_X11_EGL
   _eglGetPlatformDisplay =
      (PFNEGLGETPLATFORMDISPLAYPROC)_eglGetProcAddress("eglGetPlatformDisplay");
   _eglGetPlatformDisplayEXT =
      (PFNEGLGETPLATFORMDISPLAYEXTPROC)_eglGetProcAddress("eglGetPlatformDisplayEXT");
#endif
}

#ifdef HAS_GBM

/* Implement new GBM APIs */

__attribute__((unused)) static inline bool
can_ignore_modifiers(const uint64_t *modifiers,
                     const unsigned int count)
{
   for (int i = 0; i < count; i++) {
      /* linear or invalid */
      if (!modifiers[i] || modifiers[i] == DRM_FORMAT_MOD_INVALID) {
         return true;
      }
   }

   return !count;
}

#ifndef HAS_gbm_bo_get_offset
uint32_t
gbm_bo_get_offset(struct gbm_bo *bo, int plane)
{
   return 0;
}
#endif

#ifndef HAS_gbm_bo_get_modifier
uint64_t
gbm_bo_get_modifier(struct gbm_bo *bo)
{
   return DRM_FORMAT_MOD_INVALID;
}
#endif

#ifndef HAS_gbm_bo_get_plane_count
int
gbm_bo_get_plane_count(struct gbm_bo *bo)
{
   return 1;
}
#endif

#ifndef HAS_gbm_bo_get_stride_for_plane
uint32_t
gbm_bo_get_stride_for_plane(struct gbm_bo *bo, int plane)
{
   if (plane)
      return 0;

   return gbm_bo_get_stride(bo);
}
#endif

#ifndef HAS_gbm_bo_get_fd_for_plane
int
gbm_bo_get_fd_for_plane(struct gbm_bo *bo, int plane)
{
   if (plane)
      return -1;

   return gbm_bo_get_fd(bo);
}
#endif

#ifndef HAS_gbm_bo_get_handle_for_plane
union gbm_bo_handle
gbm_bo_get_handle_for_plane(struct gbm_bo *bo, int plane)
{
   union gbm_bo_handle ret;
   ret.s32 = -1;

   if (plane)
      return ret;

   return gbm_bo_get_handle(bo);
}
#endif

#ifndef HAS_gbm_device_get_format_modifier_plane_count
int
gbm_device_get_format_modifier_plane_count(struct gbm_device *gbm,
                                           uint32_t format,
                                           uint64_t modifier)
{
   return can_ignore_modifiers(&modifier, 1) ? 1 : 0;
}
#endif

#ifndef HAS_gbm_bo_create_with_modifiers
struct gbm_bo *
gbm_bo_create_with_modifiers(struct gbm_device *gbm,
                             uint32_t width, uint32_t height,
                             uint32_t format,
                             const uint64_t *modifiers,
                             const unsigned int count)
{
   if (!can_ignore_modifiers(modifiers, count))
      return NULL;

   return gbm_bo_create(gbm, width, height, format, GBM_BO_USE_LINEAR);
}
#endif

#ifndef HAS_gbm_surface_create_with_modifiers
struct gbm_surface *
gbm_surface_create_with_modifiers(struct gbm_device *gbm,
                                  uint32_t width, uint32_t height,
                                  uint32_t format,
                                  const uint64_t *modifiers,
                                  const unsigned int count)
{
   if (!can_ignore_modifiers(modifiers, count))
      return NULL;

   return gbm_surface_create(gbm, width, height, format, 0);
}
#endif

#ifndef HAS_gbm_bo_map
void *
gbm_bo_map(struct gbm_bo *bo,
           uint32_t x, uint32_t y, uint32_t width, uint32_t height,
           uint32_t flags, uint32_t *stride, void **map_data)
{
   struct drm_mode_map_dumb arg;
   struct gbm_device *gbm_dev;
   void *map;
   int fd, ret;

   if (!bo || !map_data || width <= 0 || width > gbm_bo_get_width(bo) ||
       height <= 0 || height > gbm_bo_get_height(bo)) {
      errno = EINVAL;
      return MAP_FAILED;
   }

   gbm_dev = gbm_bo_get_device(bo);
   if (!gbm_dev)
      return MAP_FAILED;

   fd = gbm_device_get_fd(gbm_dev);
   if (fd < 0)
      return MAP_FAILED;

   memset(&arg, 0, sizeof(arg));
   arg.handle = gbm_bo_get_handle(bo).u32;
   ret = drmIoctl(fd, DRM_IOCTL_MODE_MAP_DUMB, &arg);
   if (ret)
      return MAP_FAILED;

   map = mmap(NULL, gbm_bo_get_stride(bo) * gbm_bo_get_height(bo),
              PROT_READ | PROT_WRITE, MAP_SHARED, fd, arg.offset);
   if (map == MAP_FAILED)
      return map;

   *map_data = map;

   if (stride)
      *stride = gbm_bo_get_stride(bo);

   return map + y * gbm_bo_get_stride(bo) + x * (gbm_bo_get_bpp(bo) >> 3);
}
#endif

#ifndef HAS_gbm_bo_unmap
void
gbm_bo_unmap(struct gbm_bo *bo, void *map_data)
{
   if (map_data)
      munmap(map_data, gbm_bo_get_stride(bo) * gbm_bo_get_height(bo));
}
#endif

/* From mesa3d 20.1.5 : src/gbm/main/gbm.c */
#ifndef HAS_gbm_bo_get_bpp
uint32_t
gbm_bo_get_bpp(struct gbm_bo *bo)
{
   switch (gbm_bo_get_format(bo)) {
   default:
      return 0;
   case GBM_FORMAT_C8:
   case GBM_FORMAT_R8:
   case GBM_FORMAT_RGB332:
   case GBM_FORMAT_BGR233:
      return 8;
   case GBM_FORMAT_GR88:
   case GBM_FORMAT_XRGB4444:
   case GBM_FORMAT_XBGR4444:
   case GBM_FORMAT_RGBX4444:
   case GBM_FORMAT_BGRX4444:
   case GBM_FORMAT_ARGB4444:
   case GBM_FORMAT_ABGR4444:
   case GBM_FORMAT_RGBA4444:
   case GBM_FORMAT_BGRA4444:
   case GBM_FORMAT_XRGB1555:
   case GBM_FORMAT_XBGR1555:
   case GBM_FORMAT_RGBX5551:
   case GBM_FORMAT_BGRX5551:
   case GBM_FORMAT_ARGB1555:
   case GBM_FORMAT_ABGR1555:
   case GBM_FORMAT_RGBA5551:
   case GBM_FORMAT_BGRA5551:
   case GBM_FORMAT_RGB565:
   case GBM_FORMAT_BGR565:
      return 16;
   case GBM_FORMAT_RGB888:
   case GBM_FORMAT_BGR888:
      return 24;
   case GBM_FORMAT_XRGB8888:
   case GBM_FORMAT_XBGR8888:
   case GBM_FORMAT_RGBX8888:
   case GBM_FORMAT_BGRX8888:
   case GBM_FORMAT_ARGB8888:
   case GBM_FORMAT_ABGR8888:
   case GBM_FORMAT_RGBA8888:
   case GBM_FORMAT_BGRA8888:
   case GBM_FORMAT_XRGB2101010:
   case GBM_FORMAT_XBGR2101010:
   case GBM_FORMAT_RGBX1010102:
   case GBM_FORMAT_BGRX1010102:
   case GBM_FORMAT_ARGB2101010:
   case GBM_FORMAT_ABGR2101010:
   case GBM_FORMAT_RGBA1010102:
   case GBM_FORMAT_BGRA1010102:
      return 32;
   case GBM_FORMAT_XBGR16161616F:
   case GBM_FORMAT_ABGR16161616F:
      return 64;
   }
}
#endif

/* From mesa3d 20.1.5 : src/gbm/main/gbm.c */
#ifndef HAS_gbm_format_get_name
static uint32_t
gbm_format_canonicalize(uint32_t gbm_format)
{
   switch (gbm_format) {
   case GBM_BO_FORMAT_XRGB8888:
      return GBM_FORMAT_XRGB8888;
   case GBM_BO_FORMAT_ARGB8888:
      return GBM_FORMAT_ARGB8888;
   default:
      return gbm_format;
   }
}

char *
gbm_format_get_name(uint32_t gbm_format, struct gbm_format_name_desc *desc)
{
   gbm_format = gbm_format_canonicalize(gbm_format);

   desc->name[0] = gbm_format;
   desc->name[1] = gbm_format >> 8;
   desc->name[2] = gbm_format >> 16;
   desc->name[3] = gbm_format >> 24;
   desc->name[4] = 0;

   return desc->name;
}
#endif

/* Wrappers for unsupported flags */

struct gbm_surface *
gbm_surface_create(struct gbm_device *gbm,
                   uint32_t width, uint32_t height,
                   uint32_t format, uint32_t flags)
{
   struct gbm_surface *surface;

   surface = _gbm_surface_create(gbm, width, height, format, flags);
   if (surface)
      return surface;

   flags &= GBM_BO_USE_SCANOUT | GBM_BO_USE_RENDERING;
   return _gbm_surface_create(gbm, width, height, format, flags);
}

struct gbm_bo *
gbm_bo_create(struct gbm_device *gbm,
              uint32_t width, uint32_t height,
              uint32_t format, uint32_t flags)
{
   struct gbm_bo *bo;

   bo = _gbm_bo_create(gbm, width, height, format, flags);
   if (bo)
      return bo;

   flags &= GBM_BO_USE_SCANOUT | GBM_BO_USE_RENDERING |
      GBM_BO_USE_WRITE | GBM_BO_USE_CURSOR_64X64;
   return _gbm_bo_create(gbm, width, height, format, flags);
}

#endif // HAS_GBM

#ifdef HAS_X11_EGL

/* Hacked displays (should not be much) */
#define MAX_X11_DISPLAY 32
static Display *_x11_displays[MAX_X11_DISPLAY] = { NULL, };

static pthread_mutex_t _x11_mutex = PTHREAD_MUTEX_INITIALIZER;

static inline int
force_x11_threads(void)
{
   return !getenv("MALI_X11_NO_FORCE_THREADS");
}

__attribute__((constructor)) static void
init_x11_threads(void)
{
   if (force_x11_threads())
      XInitThreads();
}

__attribute__((destructor)) static void
cleanup_x11_display(void)
{
   int i;

   for (i = 0; i < MAX_X11_DISPLAY; i++) {
      Display *display = _x11_displays[i];
      if (display)
         XCloseDisplay(display);
   }
}

static Display *
fixup_x11_display(Display *display)
{
   int i;

   if (!force_x11_threads())
      return display;

   if (!display || display->lock_fns)
      return display;

   pthread_mutex_lock(&_x11_mutex);
   /* Create a new threaded display */
   display = XOpenDisplay(DisplayString(display));

   for (i = 0; i < MAX_X11_DISPLAY; i++) {
      if (!_x11_displays[i]) {
         _x11_displays[i] = display;
         break;
      }
   }
   pthread_mutex_unlock(&_x11_mutex);

   return display;
}

/* Override libmali symbols */

EGLAPI EGLDisplay EGLAPIENTRY
eglGetDisplay (EGLNativeDisplayType display_id)
{
   Display *display = fixup_x11_display((void *)display_id);

   return _eglGetDisplay((EGLNativeDisplayType)display);
}

EGLAPI EGLDisplay EGLAPIENTRY
eglGetPlatformDisplay(EGLenum platform, void *native_display, const EGLAttrib *attrib_list)
{
   if (!_eglGetPlatformDisplay)
      return EGL_NO_DISPLAY;

   if (platform == EGL_PLATFORM_X11_KHR && native_display) {
      native_display = (void *)fixup_x11_display(native_display);
      if (!native_display)
         return EGL_NO_DISPLAY;
   }

   return _eglGetPlatformDisplay(platform, native_display, attrib_list);
}

EGLAPI EGLDisplay EGLAPIENTRY
eglGetPlatformDisplayEXT (EGLenum platform, void *native_display, const EGLint *attrib_list)
{
   if (!_eglGetPlatformDisplayEXT)
      return EGL_NO_DISPLAY;

   if (platform == EGL_PLATFORM_X11_KHR && native_display) {
      native_display = (void *)fixup_x11_display(native_display);
      if (!native_display)
         return EGL_NO_DISPLAY;
   }

   return _eglGetPlatformDisplayEXT(platform, native_display, attrib_list);
}

EGLAPI __eglMustCastToProperFunctionPointerType EGLAPIENTRY
eglGetProcAddress(const char *procname)
{
   if (!procname)
      return NULL;

   if (!strcmp(procname, __func__))
      return (__eglMustCastToProperFunctionPointerType)eglGetProcAddress;

   if (!strcmp(procname, "eglGetDisplay"))
      return (__eglMustCastToProperFunctionPointerType)eglGetDisplay;

   if (!strcmp(procname, "eglGetPlatformDisplay")) {
      if (!_eglGetPlatformDisplay)
         return NULL;
      return (__eglMustCastToProperFunctionPointerType)eglGetPlatformDisplay;
   }

   if (!strcmp(procname, "eglGetPlatformDisplayEXT")) {
      if (!_eglGetPlatformDisplayEXT)
         return NULL;
      return (__eglMustCastToProperFunctionPointerType)eglGetPlatformDisplayEXT;
   }

   return _eglGetProcAddress(procname);
}

#endif // HAS_X11
