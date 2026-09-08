extends RefCounted
class_name WorldReputation

# ============================================================
#  РЕПУТАЦИЯ
# ============================================================
var reputations: Dictionary = {}   # name -> {fame, deeds, last_update}

# ============================================================
#  ОБНОВЛЕНИЕ РЕПУТАЦИИ
# ============================================================
func update_reputation(agent: Agent, deed: String, impact: float):
	if not agent.has_name:
		return
	var name = agent.self_name
	if not reputations.has(name):
		reputations[name] = {
			"fame": 0.0,
			"deeds": [],
			"last_update": SimManager.instance.time
		}
	var rep = reputations[name]
	rep.fame = clamp(rep.fame + impact, 0.0, 1.0)
	rep.deeds.append(deed)
	if rep.deeds.size() > 10:
		rep.deeds.pop_front()
	rep.last_update = SimManager.instance.time

# ============================================================
#  ПОЛУЧЕНИЕ РЕПУТАЦИИ
# ============================================================
func get_fame(name: String) -> float:
	if reputations.has(name):
		return reputations[name].fame
	return 0.0

func get_deeds(name: String) -> Array:
	if reputations.has(name):
		return reputations[name].deeds
	return []

# ============================================================
#  ВЛИЯНИЕ РЕПУТАЦИИ НА ПОЛЕ
# ============================================================
func apply_reputation_to_field(field_system: FieldSystem, agent: Agent):
	if not agent.has_name:
		return
	var fame = get_fame(agent.self_name)
	if fame < 0.1:
		return
	var pos = agent.pos
	var amplitude = fame * 0.2
	var radius = 2
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var p = pos + Vector2(dx, dy)
			if p.x < 0 or p.x >= field_system.grid_size or p.y < 0 or p.y >= field_system.grid_size:
				continue
			var dist = sqrt(dx*dx + dy*dy)
			if dist > radius:
				continue
			var influence = amplitude * (1.0 - dist / radius)
			field_system.set_field_at(p, field_system.get_field_at(p) + influence)

# ============================================================
#  ЛОГИРОВАНИЕ
# ============================================================
func get_summary() -> String:
	var s = "WorldReputation: " + str(reputations.size()) + " names\n"
	for name in reputations:
		s += "  " + name + ": fame " + str(reputations[name].fame).pad_decimals(2) + "\n"
	return s
