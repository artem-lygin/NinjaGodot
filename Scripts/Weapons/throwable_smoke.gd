extends RigidBody2D

const BOUNCE := 0.2 # Bounce on contact
const FRICTION := 1.0 # Surface grip

# │ Property    │ Description
# ├─────────────┼────────────────────────────────────────────
# │ BOUNCE      │ 0.0 means no bouncing at all when 
# │             │ hitting surfaces. Values closer to 1.0 
# │             │ would make it bounce like a ball.
# ├─────────────┼────────────────────────────────────────────
# │ FRICTION    │ 1.5 means strong grip with the surface.
# │             │ Higher values reduce sliding.
# │             │ 0.0 would be completely slippery.

@export var lifetime := 10.0

func _ready():
	# Reduce movement after landing
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = 0.0  # Keep 0 to match the trajectory_drawer()
	angular_damp = 2.0  # Stops rolling/spinning quickly
	
	# Set up physics material
	var mat := PhysicsMaterial.new()
	mat.bounce = BOUNCE 
	mat.friction = FRICTION  
	physics_material_override = mat

	# Lifetime timer
	await get_tree().create_timer(lifetime).timeout
	queue_free()
