extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	print("✅ Ghost ready and in tree. Node name:", name)

func setup(texture: Texture2D, position: Vector2, flip_h: bool):
	if not sprite:
		push_error("❌ Sprite is null in GhostSprite!")
		return

	print("🧊 Ghost texture received:", texture)

	# Apply texture and flip to the child sprite
	sprite.texture = texture
	sprite.flip_h = flip_h

	# ✅ Correct: set the root ghost node position
	self.global_position = position
	print("📍 Setting ghost global_position to:", position)
	print("📍 Ghost global_position after setup:", self.global_position)

	# Set transparency
	modulate = Color(1, 1, 1, 0.8)

	# Fade out tween
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	queue_free()
