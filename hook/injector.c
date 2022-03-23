extern int mali_injected;

__attribute__((constructor)) static void
_injector() {
   mali_injected = 1;
}
