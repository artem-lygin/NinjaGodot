extends CharacterBody2D

const SPEED = 200             # Max horizontal speed
const JUMP_FORCE = -400
const GRAVITY = 800
const ACCELERATION = 1000     # Speed gain when moving
const FRICTION = 800          # Speed loss when not moving
const MOMENTUM_THRESHOLD = 10.0  # Player can "turn" at low speeds
const BASE_DAMAGE = 10

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
@onready var sword_hitbox = $SwordHitbox
@onready var sword_shape = $SwordHitbox/CollisionShape2D

func _ready():
	# Make sure the sword hitbox is off when game starts
	sword_hitbox.monitoring = false
	sword_shape.disabled = true
	# Capture the player's initial position at the start of the game
	start_position = global_position
	
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


func _physics_process(delta):
	# 🏃 Use self.velocity directly to avoid clashing with dash logic
	# (No need for local `velocity` copy anymore)

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
			var sword_shape = sword_hitbox.get_node("CollisionShape2D")
			sword_shape.position.x = abs(sword_shape.position.x) * facing_direction

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

	# 🪂 Jumping
	if Input.is_action_just_pressed("jump") and jumps_remaining > 0:
		self.velocity.y = JUMP_FORCE

		# 💨 Show dust only for midair jump
		if jumps_remaining == 1:
			dust.restart()

		jumps_remaining -= 1  # Use up a jump

	# 🗡️ Attack input
	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()

	# 🌀 Dash input
	if not is_dashing and can_dash and Input.is_action_just_pressed("dash"):
		print("🌀 Dash input detected!")
		start_dash()
		
	if is_dashing:
		ghost_timer -= delta
		if ghost_timer <= 0:
			print("👻 Attempting to spawn ghost")
			spawn_ghost()
			ghost_timer = ghost_spawn_interval

	# 📊 Debug UI: speed & jumps
	speed_label.text = str(round(self.velocity.x))
	jump_label.text = "Jumps: " + str(jumps_remaining)

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
			print("💨 Walked off ledge — used one jump")

	# 🧠 Save grounded state for next frame
	was_on_floor = is_on_floor()

	# 🔄 Restart level
	if Input.is_action_just_pressed("restart_level"):
		get_tree().reload_current_scene()
		
	# Megacrit after dash
	if time_since_dash < megacrit_window:
		time_since_dash += delta

	# 🕹️ Finally: apply movement!
	move_and_slide()

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

func is_in_megacrit_window() -> bool:
	return time_since_dash < megacrit_window
