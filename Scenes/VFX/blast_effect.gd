extends Node2D

# @export var max_radius := 150.0
# @export var ripple_count := 3
@export var duration := 0.8
@onready var particles := $BlastParticles  # Your CPUParticles2D or GPUParticles2D node

@onready var shader: ShaderMaterial = $ColorRect.material as ShaderMaterial

var timer := 0.0

func _ready():

	set_process(true)
	
	if $BlastParticles:
		$BlastParticles.restart()

func _process(delta):
	timer += delta
	# var progress: float = clamp(timer / duration, 0.0, 1.0)
	var t: float = clamp(timer / duration, 0.0, 1.0)
	var progress: float = 1.0 - pow(1.0 - t, 2.5) # easeOutQuad-like effect
	if shader:
		shader.set_shader_parameter("radius", 450.0)
		shader.set_shader_parameter("progress", progress)
		shader.set_shader_parameter("ring_color", Color(1, 1, 1, 1))
		if progress >= 1.0:
			queue_free()


	if timer >= duration:
		queue_free()
