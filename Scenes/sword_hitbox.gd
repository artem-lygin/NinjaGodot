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
	
	if area.name != "HurtBox":
		return
		
	# Get the dummy node (parent of the HurtBox)
	var dummy = area.get_parent()
	
	if dummy and dummy.has_method("take_damage"):
		var direction = player.facing_direction # Roll for crit
		var is_crit = randf() < base_crit_chance
		var final_damage = base_damage * crit_multiplier if is_crit else base_damage

		print("💥 Hitting dummy:", dummy.name, "| Damage:", final_damage, "| Crit:", is_crit) # Debug log
		dummy.take_damage(final_damage, direction, is_crit)
	else:
		print("⚠️ Hit object has no take_damage() method.")
