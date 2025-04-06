extends CharacterBody2D

# =============================
# 🧠 enemy_class.gd (BASE ENEMY)
# =============================

# ✅ Shared health and damage system
# ✅ Health bar with color + shake effects
# ✅ Floating damage & crit labels
# ✅ Knockback based on damage taken
# ✅ Death launch based on final hit force
# ✅ State machine: IDLE, PATROL, AGGRO, STUNNED, DEAD
# ✅ AGGRO with delay + timer after taking damage
# ✅ STUN with cooldown
# ✅ Animation control via state
# ✅ Fall cleanup (queue_free if falls off screen)
# ✅ Visual feedback (flash red on hit)
# ✅ Configurable base speed and gravity
# ✅ Toggles:
#    - knockable
#    - aggroable

const SPEED = 40  # How fast the dummy moves
const GRAVITY = 800.0  # Match this to your player's gravity

# -- Health System --
var max_hp: int = 60
var current_hp: int = max_hp
var is_dead: bool = false

# -- Basic Properties --
var knockable := true # Can be knocked back
var aggroable := true # Can turn to AGGRO state

# -- Knockback / Damage Reaction --
var is_stunned: bool = false
var hit_direction: int = 0 # Direction of the hit tooked
var recently_hit := false # For avoiding several take_damage from one hit
var last_damage_received: int = 0 # Death Launch mechanic

var direction = -1  # Start facing left (-1 for left, 1 for right)
var turn_cooldown = 0.0
var aggro_timer := 0.0
var aggro_turn_cooldown := 0.0
var player_node: Node2D = null  # Assigned when enemy aggro is triggered
var previous_state: State = State.IDLE # Tracking last state for proper ordering of states

# -- State System --
enum State { IDLE, PATROL, AGGRO, STUNNED, DEAD }
var current_state: State = State.PATROL

# -- UI Components (preloaded scenes) --
var HealthBarSize = 32
var HealthBarScene := preload("res://Scenes/ui/HealthBar.tscn")
var DamageLabelScene := preload("res://Scenes/ui/DamageLabel.tscn")
var CritLabelScene := preload("res://Scenes/ui/CritLabel.tscn")

@onready var health_bar: ProgressBar = null  # Will be assigned on spawn
@onready var ray_ground = $RayCast2D_Ground
@onready var ray_wall = $RayCast2D_Wall
@onready var foe_sprite = $Visuals/FoeAnimatedSprite
var hurt_box: Area2D  # Will be set in _ready()

func set_state(new_state: State) -> void:
	current_state = new_state

	var state_name = ""
	match new_state:
		State.IDLE: state_name = "IDLE"
		State.PATROL: state_name = "PATROL"
		State.AGGRO: state_name = "AGGRO"
		State.STUNNED: state_name = "STUNNED"
		State.DEAD: state_name = "DEAD"
		_: state_name = str(new_state)

	print("[Enemy] State set to:", state_name)

func _ready() -> void:
	current_hp = max_hp
	hurt_box = $Combat/HurtBox  # Default hurtbox path

	# Spawn and attach health bar above enemy
	var bar = HealthBarScene.instantiate()
	bar.position = Vector2(0, -40)
	add_child(bar)

	# Get the ProgressBar node from the instantiated scene
	health_bar = bar.get_node("ProgressBar")
	print("[Enemy] Health bar node type:", health_bar.get_class())
	print("[Enemy] Health bar script:", health_bar.get_script())
	
	health_bar.custom_minimum_size.x = HealthBarSize # Dynamically sized bar
	health_bar.max_value = max_hp
	health_bar.value = max_hp
	health_bar.visible = false  # Hidden until damaged
	
	# Connect to the sword hitbox signal
	connect("area_entered", Callable(self, "_on_hit"))
	
	# Initialize sprite
	if foe_sprite:
		foe_sprite.play("walk")

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.y += GRAVITY * delta  # Add gravity even if dead C'mon
		move_and_slide() # Moves with current velocity and do not scipped by physics
		return

	# Apply gravity
	velocity.y += GRAVITY * delta

	match current_state:
		State.IDLE:
			velocity.x = 0
		State.PATROL:
			if not is_stunned:
				velocity.x = direction * SPEED
			turn_cooldown -= delta
			if turn_cooldown <= 0 and (not ray_ground.is_colliding() or ray_wall.is_colliding()):
				direction *= -1
				turn_cooldown = 0.3
				if foe_sprite:
					foe_sprite.flip_h = direction < 0
				ray_wall.target_position.x *= -1
				ray_ground.position.x *= -1
		State.AGGRO:
			if player_node and not is_stunned:
				aggro_turn_cooldown -= delta

				if aggro_turn_cooldown <= 0:
					var direction_to_player = sign(player_node.global_position.x - global_position.x)

					# Only flip if direction has changed
					if direction_to_player != direction:
						direction = direction_to_player
						aggro_turn_cooldown = 0.3  # 300ms delay before another turn

						if foe_sprite:
							foe_sprite.flip_h = direction < 0

				velocity.x = direction * SPEED * 1.5

			aggro_timer -= delta
			if aggro_timer <= 0:
				set_state(State.PATROL)
		_:
			pass


	# Update animation based on movement
	if not is_dead and not is_stunned and foe_sprite:
		if abs(velocity.x) > 1:
			if foe_sprite.animation != "walk":
				foe_sprite.play("walk")
		else:
			if foe_sprite.animation != "idle":
				foe_sprite.play("idle")

	# Clean up if enemy falls way off screen
	if global_position.y > 2000:
		queue_free()
	
	move_and_slide()

func take_damage(amount: int, attacker_direction: int, is_crit: bool = false) -> void:
	if is_dead or recently_hit:
		return

	recently_hit = true
	hit_direction = attacker_direction
	last_damage_received = amount
	current_hp -= amount

	print("[Enemy] Took damage:", amount, "| Crit:", is_crit)

	# Update health bar visuals
	health_bar.value = current_hp
	health_bar.update_color()  # Use the health_bar's built-in method
	health_bar.visible = current_hp < max_hp
	show_damage_label(amount, is_crit)
	health_bar.shake()  # Use the health_bar's built-in shake method

	# Flash red briefly on hit
	modulate = Color(1.0, 0.5, 0.5)  # Light red tint
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	recently_hit = false

	# Check for death
	if current_hp <= 0:
		die()
		return

	# Always go aggro after taking damage, refresh duration
	if aggroable and not is_dead and attacker_direction != 0:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			trigger_aggro(player)
			
	# Only apply stun and knockback if not dying
	stun()
	
	if knockable:
		apply_knockback(amount)
	else:
		print("[Enemy] Knockback disabled.")

func apply_knockback(amount: int) -> void:
	var knockback_ratio: float = clamp(float(amount) / float(max_hp), 0.0, 1.0)
	var scaled_ratio := pow(knockback_ratio, 3.0)
	var knockback_strength: float = lerp(30.0, 200.0, scaled_ratio)

	velocity.x = knockback_strength * hit_direction
	velocity.y = -knockback_strength * 0.8

func stun(duration: float = 0.3) -> void:
	if is_stunned:
		return

	is_stunned = true
	previous_state = current_state
	set_state(State.STUNNED)

	await get_tree().create_timer(duration).timeout
	is_stunned = false

	if not is_dead:
		set_state(previous_state)

func trigger_aggro(target: Node2D) -> void:
	player_node = target
	aggro_timer = 5.0
	if current_state != State.AGGRO and not is_stunned:
		set_state(State.AGGRO)
		if foe_sprite and foe_sprite.sprite_frames:
			if foe_sprite.sprite_frames.has_animation("aggro"):
				foe_sprite.play("aggro")
			else:
				foe_sprite.play("idle")

func die() -> void:
	direction = 0 # no more walking for AI

	print("[Enemy] Starting death sequence")
	print("[Enemy] Hit direction:", hit_direction)
	
	# Disable AI raycasts
	ray_ground.enabled = false
	ray_wall.enabled = false
	
	# Disable all collisions
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
			print("[Enemy] Disabled collision shape:", child.name)
	
	# Also disable the root collision shape if it exists
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
		print("[Enemy] Disabled root collision shape")
	
	# Disable the hurtbox so it no longer receives hits
	hurt_box.set_deferred("monitoring", false)
	print("[Enemy] Disabled hurtbox")

	if foe_sprite:
		foe_sprite.flip_h = direction < 0
		foe_sprite.play("dead_fall")
	
	print("[Enemy] Died")
	
	# Apply death launch
	# Calculate launch force based on damage taken
	var knockback_ratio: float = clamp(float(last_damage_received) / float(max_hp), 0.0, 1.0)
	# var scaled_ratio := pow(knockback_ratio, 3.0)  # Exponential scale
	var scaled_ratio := knockback_ratio  # Linear scale
	# Knockback Scaling Curves Reference:
	# Curve        | Formula                      | Effect
	# ------------ | ---------------------------- | -------------------------------
	# Linear       | x                            | Consistent scaling
	# Exponential  | pow(x, 2.0)                  | Punchier high-end, weak low-end
	# Steeper      | pow(x, 3.0)                  | Only massive hits cause knockback
	# SmoothStep   | x * x * (3 - 2 * x)          | Smooth S-curve easing
	var launch_force: float = lerp(150.0, 400.0, scaled_ratio)

	var death_launch_x = round(launch_force) * hit_direction
	var death_launch_y = -round(launch_force) * 0.8
	velocity = Vector2(death_launch_x, death_launch_y)

	print("[Enemy] Death launch applied - X:", death_launch_x, " Y:", death_launch_y)
	#var death_launch_x = 200 * hit_direction  # same direction where the hit was going
	#var death_launch_y = -400  # strong upward launch
	#velocity = Vector2(death_launch_x, death_launch_y)
	#print("[Enemy] Death launch applied - X:", death_launch_x, " Y:", death_launch_y)
	#print("[Enemy] Current velocity:", velocity)
	
	# Set death state after applying launch
	set_state(State.DEAD)
	is_dead = true

	# Queue free after falling for 3 seconds
	await get_tree().create_timer(3.0).timeout
	queue_free()

func show_damage_label(amount: int, is_crit: bool = false) -> void:
	var label = DamageLabelScene.instantiate()
	add_child(label)
	label.show_damage(amount)
	
	if is_crit:
		await get_tree().create_timer(0.15).timeout
		var crit_label = CritLabelScene.instantiate()
		add_child(crit_label)
		crit_label.show_crit("CRIT!")
