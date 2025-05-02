extends Node2D

@onready var ghost_sprite: Sprite2D = $ShurikenSprite2D

# func _ready():
# 	print("✅ Ghost ready and in tree. Node name:", name)
# 	print("🧪 ghost_sprite:", ghost_sprite)

func setup(texture: Texture2D, prop_position: Vector2, flip_h: bool) -> void:
	if !is_instance_valid(ghost_sprite):
		# print("❌ Sprite2D not initialized!")
		return

	ghost_sprite.texture = texture
	ghost_sprite.flip_h = flip_h
	global_position = prop_position
	ghost_sprite.self_modulate = Color(1, 1, 1, 0.8)

	# print("✅ Ghost ready and in tree. Node name:", name)
	# print("📍 Ghost Position:", global_position)

	# Animate fade out and disappear
	var tween = create_tween()
	tween.tween_property(ghost_sprite, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_LINEAR)

	await tween.finished
	queue_free()
