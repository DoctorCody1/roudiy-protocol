extends Node2D
class_name WorldLayer

var cell_size: int = 10

func _ready():
	pass

func update_world():
	queue_redraw()

func _draw():
	var sim = SimManager.instance
	if not sim:
		return
	
	# 1. Рисуем зоны (фоновые цвета)
	_draw_zones(sim)
	
	# 2. Рисуем объекты (замки, статуи, печи)
	_draw_objects(sim)
	
	# 3. Рисуем ресурсы
	_draw_resources(sim)
	
	# 4. Рисуем растения
	_draw_plants(sim)
	_draw_enemies(sim)
	_draw_names(sim)
	_draw_glia(sim)
	_draw_ancient_robots(sim)
	_draw_points_of_power(sim)

func _draw_zones(sim):
	if not sim.zones:
		return
	for zone in sim.zones:
		var center = zone.center * cell_size
		var radius = zone.radius * cell_size
		var color = _zone_color(zone.type)
		draw_circle(center, radius, color)

func _zone_color(type: String) -> Color:
	match type:
		"steel_forest":
			return Color(0.18, 0.35, 0.15, 0.3)
		"steam_swamp":
			return Color(0.42, 0.48, 0.55, 0.3)
		"ruins":
			return Color(0.55, 0.35, 0.17, 0.3)
		"factory":
			return Color(0.63, 0.35, 0.29, 0.3)
		"wasteland":
			return Color(0.83, 0.79, 0.66, 0.3)
		_:
			return Color(0.5, 0.5, 0.5, 0.1)

func _draw_names(sim):
	if not sim or sim.agents.is_empty():
		return
	var font = ThemeDB.fallback_font
	for agent in sim.agents:
		if agent.alive and agent.has_name:
			var pos = agent.pos * cell_size
			var color = Color(1.0, 0.8, 0.2)
			draw_string(font, pos + Vector2(0, -12), agent.self_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)

func _draw_ancient_robots(sim):
	if not sim or sim.ancient_robots.is_empty():
		return
	for robot in sim.ancient_robots:
		var pos = robot.pos * cell_size
		if robot.type == AncientRobot.Type.GUARDIAN:
			_draw_guardian(pos, robot.alive)
		else:
			_draw_watcher(pos, robot.alive)

func _draw_glia(sim):
	for astro in sim.astrocytes:
		var pos = astro.pos * cell_size
		var radius = astro.radius * cell_size
		draw_circle(pos, radius, Color(0.8, 0.4, 0.8, 0.2))
	for micro in sim.microglia:
		var pos = micro.pos * cell_size
		draw_circle(pos, 3, Color(0.3, 0.6, 0.3))

func _draw_objects(sim):
	if not sim.objects:
		return
	for obj in sim.objects:
		var pos = obj.pos * cell_size
		match obj.type:
			"castle":
				_draw_castle(pos, obj.size if obj.has("size") else 1.0)
			"statue":
				_draw_statue(pos)
			"furnace":
				_draw_furnace(pos)
			"rails":
				_draw_rails(pos, obj.direction if obj.has("direction") else Vector2.RIGHT)

func _draw_castle(pos: Vector2, scale: float = 1.0):
	var size = 8 * scale
	var color = Color(0.3, 0.3, 0.4)
	draw_rect(Rect2(pos - Vector2(size, size*0.6), Vector2(size*2, size*1.2)), color)
	draw_rect(Rect2(pos - Vector2(size, size*0.8), Vector2(size*0.3, size*0.5)), color)
	draw_rect(Rect2(pos + Vector2(size*0.7, -size*0.8), Vector2(size*0.3, size*0.5)), color)
	var roof_color = Color(0.5, 0.2, 0.1)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-size, -size*0.8), pos + Vector2(0, -size*1.4), pos + Vector2(size, -size*0.8)]), roof_color)

func _draw_statue(pos: Vector2):
	var color = Color(0.7, 0.7, 0.8)
	draw_line(pos + Vector2(0, -3), pos + Vector2(0, 3), color, 2)
	draw_circle(pos + Vector2(0, -5), 2, color)
	draw_line(pos + Vector2(0, -1), pos + Vector2(3, -3), color, 1.5)

func _draw_furnace(pos: Vector2):
	var color = Color(0.6, 0.2, 0.1)
	draw_rect(Rect2(pos - Vector2(3, 2), Vector2(6, 4)), color)
	draw_rect(Rect2(pos + Vector2(-1, -4), Vector2(2, 2)), Color(0.3, 0.3, 0.3))
	draw_circle(pos + Vector2(0, 1), 1.5, Color(1, 0.6, 0.1))

func _draw_rails(pos: Vector2, direction: Vector2):
	var color = Color(0.4, 0.4, 0.5)
	var perp = direction.rotated(PI/2).normalized()
	var length = 6
	draw_line(pos - direction * length/2 + perp * 1.5, pos + direction * length/2 + perp * 1.5, color, 1)
	draw_line(pos - direction * length/2 - perp * 1.5, pos + direction * length/2 - perp * 1.5, color, 1)

func _draw_resources(sim):
	if not sim.resources:
		return
	for res in sim.resources:
		var pos = res.pos * cell_size
		var color = _resource_color(res.type)
		match res.type:
			"coal":
				draw_circle(pos, 2, color)
			"copper":
				draw_colored_polygon(PackedVector2Array([pos + Vector2(0,-2), pos + Vector2(2,0), pos + Vector2(0,2), pos + Vector2(-2,0)]), color)
			"crystal":
				draw_colored_polygon(PackedVector2Array([pos + Vector2(0,-3), pos + Vector2(2,0), pos + Vector2(0,3), pos + Vector2(-2,0)]), color)
				draw_circle(pos + Vector2(-1,-1), 0.8, Color.WHITE)
			"herb":
				for i in 3:
					var angle = i * 2.094 + SimManager.instance.time * 0.01
					var leaf = pos + Vector2(cos(angle), sin(angle)) * 2.5
					draw_line(pos, leaf, color, 1)
			"key":
				draw_circle(pos, 2, color)
				draw_circle(pos + Vector2(3,0), 1.5, color)
				draw_line(pos + Vector2(1.5,0), pos + Vector2(2.5,0), color, 1)
			"food":
				draw_circle(pos, 2.5, color)
				draw_circle(pos + Vector2(0, -2), 1.5, Color(0.8, 0.2, 0.2))
			_:
				draw_circle(pos, 2, color)

func _resource_color(type: String) -> Color:
	match type:
		"coal":
			return Color(0.1, 0.1, 0.1)
		"copper":
			return Color(0.8, 0.5, 0.1)
		"crystal":
			return Color(0.2, 0.6, 0.9)
		"herb":
			return Color(0.2, 0.8, 0.2)
		"key":
			return Color(1.0, 0.8, 0.1)
		"food":
			return Color(0.3, 0.9, 0.3)
		_:
			return Color.WHITE

func _draw_plants(sim):
	if not sim.plants:
		return
	for plant in sim.plants:
		if not plant.alive:
			continue
		var color = Color.GREEN.lerp(Color.YELLOW, plant.growth)
		var radius = 2 + plant.growth * 3
		var pos = plant.position * cell_size
		draw_circle(pos, radius, color)
		draw_circle(pos, 1.5, Color(0.3, 0.15, 0.05))

func _draw_enemies(sim):
	if not sim or sim.enemies.is_empty():
		return
	for enemy in sim.enemies:
		if not enemy.alive:
			continue
		var pos = enemy.pos * cell_size
		match enemy.type:
			Enemy.Type.RUSTY_MECHANISM:
				draw_rect(Rect2(pos - Vector2(4,4), Vector2(8,8)), Color(0.5, 0.1, 0.1))
				draw_circle(pos, 2, Color(0.8, 0.4, 0.1))
			Enemy.Type.DUST_GOLEM:
				draw_circle(pos, 5, Color(0.5, 0.5, 0.5, 0.5))
				draw_circle(pos, 2, Color(0.7, 0.7, 0.7))
			Enemy.Type.DUO_MECHANISM:
				draw_circle(pos + Vector2(-4,0), 3, Color(0.8, 0.2, 0.2))
				draw_circle(pos + Vector2(4,0), 3, Color(0.2, 0.2, 0.8))
				draw_line(pos + Vector2(-2,0), pos + Vector2(2,0), Color(0.5,0.5,0.5), 1)

func _draw_guardian(pos: Vector2, alive: bool):
	var color = Color(0.3, 0.2, 0.1) if alive else Color(0.5, 0.5, 0.5, 0.4)
	var size = 6
	draw_rect(Rect2(pos - Vector2(size, size*0.8), Vector2(size*2, size*1.6)), color, true)
	draw_rect(Rect2(pos - Vector2(size, size*0.8), Vector2(size*2, size*1.6)), Color(0.6, 0.4, 0.2), false, 1.5)
	draw_rect(Rect2(pos - Vector2(3, 6), Vector2(6, 6)), Color(0.5, 0.3, 0.1), true)
	if alive:
		draw_circle(pos + Vector2(0, 2), 2.5, Color(0.8, 0.6, 0.1, 0.7))
		draw_circle(pos + Vector2(0, 2), 1.5, Color(1.0, 0.8, 0.2))
	else:
		draw_circle(pos + Vector2(0, 2), 2.5, Color(0.6, 0.6, 0.6, 0.3))
	for i in [-1, 1]:
		var gear_pos = pos + Vector2(i * (size + 1), 0)
		draw_circle(gear_pos, 2, Color(0.4, 0.3, 0.2))
		draw_circle(gear_pos, 1, Color(0.6, 0.5, 0.3))
		draw_line(gear_pos + Vector2(-2, 0), gear_pos + Vector2(2, 0), Color(0.4, 0.3, 0.2), 1)
		draw_line(gear_pos + Vector2(0, -2), gear_pos + Vector2(0, 2), Color(0.4, 0.3, 0.2), 1)
	if alive:
		draw_circle(pos + Vector2(-2, -4), 1.2, Color(1.0, 0.8, 0.0))
		draw_circle(pos + Vector2(2, -4), 1.2, Color(1.0, 0.8, 0.0))
	else:
		draw_circle(pos + Vector2(-2, -4), 1.2, Color(0.3, 0.3, 0.3))
		draw_circle(pos + Vector2(2, -4), 1.2, Color(0.3, 0.3, 0.3))

func _draw_watcher(pos: Vector2, alive: bool):
	var color = Color(0.2, 0.2, 0.2) if alive else Color(0.4, 0.4, 0.4, 0.3)
	var size = 3
	draw_circle(pos + Vector2(-2, 0), size, color)
	draw_circle(pos + Vector2(2, 0), size, color)
	draw_line(pos + Vector2(-2, -1), pos + Vector2(2, -1), color, 2)
	draw_circle(pos + Vector2(0, -3), 2.5, color)
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-2, -5),
		pos + Vector2(-3, -7),
		pos + Vector2(-1, -6)
	]), color)
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(2, -5),
		pos + Vector2(3, -7),
		pos + Vector2(1, -6)
	]), color)
	if alive:
		draw_circle(pos + Vector2(-1.5, -3.5), 1.0, Color(1.0, 0.6, 0.0, 0.9))
		draw_circle(pos + Vector2(1.5, -3.5), 1.0, Color(1.0, 0.6, 0.0, 0.9))
		draw_rect(Rect2(pos + Vector2(-1.8, -4.2), Vector2(0.6, 1.5)), Color(0.0, 0.0, 0.0))
		draw_rect(Rect2(pos + Vector2(1.2, -4.2), Vector2(0.6, 1.5)), Color(0.0, 0.0, 0.0))
	else:
		draw_circle(pos + Vector2(-1.5, -3.5), 1.0, Color(0.3, 0.3, 0.3, 0.5))
		draw_circle(pos + Vector2(1.5, -3.5), 1.0, Color(0.3, 0.3, 0.3, 0.5))
	draw_line(pos + Vector2(3.5, 1), pos + Vector2(6, 0.5), color, 1.5)
	draw_line(pos + Vector2(6, 0.5), pos + Vector2(6.5, -1), color, 1.5)

func _draw_points_of_power(sim):
	if not sim or sim.points_of_power.is_empty():
		return
	for point in sim.points_of_power:
		var pos = point.pos * cell_size
		if point.type == PointOfPower.Type.TIME_SOURCE:
			var pulse = 0.8 + 0.2 * sin(SimManager.instance.time * 0.05)
			var color = Color(1.0, 0.8, 0.2, 0.7 * pulse)
			draw_circle(pos, 10, color)
			draw_circle(pos, 6, Color(1.0, 1.0, 0.5, 0.9))
			for i in range(3):
				var radius = 12 + i * 4
				var alpha = 0.2 - i * 0.05
				draw_circle(pos, radius, Color(1, 0.8, 0.2, alpha))
		else:
			var color = _point_color(point.type)
			draw_circle(pos, 5, color)
			draw_circle(pos, 3, Color.WHITE)

func _point_color(type: int) -> Color:
	match type:
		PointOfPower.Type.ALTAR:
			return Color(0.5, 0.2, 0.8)
		PointOfPower.Type.FORGE:
			return Color(0.8, 0.4, 0.1)
		PointOfPower.Type.BATH:
			return Color(0.1, 0.6, 0.8)
		PointOfPower.Type.BRIDGE:
			return Color(0.3, 0.8, 0.3)
		_:
			return Color.WHITE
