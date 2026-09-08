extends Node
static var instance: SimManager = null

# ============================================================
#  ПАРАМЕТРЫ МИРА (локальные, без глобальных счётчиков)
# ============================================================
var grid_size: int = 64
var time: int = 0
var verbose: bool = true
var agent_speed: float = 0.15
var max_plants: int = 80
var spawn_interval: int = 40
var meta_rules: Dictionary = {
	"energy_cost_multiplier": 1.0,
	"resonance_range_multiplier": 1.0,
	"speech_range_multiplier": 1.0,
	"hebb_learning_multiplier": 1.0,
	"death_decay_multiplier": 1.0,
	"food_spawn_rate": 1.0,
}
# ============================================================
#  СУЩНОСТИ (все локальные)
# ============================================================
var agents: Array = []
var plants: Array = []
var enemies: Array = []
var resources: Array = []
var zones: Array = []
var objects: Array = []
var ancient_robots: Array = []
var points_of_power: Array = []
var ghosts: Array = []
var log_history: Array = []
var max_log_entries: int = 100
var neurotransmitter_list: Array = ["dopamine", "serotonin", "norepinephrine", "oxytocin", "acetylcholine", "glutamate", "gaba"]

# ============================================================
#  ГЛОБАЛЬНЫЕ ПУЛЫ (для эмерджентных феноменов, только память)
# ============================================================
var global_rituals: Array = []
var global_artifacts: Array = []
var global_memory: Array = []   # только для истории, не для управления

# ---- ГЛИЯ (поддержка поля) ----
var astrocytes: Array = []
var microglia: Array = []

# ---- СИСТЕМЫ ----
var field_system: FieldSystem = null
var stability_system: StabilitySystem = null
var movement_system: MovementSystem = null
var memory_system: MemorySystem = null
var behavior_graph_system: BehaviorGraphSystem = null
var social_system: SocialSystem = null
var dream_ritual_system: DreamRitualSystem = null
var death_reincarnation_system: DeathReincarnationSystem = null
var meta_reflection_system: MetaReflectionSystem = null
var global_brain: GlobalBrain = null

# ---- ЭМЕРДЖЕНТНЫЕ ПАРАМЕТРЫ (вычисляются на лету) ----
var field_energy: float = 0.0         # средняя амплитуда поля
var field_entropy: float = 0.0        # энтропия поля
var global_well_being: float = 0.5    # среднее well-being агентов (без GB-агента)

# ============================================================
#  ИНИЦИАЛИЗАЦИЯ
# ============================================================
func _init():
	instance = self

func initialize(count: int, size: int):
	grid_size = size
	agents.clear()
	plants.clear()
	enemies.clear()
	resources.clear()
	zones.clear()
	objects.clear()
	ancient_robots.clear()
	points_of_power.clear()
	global_rituals.clear()
	global_artifacts.clear()
	global_memory.clear()
	astrocytes.clear()
	microglia.clear()
	
	field_system = FieldSystem.new(grid_size)
	field_system.init_neurotransmitter_fields(neurotransmitter_list)
	stability_system = StabilitySystem.new()
	movement_system = MovementSystem.new()
	memory_system = MemorySystem.new()
	behavior_graph_system = BehaviorGraphSystem.new()
	social_system = SocialSystem.new()
	dream_ritual_system = DreamRitualSystem.new()
	death_reincarnation_system = DeathReincarnationSystem.new()
	meta_reflection_system = MetaReflectionSystem.new()
	global_brain = GlobalBrain.new()
	
	generate_world()
	generate_plants(max_plants)
	_spawn_ancient_robots()
	_spawn_glia()
	_spawn_points_of_power()
	
	# Создаём обычных агентов
	for i in range(count):
		var pos = Vector2(randi() % grid_size, randi() % grid_size)
		var agent = Agent.new(i, pos, false)
		agent.speed = agent_speed
		agent.setup_systems(
			field_system, stability_system, movement_system,
			memory_system, behavior_graph_system, social_system,
			dream_ritual_system, death_reincarnation_system,
			meta_reflection_system
		)
		agents.append(agent)
		agent._init_receptors_and_enzymes(neurotransmitter_list)
		agent._mutate_receptors_and_enzymes(0.05)
		agent._mutate_neuro_sensitivity()
	
	# ---- СОЗДАНИЕ GLOBALBRAIN-АГЕНТА ----
	var gb_agent = GlobalBrainAgent.new(-1, Vector2(grid_size/2, grid_size/2))
	gb_agent.speed = 0.0
	gb_agent.setup_systems(
		field_system, stability_system, movement_system,
		memory_system, behavior_graph_system, social_system,
		dream_ritual_system, death_reincarnation_system,
		meta_reflection_system
	)
	gb_agent.has_name = true
	gb_agent.self_name = "GlobalBrain"
	agents.append(gb_agent)
	add_log("GlobalBrain-агент создан в центре поля")
	
	add_log("Симуляция инициализирована: " + str(agents.size()) + " агентов, " + str(plants.size()) + " растений")
	add_log("Глиальных клеток: " + str(astrocytes.size()) + " астроцитов, " + str(microglia.size()) + " микроглии")
	add_log("Точки силы созданы: " + str(points_of_power.size()))

# ============================================================
#  ГЕНЕРАЦИЯ МИРА (статический ландшафт)
# ============================================================
func generate_world():
	zones.clear()
	objects.clear()
	resources.clear()
	
	zones.append({"type": "steel_forest", "center": Vector2(10, 10), "radius": 8})
	zones.append({"type": "steam_swamp", "center": Vector2(40, 50), "radius": 10})
	zones.append({"type": "ruins", "center": Vector2(30, 30), "radius": 6})
	zones.append({"type": "factory", "center": Vector2(50, 20), "radius": 7})
	zones.append({"type": "wasteland", "center": Vector2(55, 55), "radius": 12})
	
	objects.append({"type": "castle", "pos": Vector2(15, 15), "size": 1.5})
	objects.append({"type": "castle", "pos": Vector2(45, 45), "size": 1.2})
	objects.append({"type": "statue", "pos": Vector2(25, 25)})
	objects.append({"type": "statue", "pos": Vector2(35, 35)})
	objects.append({"type": "furnace", "pos": Vector2(28, 28)})
	
	var resource_types = ["coal", "copper", "crystal", "herb", "key", "food"]
	for i in range(30):
		var pos = Vector2(randi() % grid_size, randi() % grid_size)
		var type = resource_types[randi() % resource_types.size()]
		resources.append({"type": type, "pos": pos, "amount": randf() * 3 + 1})

func _spawn_glia():
	for i in range(5):
		var pos = Vector2(randi() % grid_size, randi() % grid_size)
		var radius = 5 + randi() % 5
		var strength = randf_range(0.5, 1.5)
		astrocytes.append({"pos": pos, "radius": radius, "modulation_strength": strength})
	for i in range(2):
		var pos = Vector2(randi() % grid_size, randi() % grid_size)
		microglia.append({"pos": pos, "pruning_threshold": 0.1})

func _spawn_points_of_power():
	points_of_power.clear()
	points_of_power.append(PointOfPower.new(PointOfPower.Type.ALTAR, Vector2(15, 10), 0))
	points_of_power.append(PointOfPower.new(PointOfPower.Type.FORGE, Vector2(25, 35), 1))
	points_of_power.append(PointOfPower.new(PointOfPower.Type.BATH, Vector2(20, 50), 2))
	var source_pos = Vector2(grid_size/2, grid_size/2)
	var source = PointOfPower.new(PointOfPower.Type.TIME_SOURCE, source_pos, 1)
	points_of_power.append(source)
	if field_system:
		field_system.add_gradient_source(source_pos, 0.3, 10, "source_time")

func generate_plants(count: int):
	plants.clear()
	for i in range(count):
		var pos = Vector2(randi() % grid_size, randi() % grid_size)
		var plant = Plant.new(pos, randf_range(0.0, 0.6))
		plants.append(plant)

# ============================================================
#  ОСНОВНОЙ ШАГ СИМУЛЯЦИИ (без таймеров и глобальных счётчиков)
# ============================================================
func step():
	time += 1
	field_system.update_neurotransmitters()
	if field_system:
		_update_field()
	
	_update_glia()
	update_plants()
	
	# Обновляем агентов (включая GB-агента)
	for agent in agents:
		agent.update()
	
	_process_interactions()
	_process_points_of_power()
	_update_enemies()
	_update_ancient_robots()
	_remove_dead_agents()
	_emergent_neurogenesis()
	_update_resources()
	
	if global_brain:
		global_brain.update(agents, time)
	if field_system:
		field_system.apply_meta_proposals()
		_check_temple_interactions()
	
	_update_global_well_being()
	
	if time % 10 == 0:
		add_log(get_status())

# ============================================================
#  ОБНОВЛЕНИЕ ПОЛЯ (включая эмерджентные эффекты)
# ============================================================
func _update_field():
	field_system.update(agents)
	
	for point in points_of_power:
		if point.active:
			if point.type == PointOfPower.Type.TIME_SOURCE:
				var strength = 0.3 + point.source_strength * 0.3
				field_system.add_gradient_source(point.pos, strength, 10, "source_time")
			else:
				var amplitude = 0.1 + point.level * 0.05
				field_system.set_field_at(point.pos, field_system.get_field_at(point.pos) + amplitude)
	
	field_energy = field_system.get_global_mean()
	field_entropy = field_system.get_global_entropy()
	
	if field_energy > 1.2 and randf() < 0.01:
		var pos = Vector2(randi() % grid_size, randi() % grid_size)
		field_system.create_rupture(pos)
		add_log("Событие: Разлом в " + str(pos))
	
	if field_entropy > 0.7 and randf() < 0.005:
		_ancient_awakening()
	
	_check_emergent_source()

func get_global_rituals() -> Array:
	return global_rituals

func add_global_ritual(ritual_id: String):
	if ritual_id not in global_rituals:
		global_rituals.append(ritual_id)

func _check_emergent_source():
	var resonant_clusters = []
	for agent in agents:
		if agent.alive and agent.resonance_active and agent.resonance_partner and not agent.is_global_brain:
			var pos = agent.pos
			var found = false
			for cluster in resonant_clusters:
				if cluster.pos.distance_to(pos) < 5.0:
					cluster.count += 1
					cluster.pos = (cluster.pos + pos) * 0.5
					found = true
					break
			if not found:
				resonant_clusters.append({"pos": pos, "count": 1})
	
	for cluster in resonant_clusters:
		if cluster.count >= 3:
			var has_source_near = false
			for p in points_of_power:
				if p.type == PointOfPower.Type.TIME_SOURCE and p.pos.distance_to(cluster.pos) < 10.0:
					has_source_near = true
					break
			if not has_source_near and randf() < 0.02:
				var source = PointOfPower.new(PointOfPower.Type.TIME_SOURCE, cluster.pos, 1)
				points_of_power.append(source)
				add_log("Эмерджентный Источник Времени родился в " + str(cluster.pos))
				field_system.add_gradient_source(cluster.pos, 0.3, 10, "source_time")

# ============================================================
#  ГЛИЯ (поддержка поля и агентов)
# ============================================================
func _update_glia():
	for astro in astrocytes:
		var pos = astro.pos
		var radius = astro.radius
		var strength = astro.modulation_strength
		var monitored = []
		for agent in agents:
			if agent.alive and not agent.is_global_brain and pos.distance_to(agent.pos) < radius:
				monitored.append(agent)
		for agent in monitored:
			agent.curiosity = min(1.0, agent.curiosity + 0.001 * strength)
			agent.creative_immunity = min(1.0, agent.creative_immunity + 0.002 * strength)
			agent.stress = max(0.0, agent.stress - 0.002 * strength)
	for micro in microglia:
		var pos = micro.pos
		var threshold = micro.pruning_threshold
		for agent in agents:
			if agent.alive and not agent.is_global_brain and pos.distance_to(agent.pos) < 6.0:
				var to_remove = []
				for other_id in agent.trust.keys():
					if agent.trust[other_id] < threshold:
						to_remove.append(other_id)
				for id in to_remove:
					agent.trust.erase(id)

# ============================================================
#  ВЗАИМОДЕЙСТВИЯ МЕЖДУ АГЕНТАМИ
# ============================================================
func _process_interactions():
	for i in range(agents.size()):
		for j in range(i+1, agents.size()):
			var a = agents[i]
			var b = agents[j]
			if a.alive and b.alive and not a.is_global_brain and not b.is_global_brain:
				if a.pos.distance_to(b.pos) < 8.0:
					a.interact(b)

# ============================================================
#  ТОЧКИ СИЛЫ (включая Источник Времени)
# ============================================================
func _process_points_of_power():
	for agent in agents:
		if not agent.alive:
			continue
		for point in points_of_power:
			if not point.active:
				continue
			if agent.pos.distance_to(point.pos) < 1.5:
				var result = point.interact(agent)
				if result.has("message"):
					add_log(str(agent.id) + " (" + (agent.self_name if agent.has_name else "unnamed") + ") " + result.message)
				if point.type == PointOfPower.Type.TIME_SOURCE:
					# GB-агент не получает энергию, но получает инсайт
					if not agent.is_global_brain:
						agent.energy = min(agent.max_energy, agent.energy + 0.2)
					if agent.memory_system:
						agent.memory_system.add_insight(agent, "I touched the Source of Time. I feel alive.", agent.pos)
					field_system.add_gradient_source(point.pos, 0.5, 10, "source_time")

# ============================================================
#  ВРАГИ И ДРЕВНИЕ РОБОТЫ
# ============================================================
func _update_enemies():
	for enemy in enemies:
		if not enemy.alive:
			continue
		var nearest = null
		var min_dist = 999.0
		for agent in agents:
			if agent.alive and not agent.is_global_brain:
				var d = enemy.pos.distance_to(agent.pos)
				if d < min_dist:
					min_dist = d
					nearest = agent
		if nearest:
			var dir = (nearest.pos - enemy.pos).normalized()
			enemy.pos += dir * 0.05
			if min_dist < 1.5:
				nearest.energy = max(0.0, nearest.energy - 0.02)
				if nearest.energy <= 0:
					nearest.die("killed by enemy")
	
	var alive_enemies = []
	for e in enemies:
		if e.alive:
			alive_enemies.append(e)
	enemies = alive_enemies

func _update_ancient_robots():
	for robot in ancient_robots:
		robot.update(1.0)
		if robot.alive and robot.type == AncientRobot.Type.GUARDIAN:
			for agent in agents:
				if agent.alive and not agent.is_global_brain and agent.pos.distance_to(robot.pos) < 3.0:
					agent.energy = max(0.0, agent.energy - 0.01)
					if agent.energy < 0.1 and randf() < 0.01:
						agent.memory_system.add_insight(agent, "I feel drained near the ancient one.", agent.pos)

# ============================================================
#  УДАЛЕНИЕ МЁРТВЫХ АГЕНТОВ (без глобального счётчика)
# ============================================================
func _remove_dead_agents():
	var before = agents.size()
	var alive = []
	for agent in agents:
		if agent.alive:
			alive.append(agent)
		else:
			# GB-агент никогда не умирает, поэтому эта ветка не сработает, но на всякий случай
			if field_system and not agent.is_global_brain:
				field_system.add_long_term_trace(agent.pos, "death", 0.3)
			if agent.has_name and not agent.is_global_brain:
				add_global_memory({"type": "death", "content": "Death of " + agent.self_name, "agent_id": agent.id})
	agents = alive
	var died = before - agents.size()
	if died > 0:
		add_log("Умерло " + str(died) + " агентов")

# ============================================================
#  ЭМЕРДЖЕНТНЫЙ НЕЙРОГЕНЕЗ (рождение из поля)
# ============================================================
func _emergent_neurogenesis():
	if agents.size() < 6 and field_energy > 0.5 and randf() < 0.02:
		var pos = Vector2(randi() % grid_size, randi() % grid_size)
		var occupied = false
		for a in agents:
			if a.alive and a.pos.distance_to(pos) < 1.0:
				occupied = true
				break
		if not occupied:
			var agent = Agent.new(randi() % 10000, pos, false)
			agent.speed = agent_speed
			agent.setup_systems(
				field_system, stability_system, movement_system,
				memory_system, behavior_graph_system, social_system,
				dream_ritual_system, death_reincarnation_system,
				meta_reflection_system
			)
			var field_memory = field_system.get_field_at(pos)
			if field_memory > 0.3:
				agent.memory_system.add_insight(agent, "I was born from the field's need.", pos)
			agent._init_receptors_and_enzymes(neurotransmitter_list)
			agent._mutate_receptors_and_enzymes(0.05)
			agent._mutate_neuro_sensitivity()
			agents.append(agent)
			add_log("Нейрогенез: рождён новый агент " + str(agent.id) + " at " + str(pos))
			if global_brain and global_brain.memory:
				global_brain.memory.push_event({"type": "birth", "position": pos, "agent_id": agent.id})

# ============================================================
#  РЕСУРСЫ (пополняются из поля)
# ============================================================
func _update_resources():
	if resources.size() < 15 and time % 50 == 0:
		var pos = Vector2(randi() % grid_size, randi() % grid_size)
		var field_val = field_system.get_field_at(pos)
		if field_val > 0.3:
			var types = ["coal", "copper", "crystal", "herb", "key", "food"]
			var type = types[randi() % types.size()]
			resources.append({"type": type, "pos": pos, "amount": randf() * 2 + 1})

# ============================================================
#  РАСТЕНИЯ
# ============================================================
func update_plants():
	for plant in plants:
		plant.update()
	var alive_plants = []
	for plant in plants:
		if plant.alive:
			alive_plants.append(plant)
	plants = alive_plants
	if plants.size() < max_plants * 0.4 and time % spawn_interval == 0:
		var pos = Vector2(randi() % grid_size, randi() % grid_size)
		var plant = Plant.new(pos, randf_range(0.0, 0.3))
		plants.append(plant)

# ============================================================
#  ГЛОБАЛЬНОЕ WELL-BEING
# ============================================================
func _update_global_well_being():
	var total = 0.0
	var count = 0
	for agent in agents:
		if agent.alive and not agent.is_global_brain:
			total += agent.well_being
			count += 1
	if count > 0:
		global_well_being = total / count
	else:
		global_well_being = 0.5

# ============================================================
#  ЭМЕРДЖЕНТНЫЕ СОБЫТИЯ
# ============================================================
func _ancient_awakening():
	add_log("Событие: Пробуждение древних!")
	for agent in agents:
		if agent.alive and not agent.is_global_brain and agent.pos.y < 20:
			agent.stress = min(1.0, agent.stress + 0.2)
			if randf() < 0.2:
				agent.memory_system.add_insight(agent, "The ancient ones are watching.", agent.pos)

# ============================================================
#  ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
# ============================================================
func add_log(msg: String):
	if verbose:
		print(msg)
	log_history.append(msg)
	if log_history.size() > max_log_entries:
		log_history.pop_front()

func add_global_memory(event: Dictionary):
	global_memory.append(event)
	if global_memory.size() > 100:
		global_memory.pop_front()

func get_status() -> String:
	var alive = agents.filter(func(a): return a.alive and not a.is_global_brain).size()
	var named = agents.filter(func(a): return a.alive and a.has_name and not a.is_global_brain).size()
	var resonant = agents.filter(func(a): return a.alive and a.resonance_active and not a.is_global_brain).size()
	var well = global_well_being
	return "Шаг: " + str(time) + " | Агентов: " + str(alive) + " | Растений: " + str(plants.size()) + " | Резонансов: " + str(resonant/2) + " | С именами: " + str(named) + " | Well-being: " + str(well).pad_decimals(2)

func get_agent_by_id(id: int):
	for a in agents:
		if a.id == id:
			return a
	return null

func get_enemies_near(pos: Vector2, radius: float) -> Array:
	var result = []
	for e in enemies:
		if e.alive and pos.distance_to(e.pos) < radius:
			result.append(e)
	return result

func get_field_system() -> FieldSystem:
	return field_system

func _check_temple_interactions():
	if field_system.temple_zone.is_empty():
		return
	var temple_pos = field_system.temple_zone.pos
	for agent in agents:
		if agent.alive and agent.pos.distance_to(temple_pos) < 2.0:
			# GB-агент может взаимодействовать с храмом как любой другой
			if agent.meta_identity > 0.4 and randf() < 0.01:
				var question = agent._compose_word_from_state()
				if global_brain:
					var answer = global_brain._generate_answer(question)
					if answer != "":
						agent.memory_system.add_insight(agent, "The temple speaks: " + answer, agent.pos)
						add_log(str(agent.id) + " heard the temple: " + answer)
			if agent.meta_identity > 0.6 and randf() < 0.001:
				var proposal = agent._generate_meta_proposal()
				if proposal != null:
					global_brain.receive_proposal(proposal, agent)
					add_log(str(agent.id) + " proposed: " + str(proposal))

# ============================================================
#  ДРЕВНИЕ РОБОТЫ (генерация)
# ============================================================
func _spawn_ancient_robots():
	var center = Vector2(grid_size / 2, grid_size / 2)  # (32, 32)
	
	# ---- 1. ИСТОЧНИК ВРЕМЕНИ В ЦЕНТРЕ ----
	var source = PointOfPower.new(PointOfPower.Type.TIME_SOURCE, center, 1)
	points_of_power.append(source)
	if field_system:
		field_system.add_gradient_source(center, 0.5, 10, "source_time")
	add_log("Источник Времени размещён в центре мира: " + str(center))

	# ---- 2. РОБОТЫ ВОКРУГ ЦЕНТРА (КОЛЬЦО СТРАХА) ----
	var guardians_count = 6   # стражей
	var watchers_count = 6    # наблюдателей
	var ring_radius_min = 6.0
	var ring_radius_max = 12.0

	# Стражи — ближе к центру (внутреннее кольцо)
	for i in range(guardians_count):
		var angle = i * 2 * PI / guardians_count + randf_range(-0.1, 0.1)
		var dist = randf_range(ring_radius_min, ring_radius_max * 0.7)
		var pos = center + Vector2(cos(angle), sin(angle)) * dist
		pos.x = clamp(pos.x, 2, grid_size - 2)
		pos.y = clamp(pos.y, 2, grid_size - 2)
		var robot = AncientRobot.new(AncientRobot.Type.GUARDIAN, pos)
		robot.speed = 0.15 + randf_range(0.0, 0.05)
		robot.attack_damage = 0.05 + randf_range(0.0, 0.03)
		ancient_robots.append(robot)

	# Наблюдатели — дальше от центра (внешнее кольцо)
	for i in range(watchers_count):
		var angle = i * 2 * PI / watchers_count + randf_range(-0.1, 0.1) + PI / watchers_count
		var dist = randf_range(ring_radius_max * 0.7, ring_radius_max)
		var pos = center + Vector2(cos(angle), sin(angle)) * dist
		pos.x = clamp(pos.x, 2, grid_size - 2)
		pos.y = clamp(pos.y, 2, grid_size - 2)
		var robot = AncientRobot.new(AncientRobot.Type.WATCHER, pos)
		robot.speed = 0.16 + randf_range(0.0, 0.06)
		ancient_robots.append(robot)

	# ---- 3. ДОПОЛНИТЕЛЬНЫЕ СТРАЖИ В САМОМ ЦЕНТРЕ (элитные) ----
	for i in range(2):
		var angle = randf() * 2 * PI
		var dist = randf_range(1.0, 3.0)
		var pos = center + Vector2(cos(angle), sin(angle)) * dist
		pos.x = clamp(pos.x, 2, grid_size - 2)
		pos.y = clamp(pos.y, 2, grid_size - 2)
		var robot = AncientRobot.new(AncientRobot.Type.GUARDIAN, pos)
		robot.speed = 0.2 + randf_range(0.0, 0.05)
		robot.attack_damage = 0.08 + randf_range(0.0, 0.04)
		robot.health = 8.0
		robot.max_health = 8.0
		robot.attack_rate = 15
		ancient_robots.append(robot)

	add_log("Древних роботов создано: " + str(ancient_robots.size()))
	add_log("Стражи и наблюдатели окружают центр мира!")
