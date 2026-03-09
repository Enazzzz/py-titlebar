# nice-titlebar

Windows custom titlebar library built with Cython.

## What it does

- Creates a borderless Win32 window.
- Draws a custom titlebar (Direct2D-backed fill and button rendering).
- Exposes a pure Python API for title text, colors, transparency, and buttons.
- Supports Python callbacks for custom titlebar button clicks.

## Requirements

- Windows 10 or 11
- CPython 3.10+
- MSVC Build Tools

## Install (editable for development)

```powershell
python -m pip install -e ".[dev]"
```

## Quick start

```python
from nice_titlebar import TitleBarButton, Window, run

def custom_action(window):
	"""Handle custom button clicks."""
	window.set_client_background((40, 56, 88, 255))

window = Window(title="My App", width=900, height=560)
window.titlebar.set_background_color((20, 20, 24, 255))
window.titlebar.set_text_color((238, 238, 244, 255))
window.titlebar.add_button(
	TitleBarButton(kind="custom", icon="o", width=40, on_click=custom_action)
)
window.show()
run()
```

## Example

Run:

```powershell
python examples/basic_window.py
```

## Notes

- The package includes a Cython extension module at `src/nice_titlebar/_win32_titlebar.pyx`.
- If native build fails, Python import will still work but calling `Window()` will raise a clear runtime error.

