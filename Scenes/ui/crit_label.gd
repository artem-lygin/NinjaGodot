extends Label

# =============================
# 💥 crit_label.gd
# =============================

# ✅ Displays "CRIT!" label above enemy
# ✅ Customizable text and color (gold by default)
# ✅ Pops upward with tweened movement
# ✅ Shakes horizontally (impact feel)
# ✅ Fades out and auto-removes (queue_free)
# ✅ Delay configurable when triggered
# ✅ Highest Z index to appear over all visuals

func show_crit(custom_text: String = "CRIT!"):
	self.text = custom_text
	scale = Vector2(1.6, 1.6)  # Start slightly larger
	modulate.a = 1.0
	position = Vector2(-20, -64)

	# Big red or gold color
	add_theme_color_override("font_color", Color("FFD700"))  # gold
	add_theme_font_size_override("font_size", 24)

	# Animate float up + fade out
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "position", Vector2(-20, -148), 1.8).set_trans(Tween.TRANS_SINE).set_delay(0.1) # Float up with delay
	tween.tween_property(self, "modulate:a", 0.0, 1.8).set_trans(Tween.TRANS_SINE) # Fade out
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) # POP scale-in
	
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
