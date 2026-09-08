class_name Plant
extends RefCounted

var position: Vector2
var growth: float = 0.0
var max_energy: float = 2.0
var alive: bool = true
var growth_rate: float = 0.02
var decay_rate: float = 0.01

func _init(pos: Vector2, initial_growth: float = 0.0):
	position = pos
	growth = initial_growth

func update():
	if not alive:
		return
	if growth < 1.0:
		growth += growth_rate
		if growth > 1.0:
			growth = 1.0
	else:
		growth -= decay_rate
		if growth < 0.0:
			alive = false

func get_energy_value() -> float:
	return max_energy * growth

func is_ripe() -> bool:
	return growth >= 1.0
