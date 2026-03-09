# Win32 and Direct2D API Inventory

This document records the APIs used by the native layer.

## Window lifecycle and class registration

- `GetModuleHandleW`
- `RegisterClassExW`
- `CreateWindowExW`
- `ShowWindow`
- `UpdateWindow`
- `DestroyWindow`
- `DefWindowProcW`
- `SetWindowTextW`

## Message loop

- `GetMessageW`
- `TranslateMessage`
- `DispatchMessageW`
- `PostQuitMessage`

## Geometry and paint

- `GetWindowRect`
- `GetClientRect`
- `InvalidateRect`
- `BeginPaint`
- `EndPaint`
- `GetDC`
- `ReleaseDC`

## Non-client behavior and commands

- `WM_NCHITTEST` hit-test return codes:
	- `HTCLIENT`
	- `HTCAPTION`
	- `HTLEFT`, `HTRIGHT`, `HTTOP`, `HTBOTTOM`
	- `HTTOPLEFT`, `HTTOPRIGHT`, `HTBOTTOMLEFT`, `HTBOTTOMRIGHT`
- `WM_SYSCOMMAND` commands:
	- `SC_MINIMIZE`
	- `SC_MAXIMIZE`
	- `SC_RESTORE`
	- `SC_CLOSE`

## Transparency

- `SetLayeredWindowAttributes`
- Style flags:
	- `WS_EX_LAYERED`
	- `LWA_ALPHA`

## GDI text overlay

- `SetBkMode`
- `SetTextColor`
- `DrawTextW`

## Direct2D

- `D2D1CreateFactory`
- `ID2D1Factory::CreateHwndRenderTarget`
- `ID2D1HwndRenderTarget::BeginDraw`
- `ID2D1HwndRenderTarget::EndDraw`
- `ID2D1HwndRenderTarget::Clear`
- `ID2D1HwndRenderTarget::FillRectangle`
- `ID2D1HwndRenderTarget::Resize`
- `ID2D1RenderTarget::CreateSolidColorBrush`

