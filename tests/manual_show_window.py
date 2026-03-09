"""Manual demo script that opens a real window.

Run this directly (not via pytest):

    python tests/manual_show_window.py
"""

from nice_titlebar import TitleBarButton, Window, run


def _toggle_background(window: Window) -> None:
	"""Toggle client background color on each click."""
	if getattr(window, "_demo_toggle", False):
		window.set_client_background((32, 32, 36, 255))
		window._demo_toggle = False
	else:
		window.set_client_background((26, 44, 76, 255))
		window._demo_toggle = True


def _demo_basic_window() -> None:
	"""Basic demo: one window with a custom titlebar and toggle button."""
	window = Window(
		width=960,
		height=600,
		title="Nice Titlebar Test Window",
		background_color=(32, 32, 36, 255),
		titlebar_height=36,
		transparent=False,
		opacity=1.0,
	)

	# Basic styling
	window.titlebar.set_background_color((18, 18, 24, 255))
	window.titlebar.set_text_color((236, 240, 244, 255))

	# Add a custom button on the right that toggles the background
	window.titlebar.add_button(
		TitleBarButton(
			kind="custom",
			icon="o",
			tooltip="Toggle background",
			background_color=(0, 0, 0, 0),
			hover_color=(48, 92, 132, 255),
			width=40,
			on_click=_toggle_background,
		)
	)

	window.show()
	run()


def _demo_transparent_window() -> None:
	"""Demo: semi-transparent window with bright titlebar colors."""
	window = Window(
		width=960,
		height=600,
		title="Transparent Nice Titlebar",
		background_color=(12, 12, 16, 220),
		titlebar_height=36,
		transparent=True,
		opacity=0.92,
	)

	window.titlebar.set_background_color((40, 40, 72, 230))
	window.titlebar.set_text_color((250, 250, 255, 255))

	window.titlebar.add_button(
		TitleBarButton(
			kind="custom",
			icon="R",
			tooltip="Reset background",
			background_color=(0, 0, 0, 0),
			hover_color=(70, 70, 100, 255),
			width=40,
			on_click=lambda w: w.set_client_background((12, 12, 16, 220)),
		)
	)

	window.titlebar.add_button(
		TitleBarButton(
			kind="custom",
			icon="G",
			tooltip="Green-ish background",
			background_color=(0, 0, 0, 0),
			hover_color=(32, 90, 64, 255),
			width=40,
			on_click=lambda w: w.set_client_background((18, 44, 32, 230)),
		)
	)

	window.show()
	run()


def _demo_two_windows() -> None:
	"""Demo: open two windows to verify multi-window handling."""
	main_win = Window(
		width=900,
		height=540,
		title="Main Nice Titlebar Window",
		background_color=(30, 30, 34, 255),
		titlebar_height=34,
		transparent=False,
		opacity=1.0,
	)
	aux_win = Window(
		width=480,
		height=320,
		title="Auxiliary Window",
		background_color=(26, 44, 76, 255),
		titlebar_height=30,
		transparent=False,
		opacity=1.0,
	)

	main_win.titlebar.set_background_color((20, 20, 26, 255))
	aux_win.titlebar.set_background_color((16, 32, 56, 255))

	main_win.show()
	aux_win.show()
	run()


def _paint_canvas(window: Window, canvas) -> None:
	"""Example paint callback using the Direct2D-backed canvas."""
	# Read current box state with sensible defaults.
	box_x = getattr(window, "_box_x", 60)
	box_y = getattr(window, "_box_y", 200)
	box_w = getattr(window, "_box_w", 260)
	box_h = getattr(window, "_box_h", 140)
	box_color = getattr(window, "_box_color", (64, 120, 180, 255))

	# Read button state.
	btn_x = getattr(window, "_btn_x", 60)
	btn_y = getattr(window, "_btn_y", 120)
	btn_w = getattr(window, "_btn_w", 180)
	btn_h = getattr(window, "_btn_h", 40)
	btn_idle = getattr(window, "_btn_idle_color", (80, 90, 120, 255))
	btn_pressed = getattr(window, "_btn_pressed", False)
	btn_active = getattr(window, "_btn_active_color", (140, 160, 220, 255))
	btn_color = btn_active if btn_pressed else btn_idle

	# Background accent stripe.
	canvas.fill_rect(0, 60, 960, 80, (48, 32, 72, 255))

	# Clickable button just under the stripe.
	canvas.fill_rect(btn_x, btn_y, btn_w, btn_h, btn_color)

	# Draggable primary panel.
	canvas.fill_rect(box_x, box_y, box_w, box_h, box_color)

	# A secondary static panel.
	canvas.fill_rect(box_x + box_w + 40, box_y, box_w, box_h, (120, 72, 160, 255))

	# Footer strip.
	canvas.fill_rect(0, window.titlebar.style.height + 400, 960, 40, (24, 24, 32, 255))


def _demo_canvas_window() -> None:
	"""Demo: window with a Python-driven Direct2D canvas."""
	window = Window(
		width=960,
		height=600,
		title="Nice Titlebar Canvas Demo",
		background_color=(20, 20, 26, 255),
		titlebar_height=36,
		transparent=False,
		opacity=1.0,
	)

	window.titlebar.set_background_color((16, 16, 30, 255))
	window.titlebar.set_text_color((236, 240, 244, 255))

	# Initial interactive panel state.
	window._box_x = 60
	window._box_y = 200
	window._box_w = 260
	window._box_h = 140
	window._box_color = (64, 120, 180, 255)
	window._dragging = False
	window._drag_offset = (0, 0)

	# Simple client-area button state.
	window._btn_x = 60
	window._btn_y = 120
	window._btn_w = 180
	window._btn_h = 40
	window._btn_idle_color = (80, 90, 120, 255)
	window._btn_active_color = (140, 160, 220, 255)
	window._btn_pressed = False

	# Install the paint callback that draws into the client area.
	window.on_paint(_paint_canvas)

	def _inside_box(w: Window, x: int, y: int) -> bool:
		"""Return True if (x, y) lies inside the draggable box."""
		bx = getattr(w, "_box_x", 60)
		by = getattr(w, "_box_y", 200)
		bw = getattr(w, "_box_w", 260)
		bh = getattr(w, "_box_h", 140)
		return bx <= x <= bx + bw and by <= y <= by + bh

	def _inside_button(w: Window, x: int, y: int) -> bool:
		"""Return True if (x, y) lies inside the demo button."""
		bx = getattr(w, "_btn_x", 60)
		by = getattr(w, "_btn_y", 120)
		bw = getattr(w, "_btn_w", 180)
		bh = getattr(w, "_btn_h", 40)
		return bx <= x <= bx + bw and by <= y <= by + bh

	def handle_mouse_down(w: Window, x: int, y: int) -> None:
		"""React to mouse press: click button or start dragging the panel."""
		# Button: mark pressed and trigger repaint so color changes immediately.
		if _inside_button(w, x, y):
			w._btn_pressed = True
			w.set_client_background(w._background_color)
			return

		# Panel drag.
		if _inside_box(w, x, y):
			w._dragging = True
			w._drag_offset = (x - w._box_x, y - w._box_y)

	def handle_mouse_up(w: Window, x: int, y: int) -> None:
		"""Stop dragging and toggle button state on release."""
		# If mouse was released over the button, toggle its idle color.
		if _inside_button(w, x, y) and getattr(w, "_btn_pressed", False):
			# Flip between two color themes for the button itself.
			if w._btn_idle_color == (80, 90, 120, 255):
				w._btn_idle_color = (180, 120, 80, 255)
			else:
				w._btn_idle_color = (80, 90, 120, 255)
			w._btn_pressed = False
			w.set_client_background(w._background_color)
			return

		w._btn_pressed = False
		w._dragging = False

	def handle_mouse_move(w: Window, x: int, y: int) -> None:
		"""Move the panel while dragging and trigger repaint."""
		if getattr(w, "_dragging", False):
			off_x, off_y = getattr(w, "_drag_offset", (0, 0))
			w._box_x = x - off_x
			w._box_y = y - off_y
			# Force a repaint by re-applying the same background color.
			w.set_client_background(w._background_color)

	def handle_key_down(w: Window, vk: int) -> None:
		"""Arrow keys nudge the panel, space toggles its color."""
		step = 10
		if vk == 0x25:  # VK_LEFT
			w._box_x -= step
		elif vk == 0x27:  # VK_RIGHT
			w._box_x += step
		elif vk == 0x26:  # VK_UP
			w._box_y -= step
		elif vk == 0x28:  # VK_DOWN
			w._box_y += step
		elif vk == 0x20:  # VK_SPACE
			if w._box_color == (64, 120, 180, 255):
				w._box_color = (180, 96, 64, 255)
			else:
				w._box_color = (64, 120, 180, 255)
		else:
			return
		w.set_client_background(w._background_color)

	window.on_mouse_down(handle_mouse_down)
	window.on_mouse_up(handle_mouse_up)
	window.on_mouse_move(handle_mouse_move)
	window.on_key_down(handle_key_down)

	window.show()
	run()


def main() -> None:
	"""Entry-point: choose which manual demo to run."""
	# Pick ONE of the demos below to focus on when experimenting.
	# _demo_basic_window()
	# _demo_transparent_window()
	# _demo_two_windows()
	_demo_canvas_window()

if __name__ == "__main__":
	main()

