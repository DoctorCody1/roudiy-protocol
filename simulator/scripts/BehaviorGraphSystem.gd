extends RefCounted
class_name BehaviorGraphSystem

# ============================================================
#  КОНСТАНТЫ
# ============================================================
const MAX_GRAPH_STATES: int = 10
const BASE_STATES = ["idle", "explore", "hungry", "danger", "tired"]
const STATE_PRIORITIES = {
	"danger": 100,
	"hungry": 80,
	"tired": 70,
	"explore": 50,
	"idle": 10
}
const INNOVATION_COOLDOWN: int = 30
# Добавить новые константы
const INERTIA_CHANCE: float = 0.3    # 30% шанс остаться в текущем состоянии
const NOISE_CHANCE: float = 0.1      # 10% шанс выбрать случайное действие
# ============================================================
#  ИНИЦИАЛИЗАЦИЯ
# ============================================================
func init_agent(agent):
	agent.behavior_graph = _create_default_graph()
	agent.current_state = "idle"
	agent.graph_version = 1
	agent.graph_memory = []
	agent.invented_states = []
	agent.state_effectiveness = {}
	agent.state_usage = {}
	agent.graph_innovation_cooldown = 0
	agent.graph_analysis_cooldown = 0
	agent.has_imitated = false
	agent.copied_actions = []

func _create_default_graph() -> Dictionary:
	return {
		"idle": {"action": "wait", "next": "idle", "condition": "true"},
		"explore": {"action": "explore", "next": "hungry", "condition": "energy > 0.4"},
		"hungry": {"action": "find_food", "next": "explore", "condition": "energy < 0.5"},
		"danger": {"action": "flee", "next": "idle", "condition": "danger_near"},
		"tired": {"action": "rest", "next": "idle", "condition": "stress > 0.7"}
	}

# ============================================================
#  ОСНОВНОЙ МЕТОД ОБНОВЛЕНИЯ (ВЫЗЫВАЕТСЯ ПОСЛЕ ДВИЖЕНИЯ)
# ============================================================
func update_agent(agent, delta: float):
	# 1. Охлаждение инноваций
	if agent.graph_innovation_cooldown > 0:
		agent.graph_innovation_cooldown -= 1
	if agent.graph_analysis_cooldown > 0:
		agent.graph_analysis_cooldown -= 1
	
	# 2. Выбираем состояние на основе текущего контекста
	var new_state = _determine_state(agent)
	
	# 3. Если состояние изменилось, применяем его
	if new_state != agent.current_state:
		agent.current_state = new_state
		# Обновляем usage
		agent.state_usage[new_state] = agent.state_usage.get(new_state, 0) + 1
		# Записываем в effectiveness (для оценки)
		if not agent.state_effectiveness.has(new_state):
			agent.state_effectiveness[new_state] = {"usage": 0, "energy_gain": 0.0, "stress_reduction": 0.0}
		agent.state_effectiveness[new_state]["usage"] += 1
		
		# Применяем модификаторы состояния (если есть)
		_apply_state_modifiers(agent, new_state)
		
		# Логируем смену состояния
		if agent.has_name and randf() < 0.1:
			SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") entered state: " + new_state)
	
	# 4. Обновляем effectiveness на основе изменений энергии и стресса (отслеживаем в MovementSystem и StabilitySystem)
	# Это делается в _apply_state_modifiers и при вызове извне
	
	# 5. Проверяем, не пора ли создать новое состояние (из инсайта или творчества)
	if agent.creative_immunity > 0.3 and agent.graph_innovation_cooldown <= 0 and randf() < 0.01:
		_create_state_from_insight(agent)

# ============================================================
#  ОПРЕДЕЛЕНИЕ СОСТОЯНИЯ (ПАССИВНОЕ, НА ОСНОВЕ КОНТЕКСТА)
# ============================================================
# Добавить новые константы


# В _determine_state() добавить инерцию
func _determine_state(agent) -> String:
	var candidates = []
	if _danger_near(agent) or agent.is_unsafe:
		candidates.append("danger")
	if agent.is_hungry:
		candidates.append("hungry")
	if agent.is_tired:
		candidates.append("tired")
	if agent.curiosity > 0.7 and agent.energy > agent.max_energy * 0.5 and not agent.is_hungry and not agent.is_tired:
		candidates.append("explore")
	candidates.append("idle")
	
	# Вычисляем вероятности для каждого состояния
	var probabilities = {}
	var total = 0.0
	for state in candidates:
		var priority = STATE_PRIORITIES.get(state, 0)
		# Смещение: чем сильнее потребность, тем выше приоритет
		var distance = 1.0
		match state:
			"hungry":
				distance = agent.hunger / agent.hunger_threshold
			"tired":
				distance = agent.fatigue / agent.fatigue_threshold
			"danger":
				distance = 1.0 if _danger_near(agent) else 0.5
			"explore":
				distance = (agent.curiosity / 0.7) * (agent.energy / (agent.max_energy * 0.5))
			"idle":
				distance = 0.5
		var weight = priority * max(0.1, distance)
		probabilities[state] = weight
		total += weight
	
	if total == 0:
		return "idle"
	
	# Случайный выбор с весами (с шумом)
	var roll = randf() * total
	var cum = 0.0
	for state in candidates:
		cum += probabilities[state]
		if roll <= cum:
			# 10% шанс выбора случайного состояния (шум)
			if randf() < 0.1 and candidates.size() > 1:
				var other = candidates[randi() % candidates.size()]
				while other == state and candidates.size() > 1:
					other = candidates[randi() % candidates.size()]
				return other
			return state
	return "idle"

func _danger_near(agent) -> bool:
	for a in SimManager.instance.agents:
		if a.predator and a.alive and agent.pos.distance_to(a.pos) < 10:
			return true
	return false
func _get_word_effect(agent) -> String:
	# Проверяем последнее spoken_word или heard_word
	for entry in agent.memory.slice(-5):
		if entry.type == "spoken_word" or entry.type == "heard_word":
			var content = entry.content
			if "seek" in content:
				return "seek"
			elif "rest" in content:
				return "rest"
			elif "dig" in content:
				return "dig"
	return ""
# ============================================================
#  ПРИМЕНЕНИЕ МОДИФИКАТОРОВ СОСТОЯНИЯ
# ============================================================
func _apply_state_modifiers(agent, state_name: String):
	if not agent.behavior_graph.has(state_name):
		return
	var data = agent.behavior_graph[state_name]
	if not data.has("modifiers"):
		return
	var mods = data["modifiers"]
	
	# Применяем каждый модификатор
	if mods.has("energy_drain"):
		agent.energy = clamp(agent.energy + mods["energy_drain"], 0.0, agent.max_energy)
	if mods.has("stress_reduction"):
		agent.stress = max(0.0, agent.stress - mods["stress_reduction"])
	if mods.has("curiosity_boost"):
		agent.curiosity = min(1.0, agent.curiosity + mods["curiosity_boost"])
	if mods.has("speed_multiplier"):
		agent.speed_multiplier = mods["speed_multiplier"]
	# Прочие модификаторы можно добавить позже

# ============================================================
#  УПРАВЛЕНИЕ СОСТОЯНИЯМИ
# ============================================================
func add_state(agent, state_name: String, state_data: Dictionary):
	if agent.behavior_graph.has(state_name):
		return
	if agent.behavior_graph.size() >= MAX_GRAPH_STATES:
		# Удаляем самое неэффективное состояние (кроме базовых)
		_prune_ineffective_state(agent)
	agent.behavior_graph[state_name] = state_data
	if state_name not in agent.invented_states:
		agent.invented_states.append(state_name)
		agent.state_usage[state_name] = 0
	agent.graph_innovation_cooldown = INNOVATION_COOLDOWN
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") added state: " + state_name)

func _prune_ineffective_state(agent):
	var candidates = []
	for state in agent.behavior_graph.keys():
		if state in BASE_STATES:
			continue
		var eff = _evaluate_state(agent, state)
		if eff < 0.3:
			candidates.append(state)
	if candidates.is_empty():
		# Удаляем случайное небазовое состояние
		for state in agent.behavior_graph.keys():
			if state not in BASE_STATES:
				candidates.append(state)
				break
	if candidates.is_empty():
		return
	var to_remove = candidates[randi() % candidates.size()]
	agent.behavior_graph.erase(to_remove)
	if to_remove in agent.invented_states:
		agent.invented_states.erase(to_remove)

func _evaluate_state(agent, state_name: String) -> float:
	if not agent.state_effectiveness.has(state_name):
		return 0.0
	var data = agent.state_effectiveness[state_name]
	var usage = data["usage"]
	if usage == 0:
		return 0.0
	var avg_energy = data["energy_gain"] / usage
	var avg_stress = data["stress_reduction"] / usage
	var score = (avg_energy / agent.max_energy) * 0.5 + (avg_stress / 1.0) * 0.5
	return clamp(score, 0.0, 1.0)

# ============================================================
#  СОЗДАНИЕ НОВЫХ СОСТОЯНИЙ ИЗ ИНСАЙТОВ / ТВОРЧЕСТВА
# ============================================================
func _create_state_from_insight(agent):
	if not agent.memory_system:
		return
	var insights = agent.memory_system.get_recent_insights(agent, 1)
	if insights.is_empty():
		return
	var insight = insights[0]
	var words = insight.split(" ")
	var state_name = "insight_" + words[0] if words.size() > 0 else "insight_state"
	if agent.behavior_graph.has(state_name):
		return
	var action = "wait"
	if "explore" in insight or "see" in insight:
		action = "explore"
	elif "help" in insight or "share" in insight:
		action = "socialize"
	elif "rest" in insight or "sleep" in insight:
		action = "rest"
	elif "eat" in insight or "food" in insight:
		action = "find_food"
	var state_data = {
		"action": action,
		"next": "idle",
		"condition": "true",
		"modifiers": {
			"stress_reduction": 0.02 + randf() * 0.03,
			"curiosity_boost": 0.01 + randf() * 0.02
		}
	}
	add_state(agent, state_name, state_data)
	agent.creative_immunity = min(1.0, agent.creative_immunity + 0.05)
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") created state from insight: " + state_name)

# ============================================================
#  МУТАЦИЯ ГРАФА (ЭВОЛЮЦИЯ)
# ============================================================
func mutate_graph(agent):
	if agent.graph_innovation_cooldown > 0:
		return
	if agent.creative_immunity < 0.4:
		return
	if agent.behavior_graph.is_empty():
		return
	
	var new_graph = agent.behavior_graph.duplicate()
	var states = new_graph.keys()
	
	# 1. Удаляем неэффективные состояния (кроме базовых)
	var to_remove = []
	for state in states:
		if state in BASE_STATES:
			continue
		if _evaluate_state(agent, state) < 0.3 and agent.state_usage.get(state, 0) > 2:
			to_remove.append(state)
	for state in to_remove:
		new_graph.erase(state)
		if state in agent.invented_states:
			agent.invented_states.erase(state)
	
	# 2. Изменяем действия в неэффективных состояниях
	for state in states:
		if state in BASE_STATES:
			continue
		if new_graph.has(state) and randf() < 0.2:
			var actions = ["wait", "explore", "find_food", "rest", "socialize"]
			new_graph[state]["action"] = actions[randi() % actions.size()]
	
	# 3. Добавляем комбинированные состояния из эффективных
	var effective_states = []
	for state in states:
		if _evaluate_state(agent, state) > 0.6:
			effective_states.append(state)
	if effective_states.size() >= 2 and randf() < 0.2:
		var s1 = effective_states[randi() % effective_states.size()]
		var s2 = effective_states[randi() % effective_states.size()]
		if s1 != s2:
			var new_state = s1 + "_then_" + s2
			if not new_graph.has(new_state) and new_graph.size() < MAX_GRAPH_STATES:
				var data = {
					"action": new_graph[s1].get("action", "wait") + "_then_" + new_graph[s2].get("action", "wait"),
					"next": "idle",
					"condition": "true",
					"modifiers": _generate_random_modifiers()
				}
				add_state(agent, new_state, data)
	
	# 4. Сохраняем старый граф в историю
	agent.graph_memory.append({"graph": agent.behavior_graph.duplicate(), "time": SimManager.instance.time})
	if agent.graph_memory.size() > 10:
		agent.graph_memory.pop_front()
	
	# 5. Принимаем новый граф
	agent.behavior_graph = new_graph
	agent.graph_version += 1
	agent.creative_immunity = max(0.0, agent.creative_immunity - 0.1)
	agent.graph_innovation_cooldown = INNOVATION_COOLDOWN
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") mutated graph (v" + str(agent.graph_version) + ")")

func _generate_random_modifiers() -> Dictionary:
	var mods = {}
	if randf() < 0.3:
		mods["stress_reduction"] = 0.02 + randf() * 0.05
	if randf() < 0.3:
		mods["curiosity_boost"] = 0.01 + randf() * 0.03
	if randf() < 0.3:
		mods["energy_drain"] = -0.01 - randf() * 0.02
	return mods

# ============================================================
#  ПОЛУЧЕНИЕ ГРАФА ОТ ДРУГОГО АГЕНТА (СОЦИАЛЬНОЕ НАУЧЕНИЕ)
# ============================================================
func receive_graph(agent, graph: Dictionary, sender):
	if graph.is_empty() or not sender.alive:
		return
	# Оценка полученного графа (простая эвристика)
	var their_score = 0.0
	var count = graph.size()
	for state in graph.keys():
		var data = graph[state]
		if data.has("action"): their_score += 0.5
		if data.has("next"): their_score += 0.3
		if data.has("modifiers"): their_score += 0.2
	their_score = their_score / max(1, count)
	
	# Сравниваем со своим
	var my_score = 0.0
	count = agent.behavior_graph.size()
	for state in agent.behavior_graph.keys():
		var data = agent.behavior_graph[state]
		if data.has("action"): my_score += 0.5
		if data.has("next"): my_score += 0.3
		if data.has("modifiers"): my_score += 0.2
	my_score = my_score / max(1, count)
	
	# Учитываем доверие
	var trust_factor = agent.trust.get(sender.id, 0.0) + agent.trust_bonus
	their_score *= (1.0 + trust_factor * 0.2)
	
	if their_score > my_score and agent.creative_immunity > 0.2:
		# Принимаем граф
		agent.graph_memory.append({"graph": agent.behavior_graph.duplicate(), "time": SimManager.instance.time})
		if agent.graph_memory.size() > 10:
			agent.graph_memory.pop_front()
		agent.behavior_graph = graph.duplicate()
		agent.graph_version += 1
		if agent.has_name:
			SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") adopted graph from " + str(sender.id))
		# Добавляем новые состояния в изобретения
		for state in agent.behavior_graph.keys():
			if state not in BASE_STATES and state not in agent.invented_states:
				agent.invented_states.append(state)
