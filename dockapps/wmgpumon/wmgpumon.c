/* wmgpumon.c — NVIDIA GPU monitor dockapp for Window Maker
 *
 * Visual style borrowed from wmload (back.xpm).
 * The embossed frame and green LED come from the XPM; this code only
 * draws the four GPU metrics inside the dark inner panel.
 *
 * Usage: wmgpumon [-display <disp>] [-interval <sec>]
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/select.h>

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/xpm.h>
#include <X11/Xft/Xft.h>

#include "back.xpm"

/* ── content area (measured from back.xpm) ───────────────── */
#define WIN_SIZE    64
#define CONTENT_X   10   /* left text margin (past the LED strip) */
#define CONTENT_Y    6   /* top of dark panel */
#define CONTENT_W   47   /* usable text width (up to j pixel at x=58) */
#define CONTENT_H   52   /* panel height: rows 6–57 */
#define N_ROWS       4
#define ROW_H       (CONTENT_H / N_ROWS)   /* 13 px */

/* ── gpu data ────────────────────────────────────────────── */
typedef struct {
    int   util;
    int   mem_pct;
    int   temp;
    float power;
    float power_limit;
    int   valid;
} GpuStats;

static GpuStats gpu;

/* ── x11 state ───────────────────────────────────────────── */
static Display  *dpy;
static int       scr;
static Window    win, iconwin;
static GC        gc;
static Pixmap    buf;        /* off-screen drawing buffer  */
static Pixmap    bg;         /* read-only XPM background   */

static XftFont  *font;
static XftDraw  *xdraw;
static int       fnt_asc;
static int       fnt_h;

/* ── colour palette (text over dark panel) ───────────────── */
typedef struct { const char *hex; XftColor xft; } Color;

static Color co_fg   = { "#e0e0e0" };
static Color co_dim  = { "#888899" };
static Color co_warn = { "#e3b341" };
static Color co_crit = { "#ff5555" };

/* ── nvidia-smi query ────────────────────────────────────── */
#define NVML_CMD \
    "nvidia-smi --query-gpu=" \
    "utilization.gpu,temperature.gpu,power.draw," \
    "memory.used,memory.total,power.limit " \
    "--format=csv,noheader,nounits 2>/dev/null"

static void fetch(void)
{
    FILE *fp = popen(NVML_CMD, "r");
    if (!fp) { gpu.valid = 0; return; }

    int   u, t, mu, mt;
    float pw, pl;

    if (fscanf(fp, "%d, %d, %f, %d, %d, %f",
               &u, &t, &pw, &mu, &mt, &pl) == 6) {
        gpu.util        = u < 0 ? 0 : u > 100 ? 100 : u;
        gpu.temp        = t;
        gpu.power       = pw < 0.0f ? 0.0f : pw;
        gpu.power_limit = pl > 0.0f ? pl : 300.0f;
        gpu.mem_pct     = mt > 0 ? mu * 100 / mt : 0;
        if (gpu.mem_pct > 100) gpu.mem_pct = 100;
        gpu.valid = 1;
    } else {
        gpu.valid = 0;
    }
    pclose(fp);
}

/* ── helpers ─────────────────────────────────────────────── */
static void xft_alloc(Color *co)
{
    XftColorAllocName(dpy, DefaultVisual(dpy, scr),
                      DefaultColormap(dpy, scr), co->hex, &co->xft);
}

/* Vertical centre of row converted to Xft text baseline */
static int row_y(int row)
{
    int center = CONTENT_Y + row * ROW_H + ROW_H / 2;
    return center + fnt_asc - fnt_h / 2;
}

/* ── drawing ─────────────────────────────────────────────── */
static void draw_row(int row, const char *label,
                     const char *value, XftColor *vcol)
{
    int y = row_y(row);

    /* label — left aligned */
    XftDrawStringUtf8(xdraw, &co_dim.xft, font,
                      CONTENT_X, y,
                      (const FcChar8 *)label, strlen(label));

    /* value — right aligned within the content area */
    XGlyphInfo ext;
    XftTextExtentsUtf8(dpy, font,
                       (const FcChar8 *)value, strlen(value), &ext);
    int vx = CONTENT_X + CONTENT_W - ext.xOff;
    if (vx < CONTENT_X) vx = CONTENT_X;
    XftDrawStringUtf8(xdraw, vcol, font,
                      vx, y, (const FcChar8 *)value, strlen(value));
}

static void paint(void)
{
    char s[16];

    /* reset to the styled XPM background */
    XCopyArea(dpy, bg, buf, gc, 0, 0, WIN_SIZE, WIN_SIZE, 0, 0);

    if (!gpu.valid) {
        XftDrawStringUtf8(xdraw, &co_dim.xft, font,
                          CONTENT_X, row_y(1),
                          (const FcChar8 *)"no GPU data", 11);
        goto flush;
    }

    snprintf(s, sizeof(s), "%3d%%", gpu.util);
    draw_row(0, "UTIL", s, &co_fg.xft);

    snprintf(s, sizeof(s), "%3d%%", gpu.mem_pct);
    draw_row(1, "VRAM", s, &co_fg.xft);

    snprintf(s, sizeof(s), "%3dC", gpu.temp);
    {
        XftColor *tc = gpu.temp >= 90 ? &co_crit.xft :
                       gpu.temp >= 75 ? &co_warn.xft : &co_fg.xft;
        draw_row(2, "TEMP", s, tc);
    }

    snprintf(s, sizeof(s), "%.0fW", gpu.power);
    draw_row(3, "WATT", s, &co_fg.xft);

flush:
    XCopyArea(dpy, buf, win,     gc, 0, 0, WIN_SIZE, WIN_SIZE, 0, 0);
    XCopyArea(dpy, buf, iconwin, gc, 0, 0, WIN_SIZE, WIN_SIZE, 0, 0);
    XSync(dpy, False);
}

/* ── window + pixmap setup ───────────────────────────────── */
static void make_window(int argc, char **argv)
{
    Window root  = RootWindow(dpy, scr);
    int    depth = DefaultDepth(dpy, scr);
    Visual *vis  = DefaultVisual(dpy, scr);

    /* load the XPM background */
    XpmAttributes xa;
    xa.valuemask = XpmCloseness | XpmColormap;
    xa.closeness = 40000;
    xa.colormap  = DefaultColormap(dpy, scr);
    Pixmap mask_unused;
    if (XpmCreatePixmapFromData(dpy, root, back_xpm,
                                &bg, &mask_unused, &xa) != XpmSuccess) {
        fputs("wmgpumon: failed to load back.xpm\n", stderr);
        exit(1);
    }

    buf = XCreatePixmap(dpy, root, WIN_SIZE, WIN_SIZE, depth);

    XSetWindowAttributes a;
    a.background_pixel = BlackPixel(dpy, scr);
    a.border_pixel     = BlackPixel(dpy, scr);
    a.event_mask       = ExposureMask | StructureNotifyMask;
    unsigned long mask = CWBackPixel | CWBorderPixel | CWEventMask;

    win = XCreateWindow(dpy, root, 0, 0, WIN_SIZE, WIN_SIZE, 0,
                        depth, InputOutput, vis, mask, &a);
    iconwin = XCreateWindow(dpy, root, 0, 0, WIN_SIZE, WIN_SIZE, 0,
                            depth, InputOutput, vis, mask, &a);

    XWMHints *wm     = XAllocWMHints();
    wm->flags        = StateHint | IconWindowHint | WindowGroupHint;
    wm->initial_state = WithdrawnState;
    wm->icon_window  = iconwin;
    wm->window_group = win;
    XSetWMHints(dpy, win, wm);
    XFree(wm);

    XSizeHints *sz = XAllocSizeHints();
    sz->flags = PMinSize | PMaxSize | PBaseSize;
    sz->min_width  = sz->max_width  = sz->base_width  = WIN_SIZE;
    sz->min_height = sz->max_height = sz->base_height = WIN_SIZE;
    XSetWMNormalHints(dpy, win, sz);
    XFree(sz);

    XStoreName(dpy, win, "wmgpumon");
    XSetIconName(dpy, win, "wmgpumon");

    XClassHint *ch = XAllocClassHint();
    ch->res_name  = "wmgpumon";
    ch->res_class = "WMGpumon";
    XSetClassHint(dpy, win, ch);
    XFree(ch);

    Atom wm_del = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
    XSetWMProtocols(dpy, win, &wm_del, 1);

    XGCValues gcv;
    gcv.graphics_exposures = False;
    gcv.function = GXcopy;
    gc = XCreateGC(dpy, buf, GCGraphicsExposures | GCFunction, &gcv);

    XSetCommand(dpy, win, argv, argc);
    XMapWindow(dpy, win);
}

/* ── entry point ─────────────────────────────────────────── */
int main(int argc, char **argv)
{
    const char *dpyname  = NULL;
    int         interval = 2;

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-display")  && i+1 < argc) dpyname  = argv[++i];
        if (!strcmp(argv[i], "-interval") && i+1 < argc) interval = atoi(argv[++i]);
        if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help")) {
            puts("usage: wmgpumon [-display <disp>] [-interval <sec>]");
            return 0;
        }
    }
    if (interval < 1) interval = 1;

    dpy = XOpenDisplay(dpyname);
    if (!dpy) { fputs("wmgpumon: cannot open display\n", stderr); return 1; }
    scr = DefaultScreen(dpy);

    xft_alloc(&co_fg);
    xft_alloc(&co_dim);
    xft_alloc(&co_warn);
    xft_alloc(&co_crit);

    make_window(argc, argv);

    static const char *font_names[] = {
        "UnifontExMono:size=10:antialias=false",
        "UnifontExMono:size=9:antialias=false",
        "monospace:size=10:antialias=false",
        "monospace:size=10",
        NULL
    };
    for (int i = 0; font_names[i]; i++) {
        font = XftFontOpenName(dpy, scr, font_names[i]);
        if (font) break;
    }
    if (!font) { fputs("wmgpumon: could not load any font\n", stderr); return 1; }
    fnt_asc = font->ascent;
    fnt_h   = font->ascent + font->descent;

    xdraw = XftDrawCreate(dpy, buf,
                          DefaultVisual(dpy, scr),
                          DefaultColormap(dpy, scr));

    fetch();
    paint();

    int    xfd  = XConnectionNumber(dpy);
    time_t last = time(NULL);

    for (;;) {
        fd_set         fds;
        struct timeval tv;
        time_t now  = time(NULL);
        long   wait = interval - (long)(now - last);

        FD_ZERO(&fds);
        FD_SET(xfd, &fds);
        tv.tv_sec  = wait > 0 ? wait : 0;
        tv.tv_usec = 0;

        select(xfd + 1, &fds, NULL, NULL, &tv);

        while (XPending(dpy)) {
            XEvent ev;
            XNextEvent(dpy, &ev);
            if (ev.type == Expose)        paint();
            if (ev.type == DestroyNotify) goto done;
            if (ev.type == ClientMessage) goto done;
        }

        now = time(NULL);
        if (now - last >= interval) {
            fetch();
            paint();
            last = now;
        }
    }
done:
    XftDrawDestroy(xdraw);
    XftFontClose(dpy, font);
    XFreeGC(dpy, gc);
    XFreePixmap(dpy, buf);
    XFreePixmap(dpy, bg);
    XDestroyWindow(dpy, iconwin);
    XDestroyWindow(dpy, win);
    XCloseDisplay(dpy);
    return 0;
}
