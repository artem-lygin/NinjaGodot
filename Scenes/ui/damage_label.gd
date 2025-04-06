extends Label

# =============================
# 💢 damage_label.gd
# =============================

# ✅ Displays numeric damage value above enemy
# ✅ Color-coded: gold for crits, white for normal
# ✅ Customizable font size per damage type
# ✅ Pops upward with tweened movement
# ✅ Fades out and self-removes
# ✅ Can be shown multiple times in a row
# ✅ Z index: always on top

func show_damage(value: int, is_crit: bool = false) -> void:
	text = "-" + str(value)
	modulate.a = 1.0
	position = Vector2(-20, -36)  # Start above dummy center

	# Change color if crit
	if is_crit:
		add_theme_color_override("font_color", Color("FFD700"))
		add_theme_font_size_override("font_size", 20)
	else:
		add_theme_color_override("font_color", Color("white"))
		add_theme_font_size_override("font_size", 16)

	var tween = create_tween()
	tween.set_parallel()

	# Float upward
	tween.tween_property(self, "position", Vector2(-20, -96), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween.finished
	queue_free()  # Destroy label after animation
