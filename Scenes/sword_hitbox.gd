extends Area2D

# Optional: track parent player if needed
@onready var player = get_parent()

func _on_area_entered(area):
	# Just logs what we hit — real logic happens in the dummy
	print("⚔️ Sword entered:", area.name)
