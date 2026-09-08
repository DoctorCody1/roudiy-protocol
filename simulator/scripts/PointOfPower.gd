extends RefCounted
class_name PointOfPower

enum Type { ALTAR, FORGE, BATH, BRIDGE, TIME_SOURCE, TEMPLE }

var type: Type
var pos: Vector2
var level: int
var active: bool = true
var cooldown: int = 0
var max_cooldown: int = 50

# ---- НОВОЕ: сила источника (влияет на градиент поля) ----
var source_strength: float = 0.0          # 0..1, нарастает при активации
var source_decay: float = 0.005           # скорость затухания
var source_radius: int = 8                # радиус влияния на поле

func _init(t: Type, position: Vector2, lvl: int = 1):
	type = t
	pos = position
	level = lvl
	active = true
	source_strength = 0.0

func update():
	if cooldown > 0:
		cooldown -= 1
		if cooldown <= 0:
			active = true
	
	# ---- ЕСЛИ ЭТО ИСТОЧНИК ВРЕМЕНИ ----
	if type == Type.TIME_SOURCE:
		# Постепенное нарастание силы, если активен
		if active:
			source_strength = min(1.0, source_strength + 0.001)
		else:
			source_strength = max(0.0, source_strength - source_decay)
		
		# ---- ПЕРЕДАЧА ГРАДИЕНТА В ПОЛЕ ----
		var sim = SimManager.instance
		if sim and sim.field_system:
			_apply_source_gradient(sim.field_system)

# ---- ПРИМЕНЕНИЕ ГРАДИЕНТА К ПОЛЮ ----
func _apply_source_gradient(field_system: FieldSystem):
	if source_strength < 0.01:
		return
	var radius = source_radius * source_strength
	var amplitude = source_strength * 0.3
	var cx = int(pos.x)
	var cy = int(pos.y)
	var grid_size = field_system.grid_size
	
	for dy in range(-int(radius), int(radius) + 1):
		for dx in range(-int(radius), int(radius) + 1):
			var px = cx + dx
			var py = cy + dy
			if px < 0 or px >= grid_size or py < 0 or py >= grid_size:
				continue
			var dist = sqrt(dx*dx + dy*dy)
			if dist > radius:
				continue
			var influence = amplitude * (1.0 - dist / radius)
			field_system.set_field_at(Vector2(px, py), field_system.get_field_at(Vector2(px, py)) + influence)

# ---- ВЗАИМОДЕЙСТВИЕ С АГЕНТОМ ----
func interact(agent: Agent) -> Dictionary:
	if not active:
		return {"message": "The point is dormant."}

	match type:
		Type.ALTAR:
			if agent.has_name:
				agent.meta_identity = min(1.0, agent.meta_identity + 0.05)
				agent.well_being = min(1.0, agent.well_being + 0.03)
				active = false
				cooldown = max_cooldown
				return {"message": "The altar speaks your name: " + agent.self_name}
			else:
				return {"message": "The altar is silent."}

		Type.FORGE:
			if agent.language_system:
				var symbol = agent.language_system.get_or_create_symbol(agent, "forge_symbol")
				agent.memory_anchors += 1
				active = false
				cooldown = max_cooldown
				return {"message": "A new symbol is born in the forge."}
			return {"message": "The forge is cold."}

		Type.BATH:
			agent.energy = min(agent.max_energy, agent.energy + 0.3)
			agent.stress = max(0.0, agent.stress - 0.2)
			agent.well_being = min(1.0, agent.well_being + 0.05)
			active = false
			cooldown = max_cooldown
			return {"message": "The steam cleanses you."}

		Type.BRIDGE:
			var new_level = (level + 1) % 3
			agent.altitude = new_level
			agent.pos = Vector2(randi() % 64, new_level * 20 + 10)
			active = false
			cooldown = max_cooldown
			return {"message": "The bridge carries you to another level."}

		Type.TIME_SOURCE:
			var time_gained = 5 + randi() % 10
			agent.max_age += time_gained
			agent.well_being = min(1.0, agent.well_being + 0.1)
			agent.meta_identity = min(1.0, agent.meta_identity + 0.05)
			if agent.memory_system:
				agent.memory_system.add_insight(agent, "I touched the Source of Time. I feel alive.", agent.pos)
			active = false
			cooldown = max_cooldown * 2
			source_strength = max(0.0, source_strength - 0.2)
			return {
				"message": "The Source of Time pulses! +" + str(time_gained) + " steps.",
				"time_gained": time_gained,
				"type": "source_time"
			}

		Type.TEMPLE:
			if agent.meta_identity > 0.5:
				var proposal = agent._generate_meta_proposal()
				if proposal != null:
					SimManager.instance.global_brain.receive_proposal(proposal, agent)
					return {"message": "You speak to the Global Brain."}
			return {"message": "The temple is silent."}

	return {"message": "You feel the presence of the point."}
