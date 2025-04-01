extends Label

func show_crit(text := "CRIT!"):
	self.text = text
	modulate.a = 1.0
	position = Vector2(-20, -64)

	# Big red or gold color
	add_theme_color_override("font_color", Color("FFD700"))  # gold
	add_theme_font_size_override("font_size", 24)

	# Animate float up + fade out
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "position", Vector2(-20, -128), 1.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE)
	
	# Add shake effect (left-right jitter)
	var shake_tween = create_tween()
	var shake_amount = 6
	var shake_duration = 0.06
	var count = 5

	for i in count:
		shake_tween.tween_property(self, "position:x", position.x + randf_range(-shake_amount, shake_amount), shake_duration)
		shake_tween.tween_property(self, "position:x", position.x, shake_duration)

	await tween.finished
	queue_free()
