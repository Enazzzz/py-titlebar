"""Shared public types for the nice_titlebar API."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable, Literal

Color = tuple[int, int, int, int]
ButtonKind = Literal["close", "minimize", "maximize", "restore", "custom"]


def normalize_color(color: tuple[int, ...]) -> Color:
	"""Normalize RGB/RGBA tuples into 8-bit RGBA."""
	if len(color) == 3:
		r, g, b = color
		a = 255
	elif len(color) == 4:
		r, g, b, a = color
	else:
		raise ValueError("Color must be an RGB or RGBA tuple.")
	values = (r, g, b, a)
	for value in values:
		if value < 0 or value > 255:
			raise ValueError("Color channels must be between 0 and 255.")
	return (int(r), int(g), int(b), int(a))


@dataclass(slots=True)
class TitleBarButton:
	"""Configuration for a single titlebar button."""
	kind: ButtonKind = "custom"
	tooltip: str | None = None
	icon: str = ""
	background_color: Color = (0, 0, 0, 0)
	hover_color: Color = (55, 55, 55, 255)
	width: int = 46
	on_click: Callable[["Window"], None] | None = None


@dataclass(slots=True)
class TitleBarStyle:
	"""Visual style options for the custom titlebar."""
	height: int = 34
	background_color: Color = (24, 24, 24, 255)
	text_color: Color = (240, 240, 240, 255)
	font_family: str = "Segoe UI"
	font_size: float = 12.0
	buttons: list[TitleBarButton] = field(default_factory=list)

