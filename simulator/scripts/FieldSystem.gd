extends RefCounted
class_name FieldSystem

# ============================================================
#  ПАРАМЕТРЫ ПОЛЯ
# ============================================================
var grid_size: int = 64
var field_grid: Array = []
var decay: float = 0.99
var diffusion: float = 0.01
var fluctuation_strength: float = 0.02
var max_field_value: float = 2.0

# ---- ДОЛГОВРЕМЕННЫЕ СЛЕДЫ (память поля) ----
var long_term_traces: Array = []
const MAX_TRACES: int = 200
const TRACE_DECAY_RATE: float = 0.0005

# ---- Феромоны ----
var pheromone_field: Dictionary = {
	"pleasure": [],
	"fear": [],
	"trust": []
}
var pheromone_decay: float = 0.98
var pheromone_diffusion: float = 0.01

# ---- Паттерны ----
var pattern_memory: Array = []
const MAX_PATTERNS: int = 50
const PATTERN_STRENGTHEN_RATE: float = 0.01
const PATTERN_WEAKEN_RATE: float = 0.001

# ---- Нейротрансмиттеры ----
var nt_fields: Dictionary = {}
var nt_decay: float = 0.95
var nt_diffusion: float = 0.01
var max_nt_concentration: float = 3.0

# ---- Источники градиентов ----
var gradient_sources: Array = []

# ---- Храм ----
var temple_zone: Dictionary = {}

# ---- Мета-предложения ----
var meta_proposals: Array = []

# ---- РАДИАЛЬНЫЙ ГРАДИЕНТ (новое) ----
var center: Vector2 = Vector2(32, 32)
var max_radius: float = 32.0
var radial_field_cache: Array = []   # кэш для быстрого доступа

# ============================================================
#  ИНИЦИАЛИЗАЦИЯ
# ============================================================
func _init(size: int = 64):
	grid_size = size
	center = Vector2(grid_size / 2, grid_size / 2)
	max_radius = grid_size / 2.0
	reset_field()
	_init_radial_gradient()
	_init_pheromone_fields()
	# nt_fields инициализируется через init_neurotransmitter_fields()

func reset_field():
	field_grid.resize(grid_size * grid_size)
	for i in range(field_grid.size()):
		field_grid[i] = 0.0

# ---- РАДИАЛЬНЫЙ ГРАДИЕНТ (вместо вертикального) ----
func _init_radial_gradient():
	# Предварительно вычисляем радиальный градиент для каждой клетки
	radial_field_cache.resize(grid_size * grid_size)
	for y in range(grid_size):
		for x in range(grid_size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			var t = clamp(dist / max_radius, 0.0, 1.0)
			# В центре (t=0) → 1.5, на краю (t=1) → 0.5
			# Плавная кривая, чтобы центр был заметно сильнее
			var value = 1.5 - t * t * 1.0
			radial_field_cache[y * grid_size + x] = value

func _init_pheromone_fields():
	for key in pheromone_field.keys():
		var arr = []
		arr.resize(grid_size * grid_size)
		for i in range(arr.size()):
			arr[i] = 0.0
		pheromone_field[key] = arr

# ============================================================
#  ДОСТУП К ПОЛЮ
# ============================================================
func get_field_at(pos: Vector2) -> float:
	var x = int(pos.x) % grid_size
	var y = int(pos.y) % grid_size
	var idx = y * grid_size + x
	if idx < 0 or idx >= field_grid.size():
		return 0.0
	# Умножаем на радиальный градиент
	return field_grid[idx] * radial_field_cache[idx]

func set_field_at(pos: Vector2, value: float):
	var x = int(pos.x) % grid_size
	var y = int(pos.y) % grid_size
	var idx = y * grid_size + x
	if idx >= 0 and idx < field_grid.size():
		field_grid[idx] = clamp(value, -max_field_value, max_field_value)

func get_coherence_at(pos: Vector2) -> float:
	var x = int(pos.x) % grid_size
	var y = int(pos.y) % grid_size
	var idx = y * grid_size + x
	
	# Радиальная когерентность: центр — хаос (низкая), периферия — порядок (высокая)
	var dist = pos.distance_to(center)
	var t = clamp(dist / max_radius, 0.0, 1.0)
	# В центре (t=0) → 0.2, на краю (t=1) → 0.9
	var base_coherence = 0.2 + t * 0.7
	
	# Локальная энтропия корректирует (как было)
	var entropy = get_local_entropy(pos, 3)
	return base_coherence * (1.0 - entropy * 0.5)

func get_local_entropy(pos: Vector2, radius: int = 4) -> float:
	var values = []
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var p = pos + Vector2(x, y)
			values.append(get_field_at(p))
	if values.is_empty():
		return 0.0
	var mean = values.reduce(func(a,b): return a+b, 0.0) / values.size()
	var variance = values.reduce(func(a,b): return a + (b-mean)*(b-mean), 0.0) / values.size()
	var norm_variance = min(variance, 1.0)
	return 1.0 - (1.0 - norm_variance) * (1.0 - norm_variance)

func get_global_entropy() -> float:
	var total = 0.0
	var count = 0
	for y in range(grid_size):
		for x in range(grid_size):
			var pos = Vector2(x, y)
			total += get_local_entropy(pos, 3)
			count += 1
	return total / count if count > 0 else 0.0

func get_global_mean() -> float:
	var sum = 0.0
	for val in field_grid:
		sum += val
	return sum / field_grid.size()

# ============================================================
#  ГРАДИЕНТЫ
# ============================================================
func get_gradient(pos: Vector2) -> Vector2:
	var x = int(pos.x) % grid_size
	var y = int(pos.y) % grid_size
	var dx = get_field_at(Vector2(x+1, y)) - get_field_at(Vector2(x-1, y))
	var dy = get_field_at(Vector2(x, y+1)) - get_field_at(Vector2(x, y-1))
	return Vector2(dx, dy) * 0.5

func get_source_gradient(pos: Vector2) -> Vector2:
	if gradient_sources.is_empty():
		return Vector2.ZERO
	var total_grad = Vector2.ZERO
	for source in gradient_sources:
		var dist = pos.distance_to(source.pos)
		if dist < source.radius:
			var direction = (pos - source.pos).normalized()
			var strength = source.strength * (1.0 - dist / source.radius)
			total_grad += direction * strength
	return total_grad

func add_gradient_source(pos: Vector2, strength: float, radius: int, type: String = "source"):
	for i in range(gradient_sources.size() - 1, -1, -1):
		if gradient_sources[i].pos.distance_to(pos) < 1.0:
			gradient_sources.remove_at(i)
	gradient_sources.append({"pos": pos, "strength": strength, "radius": radius, "type": type})

# ============================================================
#  ОБНОВЛЕНИЕ ПОЛЯ
# ============================================================
func update(agents: Array, delta: float = 1.0):
	# 1. Затухание
	for i in range(field_grid.size()):
		field_grid[i] *= decay

	# 2. Диффузия
	if diffusion > 0.0:
		var diffused = field_grid.duplicate()
		for y in range(grid_size):
			for x in range(grid_size):
				var idx = y * grid_size + x
				var neighbors = 0.0
				var count = 0
				for dy in [-1, 1]:
					for dx in [-1, 1]:
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and nx < grid_size and ny >= 0 and ny < grid_size:
							var nidx = ny * grid_size + nx
							neighbors += field_grid[nidx]
							count += 1
				if count > 0:
					diffused[idx] = field_grid[idx] + diffusion * (neighbors / count - field_grid[idx])
		field_grid = diffused

	# 3. Влияние агентов
	for agent in agents:
		if not agent.alive:
			continue
		var pos = agent.pos
		var amplitude = agent.soliton_amplitude if agent.has_method("get_soliton_amplitude") else 1.0
		var radius = agent.field_radius if agent.has_method("get_field_radius") else 3
		var cx = int(pos.x) % grid_size
		var cy = int(pos.y) % grid_size
		# Радиальный модификатор: в центре влияние слабее (там уже много энергии)
		var dist_to_center = pos.distance_to(center)
		var t = clamp(dist_to_center / max_radius, 0.0, 1.0)
		var radial_mod = 0.5 + t * 0.5  # на периферии влияние сильнее
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var px = (cx + dx) % grid_size
				var py = (cy + dy) % grid_size
				var dist = sqrt(dx*dx + dy*dy)
				if dist > radius: continue
				var idx = py * grid_size + px
				var influence = amplitude * (1.0 - dist / radius) * radial_mod
				field_grid[idx] += influence

	# 4. Долговременные следы
	_apply_long_term_traces()

	# 5. Источники градиентов
	_apply_gradient_sources()

	# 6. Усиление паттернов
	_strengthen_patterns()

	# 7. Храм
	_update_temple(agents)

	# 8. Квантовые флуктуации
	for i in range(field_grid.size()):
		field_grid[i] += randf_range(-fluctuation_strength, fluctuation_strength)

	# 9. Ограничение
	for i in range(field_grid.size()):
		field_grid[i] = clamp(field_grid[i], -max_field_value, max_field_value)

	# 10. Нейротрансмиттеры
	_update_neurotransmitter_fields()

	# 11. Феромоны
	_update_pheromones()

# ============================================================
#  ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ (СОХРАНЕНЫ)
# ============================================================
func init_neurotransmitter_fields(nt_list: Array):
	for nt in nt_list:
		var arr = []
		arr.resize(grid_size * grid_size)
		arr.fill(0.0)
		nt_fields[nt] = arr

func add_neurotransmitter(pos: Vector2, nt_type: String, amount: float):
	if not nt_fields.has(nt_type):
		return
	var idx = _get_index(pos)
	nt_fields[nt_type][idx] += amount
	nt_fields[nt_type][idx] = clamp(nt_fields[nt_type][idx], 0.0, max_nt_concentration)

func get_neurotransmitter_at(pos: Vector2, nt_type: String) -> float:
	if not nt_fields.has(nt_type):
		return 0.0
	var idx = _get_index(pos)
	return nt_fields[nt_type][idx]

func get_all_neurotransmitters_at(pos: Vector2) -> Dictionary:
	var result = {}
	for nt in nt_fields.keys():
		result[nt] = get_neurotransmitter_at(pos, nt)
	return result

func _update_neurotransmitter_fields():
	for nt in nt_fields.keys():
		var field = nt_fields[nt]
		var new_field = field.duplicate()
		for y in range(grid_size):
			for x in range(grid_size):
				var idx = y * grid_size + x
				var val = field[idx] * nt_decay
				var neighbours = 0
				var total = 0.0
				for dy in [-1, 1]:
					for dx in [-1, 1]:
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and nx < grid_size and ny >= 0 and ny < grid_size:
							var nidx = ny * grid_size + nx
							total += field[nidx]
							neighbours += 1
				if neighbours > 0:
					val += total * nt_diffusion / neighbours
				new_field[idx] = clamp(val, 0.0, max_nt_concentration)
		nt_fields[nt] = new_field

func update_neurotransmitters():
	_update_neurotransmitter_fields()

func add_pheromone(pos: Vector2, type: String, amount: float):
	if not pheromone_field.has(type):
		return
	var idx = _get_index(pos)
	pheromone_field[type][idx] += amount
	pheromone_field[type][idx] = min(pheromone_field[type][idx], 1.0)

func get_pheromones_at(pos: Vector2) -> Dictionary:
	var idx = _get_index(pos)
	var result = {}
	for type in pheromone_field.keys():
		result[type] = pheromone_field[type][idx] if idx >= 0 and idx < pheromone_field[type].size() else 0.0
	return result

func _update_pheromones():
	for type in pheromone_field.keys():
		var field = pheromone_field[type]
		var new_field = field.duplicate()
		for y in range(grid_size):
			for x in range(grid_size):
				var idx = y * grid_size + x
				var val = field[idx] * pheromone_decay
				var neighbours = 0
				var total = 0.0
				for dy in [-1, 1]:
					for dx in [-1, 1]:
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and nx < grid_size and ny >= 0 and ny < grid_size:
							var nidx = ny * grid_size + nx
							total += field[nidx]
							neighbours += 1
				if neighbours > 0:
					val += total * pheromone_diffusion / neighbours
				new_field[idx] = clamp(val, 0.0, 1.0)
		pheromone_field[type] = new_field

func add_long_term_trace(pos: Vector2, type: String, strength: float, decay_rate: float = TRACE_DECAY_RATE):
	long_term_traces.append({"pos": pos, "type": type, "strength": strength, "decay_rate": decay_rate})
	if long_term_traces.size() > MAX_TRACES:
		long_term_traces.pop_front()

func _apply_long_term_traces():
	for i in range(long_term_traces.size() - 1, -1, -1):
		var trace = long_term_traces[i]
		trace.strength -= trace.decay_rate
		if trace.strength <= 0.0:
			long_term_traces.remove_at(i)
			continue
		var pos = trace.pos
		var radius = 3
		var amplitude = trace.strength * 0.1
		var cx = int(pos.x) % grid_size
		var cy = int(pos.y) % grid_size
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var px = (cx + dx) % grid_size
				var py = (cy + dy) % grid_size
				var dist = sqrt(dx*dx + dy*dy)
				if dist > radius: continue
				var idx = py * grid_size + px
				var influence = amplitude * (1.0 - dist / radius)
				if trace.type == "death":
					influence = -influence
				field_grid[idx] += influence

func _apply_gradient_sources():
	for source in gradient_sources:
		var pos = source.pos
		var strength = source.strength
		var radius = source.radius
		var cx = int(pos.x) % grid_size
		var cy = int(pos.y) % grid_size
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var px = (cx + dx) % grid_size
				var py = (cy + dy) % grid_size
				var dist = sqrt(dx*dx + dy*dy)
				if dist > radius: continue
				var idx = py * grid_size + px
				var influence = strength * (1.0 - dist / radius)
				field_grid[idx] += influence

func remember_pattern(pattern: Dictionary):
	var pos = pattern.pos
	var amplitude = pattern.amplitude
	var coherence = pattern.coherence if pattern.has("coherence") else 0.5
	for p in pattern_memory:
		if p.pos.distance_to(pos) < 2.0:
			p.amplitude = (p.amplitude + amplitude) * 0.5
			p.coherence = (p.coherence + coherence) * 0.5
			p.frequency += 1
			return
	pattern_memory.append({"pos": pos, "amplitude": amplitude, "coherence": coherence, "frequency": 1})
	if pattern_memory.size() > MAX_PATTERNS:
		pattern_memory.pop_front()

func _strengthen_patterns():
	for p in pattern_memory:
		if p.frequency > 2:
			var pos = p.pos
			var amplitude = p.amplitude * PATTERN_STRENGTHEN_RATE
			var radius = 2
			var cx = int(pos.x) % grid_size
			var cy = int(pos.y) % grid_size
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					var px = (cx + dx) % grid_size
					var py = (cy + dy) % grid_size
					var dist = sqrt(dx*dx + dy*dy)
					if dist > radius: continue
					var idx = py * grid_size + px
					var influence = amplitude * (1.0 - dist / radius)
					field_grid[idx] += influence
			p.frequency *= (1.0 - PATTERN_WEAKEN_RATE)

func _update_temple(agents: Array):
	if temple_zone.is_empty():
		for x in range(5, grid_size-5, 5):
			for y in range(5, grid_size-5, 5):
				var pos = Vector2(x, y)
				var amp = get_field_at(pos)
				var coh = get_coherence_at(pos)
				if amp > 1.2 and coh > 0.7:
					var total_meta = 0.0
					var count = 0
					for agent in agents:
						if agent.alive and pos.distance_to(agent.pos) < 3.0:
							total_meta += agent.meta_identity
							count += 1
					if count > 0 and total_meta / count > 0.5:
						temple_zone = {"pos": pos, "strength": 0.1, "age": 0, "active": false}
						break
			if not temple_zone.is_empty():
				break
	else:
		temple_zone.age += 1
		var pos = temple_zone.pos
		var radius = 4
		var amp = 0.05 * temple_zone.strength
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var p = pos + Vector2(dx, dy)
				var dist = sqrt(dx*dx + dy*dy)
				if dist > radius: continue
				var idx = int(p.y) * grid_size + int(p.x)
				if idx >= 0 and idx < field_grid.size():
					field_grid[idx] += amp * (1.0 - dist / radius)
		if temple_zone.age > 100 and temple_zone.strength > 0.8:
			temple_zone.active = true
			add_gradient_source(pos, 0.5, 8, "temple")
			for dy in range(-6, 7):
				for dx in range(-6, 7):
					var p = pos + Vector2(dx, dy)
					var dist = sqrt(dx*dx + dy*dy)
					if dist > 6: continue
					var idx = int(p.y) * grid_size + int(p.x)
					if idx >= 0 and idx < field_grid.size():
						field_grid[idx] += 0.1 * (1.0 - dist / 6)
		else:
			temple_zone.strength += 0.001
		if temple_zone.age > 500 and not temple_zone.active:
			temple_zone = {}
			return
		var current_amp = get_field_at(pos)
		if current_amp < 0.5:
			temple_zone = {}
			for i in range(gradient_sources.size() - 1, -1, -1):
				if gradient_sources[i].pos.distance_to(pos) < 1.0:
					gradient_sources.remove_at(i)

func add_meta_proposal(pos: Vector2, proposal: Dictionary, author: Agent):
	meta_proposals.append({
		"pos": pos,
		"proposal": proposal,
		"support": 0,
		"oppose": 0,
		"time": SimManager.instance.time,
		"decay": 0.1,
		"author_id": author.id
	})
	if meta_proposals.size() > 10:
		meta_proposals.pop_front()

func apply_meta_proposals():
	for i in range(meta_proposals.size() - 1, -1, -1):
		var p = meta_proposals[i]
		p.decay += 0.01
		if p.decay > 1.0:
			meta_proposals.remove_at(i)
			continue
		if p.support >= 3:
			_apply_meta_rule(p.proposal)
			meta_proposals.remove_at(i)
			SimManager.instance.add_log("Мир изменился: " + str(p.proposal))

func _apply_meta_rule(rule: Dictionary):
	var key = rule.key
	var change = rule.change
	SimManager.instance.meta_rules[key] += change
	SimManager.instance.meta_rules[key] = clamp(SimManager.instance.meta_rules[key], 0.3, 2.0)
	var pos = Vector2(randi() % 64, randi() % 64)
	set_field_at(pos, get_field_at(pos) + 0.5)

func get_grid_size() -> int:
	return grid_size

func get_field_copy() -> Array:
	return field_grid.duplicate()

func get_asynchronicity(pos: Vector2, radius: int = 5) -> float:
	var global_mean = get_global_entropy()
	if global_mean == 0.0: return 0.0
	var local_mean = 0.0
	var count = 0
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var p = pos + Vector2(x, y)
			if p.x < 0 or p.x >= grid_size or p.y < 0 or p.y >= grid_size: continue
			local_mean += get_field_at(p)
			count += 1
	if count == 0: return 0.0
	local_mean /= count
	return abs(local_mean - global_mean) / abs(global_mean)

func get_incomplete_patterns(pos: Vector2, radius: int = 6) -> Array:
	var patterns = []
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var p = pos + Vector2(x, y)
			var coherence = get_coherence_at(p)
			var amplitude = abs(get_field_at(p))
			if coherence > 0.7 and amplitude < 0.3:
				patterns.append({"pos": p, "coherence": coherence, "amplitude": amplitude, "strength": coherence * (1.0 - amplitude)})
	return patterns

func answer_pattern(pos: Vector2, agent: Agent, strength: float = 0.5):
	var amplitude = strength * 0.3 * (1.0 + agent.meta_identity * 0.5)
	var radius = 3 + int(agent.meta_identity * 2)
	var cx = int(pos.x) % grid_size
	var cy = int(pos.y) % grid_size
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var px = (cx + dx) % grid_size
			var py = (cy + dy) % grid_size
			var dist = sqrt(dx*dx + dy*dy)
			if dist > radius: continue
			var idx = py * grid_size + px
			var influence = amplitude * (1.0 - dist / radius)
			field_grid[idx] += influence

func get_resonant_patterns(pos: Vector2, radius: int = 5) -> Array:
	var current = get_field_at(pos)
	var resonant = []
	for p in pattern_memory:
		var dist = pos.distance_to(p.pos)
		if dist < radius:
			var similarity = 1.0 - abs(current - p.amplitude) / 1.0
			if similarity > 0.7:
				resonant.append(p)
	return resonant

func create_rupture(pos: Vector2):
	var radius = 3
	var amplitude = -0.4
	var cx = int(pos.x) % grid_size
	var cy = int(pos.y) % grid_size
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var px = (cx + dx) % grid_size
			var py = (cy + dy) % grid_size
			var dist = sqrt(dx*dx + dy*dy)
			if dist > radius: continue
			var idx = py * grid_size + px
			var influence = amplitude * (1.0 - dist / radius)
			field_grid[idx] += influence
	add_long_term_trace(pos, "death", 0.3)

func get_laplacian(pos: Vector2) -> float:
	var x = int(pos.x) % grid_size
	var y = int(pos.y) % grid_size
	var center = get_field_at(pos)
	var left = get_field_at(Vector2(x - 1, y))
	var right = get_field_at(Vector2(x + 1, y))
	var up = get_field_at(Vector2(x, y - 1))
	var down = get_field_at(Vector2(x, y + 1))
	return (left + right + up + down - 4.0 * center)

func _get_index(pos: Vector2) -> int:
	var x = int(pos.x) % grid_size
	var y = int(pos.y) % grid_size
	return y * grid_size + x
