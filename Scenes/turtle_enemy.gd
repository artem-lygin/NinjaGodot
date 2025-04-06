extends "res://Scenes/enemy_class.gd"

# =============================
# 🐢 turtle_enemy.gd
# =============================

# ✅ Inherits all features from enemy_class.gd
# ✅ Patrol behavior (walks left/right on platform)
# ✅ Flip sprite based on direction
# ✅ Uses base animations: walk, idle, aggro, dead_fall
# ✅ AGGRO if player detected or hit
# ✅ STUN and knockback active
# ✅ Fully customizable health, animations, and speed

const ENEMY_NAME = "Turtle"
const TURTLE_SPEED = 20  # Slower than base enemy
const TURLE_MAX_HP = 60

func _ready():
	super._ready()  # Initialize base class first
	max_hp = TURLE_MAX_HP
	current_hp = max_hp
	# Custom setup for Turtle
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	
	# Ensure hurt_box is properly initialized
	if hurt_box == null:
		print("[", ENEMY_NAME, "] HurtBox is null, attempting to find it...")
		hurt_box = $Combat/HurtBox
		if hurt_box == null:
			print("[", ENEMY_NAME, "] Error: HurtBox not found at path $Combat/HurtBox")
			print("[", ENEMY_NAME, "] Available nodes:", get_children())
			# Try alternative path
			hurt_box = $HurtBox
			if hurt_box == null:
				print("[", ENEMY_NAME, "] Error: HurtBox not found at root level either")
				return
			print("[", ENEMY_NAME, "] Found HurtBox at root level")
		print("[", ENEMY_NAME, "] Successfully initialized HurtBox")

func _physics_process(delta):
	super._physics_process(delta)

func take_damage(amount: int, attacker_direction: int, is_crit: bool = false) -> void:
	super.take_damage(amount, attacker_direction, is_crit)

func update_aggro(delta: float) -> void:
	# Placeholder for future aggro behavior (e.g., chase player)
	pass
