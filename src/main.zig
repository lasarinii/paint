const std = @import("std");
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/XKBlib.h");
    @cInclude("X11/keysym.h");
    @cInclude("X11/Xutil.h");
});

var display: *c.Display = undefined;
var screen: c_int = undefined;
var root: c.Window = undefined;

pub fn new_window(x: c_int, y: c_int, w: c_uint, h: c_uint, b: c_uint) c.Window {
    var window: c.Window = undefined;
    var att: c.XSetWindowAttributes = undefined;

    att.background_pixel = c.WhitePixel(display, screen);
    att.border_pixel = c.BlackPixel(display, screen);
    att.event_mask = c.Button1MotionMask | c.ButtonPressMask | c.ButtonReleaseMask | c.KeyPressMask;

    window = c.XCreateWindow(display, root, x, y, w, h, b, c.DefaultDepth(display, screen), c.InputOutput, c.DefaultVisual(display, screen), c.CWBackPixel | c.CWEventMask | c.CWBorderPixel, &att);

    return window;
}
pub fn new_gctx(line: c_int) c.GC {
    var gc: c.GC = undefined;
    var xgcv: c.XGCValues = undefined;
    var vmask: c_ulong = undefined;

    xgcv.line_style = c.LineSolid;
    xgcv.line_width = line;
    xgcv.cap_style = c.CapButt;
    xgcv.join_style = c.JoinMiter;
    xgcv.fill_style = c.FillSolid;
    xgcv.foreground = c.BlackPixel(display, screen);
    xgcv.background = c.WhitePixel(display, screen);

    vmask = c.GCForeground | c.GCBackground | c.GCFillStyle | c.GCLineStyle | c.GCLineWidth | c.GCCapStyle | c.GCJoinStyle;
    gc = c.XCreateGC(display, root, vmask, &xgcv);

    return gc;
}
pub fn run(gc: c.GC) void {
    var ev: c.XEvent = undefined;
    var init: c_int = 0;
    var prev_x: c_int = 0;
    var prev_y: c_int = 0;

    while (c.XNextEvent(display, &ev) == 0) {
        switch (ev.type) {
            c.ButtonPress => {
                if (ev.xbutton.button == c.Button1) {
                    _ = c.XDrawPoint(display, ev.xbutton.window, gc, ev.xbutton.x, ev.xbutton.y);
                }
            },
            c.MotionNotify => {
                if (init > 0) {
                    _ = c.XDrawLine(display, ev.xbutton.window, gc, prev_x, prev_y, ev.xbutton.x, ev.xbutton.y);
                } else {
                    _ = c.XDrawPoint(display, ev.xbutton.window, gc, ev.xbutton.x, ev.xbutton.y);
                    init = 1;
                }
                prev_x = ev.xbutton.x;
                prev_y = ev.xbutton.y;
            },
            c.ButtonRelease => {
                init = 0;
            },
            c.KeyPress => {
                if (ev.xkey.keycode == c.XKeysymToKeycode(display, c.XK_q)) {
                    return;
                }
            },
            else => {},
        }
    }
}

pub fn main() !void {
    var window: c.Window = undefined;
    var gc: c.GC = undefined;

    if (c.XOpenDisplay(null)) |d| {
        display = d;
    } else {
        std.debug.print("error\n", .{});
        return;
    }

    screen = c.DefaultScreen(display);
    root = c.RootWindow(display, screen);

    // window = c.XCreateSimpleWindow(display, root, 500, 500, 800, 400, 20, c.BlackPixel(display, screen), c.WhitePixel(display, screen));
    window = new_window(500, 500, 800, 400, 20);
    gc = new_gctx(@as(c_int, 2));

    _ = c.XMapWindow(display, window);

    run(gc);

    _ = c.XUnmapWindow(display, window);
    _ = c.XDestroyWindow(display, window);
    _ = c.XFreeGC(display, gc);
    _ = c.XCloseDisplay(display);
}
