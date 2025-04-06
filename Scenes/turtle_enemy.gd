extends "res://Scenes/enemy_class.gd"

# TurtleEnemy: Specific behavior built on top of base Enemy class
const TURTLE_SPEED = 20  # Slower than base enemy
const ENEMY_NAME = "Turtle"

func _ready():
	super._ready()  # Initialize base class first
	
	# Custom setup for Turtle
	max_hp = 30
	current_hp = max_hp
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
