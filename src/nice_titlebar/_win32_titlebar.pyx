# cython: language_level=3
# cython: boundscheck=False
# cython: wraparound=False

"""Native Win32 + Direct2D window implementation for nice_titlebar."""

from cpython.ref cimport PyObject
from cpython.ref cimport Py_INCREF, Py_DECREF
from libc.stdint cimport intptr_t, uintptr_t

cdef extern from "Python.h":
	void PyErr_Clear()

cdef extern from *:
	"""
	#define WIN32_LEAN_AND_MEAN
	#include <windows.h>
	#include <d2d1.h>
	#include <math.h>

	typedef struct NtbD2DContext {
		ID2D1Factory* factory;
		ID2D1HwndRenderTarget* target;
		ID2D1SolidColorBrush* brush;
	} NtbD2DContext;

	static int ntb_d2d_init(HWND hwnd, NtbD2DContext* ctx) {
		HRESULT hr;
		RECT rc;
		D2D1_RENDER_TARGET_PROPERTIES props;
		D2D1_HWND_RENDER_TARGET_PROPERTIES hwnd_props;
		D2D1_COLOR_F white;

		if (!ctx) {
			return -1;
		}
		ctx->factory = NULL;
		ctx->target = NULL;
		ctx->brush = NULL;

		hr = D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, __uuidof(ID2D1Factory), NULL, (void**)&ctx->factory);
		if (FAILED(hr)) {
			return (int)hr;
		}
		GetClientRect(hwnd, &rc);
		props.type = D2D1_RENDER_TARGET_TYPE_DEFAULT;
		props.pixelFormat.format = DXGI_FORMAT_UNKNOWN;
		props.pixelFormat.alphaMode = D2D1_ALPHA_MODE_PREMULTIPLIED;
		props.dpiX = 0.0f;
		props.dpiY = 0.0f;
		props.usage = D2D1_RENDER_TARGET_USAGE_NONE;
		props.minLevel = D2D1_FEATURE_LEVEL_DEFAULT;

		hwnd_props.hwnd = hwnd;
		hwnd_props.pixelSize.width = (UINT32)(rc.right - rc.left);
		hwnd_props.pixelSize.height = (UINT32)(rc.bottom - rc.top);
		hwnd_props.presentOptions = D2D1_PRESENT_OPTIONS_NONE;

		hr = ctx->factory->CreateHwndRenderTarget(&props, &hwnd_props, &ctx->target);
		if (FAILED(hr)) {
			ctx->factory->Release();
			ctx->factory = NULL;
			return (int)hr;
		}

		white.r = 1.0f;
		white.g = 1.0f;
		white.b = 1.0f;
		white.a = 1.0f;

		hr = ctx->target->CreateSolidColorBrush(&white, NULL, &ctx->brush);
		if (FAILED(hr)) {
			ctx->target->Release();
			ctx->factory->Release();
			ctx->target = NULL;
			ctx->factory = NULL;
			return (int)hr;
		}
		return 0;
	}

	static int ntb_d2d_begin(NtbD2DContext* ctx) {
		if (!ctx || !ctx->target) {
			return -1;
		}
		ctx->target->BeginDraw();
		return 0;
	}

	static int ntb_d2d_end(NtbD2DContext* ctx) {
		HRESULT hr;
		if (!ctx || !ctx->target) {
			return -1;
		}
		hr = ctx->target->EndDraw(NULL, NULL);
		return (int)hr;
	}

	static void ntb_d2d_clear(NtbD2DContext* ctx, float r, float g, float b, float a) {
		D2D1_COLOR_F color;
		if (!ctx || !ctx->target) {
			return;
		}
		color.r = r;
		color.g = g;
		color.b = b;
		color.a = a;
		ctx->target->Clear(&color);
	}

	static void ntb_d2d_fill_rect(NtbD2DContext* ctx, float left, float top, float right, float bottom, float r, float g, float b, float a) {
		D2D1_COLOR_F color;
		D2D1_RECT_F rect;
		if (!ctx || !ctx->target || !ctx->brush) {
			return;
		}
		color.r = r;
		color.g = g;
		color.b = b;
		color.a = a;
		rect.left = left;
		rect.top = top;
		rect.right = right;
		rect.bottom = bottom;
		ctx->brush->SetColor(&color);
		ctx->target->FillRectangle(&rect, ctx->brush);
	}

	static int ntb_d2d_resize(NtbD2DContext* ctx, unsigned int width, unsigned int height) {
		D2D1_SIZE_U size;
		HRESULT hr;
		if (!ctx || !ctx->target) {
			return -1;
		}
		size.width = width;
		size.height = height;
		hr = ctx->target->Resize(&size);
		return (int)hr;
	}

	static void ntb_d2d_release(NtbD2DContext* ctx) {
		if (!ctx) {
			return;
		}
		if (ctx->brush) {
			ctx->brush->Release();
			ctx->brush = NULL;
		}
		if (ctx->target) {
			ctx->target->Release();
			ctx->target = NULL;
		}
		if (ctx->factory) {
			ctx->factory->Release();
			ctx->factory = NULL;
		}
	}

	static int ntb_get_x_lparam(LPARAM p) {
		return (int)(short)LOWORD((DWORD_PTR)p);
	}

	static int ntb_get_y_lparam(LPARAM p) {
		return (int)(short)HIWORD((DWORD_PTR)p);
	}

	static unsigned int ntb_lo_word(LPARAM p) {
		return LOWORD((DWORD_PTR)p);
	}

	static unsigned int ntb_hi_word(LPARAM p) {
		return HIWORD((DWORD_PTR)p);
	}

	static void ntb_init_wndclass(WNDCLASSEXA* cls, void* proc, HINSTANCE inst, const char* class_name) {
		ZeroMemory(cls, sizeof(WNDCLASSEXA));
		cls->cbSize = sizeof(WNDCLASSEXA);
		cls->style = 0;
		cls->lpfnWndProc = (WNDPROC)proc;
		cls->cbClsExtra = 0;
		cls->cbWndExtra = 0;
		cls->hInstance = inst;
		cls->hIcon = NULL;
		cls->hCursor = NULL;
		cls->hbrBackground = NULL;
		cls->lpszMenuName = NULL;
		cls->lpszClassName = class_name;
		cls->hIconSm = NULL;
	}
	"""
	ctypedef struct RECT:
		int left
		int top
		int right
		int bottom

	ctypedef struct PAINTSTRUCT:
		void* hdc
		int fErase
		RECT rcPaint
		int fRestore
		int fIncUpdate
		unsigned char rgbReserved[32]

	ctypedef struct WNDCLASSEXA:
		pass

	ctypedef void* HWND
	ctypedef void* HINSTANCE
	ctypedef void* HBRUSH
	ctypedef void* HCURSOR
	ctypedef void* HICON
	ctypedef void* HMENU
	ctypedef void* HDC
	ctypedef intptr_t LRESULT
	ctypedef uintptr_t WPARAM
	ctypedef intptr_t LPARAM
	ctypedef unsigned int UINT
	ctypedef unsigned long DWORD
	ctypedef intptr_t LONG_PTR
	ctypedef unsigned int COLORREF

	ctypedef struct NtbD2DContext:
		pass

	HINSTANCE GetModuleHandleA(const char* lpModuleName)
	unsigned short RegisterClassExA(WNDCLASSEXA* cls)
	HWND CreateWindowExA(
		DWORD ex_style,
		const char* class_name,
		const char* window_name,
		DWORD style,
		int x,
		int y,
		int w,
		int h,
		HWND parent,
		HMENU menu,
		HINSTANCE instance,
		void* param,
	)
	int ShowWindow(HWND hwnd, int cmd_show)
	int UpdateWindow(HWND hwnd)
	int DestroyWindow(HWND hwnd)
	int SetWindowTextA(HWND hwnd, const char* text)
	LRESULT DefWindowProcW(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
	int GetMessageW(void* msg, HWND hwnd, UINT min_filter, UINT max_filter)
	int TranslateMessage(void* msg)
	LRESULT DispatchMessageW(void* msg)
	int PostQuitMessage(int code)
	int InvalidateRect(HWND hwnd, RECT* rect, int erase)
	int GetClientRect(HWND hwnd, RECT* rect)
	int GetWindowRect(HWND hwnd, RECT* rect)
	HDC BeginPaint(HWND hwnd, PAINTSTRUCT* paint)
	int EndPaint(HWND hwnd, PAINTSTRUCT* paint)
	HDC GetDC(HWND hwnd)
	int ReleaseDC(HWND hwnd, HDC hdc)
	COLORREF SetTextColor(HDC dc, COLORREF color)
	int SetBkMode(HDC dc, int mode)
	int DrawTextA(HDC dc, const char* text, int length, RECT* rect, unsigned int format)
	LONG_PTR SetWindowLongPtrW(HWND hwnd, int index, LONG_PTR value)
	LONG_PTR GetWindowLongPtrW(HWND hwnd, int index)
	int PostMessageW(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
	unsigned int GetDpiForWindow(HWND hwnd)
	int SetLayeredWindowAttributes(HWND hwnd, COLORREF key, unsigned char alpha, DWORD flags)
	void ntb_init_wndclass(WNDCLASSEXA* cls, void* proc, HINSTANCE inst, const char* class_name)
	int ntb_d2d_init(HWND hwnd, NtbD2DContext* ctx)
	int ntb_d2d_begin(NtbD2DContext* ctx)
	int ntb_d2d_end(NtbD2DContext* ctx)
	void ntb_d2d_clear(NtbD2DContext* ctx, float r, float g, float b, float a)
	void ntb_d2d_fill_rect(NtbD2DContext* ctx, float left, float top, float right, float bottom, float r, float g, float b, float a)
	int ntb_d2d_resize(NtbD2DContext* ctx, unsigned int width, unsigned int height)
	void ntb_d2d_release(NtbD2DContext* ctx)
	int ntb_get_x_lparam(LPARAM p)
	int ntb_get_y_lparam(LPARAM p)
	unsigned int ntb_lo_word(LPARAM p)
	unsigned int ntb_hi_word(LPARAM p)

	ctypedef struct POINT:
		long x
		long y

	ctypedef struct MSG:
		void* hwnd
		unsigned int message
		WPARAM wParam
		LPARAM lParam
		unsigned int time
		POINT pt
		unsigned long lPrivate

cdef int WS_POPUP = 0x80000000
cdef int WS_THICKFRAME = 0x00040000
cdef int WS_MINIMIZEBOX = 0x00020000
cdef int WS_MAXIMIZEBOX = 0x00010000
cdef int WS_SYSMENU = 0x00080000
cdef int WS_VISIBLE = 0x10000000
cdef int WS_EX_APPWINDOW = 0x00040000
cdef int WS_EX_LAYERED = 0x00080000
cdef int CW_USEDEFAULT = 0x80000000
cdef int SW_SHOW = 5
cdef int GWLP_USERDATA = -21
cdef int LWA_ALPHA = 0x00000002
cdef int WM_DESTROY = 0x0002
cdef int WM_CLOSE = 0x0010
cdef int WM_PAINT = 0x000F
cdef int WM_SIZE = 0x0005
cdef int WM_NCHITTEST = 0x0084
cdef int WM_LBUTTONDOWN = 0x0201
cdef int WM_MOUSEMOVE = 0x0200
cdef int WM_NCCALCSIZE = 0x0083
cdef int HTCLIENT = 1
cdef int HTCAPTION = 2
cdef int HTLEFT = 10
cdef int HTRIGHT = 11
cdef int HTTOP = 12
cdef int HTTOPLEFT = 13
cdef int HTTOPRIGHT = 14
cdef int HTBOTTOM = 15
cdef int HTBOTTOMLEFT = 16
cdef int HTBOTTOMRIGHT = 17
cdef int TRANSPARENT = 1
cdef int DT_LEFT = 0x0000
cdef int DT_VCENTER = 0x0004
cdef int DT_SINGLELINE = 0x0020
cdef int DT_END_ELLIPSIS = 0x00008000
cdef int WM_SYSCOMMAND = 0x0112
cdef int SC_MINIMIZE = 0xF020
cdef int SC_MAXIMIZE = 0xF030
cdef int SC_RESTORE = 0xF120
cdef int SC_CLOSE = 0xF060

cdef dict _WINDOWS = {}
cdef bint _CLASS_REGISTERED = False
cdef bytes _CLASS_NAME = b"NiceTitlebarWindowClass"


cdef inline COLORREF _rgb_color(int r, int g, int b):
	# This packs RGB for SetTextColor.
	return <COLORREF>((b << 16) | (g << 8) | r)


cdef inline tuple _normalize_rgba(object color):
	# This converts Python tuples to reliable RGBA ints.
	cdef int r = 0
	cdef int g = 0
	cdef int b = 0
	cdef int a = 255
	if color is None:
		return (0, 0, 0, 255)
	if len(color) == 3:
		r, g, b = color
	elif len(color) == 4:
		r, g, b, a = color
	else:
		raise ValueError("Color must be RGB or RGBA.")
	return (int(r), int(g), int(b), int(a))


cdef class NativeWindow:
	"""Native Win32 window backed by a Cython-managed WndProc."""

	cdef public bint created
	cdef HWND _hwnd
	cdef int _width
	cdef int _height
	cdef str _title
	cdef int _titlebar_height
	cdef tuple _titlebar_bg
	cdef tuple _titlebar_text
	cdef tuple _client_bg
	cdef list _buttons
	cdef list _button_rects
	cdef object _close_callback
	cdef object _close_owner
	cdef int _hover_index
	cdef bint _transparent
	cdef float _opacity
	cdef NtbD2DContext _d2d

	def __cinit__(self):
		# This initializes safe defaults before Python init runs.
		self.created = False
		self._hwnd = <HWND>0
		self._width = 800
		self._height = 500
		self._title = "Nice Titlebar"
		self._titlebar_height = 34
		self._titlebar_bg = (24, 24, 24, 255)
		self._titlebar_text = (240, 240, 240, 255)
		self._client_bg = (30, 30, 34, 255)
		self._buttons = []
		self._button_rects = []
		self._close_callback = None
		self._close_owner = None
		self._hover_index = -1
		self._transparent = False
		self._opacity = 1.0

	def __init__(self, int width, int height, str title, int titlebar_height, bint transparent, float opacity):
		"""Store constructor arguments used for native window creation."""
		self._width = width
		self._height = height
		self._title = title
		self._titlebar_height = titlebar_height
		self._transparent = transparent
		self._opacity = opacity

	def __dealloc__(self):
		# This ensures D2D resources are released when object is destroyed.
		ntb_d2d_release(&self._d2d)

	def configure_titlebar(self, int height, tuple bg, tuple text_color, str font_family, float font_size, list buttons):
		"""Update titlebar style and request repaint."""
		self._titlebar_height = height
		self._titlebar_bg = _normalize_rgba(bg)
		self._titlebar_text = _normalize_rgba(text_color)
		self._buttons = list(buttons)
		self._layout_buttons()
		self._invalidate()

	def set_client_background(self, int r, int g, int b, int a):
		"""Update client area background color."""
		self._client_bg = (r, g, b, a)
		self._invalidate()

	def set_title(self, str value):
		"""Update title text in native window and local state."""
		cdef bytes title_bytes
		self._title = value
		if self._hwnd != <HWND>0:
			title_bytes = value.encode("utf-8", "replace")
			SetWindowTextA(self._hwnd, <const char*>title_bytes)
		self._invalidate()

	def register_close_callback(self, object callback, object owner):
		"""Register Python callback invoked when the window is destroyed."""
		self._close_callback = callback
		self._close_owner = owner

	def show(self):
		"""Create and show the window if not already created."""
		cdef int alpha = 255
		cdef bytes title_bytes
		if self.created:
			return
		self._register_window_class()
		cdef DWORD style = WS_POPUP | WS_THICKFRAME | WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_VISIBLE
		cdef DWORD ex_style = WS_EX_APPWINDOW
		if self._transparent or self._opacity < 1.0:
			ex_style |= WS_EX_LAYERED
		title_bytes = self._title.encode("utf-8", "replace")
		self._hwnd = CreateWindowExA(
			ex_style,
			<const char*>_CLASS_NAME,
			<const char*>title_bytes,
			style,
			CW_USEDEFAULT,
			CW_USEDEFAULT,
			self._width,
			self._height,
			<HWND>0,
			<HMENU>0,
			GetModuleHandleA(<const char*>0),
			<void*>0,
		)
		if self._hwnd == <HWND>0:
			raise RuntimeError("CreateWindowExW failed.")
		_WINDOWS[<uintptr_t>self._hwnd] = self
		Py_INCREF(self)
		if self._transparent or self._opacity < 1.0:
			alpha = <int>(self._opacity * 255.0)
			if alpha < 0:
				alpha = 0
			elif alpha > 255:
				alpha = 255
			SetLayeredWindowAttributes(self._hwnd, 0, <unsigned char>alpha, LWA_ALPHA)
		self._layout_buttons()
		if ntb_d2d_init(self._hwnd, &self._d2d) != 0:
			raise RuntimeError("Direct2D initialization failed.")
		ShowWindow(self._hwnd, SW_SHOW)
		UpdateWindow(self._hwnd)
		self.created = True
		self._invalidate()

	def close(self):
		"""Destroy the native window if it exists."""
		if self._hwnd != <HWND>0:
			DestroyWindow(self._hwnd)

	cdef void _register_window_class(self):
		# This registers the Win32 class exactly once per process.
		global _CLASS_REGISTERED
		if _CLASS_REGISTERED:
			return
		cdef WNDCLASSEXA cls
		ntb_init_wndclass(
			&cls,
			<void*>_wnd_proc,
			GetModuleHandleA(<const char*>0),
			<const char*>_CLASS_NAME,
		)
		if RegisterClassExA(&cls) == 0:
			raise RuntimeError("RegisterClassExW failed.")
		_CLASS_REGISTERED = True

	cdef void _layout_buttons(self):
		# This computes button rectangles from right to left.
		cdef int right_edge = self._width
		cdef int idx = 0
		cdef int width = 46
		cdef list rects = []
		for idx in range(len(self._buttons) - 1, -1, -1):
			try:
				width = int(self._buttons[idx].get("width", 46))
			except Exception:
				width = 46
			rects.insert(0, (right_edge - width, 0, right_edge, self._titlebar_height))
			right_edge -= width
		self._button_rects = rects

	cdef void _invalidate(self):
		# This requests a repaint when the native handle exists.
		if self._hwnd != <HWND>0:
			InvalidateRect(self._hwnd, <RECT*>0, 0)

	cdef int _hit_test(self, int x, int y):
		# This returns non-client hit-test codes for drag/resize.
		cdef RECT rect
		cdef int border = 8
		cdef int left = 0
		cdef int top = 0
		cdef int width = 0
		cdef int height = 0
		GetWindowRect(self._hwnd, &rect)
		left = rect.left
		top = rect.top
		width = rect.right - rect.left
		height = rect.bottom - rect.top
		x -= left
		y -= top
		if x < border and y < border:
			return HTTOPLEFT
		if x >= width - border and y < border:
			return HTTOPRIGHT
		if x < border and y >= height - border:
			return HTBOTTOMLEFT
		if x >= width - border and y >= height - border:
			return HTBOTTOMRIGHT
		if y < border:
			return HTTOP
		if y >= height - border:
			return HTBOTTOM
		if x < border:
			return HTLEFT
		if x >= width - border:
			return HTRIGHT
		if y < self._titlebar_height:
			if self._button_hit(x, y) >= 0:
				return HTCLIENT
			return HTCAPTION
		return HTCLIENT

	cdef int _button_hit(self, int x, int y):
		# This checks if a point is inside any titlebar button.
		cdef int idx = 0
		cdef tuple rect
		for idx, rect in enumerate(self._button_rects):
			if x >= rect[0] and x < rect[2] and y >= rect[1] and y < rect[3]:
				return idx
		return -1

	cdef void _draw(self):
		# This draws titlebar and client backgrounds with Direct2D.
		cdef RECT rect
		cdef int width = 0
		cdef int height = 0
		cdef tuple bg = self._titlebar_bg
		cdef tuple client = self._client_bg
		cdef tuple btn_bg
		cdef tuple btn_hover
		cdef int idx
		cdef tuple button_rect
		GetClientRect(self._hwnd, &rect)
		width = rect.right - rect.left
		height = rect.bottom - rect.top
		if ntb_d2d_resize(&self._d2d, <unsigned int>width, <unsigned int>height) != 0:
			return
		if ntb_d2d_begin(&self._d2d) != 0:
			return
		ntb_d2d_clear(&self._d2d, client[0] / 255.0, client[1] / 255.0, client[2] / 255.0, client[3] / 255.0)
		ntb_d2d_fill_rect(
			&self._d2d,
			0.0,
			0.0,
			<float>width,
			<float>self._titlebar_height,
			bg[0] / 255.0,
			bg[1] / 255.0,
			bg[2] / 255.0,
			bg[3] / 255.0,
		)
		for idx, button_rect in enumerate(self._button_rects):
			btn_bg = _normalize_rgba(self._buttons[idx].get("bg", (0, 0, 0, 0)))
			btn_hover = _normalize_rgba(self._buttons[idx].get("hover", btn_bg))
			if idx == self._hover_index:
				btn_bg = btn_hover
			ntb_d2d_fill_rect(
				&self._d2d,
				<float>button_rect[0],
				<float>button_rect[1],
				<float>button_rect[2],
				<float>button_rect[3],
				btn_bg[0] / 255.0,
				btn_bg[1] / 255.0,
				btn_bg[2] / 255.0,
				btn_bg[3] / 255.0,
			)
		ntb_d2d_end(&self._d2d)
		self._draw_text_overlay()

	cdef void _draw_text_overlay(self):
		# This overlays text/icons with GDI for simple glyph rendering.
		cdef HDC dc
		cdef RECT text_rect
		cdef tuple text_color = self._titlebar_text
		cdef int idx
		cdef tuple rect
		cdef str icon
		cdef bytes title_bytes
		cdef bytes icon_bytes
		cdef object button
		if self._hwnd == <HWND>0:
			return
		dc = GetDC(self._hwnd)
		if dc == <HDC>0:
			return
		SetBkMode(dc, TRANSPARENT)
		SetTextColor(dc, _rgb_color(text_color[0], text_color[1], text_color[2]))
		text_rect.left = 14
		text_rect.top = 0
		text_rect.right = self._width - 180
		text_rect.bottom = self._titlebar_height
		title_bytes = self._title.encode("utf-8", "replace")
		DrawTextA(dc, <const char*>title_bytes, -1, &text_rect, DT_LEFT | DT_SINGLELINE | DT_VCENTER | DT_END_ELLIPSIS)
		for idx, rect in enumerate(self._button_rects):
			button = self._buttons[idx]
			icon = <str>button.get("icon", "")
			if not icon:
				icon = self._default_icon(<str>button.get("kind", "custom"))
			text_rect.left = rect[0]
			text_rect.top = rect[1]
			text_rect.right = rect[2]
			text_rect.bottom = rect[3]
			icon_bytes = icon.encode("utf-8", "replace")
			DrawTextA(dc, <const char*>icon_bytes, -1, &text_rect, DT_SINGLELINE | DT_VCENTER | DT_END_ELLIPSIS)
		ReleaseDC(self._hwnd, dc)

	cdef str _default_icon(self, str kind):
		# This chooses fallback glyphs for built-in button kinds.
		if kind == "minimize":
			return "-"
		if kind == "maximize":
			return "[]"
		if kind == "restore":
			return "R"
		if kind == "close":
			return "X"
		return ""

	cdef void _handle_button_click(self, int x, int y):
		# This dispatches system actions or Python callbacks for buttons.
		cdef int idx = self._button_hit(x, y)
		cdef object button
		cdef str kind
		if idx < 0:
			return
		button = self._buttons[idx]
		kind = <str>button.get("kind", "custom")
		if kind == "close":
			PostMessageW(self._hwnd, WM_SYSCOMMAND, <WPARAM>SC_CLOSE, 0)
			return
		if kind == "minimize":
			PostMessageW(self._hwnd, WM_SYSCOMMAND, <WPARAM>SC_MINIMIZE, 0)
			return
		if kind == "maximize":
			PostMessageW(self._hwnd, WM_SYSCOMMAND, <WPARAM>SC_MAXIMIZE, 0)
			return
		if kind == "restore":
			PostMessageW(self._hwnd, WM_SYSCOMMAND, <WPARAM>SC_RESTORE, 0)
			return
		try:
			if button.get("on_click") is not None:
				button["on_click"](self._close_owner)
		except Exception:
			PyErr_Clear()


cdef LRESULT __stdcall _wnd_proc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) except? -1 with gil:
	# This routes messages into the owning NativeWindow instance.
	cdef NativeWindow window = <NativeWindow>_WINDOWS.get(<uintptr_t>hwnd)
	cdef PAINTSTRUCT paint
	cdef int x = 0
	cdef int y = 0
	cdef int idx = -1
	cdef unsigned int width = 0
	cdef unsigned int height = 0

	if msg == WM_NCCALCSIZE:
		return 0

	if window is None:
		return DefWindowProcW(hwnd, msg, wparam, lparam)

	if msg == WM_NCHITTEST:
		x = ntb_get_x_lparam(lparam)
		y = ntb_get_y_lparam(lparam)
		return <LRESULT>window._hit_test(x, y)

	if msg == WM_MOUSEMOVE:
		x = ntb_get_x_lparam(lparam)
		y = ntb_get_y_lparam(lparam)
		idx = window._button_hit(x, y)
		if idx != window._hover_index:
			window._hover_index = idx
			window._invalidate()
		return 0

	if msg == WM_LBUTTONDOWN:
		x = ntb_get_x_lparam(lparam)
		y = ntb_get_y_lparam(lparam)
		if y < window._titlebar_height:
			window._handle_button_click(x, y)
		return 0

	if msg == WM_SIZE:
		width = ntb_lo_word(lparam)
		height = ntb_hi_word(lparam)
		window._width = <int>width
		window._height = <int>height
		window._layout_buttons()
		window._invalidate()
		return 0

	if msg == WM_PAINT:
		BeginPaint(hwnd, &paint)
		window._draw()
		EndPaint(hwnd, &paint)
		return 0

	if msg == WM_CLOSE:
		DestroyWindow(hwnd)
		return 0

	if msg == WM_DESTROY:
		ntb_d2d_release(&window._d2d)
		try:
			if window._close_callback is not None:
				window._close_callback(window._close_owner)
		except Exception:
			PyErr_Clear()
		if <uintptr_t>hwnd in _WINDOWS:
			del _WINDOWS[<uintptr_t>hwnd]
		window._hwnd = <HWND>0
		window.created = False
		Py_DECREF(window)
		if not _WINDOWS:
			PostQuitMessage(0)
		return 0

	return DefWindowProcW(hwnd, msg, wparam, lparam)


def run_event_loop():
	"""Run the standard Win32 message loop until windows are closed."""
	cdef MSG msg
	while GetMessageW(&msg, <HWND>0, 0, 0) > 0:
		TranslateMessage(&msg)
		DispatchMessageW(&msg)

