extends Node2D

const THROW_SPEED: float = 800.0  # Replace with a shared constant if possible
const GRAVITY: float = 800  # Replace with a shared constant if possible

# @onready var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var point_count := 60 # 120- almost full, 60-ish is about half
@export var time_step := 0.2 # Smaller = more points, smoother
var fade_tween: Tween # = create_tween()
@export var fade_duration: float = 0.2

var target_position: Vector2 = Vector2.ZERO
var is_visible := false


func _ready():
	modulate.a = 0.0
	visible = false

func _process(delta):
	queue_redraw()  # Triggers _draw()

func _draw():
	if not is_visible:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	var aiming_target = player.get_node_or_null("AimingTarget")

	if not player or not aiming_target:
		return
	
	var start_pos: Vector2 = player.global_position
	var target_pos: Vector2 = aiming_target.global_position

	var direction: Vector2 = (target_pos - start_pos).normalized()
	var draw_velocity: Vector2 = direction * THROW_SPEED

	# print("Trajectory Drawer will be calculated vith velocity: ", velocity)

	var time_step = 1.0 / Engine.get_physics_ticks_per_second()
	var reached_target := false
	
	for i in point_count:
		var t: float = i * time_step 
		var pos: Vector2 = start_pos + draw_velocity * t + 0.5 * Vector2(0, GRAVITY) * t * t
		
		# Only start drawing when we're past or near aiming_target
		if not reached_target and pos.distance_to(target_pos) < 5.5:
			reached_target = true

		if reached_target:
			var alpha := 0.6 - float(i) / float(point_count)
			var color := Color(1, 1, 1, alpha)
			draw_circle(pos - global_position, 1.5, color)

func set_visible_with_fade(show: bool) -> void:
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()

	fade_tween = create_tween()

	if show:
		visible = true
		is_visible = true
		fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE)
	else:
		fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration/2).set_trans(Tween.TRANS_SINE)
		await fade_tween.finished
		visible = false
		is_visible = false
