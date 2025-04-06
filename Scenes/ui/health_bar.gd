extends ProgressBar

# =============================
# ❤️ health_bar.gd
# =============================

# ✅ Pixel-style health bar
# ✅ Dynamically sized and positioned
# ✅ Color changes:
#    - Green (healthy)
#    - Yellow (wounded)
#    - Red (critical)
# ✅ Shake effect on damage
# ✅ Updates via method calls from enemy_class.gd
# ✅ Pivot centered — easily anchor above enemies
# ✅ Hidden when full, auto-visible on damage

var shake_amount := 4
var shake_duration := 0.2

func _ready() -> void:
	# Hide until used
	self.visible = false

	# Create and apply a unique fill style
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 1.0, 0.2)  # Start with green
	fill_style.draw_center = true
	fill_style.border_width_left = 0
	fill_style.border_width_top = 0
	fill_style.border_width_right = 0
	fill_style.border_width_bottom = 0
	fill_style.corner_radius_top_left = 0
	fill_style.corner_radius_top_right = 0
	fill_style.corner_radius_bottom_left = 0
	fill_style.corner_radius_bottom_right = 0
	add_theme_stylebox_override("fill", fill_style)

# Make sure this function is properly defined and accessible
func update_color() -> void:
	var health_ratio := value / max_value
	var fill_style = get_theme_stylebox("fill")
	
	if fill_style:  # Safety check
		if health_ratio > 0.6:
			fill_style.bg_color = Color(0.2, 1.0, 0.2)  # Green
		elif health_ratio > 0.3:
			fill_style.bg_color = Color(1.0, 1.0, 0.2)  # Yellow
		else:
			fill_style.bg_color = Color(1.0, 0.2, 0.2)  # Red

# Shake HealthBar on hit
func shake() -> void:
	var original_pos = position
	var tween = create_tween()

	tween.tween_property(
		self, "position",
		original_pos + Vector2(randf_range(-shake_amount, shake_amount), 0),
		shake_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		self, "position",
		original_pos,
		shake_duration
	).set_delay(shake_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
