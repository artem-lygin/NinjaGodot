extends Area2D

# =============================
# ⚔️ shuriken.gd
# =============================

# const DAMAGE := 20

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var ShurikenGhostScene := preload("res://Scenes/VFX/ShurikenGhost.tscn")
@export var speed: float = 800.0
@export var max_distance: float = 1200.0

var scale_timer := 0.0
const SCALE_FREQ := 2
var is_expired := false

var base_damage := randi_range(20, 30)
var direction: Vector2 = Vector2.RIGHT
var start_position: Vector2
var velocity: Vector2 = Vector2.ZERO
var pending_flip_h := false
var ghost_timer := 0.0
var ghost_interval := 0.01  # seconds between ghosts

func _ready():
	start_position = global_position
	connect("area_entered", Callable(self, "_on_area_entered"))
	if sprite:
		sprite.play("spin")
		sprite.flip_h = pending_flip_h
	else:
		push_warning("⚠️ AnimatedSprite2D not found on Shuriken!")

func setup(dir: Vector2) -> void:
	direction = dir.normalized()
	velocity = direction * speed
	pending_flip_h = direction.x < 0

func _physics_process(delta):
	position += velocity * delta
	
	# Animate Y-axis scale for rotation illusion
	scale_timer += delta
	var sine := sin(scale_timer * SCALE_FREQ)
	var y_scale := 1 - pow(sine, 2.0)  # Result: 1 → 0 → 1 → 0 → 1 
	sprite.scale.y = y_scale
	# print("🔄 Shuriken Y-scale:", y_scale)
	
	ghost_timer += delta
	if ghost_timer >= ghost_interval and not is_queued_for_deletion():
		ghost_timer = 0
		spawn_ghost()

	# Despawn when exceeding max travel distance
	if global_position.distance_to(start_position) > max_distance:
		is_expired = true
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# print("🔍 Area entered:", area.name)
	# print("🔍 Area parent:", area.get_parent().name if area.get_parent() else "No parent")
	
	# Check if the area is a HurtBox (either direct or under Combat node)
	if not (area.name == "HurtBox" or (area.get_parent() and area.get_parent().name == "HurtBox")):
		# print("❌ Not a HurtBox")
		return

	# var enemy = area.get_parent()

	# Get the enemy node (parent of the Combat node or direct parent of HurtBox)
	var enemy = area.get_parent()
	# print("🔍 First parent:", enemy.name)

	if enemy.name == "HurtBox":
		enemy = enemy.get_parent()  # Get the Combat node
		# print("🔍 Combat node:", enemy.name)

	# Always get the parent of Combat to reach the actual enemy
	if enemy.name == "Combat":
		enemy = enemy.get_parent()  # Get the actual enemy node
		# print("🔍 Enemy node:", enemy.name)

	if enemy and enemy.has_method("take_damage"):
		var player = get_tree().get_first_node_in_group("player")
		if player and "facing_direction" in player:
			var direction = player.facing_direction
			var is_crit = false
			# var base_damage = DAMAGE
			enemy.take_damage(base_damage, direction, is_crit)
		else:
			print ("⚠️ Could not access player or direction for shuriken.")
	else:
		print("⚠️ Object has no take_damage")

	queue_free()

func spawn_ghost():
	# Avoid spawning ghosts if we're being deleted
	if is_expired or is_queued_for_deletion() or !is_inside_tree():
		return
	
	if not ShurikenGhostScene or not sprite or not sprite.sprite_frames:
		return

	var ghost = ShurikenGhostScene.instantiate()
	get_tree().get_root().add_child(ghost)

	# Defer setup to next frame to allow _ready to complete
	await get_tree().process_frame
	# Avoid spawning ghosts if we're being deleted once again after await get_tree().process_frame
	if is_expired or is_queued_for_deletion() or !is_instance_valid(sprite):
		return

	var texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not texture:
		# print("❌ Could not fetch shuriken animation texture")
		return

	# print("👻 Calling ghost.setup with:", texture, global_position, sprite.flip_h)
	ghost.setup(texture, global_position, sprite.flip_h)
