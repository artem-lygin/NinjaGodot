extends Area2D

# =============================
# ⚔️ sword_hitbox.gd
# =============================

# ✅ Handles player's sword collisions
# ✅ Defines weapon stats:
#    - base_damage (random range supported)
#    - base_crit_chance
#    - crit_multiplier
# ✅ Calculates and applies final damage
# ✅ Transfers:
#    - Damage amount
#    - Hit direction
#    - Crit status
# ✅ Calls enemy's take_damage() method safely
# ✅ Isolated logic = easily extendable for new weapons
# ✅ Attack duration controlled via player script

## Optional: track parent player if needed
@onready var player = get_parent()

# -----------------------------
# ⚔️ Weapon Stats
# -----------------------------
var base_damage := randi_range(10, 15)
var base_crit_chance := 0.25  # 25% chance
var crit_multiplier := 3
# Optional future stats:
# var damage_type := "slash"
# var status_effect := "bleed"
# var knockback_strength := 100

func _on_area_entered(area: Area2D) -> void:
	# print("🔍 Area entered:", area.name)
	# print("🔍 Area parent:", area.get_parent().name if area.get_parent() else "No parent")
	
	# Check if the area is a HurtBox (either direct or under Combat node)
	if not (area.name == "HurtBox" or (area.get_parent() and area.get_parent().name == "HurtBox")):
		print("❌ Not a HurtBox")
		return
		
	# Get the enemy node (parent of the Combat node or direct parent of HurtBox)
	var enemy = area.get_parent()
	print("🔍 First parent:", enemy.name)
	
	if enemy.name == "HurtBox":
		enemy = enemy.get_parent()  # Get the Combat node
		print("🔍 Combat node:", enemy.name)
	
	# Always get the parent of Combat to reach the actual enemy
	if enemy.name == "Combat":
		enemy = enemy.get_parent()  # Get the actual enemy node
		print("🔍 Enemy node:", enemy.name)
	
	# Attack logic with CRIT and MEGACRIT support
	if enemy and enemy.has_method("take_damage"):
		var direction = player.facing_direction
		
		# 🎲 Random base damage
		var base_damage := randi_range(10, 15)
		
		# 💥 Critical hit chance check
		var is_crit = randf() < base_crit_chance

		# 💀 Megacrit (post-dash) check
		var is_mega = false
		if player.has_method("is_in_megacrit_window") and player.is_in_megacrit_window():
			is_mega = true
			print("💀 MEGACRIT triggered!")

		# 🧮 Calculate final damage
		var final_damage = base_damage * crit_multiplier if is_crit else base_damage
		if is_mega:
			final_damage *= 10  # Apply x10 multiplier for megacrit

		print("💥 Hitting enemy:", enemy.name, "| Damage:", final_damage, "| Crit:", is_crit, "| Mega:", is_mega)
		enemy.take_damage(final_damage, direction, is_crit, is_mega)
	else:
		print("⚠️ Hit object has no take_damage() method. Object name:", enemy.name if enemy else "null")
