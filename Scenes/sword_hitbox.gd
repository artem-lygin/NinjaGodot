extends Area2D
#
## Optional: track parent player if needed
@onready var player = get_parent()

# -----------------------------
# ⚔️ Weapon Stats
# -----------------------------
var base_damage := 10
var base_crit_chance := 0.25  # 25% chance
var crit_multiplier := 3
# Optional future stats:
# var damage_type := "slash"
# var status_effect := "bleed"
# var knockback_strength := 100

func _on_area_entered(area: Area2D) -> void:
	print("🔍 Area entered:", area.name)
	print("🔍 Area parent:", area.get_parent().name if area.get_parent() else "No parent")
	
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
	
	if enemy and enemy.has_method("take_damage"):
		var direction = player.facing_direction
		var is_crit = randf() < base_crit_chance
		var final_damage = base_damage * crit_multiplier if is_crit else base_damage

		print("💥 Hitting enemy:", enemy.name, "| Damage:", final_damage, "| Crit:", is_crit)
		enemy.take_damage(final_damage, direction, is_crit)
	else:
		print("⚠️ Hit object has no take_damage() method. Object name:", enemy.name if enemy else "null")
