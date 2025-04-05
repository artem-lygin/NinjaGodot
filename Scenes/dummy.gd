extends "res://Scenes/enemy_class.gd"

# Dummy enemy — inherits all logic from enemy_class.gd
# No patrol, idle or movement behavior, just a stationary target

var dummy_max_hp: int = 220  # Custom HP for the dummy

func _ready() -> void:
	max_hp = dummy_max_hp  # Override parent value BEFORE calling super
	current_hp = max_hp  # Apply this custom HP
	super._ready()
	set_state(State.IDLE)

func take_damage(amount: int, attacker_direction: int, is_crit: bool = false) -> void:
	if is_dead:
		return

	hit_direction = attacker_direction
	current_hp -= amount
	print("[Dummy] Took damage:", amount)

	health_bar.value = current_hp
	health_bar.visible = current_hp < max_hp

	# Let the health bar handle its own style and reaction
	if health_bar.has_method("update_color"):
		health_bar.update_color()

	if health_bar.has_method("shake"):
		health_bar.shake()

	show_damage_label(amount, is_crit)

	if current_hp <= 0:
		die()
