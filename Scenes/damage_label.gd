extends Label

func show_damage(value: int) -> void:
	text = "-" + str(value)
	modulate.a = 1.0
	position = Vector2(-20, -36)  # Start above dummy center

	var tween = create_tween()
	tween.set_parallel()

	# Float upward
	tween.tween_property(self, "position", Vector2(-20, -96), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween.finished
	queue_free()  # Destroy label after animation
