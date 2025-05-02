extends RigidBody2D

const BOUNCE := 0.3 # Bounce on contact
const FRICTION := 0.7 # Surface grip

# │ BOUNCE      │ 0.0 means no bouncing at all when hitting surfaces. Values closer to 1.0 would make it bounce like a ball.
# │ FRICTION    │ 1.5 means strong grip with the surface. Higher values reduce sliding. 0.0 would be completely slippery.

# ──────────────────────────────────────────────────────────────
# Mini Bomb Blast Properties
const BLAST_DELAY := 4.0
const BLAST_RADIUS := 150.0
const DAMAGE_INNER := 400  # 0% - 33%
const DAMAGE_MID := 150    # 34% - 66%
const DAMAGE_OUTER := 50   # 67% - 100%
# ──────────────────────────────────────────────────────────────

@export var lifetime := 10.0
# @onready var label: Label = $PositionLabel

#func _process(delta):
	#if label:
		#label.text = str(global_position.round())

func _ready():
	set_process(true)
	# Reduce movement after landing
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = 0.0  # Keep 0 to match the trajectory_drawer()
	angular_damp = 2.0  # Stops rolling/spinning quickly
	
	# Set up physics material
	var mat := PhysicsMaterial.new()
	mat.bounce = BOUNCE 
	mat.friction = FRICTION  
	physics_material_override = mat

	# Start fuse countdown
	await get_tree().create_timer(BLAST_DELAY).timeout
	explode()

	# Self-destruct after lifetime in case explosion doesn't
	await get_tree().create_timer(lifetime - BLAST_DELAY).timeout
	if is_instance_valid(self):
		queue_free()

func explode():
	print("💥 Mini Bomb exploded at: ", global_position)

	# Check if world is valid
	var space_state := get_world_2d().direct_space_state
	if not space_state:
		print("❌ No space_state available!")
		return
	print("🌐 Got space_state:", space_state)

	# Step 1: Define the explosion shape
	var exposion_circle := CircleShape2D.new()
	exposion_circle.radius = BLAST_RADIUS
	print("🔵 Created CircleShape2D with radius:", BLAST_RADIUS)

	# Step 2: Setup query parameters
	var shape_params := PhysicsShapeQueryParameters2D.new()
	shape_params.shape = exposion_circle
	shape_params.transform = Transform2D(0, global_position)
	shape_params.collision_mask = 1 << 3 # Layer 4 
	shape_params.collide_with_bodies = true
	shape_params.collide_with_areas = true
	print("⚙️ Query setup at:", global_position)
	print("📡 Mask set to layer 4:", shape_params.collision_mask)

	# Step 3: Perform the query
	var results := space_state.intersect_shape(shape_params)
	print("🧪 Detected in blast radius:", results.size())

	# Optional: Log all collider names
	if results.size() > 0:
		for r in results:
			var n: Node = r.get("collider")
			print("👀 Found collider:", n, "| Name:", n.name, "| Type:", n.get_class())
	else:
		print("🚫 No colliders found in radius")

	for result in results:
		var collider: Node = result.get("collider")
		if collider:
			print("🔬 Collider name:", collider.name, "| Type:", collider.get_class(), "| Layer:", collider.collision_layer, "| Is Area2D:", collider is Area2D)
		
		# ✅ Handle HurtBox structure
		var enemy = collider

		if collider.name == "HurtBox":
			print("🧠 Detected HurtBox")
			enemy = collider.get_parent()  # Combat
			if enemy.name == "Combat":
				enemy = enemy.get_parent()  # Turtle (enemy node)

		elif collider.get_parent() and collider.get_parent().name == "HurtBox":
			print("🧠 Detected child of HurtBox")
			enemy = collider.get_parent().get_parent()  # Turtle (via Combat)

		# ✅ Check if it has take_damage method
		if enemy and enemy.has_method("take_damage"):
			var distance := global_position.distance_to(enemy.global_position)
			var distance_ratio := distance / BLAST_RADIUS

			var damage := 0
			if distance_ratio <= 0.33:
				damage = 400
			elif distance_ratio <= 0.66:
				damage = 150
			else:
				damage = 50

			enemy.take_damage(damage, 0, false, false)
			var rounded_ratio: float = floor(distance_ratio * 100.0) / 100.0
			print("🔥 Damaging", enemy.name, "| Distance ratio:", rounded_ratio, "| Damage:", damage)
		else:
			print("⚠️ No take_damage() found in:", collider.name)
	
	var blast = preload("res://Scenes/VFX/BlastEffect.tscn").instantiate()
	blast.global_position = global_position
	get_tree().current_scene.add_child(blast)
	
	# Lifetime timer
	# await get_tree().create_timer(lifetime).timeout
	queue_free()
