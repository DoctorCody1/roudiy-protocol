extends RefCounted
class_name AncientRobot

enum Type { GUARDIAN, WATCHER }

var type: Type
var pos: Vector2
var alive: bool = true
var radius: float = 3.0
var health: float = 5.0
var max_health: float = 5.0

# ---- ПАРАМЕТРЫ УГРОЗЫ (базовые, модифицируются полем) ----
var detection_radius: float = 15.0
var attack_radius: float = 3.5
var speed: float = 0.18
var attack_cooldown: int = 0
var attack_rate: int = 20
var attack_damage: float = 0.06
var target_agent_id: int = -1
var max_chase_distance: float = 25.0

# ---- ПАРАМЕТРЫ ВЛИЯНИЯ НА АГЕНТОВ (зависят от поля) ----
var membrane_damage_per_hit: float = 0.02
var receptor_loss_chance: float = 0.15

var home_pos: Vector2

# ---- ДОПОЛНИТЕЛЬНО: ЗОНА ВЛИЯНИЯ ----
var field_influence_radius: float = 6.0
var field_influence_strength: float = -0.03

func _init(t: Type, position: Vector2):
	type = t
	pos = position
	home_pos = position
	
	# Базовые параметры для разных типов
	if t == Type.WATCHER:
		detection_radius = 18.0
		speed = 0.2
		attack_damage = 0.0
		attack_rate = 0
		membrane_damage_per_hit = 0.0
		receptor_loss_chance = 0.0
	else:
		attack_damage = 0.06
		membrane_damage_per_hit = 0.02
		receptor_loss_chance = 0.15

func take_damage(amount: float):
	health -= amount
	if health <= 0.0:
		alive = false

func get_context_signal(pos_agent: Vector2) -> String:
	if type == Type.GUARDIAN:
		return "The guardian's gaze burns."
	else:
		return "The watcher's eyes follow you."

# ============================================================
#  ОБНОВЛЕНИЕ (ГЛАВНЫЙ ЦИКЛ РОБОТА)
# ============================================================
func update(delta: float = 1.0):
	if not alive:
		return
	if attack_cooldown > 0:
		attack_cooldown -= 1

	var sim = SimManager.instance
	if not sim:
		return
	
	# ---- 0. ПОЛУЧАЕМ СИЛУ ПОЛЯ В ТЕКУЩЕЙ ПОЗИЦИИ ----
	var field_value = sim.field_system.get_field_at(pos)
	# Нормализуем: -2..2 -> 0..1
	var field_power = clamp((field_value + 2.0) / 4.0, 0.0, 1.0)
	
	# ---- 1. МАСШТАБИРУЕМ ПАРАМЕТРЫ ОТ СИЛЫ ПОЛЯ ----
	# Здоровье: от 5 (в слабом поле) до 15 (в сильном)
	var scaled_health = 5.0 + field_power * 10.0
	# Если здоровье изменилось, пропорционально обновляем текущее
	if scaled_health != max_health:
		var ratio = health / max_health
		max_health = scaled_health
		health = max_health * ratio
		if health <= 0.0:
			alive = false
			return
	
	# Скорость: быстрее в сильном поле
	var scaled_speed = speed * (0.6 + field_power * 0.8)
	
	# Урон: сильнее в сильном поле
	var scaled_attack_damage = attack_damage * (0.5 + field_power * 1.5)
	
	# Радиус атаки: больше в сильном поле
	var scaled_attack_radius = attack_radius * (0.8 + field_power * 0.8)
	
	# Повреждение мембраны: сильнее в сильном поле
	var scaled_membrane_damage = membrane_damage_per_hit * (0.5 + field_power * 1.5)
	
	# Шанс потери рецептора: выше в сильном поле
	var scaled_receptor_loss = receptor_loss_chance * (0.5 + field_power * 1.5)
	
	# Радиус влияния на поле (страх): больше в сильном поле
	var scaled_influence_radius = field_influence_radius * (0.6 + field_power * 0.8)
	var scaled_influence_strength = field_influence_strength * (0.5 + field_power * 1.5)
	
	# ---- 2. ВЛИЯНИЕ НА ПОЛЕ (страх) ----
	if type == Type.GUARDIAN:
		for dx in range(-int(scaled_influence_radius), int(scaled_influence_radius) + 1):
			for dy in range(-int(scaled_influence_radius), int(scaled_influence_radius) + 1):
				var p = pos + Vector2(dx, dy)
				var dist = Vector2(dx, dy).length()
				if dist > scaled_influence_radius: continue
				var influence = scaled_influence_strength * (1.0 - dist / scaled_influence_radius)
				sim.field_system.set_field_at(p, sim.field_system.get_field_at(p) + influence)

	# ---- 3. ПОИСК БЛИЖАЙШЕГО АГЕНТА ----
	var nearest_agent = null
	var nearest_dist = detection_radius + 1.0
	for agent in sim.agents:
		if not agent.alive or agent.is_global_brain:
			continue
		var d = pos.distance_to(agent.pos)
		if d < nearest_dist:
			nearest_dist = d
			nearest_agent = agent

	if nearest_agent:
		target_agent_id = nearest_agent.id
		var dir = (nearest_agent.pos - pos).normalized()
		var dist_to_target = pos.distance_to(nearest_agent.pos)

		# ---- 4. АТАКА (зависит от поля) ----
		if type == Type.GUARDIAN and dist_to_target <= scaled_attack_radius and attack_cooldown == 0:
			# Импульс в поле
			var impact_radius = 2.0
			var impact_strength = -0.15 * (0.5 + field_power * 1.0)
			for dx in range(-int(impact_radius), int(impact_radius) + 1):
				for dy in range(-int(impact_radius), int(impact_radius) + 1):
					var p = nearest_agent.pos + Vector2(dx, dy)
					var dist = Vector2(dx, dy).length()
					if dist > impact_radius: continue
					var influence = impact_strength * (1.0 - dist / impact_radius)
					sim.field_system.set_field_at(p, sim.field_system.get_field_at(p) + influence)
			
			# Урон по энергии
			nearest_agent.energy = max(0.0, nearest_agent.energy - scaled_attack_damage)
			
			# Повреждение мембраны
			if nearest_agent.cell_body.membrane.has("integrity"):
				nearest_agent.cell_body.membrane.integrity = max(0.0, 
					nearest_agent.cell_body.membrane.integrity - scaled_membrane_damage)
			
			# Потеря рецептора
			if randf() < scaled_receptor_loss:
				var receptors = nearest_agent.cell_body.membrane.receptors
				if receptors.size() > 0:
					var idx = randi() % receptors.size()
					receptors.remove_at(idx)
					if nearest_agent.memory_system:
						nearest_agent.memory_system.add_insight(
							nearest_agent,
							"I lost a receptor. I feel numb.",
							nearest_agent.pos
						)
			attack_cooldown = attack_rate

		# ---- 5. ПРЕСЛЕДОВАНИЕ (скорость зависит от поля) ----
		if dist_to_target <= detection_radius:
			var move_speed = scaled_speed
			if dist_to_target < scaled_attack_radius * 1.5:
				move_speed *= 0.7
			pos += dir * move_speed * delta
		else:
			var dir_home = (home_pos - pos).normalized()
			if pos.distance_to(home_pos) > 1.0:
				pos += dir_home * scaled_speed * 0.3 * delta
	else:
		target_agent_id = -1
		var dir_home = (home_pos - pos).normalized()
		if pos.distance_to(home_pos) > 1.0:
			pos += dir_home * speed * 0.3 * delta
