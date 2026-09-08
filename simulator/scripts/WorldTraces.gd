extends RefCounted
class_name WorldTraces

# ============================================================
#  СЛЕДЫ
# ============================================================
var traces: Array = []          # {pos, type, strength, owner_id, text, time, decay_rate}

# ============================================================
#  ДОБАВЛЕНИЕ СЛЕДА
# ============================================================
func add_trace(
	pos: Vector2,
	type: String,               # "battle", "ritual", "death", "birth", "name", "artifact"
	strength: float,
	owner_id: int = -1,
	text: String = "",
	decay_rate: float = 0.001
):
	traces.append({
		"pos": pos,
		"type": type,
		"strength": min(strength, 1.0),
		"owner_id": owner_id,
		"text": text,
		"time": SimManager.instance.time,
		"decay_rate": decay_rate
	})

# ============================================================
#  ОБНОВЛЕНИЕ СЛЕДОВ (затухание)
# ============================================================
func update(delta: float = 1.0):
	for i in range(traces.size() - 1, -1, -1):
		var t = traces[i]
		t.strength -= t.decay_rate * delta
		if t.strength <= 0.0:
			traces.remove_at(i)

# ============================================================
#  ПОЛУЧЕНИЕ СЛЕДОВ
# ============================================================
func get_traces_near(pos: Vector2, radius: float, type: String = "") -> Array:
	var result = []
	for t in traces:
		if pos.distance_to(t.pos) < radius:
			if type == "" or t.type == type:
				result.append(t)
	return result

# ============================================================
#  ПРИМЕНЕНИЕ СЛЕДОВ К ПОЛЮ
# ============================================================
func apply_traces_to_field(field_system: FieldSystem):
	for t in traces:
		var pos = t.pos
		var strength = t.strength
		var radius = 2
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var p = pos + Vector2(dx, dy)
				if p.x < 0 or p.x >= field_system.grid_size or p.y < 0 or p.y >= field_system.grid_size:
					continue
				var dist = sqrt(dx*dx + dy*dy)
				if dist > radius:
					continue
				var influence = strength * 0.1 * (1.0 - dist / radius)
				field_system.set_field_at(p, field_system.get_field_at(p) + influence)

# ============================================================
#  ЛОГИРОВАНИЕ
# ============================================================
func get_summary() -> String:
	return "WorldTraces: " + str(traces.size()) + " traces"
