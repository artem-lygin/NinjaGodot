extends Node

# --- 🎯 THROWABLE MANAGER ---
# Manages multiple types of throwable items (e.g. decoy, smoke, mini-bomb)
# Tracks how many of each type are available
# Handles cooldowns per throwable type
# Supports cycling between throwables via input

# Define each throwable type
enum ThrowableType {
	DECOY,
	SMOKE,
	MINI_BOMB,
}

# --- CONFIG ---
var max_amounts := {
	ThrowableType.DECOY: 10,
	ThrowableType.SMOKE: 10,
	ThrowableType.MINI_BOMB: 10,
}

var cooldown_durations := {
	ThrowableType.DECOY: 5.0,
	ThrowableType.SMOKE: 5.0,
	ThrowableType.MINI_BOMB: 5.0,
}

var throwable_scenes := {
	ThrowableType.DECOY: preload("res://Scenes/Weapons/ThrowableDecoy.tscn"),
	ThrowableType.SMOKE: preload("res://Scenes/Weapons/ThrowableSmoke.tscn"),
	ThrowableType.MINI_BOMB: preload("res://Scenes/Weapons/ThrowableMiniBomb.tscn"),
}

# --- STATE ---
var amounts := {
	ThrowableType.DECOY: 10,
	ThrowableType.SMOKE: 10,
	ThrowableType.MINI_BOMB: 10,
}

var cooldown_timers := {
	ThrowableType.DECOY: 0.0,
	ThrowableType.SMOKE: 0.0,
	ThrowableType.MINI_BOMB: 0.0,
}

var current_throwable: int = ThrowableType.DECOY

# --- API ---

func _process(delta):
	# Tick down cooldowns per throwable type
	for type in cooldown_timers.keys():
		if amounts[type] < max_amounts[type]:
			if cooldown_timers[type] > 0.0:
				cooldown_timers[type] -= delta
			if cooldown_timers[type] <= 0.0:
				amounts[type] += 1
				# print("🔁 Restocked ", get_throwable_name(type), " | Now:", amounts[type])
				if amounts[type] < max_amounts[type]:
					cooldown_timers[type] = cooldown_durations[type]

func can_throw() -> bool:
	return amounts[current_throwable] > 0

func throw(global_position: Vector2, velocity: Vector2):
	if not can_throw():
		# print("🚫 Cannot throw: none left")
		return

	var scene = throwable_scenes.get(current_throwable)
	if not scene:
		# push_error("❌ Throwable scene not assigned for current type")
		return

	var inst = scene.instantiate()
	inst.global_position = global_position
	inst.linear_velocity = velocity
	get_tree().current_scene.add_child(inst)

	# Update amount and always reset cooldown
	amounts[current_throwable] -= 1
	cooldown_timers[current_throwable] = cooldown_durations[current_throwable]

	# print("🎯 Threw: ", get_current_throwable_name(), " | Remaining:", amounts[current_throwable])

func switch_throwable_next():
	current_throwable = (current_throwable + 1) % ThrowableType.size()
	# print("➡️ Switched to: ", get_current_throwable_name())

func switch_throwable_prev():
	current_throwable = (current_throwable - 1 + ThrowableType.size()) % ThrowableType.size()
	# print("⬅️ Switched to: ", get_current_throwable_name())

func get_current_throwable_name() -> String:
	return get_throwable_name(current_throwable)
			
func get_throwable_name(throwable_type: int) -> String:
	match throwable_type:
		ThrowableType.DECOY:
			return "Decoy"
		ThrowableType.SMOKE:
			return "Smoke"
		ThrowableType.MINI_BOMB:
			return "Mini Bomb"
		_:
			return "Unknown"
			
func get_current_throwable_type() -> ThrowableType:
	return current_throwable

func get_throwable_count(throwable_type: ThrowableType) -> int:
	return amounts.get(throwable_type, 0)

func get_throwable_cooldown(throwable_type: ThrowableType) -> float:
	if amounts[throwable_type] < max_amounts[throwable_type]:
		return cooldown_timers.get(throwable_type, 0.0)
	return 0.0

func replenish_all():
	for type in amounts.keys():
		amounts[type] = max_amounts[type]
		cooldown_timers[type] = 0.0
	# print("🔄 All throwables replenished")
