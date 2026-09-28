class_name DealStyle
extends RefCounted

const GOLD := Color(0.92, 0.78, 0.45, 1)
const INK := Color(0.12, 0.08, 0.05, 1)


static func button(text: String, disabled: bool, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.disabled = disabled
	btn.custom_minimum_size = Vector2(88, 56)
	InstrumentStyle.action(btn)
	btn.pressed.connect(cb)
	return btn
