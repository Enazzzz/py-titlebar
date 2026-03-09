"""High-level Python API for the native custom titlebar window."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable

from .types import TitleBarButton, TitleBarStyle, normalize_color

try:
	from ._win32_titlebar import NativeWindow as _NativeWindow
	from ._win32_titlebar import run_event_loop as _run_event_loop
except Exception as exc:  # pragma: no cover - runtime fallback
	_NativeWindow = None
	_IMPORT_ERROR = exc
else:
	_IMPORT_ERROR = None


def _require_native() -> None:
	"""Raise a clear error if the native extension is unavailable."""
	if _NativeWindow is None:
		raise RuntimeError(
			"nice_titlebar native extension is unavailable. "
			"Build/install on Windows with Cython first."
		) from _IMPORT_ERROR


@dataclass(slots=True)
class TitleBar:
	"""Python wrapper for mutable titlebar state."""
	owner: "Window"
	style: TitleBarStyle

	def add_button(self, button: TitleBarButton) -> None:
		"""Append a button and push updates to the native layer."""
		self.style.buttons.append(button)
		self.owner._sync_titlebar()

	def set_buttons(self, buttons: list[TitleBarButton]) -> None:
		"""Replace all buttons and push updates to the native layer."""
		self.style.buttons = list(buttons)
		self.owner._sync_titlebar()

	def set_background_color(self, color: tuple[int, ...]) -> None:
		"""Set titlebar background color."""
		self.style.background_color = normalize_color(color)
		self.owner._sync_titlebar()

	def set_text_color(self, color: tuple[int, ...]) -> None:
		"""Set titlebar text color."""
		self.style.text_color = normalize_color(color)
		self.owner._sync_titlebar()

	def set_height(self, height: int) -> None:
		"""Set titlebar height in pixels."""
		if height < 24:
			raise ValueError("Titlebar height must be at least 24 pixels.")
		self.style.height = height
		self.owner._sync_titlebar()


class Window:
	"""Top-level window exposed to regular Python applications."""

	def __init__(
		self,
		width: int = 900,
		height: int = 560,
		title: str = "Nice Titlebar Window",
		background_color: tuple[int, ...] = (32, 32, 36, 255),
		titlebar_height: int = 34,
		transparent: bool = False,
		opacity: float = 1.0,
	) -> None:
		"""Create a window configuration and bind it to native state."""
		_require_native()
		self._title = title
		self._background_color = normalize_color(background_color)
		self._on_close_callbacks: list[Callable[["Window"], None]] = []
		self._native = _NativeWindow(
			width,
			height,
			title,
			titlebar_height,
			transparent,
			opacity,
		)
		self.titlebar = TitleBar(
			owner=self,
			style=TitleBarStyle(
				height=titlebar_height,
				buttons=[
					TitleBarButton(kind="minimize", icon="-"),
					TitleBarButton(kind="maximize", icon="[]"),
					TitleBarButton(kind="close", icon="X", hover_color=(180, 34, 34, 255)),
				],
			),
		)
		self._sync_titlebar()
		self._native.set_client_background(*self._background_color)

	def show(self) -> None:
		"""Create and display the native window."""
		self._native.show()

	def close(self) -> None:
		"""Close the native window."""
		self._native.close()

	def on_close(self, callback: Callable[["Window"], None]) -> None:
		"""Register a close callback invoked from native events."""
		self._on_close_callbacks.append(callback)
		self._native.register_close_callback(callback, self)

	@property
	def title(self) -> str:
		"""Get current title text."""
		return self._title

	@title.setter
	def title(self, value: str) -> None:
		"""Set current title text."""
		self._title = value
		self._native.set_title(value)

	def set_client_background(self, color: tuple[int, ...]) -> None:
		"""Set client area background color."""
		self._background_color = normalize_color(color)
		self._native.set_client_background(*self._background_color)

	def _sync_titlebar(self) -> None:
		"""Push Python-side titlebar state into the native layer."""
		button_payload: list[dict[str, object]] = []
		for button in self.titlebar.style.buttons:
			button_payload.append(
				{
					"kind": button.kind,
					"tooltip": button.tooltip,
					"icon": button.icon,
					"bg": button.background_color,
					"hover": button.hover_color,
					"width": button.width,
					"on_click": button.on_click,
				}
			)
		self._native.configure_titlebar(
			self.titlebar.style.height,
			self.titlebar.style.background_color,
			self.titlebar.style.text_color,
			self.titlebar.style.font_family,
			self.titlebar.style.font_size,
			button_payload,
		)
		self._native.set_title(self._title)


def run() -> None:
	"""Run the native event loop for all managed windows."""
	_require_native()
	_run_event_loop()

