extends Node

const MAX_SHURIKENS := 30
const RESTORE_TIME := 8.0
@onready var shuriken_scene = preload("res://Scenes/Shuriken.tscn")

var available := MAX_SHURIKENS
var cooldowns := []

func _ready():
	cooldowns.resize(MAX_SHURIKENS)
	for i in range(MAX_SHURIKENS):
		cooldowns[i] = 0.0
	set_process(true)

func _process(delta):
	for i in range(MAX_SHURIKENS):
		if cooldowns[i] > 0.0:
			cooldowns[i] -= delta
			if cooldowns[i] <= 0.0:
				available = min(available + 1, MAX_SHURIKENS)
				print("🔁 Restored shuriken:", i + 1)

func can_throw() -> bool:
	return available > 0

func throw(pos: Vector2, direction: Vector2) -> void:
	if not can_throw():
		print("❌ No shurikens available!")
		return

	var shuriken = shuriken_scene.instantiate()
	shuriken.global_position = pos
	shuriken.setup(direction)  # Call setup()
	get_tree().current_scene.add_child(shuriken)

	available -= 1

	for i in range(MAX_SHURIKENS):
		if cooldowns[i] <= 0.0:
			cooldowns[i] = RESTORE_TIME
			print("🕒 Cooldown started for slot", i + 1)
			break

func replenish_all():
	available = MAX_SHURIKENS
	for i in range(MAX_SHURIKENS):
		cooldowns[i] = 0.0
	# print("🔄 All shurikens replenished")
