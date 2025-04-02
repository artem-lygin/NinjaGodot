extends CharacterBody2D

const SPEED = 40  # How fast the dummy moves
const GRAVITY = 800.0  # Match this to your player’s gravity

var max_hp = 60
var current_hp = max_hp
var direction = -1  # Start facing left (-1 for left, 1 for right)
var hit_direction := 0 # Directon of the hit tooked
var turn_cooldown = 0.0
var DamageLabelScene := preload("res://Scenes/DamageLabel.tscn")
var CritLabelScene := preload("res://Scenes/CritLabel.tscn")
var is_dead = false # Dummy can die
var is_stunned = false # Dummy can be stunned (for knokback)
var recently_hit := false # For avoinding several take_damage from one hit

@onready var health_bar = $HealthBar
@onready var bar_style = health_bar.get("theme_override_styles/fill")
@onready var ray_ground = $RayCast2D_Ground
@onready var ray_wall = $RayCast2D_Wall
@onready var foe_sprite = $FoeAnimatedSprite  # Foe Animation Sprite
@onready var damage_label = $DamageLabel # Referencing Damage Label

func _physics_process(delta):
	var velocity = self.velocity
	
	# Apply gravity
	velocity.y += GRAVITY * delta

	# Move in current direction
	if not is_dead and not is_stunned:
		velocity.x = direction * SPEED
	else:
		pass # Do NOT override X velocity after death or stun!
	turn_cooldown -= delta

	# Flip direction if:
	# - there's no ground ahead
	# - or there's a wall in front
	if turn_cooldown <= 0 and (not ray_ground.is_colliding() or ray_wall.is_colliding()):
		direction *= -1  # Turn around
		turn_cooldown = 0.3  # seconds before it can turn again
		foe_sprite.flip_h = direction < 0  # Flip sprite to face new direction
		ray_wall.target_position.x *= -1 # Flip the raycasts to keep checking ahead
		ray_ground.position.x *= -1  # optional, only if ground ray is offset
	
	# Switch between walk and idle based on horizontal movement if not dead
	if not is_dead and not is_stunned:
		if abs(velocity.x) > 1:
			if foe_sprite.animation != "walk":
				foe_sprite.play("walk")
		else:
			if foe_sprite.animation != "idle":
				foe_sprite.play("idle")
			
	# Clean up if dummy falls way off screen
	if global_position.y > 2000:
		queue_free()
	
	self.velocity = velocity
	move_and_slide()

func _ready():
	
	# Apply walk sprite animation
	foe_sprite.play("walk")
	
	# Connect to the sword hitbox signal (in Player scene)
	connect("area_entered", Callable(self, "_on_hit"))
	
	# Sync health bar to max HP
	health_bar.max_value = max_hp
	health_bar.value = max_hp
	
	# initialize_health(120)  # Overrides default value
	
	# Null Check on HealtBar style
	if health_bar.get("theme_override_styles/fill") == null:
		health_bar.add_theme_stylebox_override("fill", StyleBoxFlat.new())
	bar_style = health_bar.get("theme_override_styles/fill")
	
	# Set initial bar state
	health_bar.value = current_hp
	update_health_color()
	
	# Hide HealthBar if full
	if current_hp >= max_hp:
		health_bar.visible = false

func initialize_health(hp: int) -> void:
	max_hp = hp
	current_hp = hp
	health_bar.max_value = hp
	health_bar.value = hp

# Update color based on current HP in take_damage()
func update_health_color():
	var health_percent = float(current_hp) / float(max_hp)

	if health_percent > 0.6:
		bar_style.bg_color = Color(0.2, 1.0, 0.2)  # Green
	elif health_percent > 0.3:
		bar_style.bg_color = Color(1.0, 1.0, 0.2)  # Yellow
	else:
		bar_style.bg_color = Color(1.0, 0.2, 0.2)  # Red

# Shake HealthBar on hit
func shake_health_bar():
	var original_pos = health_bar.position
	var shake_amount = 4
	var duration = 0.2

	var tween = create_tween()

	tween.tween_property(
		health_bar, "position",
		original_pos + Vector2(randf_range(-shake_amount, shake_amount), 0),
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		health_bar, "position",
		original_pos,
		duration
	).set_delay(duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Handles the logic for taking damage
func take_damage(amount: int, attacker_direction: int, is_crit: bool = false) -> void:
	
	hit_direction = attacker_direction
	current_hp -= amount # Subtract the incoming damage from current health
	
	# If health drops to 0 or below, play die
	if current_hp <= 0 and not is_dead:
		die()
		# return  # exit early, skip stun/flash
	
	show_damage_label(amount, is_crit) # Call Show damage label
	update_health_color() # Call changing health bar color depending on remaining HP
	shake_health_bar() # Call Shake the health bar to give visual feedback
	
	# Flash red briefly on hit
	modulate = Color(1.0, 0.5, 0.5)  # Light red tint
	# Wait 0.1 sec then restore normal color
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	# Update the visual health bar to reflect the new health
	health_bar.value = current_hp
	# Debug: Print current HP to console
	print("Dummy HP:", current_hp)
	
	# Show the health bar if it's not full
	if current_hp < max_hp:
		health_bar.visible = true
	
	# Apply short knockback if still alive
	if not is_dead:
		is_stunned = true
		print("Dummy stunned")
		# Proportional knockback based on damage / max_hp
		var knockback_ratio: float = clamp(float(amount) / float(max_hp), 0.0, 1.0)
		var scaled_ratio := pow(knockback_ratio, 3.0)
		# Scaled Ratio Options
		# Linear		x 						Consistent scaling
		# Exponential 	pow(x, 2.0) 			Punchier high-end, weak low-end
		# Steeper 		pow(x, 3.0) 			Only massive hits cause knockback
		# SmoothStep	x * x * (3 - 2 * x)		Smooth S-curve easing
		var knockback_strength: float = lerp(30, 200, scaled_ratio)

		# Knock direction
		velocity.x = knockback_strength * hit_direction
		velocity.y = -knockback_strength * 0.8  # bump upward with slightly less force

		# Recover from stun after short delay
		await get_tree().create_timer(0.3).timeout
		is_stunned = false

# Dying
func die() -> void:
	is_dead = true
	direction = 0 # no more walking for AI

	# Disable AI raycasts and collisions
	ray_ground.enabled = false
	ray_wall.enabled = false
	# Disable collisions by removing all layers and masks
	collision_layer = 0
	collision_mask = 0
	# Disable the hurtbox so it no longer receives hits
	$HurtBox.set_deferred("monitoring", false)

	foe_sprite.flip_h = direction < 0
	# Play death and fall animation
	foe_sprite.play("dead_fall")
	foe_sprite.stop()
	
	# Debug log
	print("💀 Dummy's dead. Last hit from direction:", hit_direction)
	
	# Apply Knockback upward and away from player
	var knockback_x = 200 * hit_direction  # same direction where the hit was going
	var knockback_y = -400
	velocity = Vector2(knockback_x, knockback_y)

	# Let the dummy fall under gravity
	# velocity.y = 250  # Slight boost to start the fall

	# Queue free after falling for 3 seconds
	await get_tree().create_timer(3.0).timeout
	queue_free()

# Damage Label logic
func show_damage_label(amount: int, is_crit: bool = false) -> void:
	var label = DamageLabelScene.instantiate()
	add_child(label)
	label.show_damage(amount)
	
	# Debug Crit Label appearnce
	#var crit_label = CritLabelScene.instantiate()
	#add_child(crit_label)
	#crit_label.show_crit("TEST CRIT!")
	
	if is_crit:
		await get_tree().create_timer(0.15).timeout  # ← 150ms delay
		print("🔥 Showing CRIT label!")  # Debug log
		var crit_label = CritLabelScene.instantiate()
		add_child(crit_label)
		crit_label.show_crit("CRIT!")

# Shake Dummy on hit
func shake_on_hit():
	var tween = create_tween()
	var original_pos = position
	var shake_amount = 5
	var duration = 0.05

	tween.set_parallel()
	tween.tween_property(self, "position", original_pos + Vector2(randf_range(-shake_amount, shake_amount), 0), duration)
	tween.tween_property(self, "position", original_pos, duration).set_delay(duration)
