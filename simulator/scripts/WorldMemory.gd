extends RefCounted
class_name WorldMemory

# ============================================================
#  ХРАНИЛИЩЕ СОБЫТИЙ
# ============================================================
var events: Array = []          # {type, time, pos, agents, description, impact}
var max_events: int = 200

# ============================================================
#  ДОБАВЛЕНИЕ СОБЫТИЯ
# ============================================================
func add_event(
	type: String,
	pos: Vector2,
	agents: Array = [],
	description: String = "",
	impact: float = 0.0
):
	var event = {
		"type": type,               # "death", "birth", "resonance", "ritual", "name_given", "name_lost", "artifact_created", "faction_formed", "conflict"
		"time": SimManager.instance.time,
		"pos": pos,
		"agents": agents,
		"description": description,
		"impact": impact
	}
	events.append(event)
	if events.size() > max_events:
		events.pop_front()

# ============================================================
#  ПОЛУЧЕНИЕ СОБЫТИЙ
# ============================================================
func get_events_near(pos: Vector2, radius: float, types: Array = []) -> Array:
	var result = []
	for e in events:
		if pos.distance_to(e.pos) < radius:
			if types.is_empty() or e.type in types:
				result.append(e)
	return result

func get_events_by_agent(agent_id: int, types: Array = []) -> Array:
	var result = []
	for e in events:
		if agent_id in e.agents:
			if types.is_empty() or e.type in types:
				result.append(e)
	return result

func get_last_event(type: String, agent_id: int = -1) -> Dictionary:
	for i in range(events.size() - 1, -1, -1):
		var e = events[i]
		if e.type == type and (agent_id == -1 or agent_id in e.agents):
			return e
	return {}

# ============================================================
#  ВЛИЯНИЕ НА ПОЛЕ
# ============================================================
func apply_event_to_field(event: Dictionary, field_system: FieldSystem):
	var pos = event.pos
	var impact = event.impact
	var radius = 3
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var p = pos + Vector2(dx, dy)
			if p.x < 0 or p.x >= field_system.grid_size or p.y < 0 or p.y >= field_system.grid_size:
				continue
			var dist = sqrt(dx*dx + dy*dy)
			if dist > radius:
				continue
			var influence = impact * (1.0 - dist / radius)
			field_system.set_field_at(p, field_system.get_field_at(p) + influence)

# ============================================================
#  ЛОГИРОВАНИЕ
# ============================================================
func get_summary() -> String:
	var s = "WorldMemory: " + str(events.size()) + " events\n"
	if events.size() > 0:
		var latest = events[-1]
		s += "Latest: " + latest.type + " at " + str(latest.pos) + " (impact: " + str(latest.impact).pad_decimals(2) + ")"
	return s
