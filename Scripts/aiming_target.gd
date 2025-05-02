extends Marker2D

func _draw():
	draw_circle(Vector2.ZERO, 3, Color(1, 1, 1, 1.0))

func _process(delta):
	queue_redraw()  # make sure it redraws every frame
