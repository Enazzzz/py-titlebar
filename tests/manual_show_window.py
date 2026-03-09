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


def main() -> None:
	"""Create a window and show it with a custom titlebar."""
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


if __name__ == "__main__":
	main()

