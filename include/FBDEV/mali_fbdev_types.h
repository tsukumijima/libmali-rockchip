/*
 * This confidential and proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 * (C) COPYRIGHT 2014-2015 ARM Limited
 * ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 */
#ifndef _MALI_FBDEV_TYPES_H_
#define _MALI_FBDEV_TYPES_H_

typedef struct fbdev_window
{
	unsigned short width;
	unsigned short height;
} fbdev_window;

typedef struct mali_native_window
{
	unsigned short width;
	unsigned short height;
} mali_native_window;

typedef union mem_handle
{
	int fd;                    /* fd to dma memory */
} mem_handle;

typedef struct egl_linux_pixmap
{
	int width, height;

	struct
	{
		/** @brief The line stride of each plane.
		 * For each plane required by the format, the number of bytes from one line of samples to the next. Other entries in
		 * the array should be 0.
		 */
		khronos_usize_t stride;
		/** @brief The byte size of each plane.
		 * For each plane required by the format, the number of bytes taken up by that plane. That includes any space wasted
		 * in partially-used blocks.
		 */
		khronos_usize_t size;
		/** @brief The offset from the memory handle to each plane.
		 * For each plane required by the format, the number of bytes from the start of the UMP region to the start of that
		 * plane. Other entries in the array should be 0.
		 */
		khronos_usize_t offset;
	}
	planes[3];

	/** An integer that specifies the format of the pixmap. Its meaning is known by tpi and winsys. */
	uint64_t pixmap_format;

	/** Three buffers that can be used by this pixmap. In case of RGB pixmap only the first one is going to be
	 * used. In case of YUV pixmap all three of them can be used for storing Y, U and V color coordinates separately.*/
	mem_handle handles[3];
} egl_linux_pixmap;

typedef struct dummy_display
{
	int width;
	int height;
	int bytes_per_pixel;
	int red_mask;
	int green_mask;
	int blue_mask;
	int alpha_mask;
	unsigned char *front_buffer;
} dummy_display;

/** Converts a pixmap ID to the corresponding pixmap structure.
 *
 * @param[in] id The pixmap ID to lookup
 *
 * @return A pointer to the pixmap structure or NULL on failure
 */
egl_linux_pixmap* egl_lookup_pixmap_ID_mapping(int32_t id);

/** Creates a pixmap ID from a pixmap structure.
 *
 * @param[in] pixmap
 *
 * @return The pixmap ID or -1 on failure
 */
int32_t egl_create_pixmap_ID_mapping(egl_linux_pixmap* pixmap);

/** Destroy a pixmap ID to pixmap structure mapping. The caller is responsible for
 *  destroying the pixmap structure.
 *
 * @param[in] id The pixmap ID for which the corresponding
 *               mapping should be destroyed
 *
 * @return EGL_TRUE on success or EGL_FALSE on failure
 */
unsigned int egl_destroy_pixmap_ID_mapping(int32_t id);

#endif /* _MALI_FBDEV_TYPES_H_ */
