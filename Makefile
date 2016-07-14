all:
	
install:
	install -d -m 755 $(DESTDIR)/usr/lib/$(DEB_HOST_MULTIARCH)
	install -D -m 644 lib/*.so $(DESTDIR)/usr/lib/$(DEB_HOST_MULTIARCH)
	install -d -m 755 $(DESTDIR)/usr/include/
	install -D -m 644 include/*.h $(DESTDIR)/usr/include/
	install -d -m 755 $(DESTDIR)/usr/lib/pkgconfig/
	install -D -m 644 pkgconfig/*.pc $(DESTDIR)/usr/lib/pkgconfig/

.PHONY: install
