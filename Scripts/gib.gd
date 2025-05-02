extends RigidBody2D

@onready var blood_particles: CPUParticles2D = $BloodParticles
@onready var blood_dust: CPUParticles2D = $BloodParticlesDust

func _ready():
	# print("🩸 Gib ready:", name, "| Type:", get_class(), "| Position:", global_position)
	blood_particles.emitting = true  # 🔥 Trigger blood on spawn
	blood_dust.emitting = true # 🔥 Trigger blood dust on spawn

	await get_tree().create_timer(1.2).timeout
	queue_free()  # 🧹 Clean up
