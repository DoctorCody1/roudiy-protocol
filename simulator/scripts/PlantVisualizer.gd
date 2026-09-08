extends Node2D

func _draw():
	var sim = SimManager.instance
	if sim == null or sim.plants.is_empty():
		return
	for plant in sim.plants:
		if not plant.alive:
			continue
		var color = Color.GREEN.lerp(Color.YELLOW, plant.growth)
		var radius = 2 + plant.growth * 3
		var pos = plant.position * 10
		draw_circle(pos, radius, color)
		draw_circle(pos, 1.5, Color(0.3, 0.15, 0.05))

func update_plants():
	queue_redraw()
