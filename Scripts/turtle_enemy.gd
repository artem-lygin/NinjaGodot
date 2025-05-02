extends "res://Scripts/enemy_class.gd"

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
const TURTLE_SPEED = 20  # Slower than base enemy (Not used)
const TURLE_MAX_HP = 60
const GORE_SPLIT = true

func _ready() -> void:
	super._ready()  # Initialize base class first
	
	# -- Gore support --
	gib_texture_left = preload("res://Sprites/foes/gibs/turtle-left.png")
	gib_texture_right = preload("res://Sprites/foes/gibs/turtle-right.png")
	
	max_hp = TURLE_MAX_HP
	current_hp = max_hp
	# Custom setup for Turtle
	health_bar.max_value = max_hp
	health_bar.value = current_hp

func _physics_process(delta):
	super._physics_process(delta)


func update_aggro(delta: float) -> void:
	# Placeholder for future aggro behavior (e.g., chase player)
	pass
