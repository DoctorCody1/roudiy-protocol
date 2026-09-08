extends RefCounted
class_name PressureCycle

var phase: String = "high"  # "high" или "low"
var timer: int = 0
var high_duration: int = 30
var low_duration: int = 70
var current_pressure: float = 1.0  # 0..1

func update():
	timer += 1
	if phase == "high" and timer >= high_duration:
		phase = "low"
		timer = 0
		current_pressure = 0.2
	elif phase == "low" and timer >= low_duration:
		phase = "high"
		timer = 0
		current_pressure = 1.0
		# Добавляем случайное смещение для следующего цикла
		var shift = randi_range(-5, 5)
		high_duration = 30 + shift
	elif phase == "low" and timer >= low_duration:
		phase = "high"
		timer = 0
		current_pressure = 1.0
		var shift = randi_range(-5, 5)
		low_duration = 70 + shift		
	# Плавное изменение давления
	if phase == "high":
		current_pressure = 1.0 - (timer / high_duration) * 0.5
	else:
		current_pressure = 0.2 + (timer / low_duration) * 0.8
	current_pressure = clamp(current_pressure, 0.0, 1.0)

func is_transition_open() -> bool:
	return current_pressure > 0.5
