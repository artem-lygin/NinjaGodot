extends CharacterBody2D

const SPEED = 200             # Max horizontal speed
const JUMP_FORCE = -400
const GRAVITY = 800
const ACCELERATION = 1000     # Speed gain when moving
const FRICTION = 800          # Speed loss when not moving
const MOMENTUM_THRESHOLD = 10.0  # Player can "turn" at low speeds
const BASE_DAMAGE = 10


# Store the player's starting position when the scene loads
var start_position: Vector2
var max_jumps = 2       # How many jumps allowed
var jumps_left = 2      # How many jumps remaining
var was_on_floor = false # For double Jump Performing 
var is_attacking = false # Is Player Attacking?
var input_direction = 0 # Starting input direction -1 is ← back, 0 no input and 1 is forward →
var facing_direction = 1  # Direction of the Player 1 = right, -1 = left

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
	is_attacking = true
	
	# Activate hitbox only during attack
	sword_shape.disabled = false
	sword_hitbox.monitoring = true

	# Play attack animation
	sprite.play("attack")
	
	await get_tree().create_timer(0.2).timeout  # ← match animation length
	# Deactivate hitbox
	sword_hitbox.monitoring = false
	sword_shape.disabled = true
	is_attacking = false

func _physics_process(delta):
	var velocity = self.velocity
	
	# If on the floor, refill jumps
	if is_on_floor():
		jumps_left = max_jumps

	# Gravity
	velocity.y += GRAVITY * delta

	# Horizontal movement

	# Get movement input direction: -1 (left), 1 (right), 0 (none)
	if Input.is_action_pressed("ui_left"):
		input_direction = -1
	elif Input.is_action_pressed("ui_right"):
		input_direction = 1
	else:
		input_direction = 0  # Ensures you stop when no key is pressed
		
	# Handle movement and facing
	if input_direction != 0:
		# Update facing direction only when moving
		facing_direction = input_direction
		sprite.flip_h = facing_direction < 0
		
		# Flip Sword Hitbox shape horizontally to match facing direction
		var sword_shape = sword_hitbox.get_node("CollisionShape2D")
		sword_shape.position.x = abs(sword_shape.position.x) * facing_direction

		# If velocity is below threshold, kickstart a tiny nudge
		if abs(velocity.x) < MOMENTUM_THRESHOLD:
			velocity.x = move_toward(velocity.x, input_direction * SPEED, ACCELERATION * delta)
		else:
			# Accelerate normally toward max speed
			velocity.x = move_toward(velocity.x, input_direction * SPEED, ACCELERATION * delta)
	else:
		# No input — apply friction to slow down
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# Jump if jump key is pressed and we have jumps left
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		# Jump
		velocity.y = JUMP_FORCE
		# Trigger dust only if this is the second jump (i.e. midair jump)
		if jumps_left == 1:
			dust.restart()
		# Use up one jump
		jumps_left -= 1

	# Trigger attack on key press (e.g. X key or gamepad button)
	if Input.is_action_just_pressed("attack") and not is_attacking:
		print("Attack key pressed!")
		start_attack()
	
	# Update speed label text (rounded horizontal speed)
	speed_label.text = str(round(velocity.x))
	# Update Jumps Remaining UI (rounded horizontal speed)
	jump_label.text = "Jumps: " + str(jumps_left)
	
	# Animation state logic
	if not is_attacking:
		if not is_on_floor():
			sprite.play("jump")
		elif abs(velocity.x) > 10:
			sprite.play("run")
		else:
			sprite.play("idle")
		
	# Reset Double Jump counter
	if is_on_floor() and not was_on_floor:
		jumps_left = max_jumps
		
	# Update the flag for the next frame
	was_on_floor = is_on_floor()

	# Restart all Scenes
	if Input.is_action_just_pressed("restart_level"):
		get_tree().reload_current_scene()
	
	
	self.velocity = velocity
	move_and_slide()
