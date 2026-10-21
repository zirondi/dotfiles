// sketchybar-menus: list or open the menu bar menus of the focused app, so
// SketchyBar can show them while the native menu bar is hidden.
//
//   sketchybar-menus -l      print one menu title per line (Apple menu skipped;
//                            the first line is the app menu)
//   sketchybar-menus -s N    open menu N (0-based, same order as -l)
//   sketchybar-menus -t      print the focused window's title (a browser's
//                            current tab)
//   sketchybar-menus -p PID … use that app instead of detecting the focused
//                            one (scripts pass the pid lsappinfo reports, since
//                            a system dialog can own the frontmost window)
//
// Needs Accessibility. Run from SketchyBar, it uses SketchyBar's permission.

#include <ApplicationServices/ApplicationServices.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// pid of the owner of the frontmost normal window (layer 0)
static pid_t frontmost_pid(void) {
  pid_t pid = 0;
  CFArrayRef windows = CGWindowListCopyWindowInfo(
      kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
  if (!windows) return 0;
  for (CFIndex i = 0; i < CFArrayGetCount(windows) && !pid; i++) {
    CFDictionaryRef w = CFArrayGetValueAtIndex(windows, i);
    int layer = -1;
    CFNumberRef layer_ref = CFDictionaryGetValue(w, kCGWindowLayer);
    if (layer_ref) CFNumberGetValue(layer_ref, kCFNumberIntType, &layer);
    if (layer != 0) continue;
    CFNumberRef pid_ref = CFDictionaryGetValue(w, kCGWindowOwnerPID);
    if (pid_ref) CFNumberGetValue(pid_ref, kCFNumberIntType, &pid);
  }
  CFRelease(windows);
  return pid;
}

static AXUIElementRef focused_app(void) {
  AXUIElementRef system = AXUIElementCreateSystemWide();
  CFTypeRef app = NULL;
  AXError err = AXUIElementCopyAttributeValue(system, kAXFocusedApplicationAttribute, &app);
  CFRelease(system);
  if (err == kAXErrorSuccess && app) return (AXUIElementRef)app;
  // macOS 27 can refuse the system-wide query; ask the frontmost app directly
  pid_t pid = frontmost_pid();
  return pid ? AXUIElementCreateApplication(pid) : NULL;
}

static CFArrayRef menu_bar_items(AXUIElementRef app) {
  CFTypeRef bar = NULL;
  CFTypeRef items = NULL;
  if (AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute, &bar) != kAXErrorSuccess)
    return NULL;
  AXUIElementCopyAttributeValue((AXUIElementRef)bar, kAXVisibleChildrenAttribute, &items);
  CFRelease(bar);
  return (CFArrayRef)items;
}

static void print_title(AXUIElementRef item) {
  CFTypeRef title = NULL;
  char buf[256] = "";
  AXUIElementCopyAttributeValue(item, kAXTitleAttribute, &title);
  if (title && CFGetTypeID(title) == CFStringGetTypeID())
    CFStringGetCString((CFStringRef)title, buf, sizeof buf, kCFStringEncodingUTF8);
  puts(buf);
  if (title) CFRelease(title);
}

static int usage(void) {
  fprintf(stderr, "usage: sketchybar-menus [-p <pid>] -l | -s <index> | -t\n");
  return 2;
}

static int print_window_title(AXUIElementRef app) {
  CFTypeRef window = NULL;
  if (AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute, &window) != kAXErrorSuccess)
    return 1;
  print_title((AXUIElementRef)window);
  CFRelease(window);
  return 0;
}

int main(int argc, char **argv) {
  pid_t forced_pid = 0;
  if (argc >= 3 && strcmp(argv[1], "-p") == 0) {
    forced_pid = (pid_t)strtol(argv[2], NULL, 10);
    argv += 2;
    argc -= 2;
  }
  int list = argc == 2 && strcmp(argv[1], "-l") == 0;
  int select = argc == 3 && strcmp(argv[1], "-s") == 0;
  int title = argc == 2 && strcmp(argv[1], "-t") == 0;
  if (!list && !select && !title) return usage();

  // Ask macOS for Accessibility on behalf of the responsible app (SketchyBar,
  // which runs this helper): the first call shows the system prompt
  const void *keys[] = {kAXTrustedCheckOptionPrompt};
  const void *values[] = {kCFBooleanTrue};
  CFDictionaryRef options = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 1,
                                               &kCFCopyStringDictionaryKeyCallBacks,
                                               &kCFTypeDictionaryValueCallBacks);
  int trusted = AXIsProcessTrustedWithOptions(options);
  CFRelease(options);
  if (!trusted) {
    fprintf(stderr, "sketchybar-menus: no Accessibility permission (prompted)\n");
    return 1;
  }

  AXUIElementRef app = forced_pid > 0 ? AXUIElementCreateApplication(forced_pid) : focused_app();
  if (!app) {
    fprintf(stderr, "sketchybar-menus: no focused app\n");
    return 1;
  }
  if (title) {
    int rc = print_window_title(app);
    CFRelease(app);
    return rc;
  }
  CFArrayRef items = menu_bar_items(app);
  if (!items) {
    fprintf(stderr, "sketchybar-menus: the focused app has no menu bar\n");
    CFRelease(app);
    return 1;
  }

  CFIndex count = CFArrayGetCount(items);
  if (list) {
    // Index 0 is the Apple menu; SketchyBar has its own
    for (CFIndex i = 1; i < count; i++)
      print_title((AXUIElementRef)CFArrayGetValueAtIndex(items, i));
  } else {
    CFIndex n = strtol(argv[2], NULL, 10) + 1;
    if (n >= 1 && n < count) {
      AXUIElementRef item = (AXUIElementRef)CFArrayGetValueAtIndex(items, n);
      // Close any open menu first, or the press toggles it shut
      AXUIElementPerformAction(item, kAXCancelAction);
      usleep(150000);
      AXUIElementPerformAction(item, kAXPressAction);
    }
  }

  CFRelease(items);
  CFRelease(app);
  return 0;
}
