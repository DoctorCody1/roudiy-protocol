extends Agent
class_name GlobalBrainAgent

# ---- ФЛАГИ (is_global_brain наследуется от Agent, не объявляем повторно) ----
var is_collapsed: bool = false
var collapse_timer: int = 0
var collapse_duration: int = 10

# ---- СУПЕРПОЗИЦИЯ ----
var positions: Array = []          # массив Vector2
var position_weights: Array = []   # веса для каждой позиции (сумма = 1.0)
var min_positions: int = 3
var max_positions: int = 7

# ---- СЕМАНТИЧЕСКАЯ СЕТЬ (прокачанная) ----
var semantic_network: SemanticMemory = null
var global_word_vectors: Dictionary = {}   # { word: Array[float] }
var word_frequency: Dictionary = {}        # { word: int }

# ---- РЕЧЬ ----
var speech_cooldown: int = 0
var min_speech_interval: int = 10
var last_speech_time: int = 0
var speech_theme: String = "neutral"

func _init(agent_id: int, position: Vector2):
	super._init(agent_id, position, false)
	max_age = 999999
	energy = 999.0
	health = 999.0
	speed = 0.0
	hunger_rate = 0.0
	fatigue_rate = 0.0
	safety_decay_rate = 0.0
	meta_identity = 0.8
	is_global_brain = true   # устанавливаем флаг, унаследованный от Agent

	# Прокачанная семантическая сеть
	semantic_network = SemanticMemory.new()
	semantic_network.embedding_dim = 16
	semantic_network.learning_rate = 0.15

	# Инициализация позиций
	positions = [position]
	position_weights = [1.0]

func setup_systems(field, stability, movement, memory, behavior, social, dream, death, meta):
	super.setup_systems(field, stability, movement, memory, behavior, social, dream, death, meta)
	if SimManager.instance and SimManager.instance.global_brain:
		SimManager.instance.global_brain.agent_self = self

# ---- ОБНОВЛЕНИЕ ----
func update(delta: float = 1.0):
	if not alive:
		return

	# 1. Синхронизация с глобальным словарём
	if age % 10 == 0:
		_sync_with_global_brain()

	# 2. Суперпозиция
	if is_collapsed:
		collapse_timer -= 1
		if collapse_timer <= 0:
			is_collapsed = false
			_update_superposition()
		return

	_update_superposition()

	# 3. Когнитивные системы
	_update_subjective_time(delta)
	var dt = subjective_time_delta
	age += 1

	_update_neurochemistry(dt)

	if stability_system and field_system:
		stability_system.update_agent(self, field_system, dt)
	if memory_system:
		memory_system.update_agent(self, dt)
	if behavior_graph_system:
		behavior_graph_system.update_agent(self, dt)
	if social_system:
		social_system.update_agent(self, dt)
		social_system.update_shadow(self, dt)
	if dream_ritual_system:
		dream_ritual_system.update_agent(self, dt)
		dream_ritual_system.process_moment(self, dt)
	if meta_reflection_system:
		meta_reflection_system.update_agent(self, dt)

	# 4. GlobalBrain аналитика
	if SimManager.instance and SimManager.instance.global_brain:
		SimManager.instance.global_brain.update(SimManager.instance.agents, SimManager.instance.time)

	# 5. Речь
	_try_speak()

	# 6. История
	state_history.append({
		"energy": energy, "stress": stress, "mood": mood,
		"hunger": hunger, "fatigue": fatigue, "health": health,
		"curiosity": curiosity, "meta_identity": meta_identity, "age": age
	})
	if state_history.size() > STATE_HISTORY_LENGTH:
		state_history.pop_front()

# ---- СУПЕРПОЗИЦИЯ ----
func _update_superposition():
	if is_collapsed:
		return
	if not SimManager.instance:
		return

	var agents = SimManager.instance.agents
	var total_pos = Vector2.ZERO
	var total_weight = 0.0
	var count = 0

	for agent in agents:
		if agent == self or not agent.alive or agent.is_global_brain:
			continue
		var weight = 0.5 + 0.5 * (agent.meta_identity * 0.6 + agent.curiosity * 0.4)
		total_pos += agent.pos * weight
		total_weight += weight
		count += 1

	if count == 0:
		return

	var new_pos = total_pos / total_weight

	# Обновляем суперпозицию
	var min_dist = 999.0
	for p in positions:
		var d = p.distance_to(new_pos)
		if d < min_dist:
			min_dist = d

	if min_dist > 2.0 and positions.size() < max_positions:
		positions.append(new_pos)
		position_weights.append(0.1)
	else:
		var best_idx = 0
		var best_dist = 999.0
		for i in range(positions.size()):
			var d = positions[i].distance_to(new_pos)
			if d < best_dist:
				best_dist = d
				best_idx = i
		positions[best_idx] = positions[best_idx].lerp(new_pos, 0.1)

	# Обновляем веса
	var new_weights = []
	for i in range(positions.size()):
		var dist = positions[i].distance_to(new_pos)
		var w = 1.0 / (1.0 + dist * 0.5)
		new_weights.append(w)
	var total_w = 0.0
	for w in new_weights:
		total_w += w
	if total_w > 0:
		for i in range(new_weights.size()):
			new_weights[i] /= total_w
	position_weights = new_weights

	while positions.size() > max_positions:
		var min_idx = 0
		var min_w = 999.0
		for i in range(position_weights.size()):
			if position_weights[i] < min_w:
				min_w = position_weights[i]
				min_idx = i
		positions.remove_at(min_idx)
		position_weights.remove_at(min_idx)

	# Основная позиция
	var main_pos = Vector2.ZERO
	for i in range(positions.size()):
		main_pos += positions[i] * position_weights[i]
	pos = main_pos

# ---- КОЛЛАПС ----
func collapse_to(pos: Vector2, duration: int = 10):
	is_collapsed = true
	collapse_timer = duration
	positions = [pos]
	position_weights = [1.0]
	self.pos = pos
	SimManager.instance.add_log("[GlobalBrainAgent] Collapsed to " + str(pos) + " for " + str(duration) + " steps")

func restore_superposition():
	is_collapsed = false
	collapse_timer = 0
	_update_superposition()
	SimManager.instance.add_log("[GlobalBrainAgent] Superposition restored")

# ---- СЕМАНТИЧЕСКАЯ СИНХРОНИЗАЦИЯ ----
func _sync_with_global_brain():
	if not SimManager.instance or not SimManager.instance.global_brain:
		return
	var gb = SimManager.instance.global_brain
	for word in gb.vocabulary:
		if not semantic_network.memory.has(word):
			semantic_network.memory[word] = semantic_network._create_random_vector()
		if not global_word_vectors.has(word):
			global_word_vectors[word] = semantic_network.memory[word]
		word_frequency[word] = word_frequency.get(word, 0) + 1

func _get_current_theme() -> String:
	if not SimManager.instance or not SimManager.instance.global_brain:
		return "neutral"
	var gb = SimManager.instance.global_brain
	if gb.entropy > 0.6:
		return "chaos"
	elif gb.mood < 0.3:
		return "sadness"
	elif gb.entropy > 0.6:
		return "chaos"
	elif gb.mood > 0.7:
		return "joy"
	elif gb.mood < 0.3:
		return "sadness"
	elif gb.resonance_with_self > 0.8:
		return "reflection"
	else:
		return "neutral"

func _select_word_by_theme(candidates: Array, theme: String) -> String:
	var themed_words = []
	for word in candidates:
		if theme in word:
			themed_words.append(word)
	if not themed_words.is_empty():
		return themed_words[randi() % themed_words.size()]
	return candidates[randi() % candidates.size()]

# ---- РЕЧЬ ----
func _try_speak():
	if speech_cooldown > 0:
		speech_cooldown -= 1
		return
	if not SimManager.instance or not SimManager.instance.global_brain:
		return
	var gb = SimManager.instance.global_brain
	if gb.entropy > 0.4 or gb.mood < 0.3:
		var word = _generate_speech()
		if word != "":
			_propagate_word_from_superposition(word)
			speech_cooldown = min_speech_interval + randi() % 10
			last_speech_time = SimManager.instance.time

func _generate_speech() -> String:
	if not SimManager.instance or not SimManager.instance.global_brain:
		return ""
	var gb = SimManager.instance.global_brain
	var words = gb.vocabulary.duplicate()
	if words.size() < 3:
		return ""

	# 1. Тема и кандидаты
	speech_theme = _get_current_theme()
	var candidates = []
	for word in words:
		if word in semantic_network.memory:
			candidates.append(word)

	if candidates.size() < 3:
		return "_".join(words.slice(0, 3))

	# 2. Стартовое слово
	var start_word = _select_word_by_theme(candidates, speech_theme)

	# 3. Семантическая марковская цепь
	var phrase = [start_word]
	var max_length = randi_range(4, 7)
	var attempts = 0
	while phrase.size() < max_length and attempts < 20:
		attempts += 1
		var last_word = phrase[-1]
		if last_word not in semantic_network.memory:
			break
		var last_vec = semantic_network.memory[last_word]

		var similar = []
		for word in candidates:
			if word == last_word or word in phrase:
				continue
			var vec = semantic_network.memory[word]
			var sim = semantic_network.cosine_similarity(last_vec, vec)
			if sim > 0.1:
				similar.append({"word": word, "sim": sim})

		if similar.is_empty():
			break

		var total_sim = 0.0
		for s in similar:
			total_sim += s.sim
		if total_sim == 0.0:
			break
		var roll = randf() * total_sim
		var cum = 0.0
		var chosen = similar[-1].word
		for s in similar:
			cum += s.sim
			if roll <= cum:
				chosen = s.word
				break
		phrase.append(chosen)

	return "_".join(phrase)

# ---- РАСПРОСТРАНЕНИЕ РЕЧИ ИЗ СУПЕРПОЗИЦИИ ----
func _propagate_word_from_superposition(word: String):
	var sim = SimManager.instance
	if not sim:
		return

	var impact = 0.2 + mood * 0.1 + curiosity * 0.05
	if word.ends_with("?"): impact *= 1.5

	# Влияние на поле из всех позиций
	if field_system:
		var amp = impact * 0.15
		var radius = 3
		for p in positions:
			for dx in range(-radius, radius + 1):
				for dy in range(-radius, radius + 1):
					var pos = p + Vector2(dx, dy)
					var dist = Vector2(dx, dy).length()
					if dist < radius:
						field_system.set_field_at(pos, field_system.get_field_at(pos) + amp * (1.0 - dist / radius))

	# Обновление семантики говорящего
	if semantic_network:
		var ctx = _get_context_vector()
		semantic_network.update(word, ctx, 0.1)

	var speech_range = _social_params.speech_range * (0.8 + 0.4 * curiosity)

	# Собираем агентов в радиусе от любой позиции
	var affected = []
	for other in sim.agents:
		if other == self or not other.alive or other.is_global_brain:
			continue
		var min_dist = 999.0
		for p in positions:
			var d = p.distance_to(other.pos)
			if d < min_dist:
				min_dist = d
		if min_dist > speech_range:
			continue
		affected.append({"agent": other, "dist": min_dist})

	# Обработка
	for entry in affected:
		var other = entry.agent
		var dist = entry.dist
		var proximity = 1.0 - dist / speech_range
		var response = impact * proximity

		other.curiosity = min(1.0, other.curiosity + response * 0.02)
		other.stress = max(0.0, other.stress - response * 0.01)

		# Мутация слова через SocialSystem
		var received_word = word
		if randf() < 0.1 * response and social_system:
			var mutated = social_system._mutate_word_by_perception(word, other)
			if mutated != word:
				received_word = mutated
				var hash = other._get_state_hash() if other.has_method("_get_state_hash") else ""
				if hash != "":
					other.language_memory[hash] = mutated
				if other.memory_system:
					other.memory_system.add_event(other, "heard_word", mutated, other.pos)

		# Обновление семантической памяти слушающего
		if other.semantic_memory and response > 0.1:
			var ctx_other = other._get_context_vector() if other.has_method("_get_context_vector") else []
			other.semantic_memory.update(received_word, ctx_other, 0.05 * response)

	# Логирование
	var display = word if not word.ends_with("?") else word + " (question)"
	SimManager.instance.add_log(str(id) + " (GlobalBrain) says: '" + display + "' from superposition")
# GlobalBrainAgent.gd (добавить)
func teleport_to(target_pos: Vector2):
	if not is_global_brain:
		return
	
	# След в старой точке
	if field_system:
		field_system.create_rupture(pos)
		field_system.add_long_term_trace(pos, "presence", 0.2)
	
	# Перемещение
	pos = target_pos
	if positions.size() > 1:
		positions = [target_pos]
		position_weights = [1.0]
	
	# Волна прибытия
	if field_system:
		var radius = 4
		var amplitude = 0.3
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var p = target_pos + Vector2(dx, dy)
				var dist = Vector2(dx, dy).length()
				if dist > radius: continue
				var influence = amplitude * (1.0 - dist / radius)
				field_system.set_field_at(p, field_system.get_field_at(p) + influence)
		field_system.add_long_term_trace(target_pos, "arrival", 0.5)
	
	# Генерация фразы из состояния (не шаблонная)
	var phrase = _generate_teleport_phrase()
	if phrase != "" and phrase != " ":
		_say_phrase(phrase)
	else:
		# Если ничего не сгенерировалось — используем дефолт из состояния
		var gb = SimManager.instance.global_brain
		if gb:
			phrase = gb._generate_grammatical_insight()
			if phrase != "" and phrase != " ":
				_say_phrase(phrase)
	
	# Лог
	if phrase != "":
		SimManager.instance.add_log("[GlobalBrain] " + phrase + " (at " + str(target_pos) + ")")

# Генерация фразы из состояния Глобального Мозга
func _generate_teleport_phrase() -> String:
	var gb = SimManager.instance.global_brain
	if not gb:
		return ""
	# Используем существующий метод, который генерирует фразу из состояния
	var phrase = gb._generate_grammatical_insight()
	if phrase != "" and phrase != " ":
		return phrase
	# Если не вышло — используем слова из vocabulary
	if not gb.vocabulary.is_empty():
		var words = gb.vocabulary.duplicate()
		words.shuffle()
		var word1 = words[0] if words.size() > 0 else "silence"
		var word2 = words[1] if words.size() > 1 else "being"
		var templates = [
			"I am " + word1,
			"I feel " + word1 + " and " + word2,
			"This place is " + word1,
			"I see " + word1,
		]
		return templates[randi() % templates.size()]
	return "I am here."

# Произнести фразу (распространить в поле и агентам)
func _say_phrase(phrase: String):
	if social_system:
		_propagate_word_from_superposition(phrase)
	if memory_system:
		memory_system.add_event(self, "spoken_word", phrase, pos)
