extends "res://Scenes/enemy_class.gd"

# Dummy enemy — inherits all logic from enemy_class.gd
# No patrol, idle or movement behavior, just a stationary target
const ENEMY_NAME = "Dummy"
const IS_KNOCKABLE = false # Can't be knoked back by attack
const IS_AGGROABLE = false # Doesn't turn to AGGRO after get a hit
const IS_STUNNABLE = true # Not used yet
const HEALTH_BAR_SIZE = 48

var dummy_max_hp: int = 220  # Custom HP for the dummy

func _ready() -> void:
	knockable = IS_KNOCKABLE
	aggroable = IS_AGGROABLE
	HealthBarSize = HEALTH_BAR_SIZE
	max_hp = dummy_max_hp  # Override parent value BEFORE calling super
	current_hp = max_hp  # Apply this custom HP
	super._ready()
	set_state(State.IDLE)

	if current_hp <= 0:
		die()
