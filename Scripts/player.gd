extends CharacterBody2D

const SPEED = 200             # Max horizontal speed
const JUMP_FORCE = -400
const GRAVITY = 800
const ACCELERATION = 1000     # Speed gain when moving
const FRICTION = 800          # Speed loss when not moving
const MOMENTUM_THRESHOLD = 10.0  # Player can "turn" at low speeds
const BASE_DAMAGE = 10
const THROW_SPEED = 800.0

# Ghost VFX
var GhostScene := preload("res://Scenes/VFX/GhostSprite.tscn")
var ghost_timer := 0.0
var ghost_spawn_interval := 0.035  # spawn every 35ms

# Store the player's starting position when the scene loads
var start_position: Vector2
var max_jumps = 2       # How many jumps allowed
var jumps_remaining = max_jumps      # How many jumps remaining
var was_on_floor = true # For double Jump Performing 
var is_attacking = false # Is Player Attacking?
var input_direction = 0 # Starting input direction -1 is ← back, 0 no input and 1 is forward →
var facing_direction = 1  # Direction of the Player 1 = right, -1 = left

# --- Dash System ---
var can_dash := true
var dash_distance := 100.0  # Not Used
var dash_cooldown := 0.5  # seconds
var dash_speed := 400.0
var is_dashing := false
var megacrit_window := 0.8
var time_since_dash := 999.0  # Start outside window

@onready var sprite = $PlayerAnimatedSprite  # Reference to animation node
@onready var speed_label = $SpeedLabel # Speed Label for test
@onready var dust = $JumpDust # Jump Dust Effect
@onready var jump_label = get_node("../UI/JumpCounterLabel")
@onready var shuriken_label = get_node("../UI/ShurikenCounterLabel")
@onready var throwable_label = get_node("../UI/ThrowableLabel")
@onready var ShurikenScene = preload("res://Scenes/Shuriken.tscn")
@onready var DecoyScene := preload("res://Scenes/Weapons/ThrowableDecoy.tscn")
@onready var drawer := $TrajectoryDrawer
@onready var sword_hitbox = $SwordHitbox
@onready var sword_shape = $SwordHitbox/CollisionShape2D
@onready var aiming_target := $AimingTarget
var is_aiming := false
@export var aim_radius: float = 80.0  # How far from the player the aim point can go

# Initialization
func _ready():
	# Make sure the sword hitbox is off when game starts
	sword_hitbox.monitoring = false
	sword_shape.disabled = true
	# Capture the player's initial position at the start of the game
	start_position = global_position

# Movement, gravity, physics-based interactions
func _physics_process(delta):
	# 🏃 Use self.velocity directly to avoid clashing with dash logic

	# ☑️ Refill jumps when grounded
	if is_on_floor():
		jumps_remaining = max_jumps

	# 🧲 Apply gravity (but not during dash)
	if not is_dashing:
		self.velocity.y += GRAVITY * delta

	# 🎮 Horizontal movement input
	if not is_dashing:
		if Input.is_action_pressed("ui_left"):
			input_direction = -1
		elif Input.is_action_pressed("ui_right"):
			input_direction = 1
		else:
			input_direction = 0  # Stop movement when no input

		# 👟 Movement + sprite direction flip
		if input_direction != 0:
			# ↔️ Remember which way we’re facing
			facing_direction = input_direction
			sprite.flip_h = facing_direction < 0

			# 🔁 Flip sword hitbox to match direction
			var sword_shape: CollisionShape2D = sword_hitbox.get_node("CollisionShape2D")
			var player_half_width: float = $CollisionShape2D.shape.radius
			var hitbox_half_width: float = (sword_shape.shape as CircleShape2D).radius
			var forward_offset: float = 30 # Tweaking the offset. 0 is fully extended arms: Collision Shapes are not interlaping
			var offset_x: float = player_half_width + hitbox_half_width - forward_offset
			sword_shape.position.x = offset_x * facing_direction

			# 🧮 Acceleration logic
			if abs(self.velocity.x) < MOMENTUM_THRESHOLD:
				# Small nudge if nearly standing still
				self.velocity.x = move_toward(self.velocity.x, input_direction * SPEED, ACCELERATION * delta)
			else:
				# Accelerate toward target speed
				self.velocity.x = move_toward(self.velocity.x, input_direction * SPEED, ACCELERATION * delta)
		else:
			# 🛑 No input = apply friction
			self.velocity.x = move_toward(self.velocity.x, 0, FRICTION * delta)

	# Jumping
	if Input.is_action_just_pressed("jump") and jumps_remaining > 0:
		self.velocity.y = JUMP_FORCE

		# 💨 Show dust only for midair jump
		if jumps_remaining == 1:
			dust.restart()

		jumps_remaining -= 1  # Use up a jump

	# Attack input
	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()
		
	# Shuriken throw input
	if Input.is_action_just_pressed("throw_secondary"):
		if ShurikenManager.can_throw():
			ShurikenManager.throw(global_position, Vector2(facing_direction, 0))

	# Handle “throw_item” Input
	if Input.is_action_just_pressed("throw_item") and is_aiming:
		var direction: Vector2 = aiming_target.global_position - global_position
		var throw_velocity: Vector2 = direction.normalized() * THROW_SPEED
		ThrowableManager.throw(global_position, throw_velocity)
	
	# Handle Trowable Manager Input
	if Input.is_action_just_pressed("switch_throwable_next"):
		ThrowableManager.switch_throwable_next()
	elif Input.is_action_just_pressed("switch_throwable_prev"):
		ThrowableManager.switch_throwable_prev()
	
	# Dash input
	if not is_dashing and can_dash and Input.is_action_just_pressed("dash"):
		# print("🌀 Dash input detected!")
		start_dash()
		
	if is_dashing:
		ghost_timer -= delta
		if ghost_timer <= 0:
			# print("👻 Attempting to spawn ghost")
			spawn_ghost()
			ghost_timer = ghost_spawn_interval

	# Manage UI 
	speed_label.text = str(round(self.velocity.x))
	jump_label.text = "Jumps: " + str(jumps_remaining)
	var shuriken_cooldown_display := ""
	for i in ShurikenManager.cooldowns:
		if i > 0.0:
			shuriken_cooldown_display = str(round(i * 100.0) / 100.0)
			break
	if shuriken_cooldown_display != "":
		shuriken_label.text = "Shurikens: %d | %s" % [ShurikenManager.available, shuriken_cooldown_display]
	else:
		shuriken_label.text = "Shurikens: %d" % ShurikenManager.available
	
	var type = ThrowableManager.get_current_throwable_type()
	var name = ThrowableManager.get_current_throwable_name()
	var amount = ThrowableManager.get_throwable_count(type)
	var cooldown = ThrowableManager.get_throwable_cooldown(type)

	var throwable_cooldown_display := ""
	if cooldown > 0.0:
		throwable_cooldown_display = " | %.2f" % cooldown

	throwable_label.text = "%s: %d%s" % [name, amount, throwable_cooldown_display]

	# 🎞️ Animation logic (unless attacking or dashing)
	if not is_attacking and not is_dashing:
		if not is_on_floor():
			sprite.play("jump")
		elif abs(self.velocity.x) > 10:
			sprite.play("run")
		else:
			sprite.play("idle")

	# 🪂 Walked off a platform? Remove 1 jump
	if is_on_floor() and not was_on_floor:
		jumps_remaining = max_jumps

	if was_on_floor and not is_on_floor():
		if jumps_remaining == max_jumps:
			jumps_remaining -= 1
			# print("💨 Walked off ledge — used one jump")

	# 🧠 Save grounded state for next frame
	was_on_floor = is_on_floor()

	# 🔄 Restart level
	if Input.is_action_just_pressed("restart_level"):
		Engine.time_scale = 1.0
		ThrowableManager.replenish_all()
		ShurikenManager.replenish_all()
		print("✅ Time and resources fully restored")
		get_tree().reload_current_scene()
		
	# Megacrit after dash
	if time_since_dash < megacrit_window:
		time_since_dash += delta

	# 🕹️ Finally: apply movement!
	move_and_slide()

# Visual updates, inputs like joystick aiming, timers
func _process(delta):
	update_aiming(delta)

func start_attack():
	if is_attacking: # Check if player already in attack
		return

	is_attacking = true
	
	# Activate hitbox only during attack
	sword_shape.disabled = false
	sword_hitbox.monitoring = true # Enable collisions for this attack

	# Play attack animation
	sprite.play("attack")
	
	await get_tree().create_timer(0.1).timeout  # ← match animation length
	# Deactivate hitbox
	sword_hitbox.monitoring = false # Disable immediately after hit window
	sword_shape.disabled = true
	await get_tree().create_timer(0.2).timeout  # Let animation finish
	is_attacking = false

func start_dash():
	print("⚡ Starting Dash")
	is_dashing = true
	ghost_timer = 0.0  # Force immediate spawn
	can_dash = false

	play_dash_animation()

	# Calculate direction
	var dash_vector = Vector2(facing_direction * dash_speed, 0)
	self.velocity = dash_vector
	print("🚀 Dash velocity applied:", self.velocity)

	# Wait to end dash (based on how far we want to travel)
	var duration = dash_distance / dash_speed
	print("⏱️ Dash duration:", duration)

	await get_tree().create_timer(duration).timeout
	is_dashing = false
	time_since_dash = 0.0  # Start counting after dash ends
	print("✅ Dash ended — Megacrit window starts")

	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true
	print("🔁 Dash cooldown reset")

func play_dash_animation():
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("dash"):
			sprite.play("dash")
			print("🎞️ Playing dash animation")
		else:
			print("⚠️ No 'dash' animation found!")

func spawn_ghost():
	if is_queued_for_deletion():
		return

	# Make sure GhostScene is loaded
	if not GhostScene:
		push_error("GhostScene not assigned or failed to preload")
		return

	# Instantiate the ghost scene
	var ghost = GhostScene.instantiate()
	get_tree().current_scene.add_child(ghost)
	print("👻 Added ghost to tree")

	# Safety check before accessing sprite frame
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(sprite.animation):
		var frame_count = sprite.sprite_frames.get_frame_count(sprite.animation)
		if sprite.frame < frame_count:
			# Get the current frame's texture
			var texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
			print("👤 Player global_position:", global_position)
			ghost.setup(texture, global_position, sprite.flip_h)
			get_tree().get_root().add_child(ghost)
			# get_tree().current_scene.add_child(ghost)
		else:
			push_warning("Frame index out of range for ghost effect.")
	else:
		push_warning("Invalid sprite_frames or animation for ghost effect.")

func update_aiming(delta: float) -> void:
	var aim_input := Vector2(
		Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
		Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	)
	
	var drawer = $TrajectoryDrawer
	
	if aim_input.length() > 0.2:
		is_aiming = true
		aiming_target.visible = true
		drawer.set_visible_with_fade(true)
		aim_input = aim_input.normalized()
		aiming_target.global_position = global_position + aim_input * aim_radius
		
		var offset = aim_input * 62
		aiming_target.position = offset
		drawer.target_position = global_position + offset

	else:
		# If stick is idle, snap to forward and hide
		is_aiming = false
		aiming_target.visible = false
		drawer.is_visible = false # Hide inststly
		drawer.set_visible_with_fade(false)
		aiming_target.global_position = global_position + Vector2(facing_direction, -0.3).normalized() * aim_radius

#func throw_item():
	#if not DecoyScene:
		#return
	#
	#var decoy = DecoyScene.instantiate()
	#decoy.global_position = global_position
	#
	## Aim direction
	## var aim_vector: Vector2 = aiming_target.global_position - global_position
	## var throw_speed: float = 800.0  # Must match trajectory_drawer
	#var throw_velocity: Vector2 = (aiming_target.global_position - decoy.global_position).normalized() * THROW_SPEED
	##var throw_velocity: Vector2 = aim_vector.normalized() * THROW_SPEED
#
	## Add decoy to scene first
	#get_tree().current_scene.add_child(decoy)
#
	## Physics tuning — make sure it's fully under our control
	#decoy.linear_damp = 0.0
	#decoy.angular_damp = 1.0
	#decoy.gravity_scale = 1.0
	#decoy.linear_velocity = throw_velocity
#
	#print("Item thrown with velocity: ", throw_velocity)

		
func is_in_megacrit_window() -> bool:
	return time_since_dash < megacrit_window
