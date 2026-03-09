"""Basic smoke tests for the Python API surface."""

import importlib
import platform

import pytest


def test_package_imports() -> None:
	"""Verify package-level exports are importable."""
	module = importlib.import_module("nice_titlebar")
	assert hasattr(module, "Window")
	assert hasattr(module, "TitleBarButton")
	assert hasattr(module, "run")


def test_window_requires_native_extension() -> None:
	"""Verify non-Windows or missing-native environments fail clearly."""
	from nice_titlebar import Window

	if platform.system() == "Windows":
		pytest.skip("This assertion is focused on non-native test environments.")
	with pytest.raises(RuntimeError):
		Window()


def test_color_validation() -> None:
	"""Verify invalid color channels are rejected."""
	from nice_titlebar.types import normalize_color

	with pytest.raises(ValueError):
		normalize_color((999, 0, 0))

