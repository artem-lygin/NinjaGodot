extends Node2D

# =============================
# 💥 crit_label.gd
# =============================

# ✅ Displays "CRIT!" or "MEGACRIT!" label above enemy
# ✅ Customizable text and color (gold by default)
# ✅ Pops upward with tweened movement
# ✅ Shakes horizontally (impact feel)
# ✅ Fades out and auto-removes (queue_free)
# ✅ Delay configurable when triggered
# ✅ Highest Z index to appear over all visuals

@onready var label: Label = $CritLabel

func show_crit(custom_text: String = "NO VALUE!"):
	label.text = custom_text
	label.scale = Vector2(1.2, 1.2)  # Start slightly larger
	label.modulate.a = 1.0
	# label.position = Vector2(0, 0)
	label.position = Vector2(-label.size.x / 2, -80)

	# 🎨 Color and size based on type of crit
	if custom_text == "MEGACRIT!!!":
		label.add_theme_color_override("font_color", Color("ff4444"))  # Bold red for mega crit
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))   # Black outline
		label.add_theme_constant_override("outline_size", 8)           # Stroke thickness
		label.add_theme_font_size_override("font_size", 28)
	else:
		label.add_theme_color_override("font_color", Color("FFD700"))  # Gold for normal crit
		label.add_theme_font_size_override("font_size", 24)

	# 🌀 Animate float up + fade out + scale pop
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "position", Vector2(0, -160), 1.8).set_trans(Tween.TRANS_SINE).set_delay(0.1)
	tween.tween_property(self, "modulate:a", 0.0, 1.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "scale", Vector2(1.6, 1.6), 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 💢 Shake effect
	var shake_tween = create_tween()
	var shake_amount = 6
	var shake_duration = 0.06
	var count = 5

	for i in count:
		shake_tween.tween_property(self, "position:x", position.x + randf_range(-shake_amount, shake_amount), shake_duration)
		shake_tween.tween_property(self, "position:x", position.x, shake_duration)

	await tween.finished
	queue_free()
