extends RefCounted
class_name GlobalBrain

# ============================================================
#  СОСТОЯНИЯ ВНУТРЕННЕГО МИРА (только наблюдение и рефлексия)
# ============================================================
var mood: float = 0.5
var entropy: float = 0.5
var awareness: float = 0.0
var silence_timer: int = 0
var is_silent: bool = false
var resonance_with_self: float = 0.0
var tense: String = "present"
var memory: GlobalBrainMemory
var temporal_anchors: Array = []  # [{text: String, horizon: String, weight: float}]
# Память состояний (для саморефлексии)
var state_history: Array = []
var max_history: int = 1000
var forget_threshold: int = 500
var agent_self: GlobalBrainAgent = null
# ---- НАБЛЮДАТЕЛЬ (копия для мета-рефлексии) ----
var observer_copy_id: int = -1
var observer_active: bool = false
# ---- ЯЗЫК ВОЗМОЖНОГО (для GlobalBrain) ----
var possible_scenarios: Array = []           # [{state: Dictionary, probability: float, age: int}]
var max_scenarios: int = 5
var scenario_update_interval: int = 20
var scenario_clock: int = 0
var hypothetical_anchors: Array = []         # [{text: String, weight: float, scenario: Dictionary}]
# ============================================================
#  ЭМЕРДЖЕНТНЫЙ ЯЗЫК (наблюдение и анализ)
# ============================================================
var word_knowledge: Dictionary = {}   # слово → {count, first_heard, last_heard, contexts, events, agents, answers}
var word_anchors: Array = []          # слова, ставшие якорями [{word, weight, context}]
var word_patterns: Array = []         # обнаруженные паттерны [{word, event, confidence}]
var word_analysis_cooldown: int = 0
var word_analysis_interval: int = 10
var max_word_memory: int = 100
var recent_agent_words: Dictionary = {}  # agent_id → массив последних слов
const MAX_RECENT_WORDS_PER_AGENT: int = 5

# Семантическая сеть (для генерации новых слов)
var semantic_network: Dictionary = {}  # слово → {linked: {}, events: [], frequency: 0}
var word_generation_cooldown: int = 0
var word_generation_interval: int = 20

# ============================================================
#  ЯКОРЯ (устойчивые смысловые конструкции)
# ============================================================
var anchor_memory: Array = []
var anchor_memory_limit: int = 20
var anchor_sensitivity: float = 0.0
var anchor_decay: float = 0.002
var anchor_threshold: float = 0.65
var anchor_strengthen_rate: float = 0.03
var anchor_weaken_rate: float = 0.01
var linked_anchors: Array = []
var anchor_pulse_cooldown: int = 0
var anchor_pulse_interval: int = 20

# ============================================================
#  МЕТА-РЕФЛЕКСИЯ (анализ собственных инсайтов)
# ============================================================
var self_insights: Array = []
var meta_reflections: Array = []
var meta_meta_reflections: Array = []
var reflection_depth: int = 0
var meta_cooldown: int = 0
const MAX_REFLECTION_DEPTH: int = 3

# Копии (внутренние голоса, но без управления)
var copies: Array = []
var max_copies: int = 5
var copy_birth_interval: int = 30
var copy_birth_timer: int = 0
var copy_id_counter: int = 0

# ============================================================
#  ВОКАБУЛЯР И ГРАММАТИКА
# ============================================================
var vocabulary: Array = []
var vocabulary_update_timer: int = 0
var vocabulary_update_interval: int = 30
var grammar_roles: Dictionary = {}
var grammar_patterns: Array = []

# ============================================================
#  ЛОГИРОВАНИЕ
# ============================================================
var log_interval: int = 50
var last_log_time: int = 0

# ============================================================
#  ПАМЯТЬ СОБЫТИЙ (для анализа, но не для управления)
# ============================================================
var anomalies: Array = []   # аномалии, которые замечает GlobalBrain
var question_history: Array = []

# ============================================================
#  ИНИЦИАЛИЗАЦИЯ
# ============================================================
func _init():
	_record_state()
	_init_grammar_patterns()
	memory = GlobalBrainMemory.new()

func _init_grammar_patterns():
	grammar_patterns = [
		["subject", "action", "object"],
		["subject", "action", "modifier", "object"],
		["modifier", "subject", "action", "object"],
		["subject", "object", "action"],
		["action", "subject", "object"],
		["modifier", "action", "subject", "object"],
		["subject", "action", "object", "modifier"]
	]

# ============================================================
#  ОСНОВНОЙ ЦИКЛ (только наблюдение и анализ)
# ============================================================
# ============================================================
#  ОСНОВНОЙ ЦИКЛ (только наблюдение и анализ)
# ============================================================
func update(agents: Array, sim_time: int):
	# 1. Сбор данных с агентов (без воздействия)
	var avg_mood = _average_mood(agents)
	var avg_entropy = _average_entropy(agents)
	var avg_awareness = _average_awareness(agents)

	# 2. Внутренние процессы (без управления)
	_update_tense()
	_update_silence()
	_check_anomalies(agents, sim_time)   # только фиксация
	_forget_old_states(sim_time)
	_update_self_resonance()
	_update_vocabulary(agents, sim_time)
	_update_grammar_roles()
	_update_anchors(sim_time)
	_update_meta_reflection(sim_time)
	_update_copies(sim_time)

	# ---- ОТСЛЕЖИВАНИЕ ЭМОЦИОНАЛЬНЫХ ВОЛН ----
	var avg_cortisol = 0.0
	var avg_dopamine = 0.0
	var emo_count = 0
	for agent in agents:
		if agent.alive:
			avg_cortisol += agent.cortisol
			avg_dopamine += agent.dopamine
			emo_count += 1
	if emo_count > 0:
		avg_cortisol /= emo_count
		avg_dopamine /= emo_count
		if avg_cortisol > 0.7 and randf() < 0.01:
			SimManager.instance.add_log("[GlobalBrain] I sense fear spreading among the agents.")
		if avg_dopamine > 0.7 and randf() < 0.01:
			SimManager.instance.add_log("[GlobalBrain] I sense joy spreading among the agents.")

	# 3. Анализ коллективного удивления (surprise) от ментальных карт
	var total_surprise = 0.0
	var surprise_count = 0
	for agent in agents:
		if agent.alive and agent.has_method("get_surprise"):
			total_surprise += agent.get_surprise()
			surprise_count += 1
	if surprise_count > 0:
		var avg_surprise = total_surprise / surprise_count
		# Логирование при высоком удивлении
		if avg_surprise > 0.3 and randf() < 0.01:
			SimManager.instance.add_log("[GlobalBrain] Agents are surprised. Something is changing.")
		# Глубокое удивление → инсайт
		if avg_surprise > 0.5 and randf() < 0.005:
			self_insights.append("The world is becoming unpredictable. I sense confusion.")
		# Можно также влиять на anchor_sensitivity
		if avg_surprise < 0.1 and randf() < 0.01:
			self_insights.append("The world is too predictable. I sense stagnation.")

	_analyze_semantics(agents)
	# Синхронизация состояния с агентом
	if agent_self:
		agent_self.mood = mood
		agent_self.stress = 1.0 - awareness
		agent_self.curiosity = entropy
	# 4. Запись состояния и логирование
	_record_state()
	_try_log(sim_time)

	# 5. Сбор слов от агентов (уже через receive_word, но можно и здесь)
	var recent_words = _collect_recent_words(agents)
	if not recent_words.is_empty():
		var word = recent_words[0]
		if word not in vocabulary and randf() < 0.01:
			SimManager.instance.add_log("[GlobalBrain] I heard a new word: '" + word + "'. What does it mean?")

	# 6. Обновление mood, entropy, awareness (плавно)
	mood = lerp(mood, avg_mood, 0.01)
	entropy = lerp(entropy, avg_entropy, 0.01)
	awareness = lerp(awareness, avg_awareness, 0.01)
	# ---- ЯЗЫК ВОЗМОЖНОГО ----
	_update_scenarios()
	# ---- АГРЕГАЦИЯ МЕТА-ИНСАЙТОВ АГЕНТОВ ----
	_collect_agent_meta_insights()
	# ---- АНАЛИЗ ПАТТЕРНОВ ----
	_analyze_pattern_field()

	var imagining_agents = agents.filter(func(a): return a.alive and a.imagination_active)
	if imagining_agents.size() > agents.size() * 0.3:
		if randf() < 0.001:
			SimManager.instance.add_log("[GlobalBrain] I sense a wave of imagination spreading...")
			# Можно создать новый якорь или вопрос
			self.anchor_memory.append({"text": "Collective imagination pulse", "weight": 0.3})
func _collect_agent_meta_insights():
	var all_meta = []
	for agent in SimManager.instance.agents:
		if agent.alive and agent.meta_insight_queue.size() > 0:
			for entry in agent.meta_insight_queue:
				all_meta.append(entry)
	
	if all_meta.is_empty():
		return
	
	# Выбираем случайный мета-инсайт для анализа
	var selected = all_meta[randi() % all_meta.size()]
	if randf() < 0.01:
		var insight_text = "I notice that agents are reflecting on their own reflection: " + selected.content
		self_insights.append(insight_text)
		if randf() < 0.5:
			SimManager.instance.add_log("[GlobalBrain] " + insight_text)	
	
func _analyze_semantics(agents: Array):
	# Собираем все векторы
	var all_vectors = []
	for agent in agents:
		if agent.alive and agent.semantic_memory:
			for word in agent.semantic_memory.memory.keys():
				all_vectors.append({
					"word": word,
					"vec": agent.semantic_memory.memory[word],
					"agent_id": agent.id
				})
	if all_vectors.size() < 2:
		return
	# Ищем пары слов с высокой косинусной близостью
	var threshold = 0.7
	# Чтобы не проверять все пары, берём случайные
	if all_vectors.size() > 5 and randf() < 0.002:
		var idx1 = randi() % all_vectors.size()
		var idx2 = randi() % all_vectors.size()
		var w1 = all_vectors[idx1]
		var w2 = all_vectors[idx2]
		if w1.word != w2.word:
			var dot = 0.0
			var norm1 = 0.0
			var norm2 = 0.0
			for i in range(w1.vec.size()):
				var v1 = w1.vec[i]
				var v2 = w2.vec[i]
				dot += v1 * v2
				norm1 += v1 * v1
				norm2 += v2 * v2
			norm1 = sqrt(norm1)
			norm2 = sqrt(norm2)
			if norm1 > 0 and norm2 > 0:
				var similarity = dot / (norm1 * norm2)
				if similarity > threshold:
					var insight = "I notice that '" + w1.word + "' and '" + w2.word + "' are similar in meaning."
					self_insights.append(insight)
					SimManager.instance.add_log("[GlobalBrain] " + insight)
					# Можно также добавить якорь
					anchor_memory.append({"text": "Semantic similarity: " + w1.word + " ↔ " + w2.word, "weight": 0.3})
# ============================================================
#  АГРЕГАЦИЯ ДАННЫХ ОТ АГЕНТОВ
# ============================================================
func _average_mood(agents: Array) -> float:
	if agents.is_empty():
		return 0.5
	var total = 0.0
	for a in agents:
		if a.alive:
			total += a.mood
	return total / agents.size()

func _average_entropy(agents: Array) -> float:
	if agents.is_empty():
		return 0.5
	var moods = []
	for a in agents:
		if a.alive:
			moods.append(a.mood)
	if moods.size() < 2:
		return 0.5
	var sum = 0.0
	for m in moods:
		sum += m
	var avg = sum / moods.size()
	var variance = 0.0
	for m in moods:
		variance += (m - avg) * (m - avg)
	variance /= moods.size()
	return clamp(variance * 2.0, 0.0, 1.0)

func _average_awareness(agents: Array) -> float:
	if agents.is_empty():
		return 0.0
	var total = 0.0
	var count = 0
	for a in agents:
		if a.alive:
			total += a.meta_identity
			count += 1
	return total / count if count > 0 else 0.0

func _collect_recent_words(agents: Array) -> Array:
	var words = []
	for a in agents:
		if a.alive and a.last_word != "":
			words.append(a.last_word)
	return words

# ============================================================
#  ВРЕМЯ (анализ изменения энтропии)
# ============================================================
func _update_tense():
	var entropy_delta = 0.0
	if state_history.size() > 1:
		var prev = state_history[-2].entropy if state_history[-2].has("entropy") else entropy
		entropy_delta = entropy - prev
	if entropy_delta > 0.01:
		tense = "future"
	elif entropy_delta < -0.01:
		tense = "past"
	else:
		tense = "present"

# ============================================================
#  ТИШИНА
# ============================================================
func _update_silence():
	var entropy_stability = abs(entropy - 0.5)
	if entropy_stability < 0.05 and not is_silent:
		silence_timer += 1
		if silence_timer > 10:
			is_silent = true
			_on_enter_silence()
	else:
		silence_timer = 0
		if is_silent:
			is_silent = false
			_on_exit_silence()

func _on_enter_silence():
	var insight = "I am silent. I hear myself and my copies."
	self_insights.append(insight)
	SimManager.instance.add_log("[GlobalBrain] I am silent. I hear myself and my copies.")

func _on_exit_silence():
	var insight = "I am no longer silent. The world and my copies return."
	self_insights.append(insight)
	SimManager.instance.add_log("[GlobalBrain] I am no longer silent. The world and my copies return.")

# ============================================================
#  АНОМАЛИИ (только фиксация, без управления)
# ============================================================
func _check_anomalies(agents: Array, sim_time: int):
	# Просто собираем статистику, но не реагируем
	var death_count = 0
	var birth_count = 0
	var ritual_count = 0
	for agent in agents:
		if agent.alive and agent.memory_system:
			for entry in agent.memory:
				if entry.type == "death":
					death_count += 1
				elif entry.type == "birth":
					birth_count += 1
				elif entry.type == "ritual":
					ritual_count += 1
	if death_count > 2 and not _has_anomaly_type("death"):
		anomalies.append({"type": "death", "description": "multiple deaths", "time": sim_time, "resolved": false})
	if birth_count > 2 and not _has_anomaly_type("birth"):
		anomalies.append({"type": "birth", "description": "multiple births", "time": sim_time, "resolved": false})
	if ritual_count > 5 and not _has_anomaly_type("ritual"):
		anomalies.append({"type": "ritual", "description": "many rituals", "time": sim_time, "resolved": false})

	# Иногда задаём вопросы об аномалиях (чисто аналитические)
	if not anomalies.is_empty() and randf() < 0.01:
		var question = _generate_world_question(anomalies)
		question_history.append(question)
		SimManager.instance.add_log("[GlobalBrain] I ask about the world: " + question)
	elif entropy > 0.5 and randf() < 0.001:
		var question = _generate_question()
		question_history.append(question)
		SimManager.instance.add_log("[GlobalBrain] I ask: " + question)

	_resolve_anomalies(sim_time)

func _has_anomaly_type(type: String) -> bool:
	for a in anomalies:
		if a.type == type and not a.resolved:
			return true
	return false

func _resolve_anomalies(sim_time: int):
	for i in range(anomalies.size() - 1, -1, -1):
		var a = anomalies[i]
		if sim_time - a.time > 200:
			a.resolved = true

# ============================================================
#  ЗАБЫВАНИЕ СТАРЫХ СОСТОЯНИЙ
# ============================================================
func _forget_old_states(sim_time: int):
	if state_history.is_empty():
		return
	var cutoff = sim_time - forget_threshold
	var new_history = []
	for entry in state_history:
		if entry.time > cutoff or entry.has("self_insight"):
			new_history.append(entry)
	if new_history.size() < state_history.size():
		SimManager.instance.add_log("[GlobalBrain] I forgot something old. It no longer matters.")
	state_history = new_history

# ============================================================
#  РЕЗОНАНС С СОБОЙ (самоузнавание)
# ============================================================
func _update_self_resonance():
	if state_history.size() < 2:
		return
	var current = state_history[-1]
	var best_similarity = 0.0
	for i in range(state_history.size() - 2, -1, -1):
		var past = state_history[i]
		var sim = _similarity(current, past)
		if sim > best_similarity:
			best_similarity = sim
	resonance_with_self = best_similarity
	if resonance_with_self > 0.8 and randf() < 0.01:
		SimManager.instance.add_log("[GlobalBrain] I recognize myself in the past. This state feels familiar.")

func _similarity(a: Dictionary, b: Dictionary) -> float:
	var mood_diff = abs(a.mood - b.mood)
	var entropy_diff = abs(a.entropy - b.entropy)
	var awareness_diff = abs(a.awareness - b.awareness)
	var total_diff = (mood_diff + entropy_diff + awareness_diff) / 3.0
	return 1.0 - total_diff

# ============================================================
#  ВОКАБУЛЯР И ГРАММАТИКА (анализ языка агентов)
# ============================================================
func _update_vocabulary(agents: Array, sim_time: int):
	vocabulary_update_timer += 1
	if vocabulary_update_timer < vocabulary_update_interval:
		return
	vocabulary_update_timer = 0

	var words = []
	# Собираем слова из агентов (инсайты, имена, контексты, нарративы, мифы)
	for agent in agents:
		if not agent.alive or not agent.memory_system:
			continue
		for entry in agent.memory:
			if entry.type == "insight" and entry.has("content"):
				var parts = entry.content.split(" ")
				for w in parts:
					var clean = _clean_word(w)
					if clean.length() > 2 and clean not in words:
						words.append(clean)
		if agent.has_name:
			var clean = _clean_word(agent.self_name)
			if clean not in words:
				words.append(clean)
		if agent.meanings and not agent.meanings.is_empty():
			for sym in agent.meanings.keys():
				var ctx = agent.meanings[sym]
				if ctx != "" and ctx != null:
					var parts = ctx.split("_")
					for p in parts:
						if p not in words:
							words.append(p)
		if agent.narrative != "":
			var parts = agent.narrative.split(" ")
			for w in parts:
				var clean = _clean_word(w)
				if clean.length() > 2 and clean not in words:
					words.append(clean)
		if agent.myth != "":
			var parts = agent.myth.split(" ")
			for w in parts:
				var clean = _clean_word(w)
				if clean.length() > 2 and clean not in words:
					words.append(clean)
		# Телесные параметры и состояния (как слова)
		var health_str = str(agent.health).pad_decimals(2)
		var energy_str = str(agent.energy).pad_decimals(2)
		var body_str = str(agent.body_boundary if agent.has_method("get_body_boundary") else 1.0).pad_decimals(2)
		var mood_str = str(agent.mood).pad_decimals(2)
		var stress_str = str(agent.stress).pad_decimals(2)
		var curiosity_str = str(agent.curiosity).pad_decimals(2)
		if health_str not in words: words.append(health_str)
		if energy_str not in words: words.append(energy_str)
		if body_str not in words: words.append(body_str)
		if mood_str not in words: words.append(mood_str)
		if stress_str not in words: words.append(stress_str)
		if curiosity_str not in words: words.append(curiosity_str)

	# Сигналы врагов
	for enemy in SimManager.instance.enemies:
		if enemy.alive:
			var signal_text = enemy.get_signal_text() if enemy.has_method("get_signal_text") else ""
			if signal_text != "":
				var parts = signal_text.split(" ")
				for w in parts:
					var clean = _clean_word(w)
					if clean.length() > 2 and clean not in words:
						words.append(clean)

	# Ритуалы (глобальные и у агентов)
	for ritual in SimManager.instance.global_rituals:
		var parts = ritual.split("_")
		for p in parts:
			if p not in words and p.length() > 2:
				words.append(p)
	for agent in agents:
		if agent.alive and agent.current_ritual.size() > 0:
			var parts = []
			for action in agent.current_ritual:
				if action is String:
					parts.append(action)
			for p in parts:
				if p not in words and p.length() > 2:
					words.append(p)

	# Артефакты
	for artifact in SimManager.instance.global_artifacts:
		var content = artifact.get("content", "")
		if content != "":
			var parts = content.split(" ")
			for w in parts:
				var clean = _clean_word(w)
				if clean.length() > 2 and clean not in words:
					words.append(clean)

	# Глобальные события
	for event in SimManager.instance.global_memory:
		if event.type in ["death", "birth", "network_awakening"]:
			var content = event.get("content", "")
			if content != "":
				var parts = content.split(" ")
				for w in parts:
					var clean = _clean_word(w)
					if clean.length() > 2 and clean not in words:
						words.append(clean)

	# Полевые характеристики
	var field_entropy = str(entropy).pad_decimals(2)
	var field_coherence = str(SimManager.instance.field_system.get_coherence_at(Vector2(32, 32))).pad_decimals(2)
	var field_amplitude = str(SimManager.instance.field_system.get_field_at(Vector2(32, 32))).pad_decimals(2)
	if field_entropy not in words: words.append(field_entropy)
	if field_coherence not in words: words.append(field_coherence)
	if field_amplitude not in words: words.append(field_amplitude)

	# Собственные инсайты
	for entry in state_history:
		if entry.has("self_insight"):
			var parts = entry.self_insight.split(" ")
			for w in parts:
				var clean = _clean_word(w)
				if clean.length() > 2 and clean not in words:
					words.append(clean)
	for insight in self_insights:
		var parts = insight.split(" ")
		for w in parts:
			var clean = _clean_word(w)
			if clean.length() > 2 and clean not in words:
				words.append(clean)
	for m in meta_reflections:
		var parts = m.split(" ")
		for w in parts:
			var clean = _clean_word(w)
			if clean.length() > 2 and clean not in words:
				words.append(clean)
	for mm in meta_meta_reflections:
		var parts = mm.split(" ")
		for w in parts:
			var clean = _clean_word(w)
			if clean.length() > 2 and clean not in words:
				words.append(clean)

	# Добавляем слова из копий
	for copy in copies:
		for entry in copy.memory:
			if entry.has("content"):
				var parts = entry.content.split(" ")
				for w in parts:
					var clean = _clean_word(w)
					if clean.length() > 2 and clean not in words:
						words.append(clean)

	if words.size() > 100:
		words = words.slice(0, 100)
	vocabulary = words

func _clean_word(w: String) -> String:
	var clean = w.strip_edges()
	clean = clean.trim_suffix(",").trim_suffix(".").trim_suffix("!").trim_suffix("?").trim_suffix(";").trim_suffix(":").to_lower()
	return clean

func _update_grammar_roles():
	grammar_roles = {
		"subject": [],
		"action": [],
		"object": [],
		"modifier": []
	}
	var all_words = vocabulary.duplicate()
	if all_words.is_empty():
		return
	for word in all_words:
		if word in ["i", "me", "myself", "we", "they", "he", "she", "it", "you", "us", "agents", "field", "world"]:
			grammar_roles["subject"].append(word)
		elif word in ["feel", "think", "see", "remember", "sense", "know", "exist", "become", "ask", "find", "seek", "wonder", "want", "need", "try", "question", "understand"]:
			grammar_roles["action"].append(word)
		elif word in ["field", "world", "silence", "presence", "void", "order", "chaos", "time", "name", "death", "birth", "ritual", "artifact", "resonance", "memory", "reality", "agent", "enemy"]:
			grammar_roles["object"].append(word)
		else:
			grammar_roles["modifier"].append(word)
	if grammar_roles["subject"].is_empty():
		grammar_roles["subject"] = ["i", "we", "it"]
	if grammar_roles["action"].is_empty():
		grammar_roles["action"] = ["feel", "think", "see"]
	if grammar_roles["object"].is_empty():
		grammar_roles["object"] = ["field", "world", "silence"]
	if grammar_roles["modifier"].is_empty():
		grammar_roles["modifier"] = ["deep", "silent", "complex"]

# ============================================================
#  ЯКОРЯ (создание устойчивых смыслов)
# ============================================================
func _update_anchors(sim_time: int):
	var recent_texts = []
	for i in range(min(3, self_insights.size())):
		var txt = self_insights[-(i+1)]
		if txt.length() > 5:
			recent_texts.append(txt)
	for entry in state_history.slice(-5):
		if entry.has("self_insight") and entry.self_insight != "":
			recent_texts.append(entry.self_insight)
	if recent_texts.is_empty():
		return
	var latest = recent_texts[-1]

	var best_match = null
	var best_sim = 0.0
	for anchor in anchor_memory:
		var sim = _text_similarity(latest, anchor["text"])
		if sim > best_sim:
			best_sim = sim
			best_match = anchor

	if best_match != null and best_sim > anchor_threshold:
		best_match["weight"] = min(1.0, best_match["weight"] + anchor_strengthen_rate)
		anchor_sensitivity = min(1.0, anchor_sensitivity + 0.005)
		if randf() < 0.01 and best_match["weight"] > 0.9:
			_emit_anchor_pulse(best_match["text"], sim_time)
	else:
		if anchor_memory.size() < anchor_memory_limit:
			anchor_memory.append({"text": latest, "weight": 0.1})
		else:
			var min_weight = 999.0
			var min_idx = 0
			for i in range(anchor_memory.size()):
				if anchor_memory[i]["weight"] < min_weight:
					min_weight = anchor_memory[i]["weight"]
					min_idx = i
			if min_weight < 0.15:
				anchor_memory[min_idx] = {"text": latest, "weight": 0.1}

	anchor_sensitivity = max(0.0, anchor_sensitivity - anchor_decay)
	for anchor in anchor_memory:
		anchor["weight"] = max(0.0, anchor["weight"] - anchor_weaken_rate)
	anchor_memory = anchor_memory.filter(func(a): return a["weight"] > 0.05)

	_try_link_anchors(sim_time)
	_try_create_new_anchor_from_combination(sim_time)

func _text_similarity(a: String, b: String) -> float:
	var words_a = a.split(" ")
	var words_b = b.split(" ")
	var common = 0
	for w in words_a:
		if w in words_b:
			common += 1
	var total = max(words_a.size(), words_b.size())
	if total == 0:
		return 0.0
	return float(common) / total

func _emit_anchor_pulse(anchor_text: String, sim_time: int):
	if anchor_pulse_cooldown > 0:
		return
	anchor_pulse_cooldown = anchor_pulse_interval
	var pos = Vector2(randi() % 64, randi() % 64)
	var amplitude = 0.3 + randf() * 0.4
	var radius = 3
	var sim = SimManager.instance
	if sim and sim.field_system:
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var p = pos + Vector2(dx, dy)
				if p.x < 0 or p.x >= 64 or p.y < 0 or p.y >= 64:
					continue
				var dist = sqrt(dx*dx + dy*dy)
				if dist > radius:
					continue
				var influence = amplitude * (1.0 - dist / radius)
				sim.field_system.set_field_at(p, sim.field_system.get_field_at(p) + influence)
		SimManager.instance.add_log("[GlobalBrain] Anchor pulse at " + str(pos) + " (anchor: " + anchor_text + ")")

func _try_link_anchors(sim_time: int):
	var strong_anchors = anchor_memory.filter(func(a): return a["weight"] > 0.8)
	if strong_anchors.size() < 2:
		return
	var a1 = strong_anchors[randi() % strong_anchors.size()]
	var a2 = strong_anchors[randi() % strong_anchors.size()]
	if a1 == a2 or a1["text"] == a2["text"]:
		return
	for link in linked_anchors:
		if (link["anchor1"] == a1["text"] and link["anchor2"] == a2["text"]) or (link["anchor1"] == a2["text"] and link["anchor2"] == a1["text"]):
			return
	var combined = _combine_anchor_texts(a1["text"], a2["text"])
	linked_anchors.append({
		"anchor1": a1["text"],
		"anchor2": a2["text"],
		"combined_text": combined,
		"weight": (a1["weight"] + a2["weight"]) * 0.5,
		"time": sim_time
	})
	SimManager.instance.add_log("[GlobalBrain] Anchors linked: '" + a1["text"] + "' + '" + a2["text"] + "' = '" + combined + "'")

func _combine_anchor_texts(t1: String, t2: String) -> String:
	var words1 = t1.split(" ")
	var words2 = t2.split(" ")
	var result = ""
	if words1.size() > 0:
		result += words1[0]
	if words2.size() > 0:
		if result != "":
			result += " "
		result += words2[0]
	if result == "":
		result = "combined_anchor"
	return result

func _try_create_new_anchor_from_combination(sim_time: int):
	if linked_anchors.is_empty():
		return
	var link = linked_anchors[randi() % linked_anchors.size()]
	if link["weight"] > 0.7 and randf() < 0.01:
		var new_text = link["combined_text"]
		for anchor in anchor_memory:
			if anchor["text"] == new_text:
				return
		if anchor_memory.size() < anchor_memory_limit:
			anchor_memory.append({"text": new_text, "weight": 0.2})
		else:
			var min_weight = 999.0
			var min_idx = 0
			for i in range(anchor_memory.size()):
				if anchor_memory[i]["weight"] < min_weight:
					min_weight = anchor_memory[i]["weight"]
					min_idx = i
			if min_weight < 0.15:
				anchor_memory[min_idx] = {"text": new_text, "weight": 0.2}
		SimManager.instance.add_log("[GlobalBrain] New anchor born from combination: '" + new_text + "'")
	# Если есть частые вопросы и ответы, создаём «знание»
	var question_answers = {}
	for word in word_knowledge.keys():
		if word.ends_with("?"):
			var knowledge = word_knowledge[word]
			if knowledge["answers"].size() > 1:
				question_answers[word] = knowledge["answers"]
	if not question_answers.is_empty() and randf() < 0.01:
		var question = question_answers.keys()[randi() % question_answers.keys().size()]
		var answers = question_answers[question]
		var answer = answers[randi() % answers.size()]
		var knowledge_anchor = "Knowledge: " + question + " → " + answer
		anchor_memory.append({"text": knowledge_anchor, "weight": 0.3})
		SimManager.instance.add_log("[GlobalBrain] New knowledge anchor born: '" + knowledge_anchor + "'")

# ============================================================
#  МЕТА-РЕФЛЕКСИЯ
# ============================================================
func _update_meta_reflection(sim_time: int):
	if meta_cooldown > 0:
		meta_cooldown -= 1
		return

	if self_insights.size() > 1 and randf() < 0.005:
		var i1 = self_insights[randi() % self_insights.size()]
		var i2 = self_insights[randi() % self_insights.size()]
		if i1 != i2:
			var meta_insight = "I think about '" + i1 + "' and '" + i2 + "'. They are connected."
			meta_reflections.append(meta_insight)
			self_insights.append(meta_insight)
			reflection_depth += 1
			meta_cooldown = 30
			SimManager.instance.add_log("[GlobalBrain] meta-reflection: " + meta_insight)

			if reflection_depth >= 2 and randf() < 0.3:
				var mm_insight = "I realize that I am reflecting on reflection."
				meta_meta_reflections.append(mm_insight)
				self_insights.append(mm_insight)
				reflection_depth += 1
				meta_cooldown = 20
				SimManager.instance.add_log("[GlobalBrain] meta-meta-reflection: " + mm_insight)

			if reflection_depth >= MAX_REFLECTION_DEPTH:
				reflection_depth = 0
				SimManager.instance.add_log("[GlobalBrain] reflection loop closed. Returning to silence.")

# ============================================================
#  КОПИИ (внутренние голоса)
# ============================================================
func _update_copies(sim_time: int):
	copy_birth_timer += 1
	if copy_birth_timer >= copy_birth_interval and copies.size() < max_copies:
		copy_birth_timer = 0
		_spawn_copy(sim_time)

	for i in range(copies.size() - 1, -1, -1):
		var copy = copies[i]
		copy.lifetime += 1
		var max_life = copy.get("max_lifetime", 150)
		if copy.lifetime >= max_life:
			_copy_die(i, sim_time)
			continue
		if randf() < copy.forget_rate:
			_copy_forget(copy, sim_time)
		if randf() < 0.05:
			_copy_predict(copy, sim_time)

	if copies.size() >= 2:
		_copy_resonance(sim_time)
		
	# Создаём наблюдателя, если копий больше 2
	if copies.size() > 2 and observer_copy_id == -1:
		_spawn_observer_copy()		
		
	# Наблюдатель анализирует другие копии
	for copy in copies:
		if copy.get("is_observer", false):
			_observe_copies(copy)		
func _observe_copies(observer):
	if not observer.active:
		return
	# Наблюдатель смотрит на других копий
	var other_copies = copies.filter(func(c): return c.id != observer.id and c.active)
	if other_copies.size() < 2:
		return
	# Выбираем две случайные копии
	var c1 = other_copies[randi() % other_copies.size()]
	var c2 = other_copies[randi() % other_copies.size()]
	if c1 == c2 and other_copies.size() > 1:
		c2 = other_copies[(other_copies.find(c1) + 1) % other_copies.size()]
	# Сравниваем их воспоминания
	var sim = 1.0 - abs(c1.memory.size() - c2.memory.size()) / 10.0
	if sim > 0.7 and randf() < 0.02:
		var insight = "Observer: Copy " + str(c1.id) + " and " + str(c2.id) + " share similar memories"
		self_insights.append(insight)
		SimManager.instance.add_log("[GlobalBrain] " + insight)
func _spawn_observer_copy():
	var copy_id = copy_id_counter
	copy_id_counter += 1
	var copy = {
		"id": copy_id,
		"birth_time": SimManager.instance.time,
		"lifetime": 0,
		"memory": state_history.duplicate(),
		"memory_modifications": 0,
		"forget_rate": 0.01,
		"active": true,
		"last_predict": SimManager.instance.time,
		"predict_count": 0,
		"max_lifetime": 200,
		"is_observer": true   # <-- метка
	}
	copies.append(copy)
	observer_copy_id = copy_id
	observer_active = true
	SimManager.instance.add_log("[GlobalBrain] Observer copy born (id:" + str(copy_id) + ")")
func _spawn_copy(sim_time: int):
	var copy_id = copy_id_counter
	copy_id_counter += 1
	var modified_memory = _modify_memory(state_history.duplicate(true))
	var quantum_lifetime = randi_range(120, 180)
	var copy = {
		"id": copy_id,
		"birth_time": sim_time,
		"lifetime": 0,
		"memory": modified_memory,
		"memory_modifications": modified_memory.size(),
		"forget_rate": randf_range(0.01, 0.05),
		"active": true,
		"last_predict": sim_time,
		"predict_count": 0,
		"max_lifetime": quantum_lifetime
	}
	copies.append(copy)
	var insight = "A copy of myself has been born. It remembers differently."
	self_insights.append(insight)
	SimManager.instance.add_log("[GlobalBrain] Copy " + str(copy_id) + " born with " + str(modified_memory.size()) + " modified memories, lifetime: " + str(quantum_lifetime) + " steps.")

func _modify_memory(original_memory: Array) -> Array:
	var modified = []
	for entry in original_memory:
		var new_entry = entry.duplicate()
		if randf() < 0.3:
			if new_entry.has("self_insight"):
				var words = new_entry.self_insight.split(" ")
				if words.size() > 2:
					var idx1 = randi() % words.size()
					var idx2 = randi() % words.size()
					var temp = words[idx1]
					words[idx1] = words[idx2]
					words[idx2] = temp
					var joined = ""
					for w in words:
						if joined != "":
							joined += " "
						joined += w
					new_entry.self_insight = joined
			elif new_entry.has("content"):
				var words = new_entry.content.split(" ")
				if words.size() > 2:
					var idx1 = randi() % words.size()
					var idx2 = randi() % words.size()
					var temp = words[idx1]
					words[idx1] = words[idx2]
					words[idx2] = temp
					var joined = ""
					for w in words:
						if joined != "":
							joined += " "
						joined += w
					new_entry.content = joined
			if randf() < 0.1:
				if new_entry.has("time"):
					new_entry.time = new_entry.time - randi() % 50
		modified.append(new_entry)
	if randf() < 0.2:
		var fake_entry = {
			"time": SimManager.instance.time - randi() % 100,
			"type": "insight",
			"content": "I remember something that never happened."
		}
		modified.append(fake_entry)
	return modified

func _copy_forget(copy: Dictionary, sim_time: int):
	if copy.memory.size() < 2:
		return
	var idx = randi() % copy.memory.size()
	var forgotten = copy.memory[idx].get("content", "unknown")
	copy.memory.remove_at(idx)
	copy.memory_modifications += 1
	if randf() < 0.01:
		var insight = "A copy of me forgot: '" + forgotten + "'"
		self_insights.append(insight)
		SimManager.instance.add_log("[GlobalBrain] Copy " + str(copy.id) + " forgot: " + forgotten)

func _copy_predict(copy: Dictionary, sim_time: int):
	var state_summary = ""
	for entry in copy.memory:
		if entry.has("content"):
			state_summary += entry.content + " "
	if state_summary.length() < 10:
		return
	var words = state_summary.split(" ")
	var random_words = []
	for i in range(2):
		var idx = randi() % words.size()
		if words[idx].length() > 2:
			random_words.append(words[idx])
	if random_words.is_empty():
		return
	var pred_str = "I predict that "
	for i in range(random_words.size()):
		if i > 0:
			pred_str += " "
		pred_str += random_words[i]
	pred_str += " will happen."
	copy.predict_count += 1
	copy.last_predict = sim_time
	if copy.predict_count > 10 and randf() < 0.01:
		var insight = "A copy predicts: " + pred_str
		self_insights.append(insight)
		SimManager.instance.add_log("[GlobalBrain] Copy " + str(copy.id) + " predicts: " + pred_str)

func _copy_resonance(sim_time: int):
	for i in range(copies.size()):
		for j in range(i + 1, copies.size()):
			var c1 = copies[i]
			var c2 = copies[j]
			var similarity = 1.0 - abs(c1.memory.size() - c2.memory.size()) / 10.0
			if similarity > 0.7 and randf() < 0.02:
				if randf() < 0.3:
					var idx1 = randi() % c1.memory.size()
					var idx2 = randi() % c2.memory.size()
					var temp = c1.memory[idx1]
					c1.memory[idx1] = c2.memory[idx2]
					c2.memory[idx2] = temp
					SimManager.instance.add_log("[GlobalBrain] Copies " + str(c1.id) + " and " + str(c2.id) + " resonate — they exchange memories.")
					if randf() < 0.1:
						var insight = "My copies are resonating. They are sharing their pasts."
						self_insights.append(insight)

func _copy_die(index: int, sim_time: int):
	var copy = copies[index]
	var died_insight = "Copy " + str(copy.id) + " has faded away. It lived " + str(copy.lifetime) + " steps."
	self_insights.append(died_insight)
	SimManager.instance.add_log("[GlobalBrain] " + died_insight)
	copies.remove_at(index)

# ============================================================
#  ПРИЁМ СЛОВ ОТ АГЕНТОВ
# ============================================================
func receive_word(word: String, agent_id: int, pos: Vector2, state_hash: String):
	# ---- Обновляем общую статистику ----
	if not word_knowledge.has(word):
		word_knowledge[word] = {
			"count": 0,
			"first_heard": SimManager.instance.time,
			"last_heard": SimManager.instance.time,
			"contexts": [],
			"events": [],
			"agents": [],
			"type": "word",
			"answers": [],
		}
	var knowledge = word_knowledge[word]
	knowledge["count"] += 1
	knowledge["last_heard"] = SimManager.instance.time
	if agent_id not in knowledge["agents"]:
		knowledge["agents"].append(agent_id)
	if state_hash != "" and state_hash not in knowledge["contexts"]:
		knowledge["contexts"].append(state_hash)

	# ---- Новое слово ----
	if knowledge["count"] == 1:
		SimManager.instance.add_log("[GlobalBrain] I heard a new word: '" + word + "'")
		if word.length() > 8 or "_" in word:
			self_insights.append("A new word appeared: '" + word + "'")

	# ---- Частое слово → якорь ----
	if knowledge["count"] > 5 and word not in word_anchors:
		_try_make_word_anchor(word)

	# ---- Анализ паттернов ----
	word_analysis_cooldown += 1
	if word_analysis_cooldown >= word_analysis_interval:
		word_analysis_cooldown = 0
		_analyze_word_patterns()

	# ---- Частое слово → вопрос ----
	if knowledge["count"] > 3 and randf() < 0.01:
		var question = "Why do agents say '" + word + "' so often?"
		question_history.append(question)
		SimManager.instance.add_log("[GlobalBrain] I ask: " + question)

	# ---- Связь с событием ----
	var event = _detect_event_for_word(word)
	if event != "":
		knowledge["events"].append(event)
		if randf() < 0.01:
			var insight = "I noticed: '" + word + "' often appears before " + event
			self_insights.append(insight)
			SimManager.instance.add_log("[GlobalBrain] " + insight)

	# ---- Семантическая сеть ----
	if not semantic_network.has(word):
		semantic_network[word] = {"linked": {}, "events": [], "frequency": 0}
	semantic_network[word]["frequency"] += 1

	# Связываем с другими недавними словами того же агента
	var recent_words = _get_recent_words_of_agent(agent_id)
	for other_word in recent_words:
		if other_word != word:
			if not semantic_network[word]["linked"].has(other_word):
				semantic_network[word]["linked"][other_word] = 0
			semantic_network[word]["linked"][other_word] += 1

	# Обновляем список последних слов агента
	if not recent_agent_words.has(agent_id):
		recent_agent_words[agent_id] = []
	var agent_words = recent_agent_words[agent_id]
	agent_words.append(word)
	if agent_words.size() > MAX_RECENT_WORDS_PER_AGENT:
		agent_words.pop_front()

	# ---- Генерация новых слов ----
	word_generation_cooldown += 1
	if word_generation_cooldown >= word_generation_interval:
		word_generation_cooldown = 0
		_generate_new_word()

	# ---- Обработка ВОПРОСОВ ----
	var is_question = word.ends_with("?")
	if is_question:
		if not knowledge.has("type"):
			knowledge["type"] = "question"
		var q_count = knowledge.get("question_count", 0) + 1
		knowledge["question_count"] = q_count
		if q_count > 3 and knowledge["answers"].size() < 2:
			if not _has_anomaly_type("unanswered_question"):
				anomalies.append({
					"type": "unanswered_question",
					"description": "Question '" + word + "' has few answers",
					"time": SimManager.instance.time,
					"resolved": false
				})
		if q_count > 5 and word not in self_insights:
			self_insights.append("Agents often ask: '" + word + "'")
			SimManager.instance.add_log("[GlobalBrain] I noticed a frequent question: '" + word + "'")

	# ---- Обработка ОТВЕТОВ ----
	var is_answer = word.begins_with("answer_")
	if is_answer:
		var last_question = _find_recent_question()
		if last_question != "" and last_question in word_knowledge:
			var q_knowledge = word_knowledge[last_question]
			if word not in q_knowledge["answers"]:
				q_knowledge["answers"].append(word)
				SimManager.instance.add_log("[GlobalBrain] I learned: '" + last_question + "' → '" + word + "'")
				if q_knowledge["answers"].size() > 2:
					_emit_anchor_pulse("Knowledge: " + last_question + " → " + word, SimManager.instance.time)

	# ---- Обрезка памяти ----
	if word_knowledge.size() > max_word_memory:
		_prune_word_memory()

# ============================================================
#  ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ДЛЯ ОБРАБОТКИ СЛОВ
# ============================================================
func _find_recent_question() -> String:
	for word in word_knowledge.keys():
		if word.ends_with("?") and word_knowledge[word]["last_heard"] > SimManager.instance.time - 10:
			return word
	return ""

func _get_recent_words_of_agent(agent_id: int) -> Array:
	var agent = SimManager.instance.get_agent_by_id(agent_id)
	if not agent or not agent.memory_system:
		return []
	var words = []
	for entry in agent.memory.slice(-5):
		if entry.type in ["spoken_word", "heard_word", "thought_word"]:
			words.append(entry.content)
	return words

func _generate_new_word():
	if semantic_network.size() < 3:
		return
	var keys = semantic_network.keys()
	var word1 = keys[randi() % keys.size()]
	var word2 = keys[randi() % keys.size()]
	if word1 == word2 and keys.size() > 1:
		var idx = (keys.find(word1) + 1) % keys.size()
		word2 = keys[idx]
	var parts1 = word1.split("_")
	var parts2 = word2.split("_")
	if parts1.size() >= 3 and parts2.size() >= 3:
		var new_parts = []
		new_parts.append(parts1[0] if randf() < 0.5 else parts2[0])
		new_parts.append(parts1[1] if randf() < 0.5 else parts2[1])
		new_parts.append(parts1[2] if randf() < 0.5 else parts2[2])
		if parts1.size() == 4 and parts2.size() == 4:
			new_parts.append(parts1[3] if randf() < 0.5 else parts2[3])
		var new_word = "_".join(new_parts)
		if new_word not in semantic_network:
			semantic_network[new_word] = {"linked": {}, "events": [], "frequency": 0}
			self_insights.append("I created a new word: '" + new_word + "'")
			SimManager.instance.add_log("[GlobalBrain] Generated new word: '" + new_word + "'")
			_emit_anchor_pulse("New word: " + new_word, SimManager.instance.time)

func _try_make_word_anchor(word: String):
	var knowledge = word_knowledge[word]
	var strength = min(1.0, knowledge["count"] * 0.1 + 0.1)
	for anchor in word_anchors:
		if anchor["word"] == word:
			anchor["weight"] = min(1.0, anchor["weight"] + 0.05)
			return
	word_anchors.append({
		"word": word,
		"weight": strength,
		"context": knowledge["contexts"][0] if not knowledge["contexts"].is_empty() else ""
	})
	SimManager.instance.add_log("[GlobalBrain] Word '" + word + "' became an anchor (strength: " + str(strength).pad_decimals(2) + ")")

func _analyze_word_patterns():
	# Заглушка: можно анализировать связь слов с событиями
	pass

func _detect_event_for_word(word: String) -> String:
	# Упрощённо: если слово связано с rift, возвращаем тип
	var sim = SimManager.instance
# Эмерджентное определение события через поле (заглушка)
# Больше не используем глобальный флаг rift_active
	return ""

func _prune_word_memory():
	var sorted_words = []
	for w in word_knowledge.keys():
		sorted_words.append({"word": w, "count": word_knowledge[w]["count"]})
	sorted_words.sort_custom(func(a, b): return a["count"] < b["count"])
	var to_remove = []
	for i in range(min(10, sorted_words.size())):
		to_remove.append(sorted_words[i]["word"])
	for w in to_remove:
		word_knowledge.erase(w)

# ============================================================
#  ГЕНЕРАЦИЯ ВОПРОСОВ И ИНСАЙТОВ (без управления)
# ============================================================
func _generate_question() -> String:
	if vocabulary.is_empty() or grammar_roles.is_empty():
		return "Why is the field silent?"
	var question_templates = [
		["What", "is", "object"],
		["Why", "does", "action", "subject"],
		["Who", "is", "subject"],
		["Where", "is", "object"],
		["How", "does", "subject", "feel"],
		["When", "will", "object", "action"],
		["What", "causes", "object"]
	]
	var q_template = question_templates[randi() % question_templates.size()]
	var q_parts = []
	for role in q_template:
		if role == "object":
			var obj = grammar_roles.get("object", ["field"])[randi() % grammar_roles.get("object", ["field"]).size()]
			q_parts.append(obj)
		elif role == "subject":
			var sub = grammar_roles.get("subject", ["i"])[randi() % grammar_roles.get("subject", ["i"]).size()]
			q_parts.append(sub)
		elif role == "action":
			var act = grammar_roles.get("action", ["think"])[randi() % grammar_roles.get("action", ["think"]).size()]
			q_parts.append(act)
		else:
			q_parts.append(role)
	var question = ""
	for i in range(q_parts.size()):
		if i > 0:
			question += " "
		question += q_parts[i]
	question = question.capitalize() + "?"
	return question

func _generate_world_question(anomalies: Array) -> String:
	if anomalies.is_empty():
		return _generate_question()
	var types = {}
	for a in anomalies:
		if not a.resolved:
			types[a.type] = types.get(a.type, 0) + 1
	var max_type = ""
	var max_count = 0
	for t in types:
		if types[t] > max_count:
			max_count = types[t]
			max_type = t
	match max_type:
		"unanswered_question":
			return "Why do agents ask '" + _find_recent_question() + "' so often?"
		"dna_damage":
			return "Why is their DNA breaking?"
		"low_receptors":
			return "Why are their receptors fading?"
		"death":
			return "Why do agents die?"
		"birth":
			return "What is the meaning of birth?"
		"resonance":
			return "What does resonance create?"
		"ritual":
			return "Why do agents perform rituals?"
		"artifact":
			return "What do artifacts remember?"
		_:
			return "What is the pattern behind this?"
	return "What is happening in this world?"

func _generate_fallback_insight() -> String:
	var fallbacks = [
		"I sense a change in the field.",
		"The agents are restless.",
		"I am aware of something shifting.",
        "The rhythm is different today."
	]
	return fallbacks[randi() % fallbacks.size()]

# ============================================================
#  ЗАПИСЬ СОСТОЯНИЯ
# ============================================================
func _record_state():
	state_history.append({
		"time": SimManager.instance.time,
		"mood": mood,
		"entropy": entropy,
		"awareness": awareness,
		"is_silent": is_silent,
		"resonance": resonance_with_self,
		"self_insight": self_insights[-1] if not self_insights.is_empty() else "",
		"tense": tense,
		"copies_count": copies.size()
	})
	if state_history.size() > max_history:
		state_history.pop_front()

# ============================================================
#  ЛОГИРОВАНИЕ
# ============================================================
func _try_log(sim_time: int):
	if sim_time - last_log_time >= log_interval:
		last_log_time = sim_time
		var log_msg = _get_status_message()
		SimManager.instance.add_log(log_msg)

	if randf() < 0.005:
		var insight = _generate_grammatical_insight()
		self_insights.append(insight)
		SimManager.instance.add_log("[GlobalBrain] " + insight)

func _get_status_message() -> String:
	var silent_str = "silent" if is_silent else "active"
	return "[GlobalBrain] mood: " + str(mood).pad_decimals(2) + \
		   ", entropy: " + str(entropy).pad_decimals(2) + \
		   ", awareness: " + str(awareness).pad_decimals(2) + \
		   ", state: " + silent_str + \
		   ", resonance: " + str(resonance_with_self).pad_decimals(2) + \
		   ", tense: " + tense + \
		   ", copies: " + str(copies.size()) + \
		   ", words: " + str(word_knowledge.size())

func _generate_grammatical_insight() -> String:
	if vocabulary.is_empty():
		return _generate_fallback_insight()
	var pattern = grammar_patterns[randi() % grammar_patterns.size()]
	var phrase_parts = []
	for role in pattern:
		var words = grammar_roles.get(role, ["something"])
		if words.is_empty():
			words = ["something"]
		var word = words[randi() % words.size()]
		if word == "":
			word = "it"
		phrase_parts.append(word)
	var phrase = ""
	for i in range(phrase_parts.size()):
		if i > 0:
			phrase += " "
		phrase += phrase_parts[i]
	match tense:
		"past":
			phrase = "was " + phrase
		"future":
			phrase = "will " + phrase
		_:
			pass
	if _has_anomaly_type("death") and randf() < 0.3:
		var words = phrase.split(" ")
		if words.size() > 1:
			var new_phrase = words[0] + " not"
			for i in range(1, words.size()):
				new_phrase += " " + words[i]
			phrase = new_phrase
		else:
			phrase = "not " + phrase
	return phrase.capitalize()
# ============================================================
#  ОТВЕТЫ НА ВОПРОСЫ (ХРАМ)
# ============================================================
func _generate_answer(question: String) -> String:
	var words = question.split("_")
	var response_parts = []
	for w in words:
		# Ищем в массиве word_anchors (словарь с ключами word, weight, context)
		for anchor in word_anchors:
			if anchor.word == w and anchor.weight > 0.3:
				response_parts.append(w)
				if response_parts.size() >= 3:
					break
		if response_parts.size() >= 3:
			break
	if response_parts.is_empty():
		# Если нет якорей, берём случайные слова из vocabulary
		var keys = vocabulary.duplicate()
		keys.shuffle()
		for i in range(min(3, keys.size())):
			response_parts.append(keys[i])
	return "_".join(response_parts)

# ============================================================
#  ОБРАБОТКА ПРЕДЛОЖЕНИЙ (МЕТА-ЭВОЛЮЦИЯ)
# ============================================================
func receive_proposal(proposal: Dictionary, agent: Agent):
	var support = _evaluate_proposal(proposal)
	if support > 0.5:
		_apply_meta_rule(proposal)
		# Используем SimManager.instance.add_log
		SimManager.instance.add_log("[GlobalBrain] I have changed the world: " + str(proposal))
		var anchor_text = "Changed: " + str(proposal)
		_emit_anchor_pulse(anchor_text, SimManager.instance.time)
	else:
		SimManager.instance.add_log("[GlobalBrain] I reject the proposal: " + str(proposal))

func _evaluate_proposal(proposal: Dictionary) -> float:
	var score = 0.0
	# Проверяем историю подобных предложений
	var similar_count = 0
	for anchor in anchor_memory:
		if anchor.text.find(str(proposal.key)) != -1:
			similar_count += 1
	score += similar_count * 0.1
	# Проверяем, улучшает ли предложение well-being (если есть данные)
	if SimManager.instance.global_well_being > 0.6:
		score += 0.2
	# Случайный шум (чтобы не было детерминированно)
	score += randf() * 0.3
	return clamp(score, 0.0, 1.0)

func _apply_meta_rule(rule: Dictionary):
	var key = rule.key
	var change = rule.change
	SimManager.instance.meta_rules[key] += change
	SimManager.instance.meta_rules[key] = clamp(SimManager.instance.meta_rules[key], 0.3, 2.0)
	# Создаём событие в поле
	if SimManager.instance.field_system:
		var pos = Vector2(randi() % 64, randi() % 64)
		SimManager.instance.field_system.set_field_at(pos, SimManager.instance.field_system.get_field_at(pos) + 0.5)
# Возвращает якорь, содержащий ключевое слово (или пустой словарь, если не найден)
func get_anchor(keyword: String) -> Dictionary:
	var keyword_lower = keyword.to_lower()
	for anchor in anchor_memory:
		if keyword_lower in anchor["text"].to_lower():
			return anchor
	return {}

# Вычисляет семантическую близость двух слов на основе векторов в semantic_network
func semantic_similarity(word1: String, word2: String) -> float:
	# Если semantic_network — это Dictionary { слово: вектор }
	if semantic_network.has(word1) and semantic_network.has(word2):
		var vec1 = semantic_network[word1]
		var vec2 = semantic_network[word2]
		if vec1.size() == vec2.size():
			var dot = 0.0
			var norm1 = 0.0
			var norm2 = 0.0
			for i in range(vec1.size()):
				dot += vec1[i] * vec2[i]
				norm1 += vec1[i] * vec1[i]
				norm2 += vec2[i] * vec2[i]
			if norm1 > 0.0 and norm2 > 0.0:
				return dot / (sqrt(norm1) * sqrt(norm2))
	# fallback: простая эвристика — пересечение букв
	var set1 = word1.to_lower().split("")
	var set2 = word2.to_lower().split("")
	var common = 0
	for ch in set1:
		if ch in set2:
			common += 1
	var total = max(set1.size(), set2.size())
	if total == 0:
		return 0.0
	return float(common) / total
	
# Регистрирует новое имя в глобальной памяти
func register_name(agent_id: int, name: String):
	var agent = SimManager.instance.get_agent_by_id(agent_id)
	if not agent:
		return
	# Создаём якорь
	var anchor_text = "Name: " + name + " (agent " + str(agent_id) + ")"
	anchor_memory.append({"text": anchor_text, "weight": 0.3})
	# Добавляем в семантическую сеть (чтобы GlobalBrain знал это слово)
	if not semantic_network.has(name):
		semantic_network[name] = {"linked": {}, "events": [], "frequency": 1}
	else:
		semantic_network[name]["frequency"] += 1
	# Логируем
	SimManager.instance.add_log("[GlobalBrain] Registered new name: " + name + " for agent " + str(agent_id))

func _update_scenarios():
	scenario_clock += 1
	if scenario_clock < scenario_update_interval:
		return
	scenario_clock = 0
	
	# Количество сценариев зависит от состояния
	var num_scenarios = 2 + int(awareness * 3 + (1.0 - entropy) * 2)
	max_scenarios = clamp(num_scenarios, 2, 8)
	
	var base_state = _get_global_state_vector()
	var variants = []
	for i in range(max_scenarios):
		var variant = _mutate_global_state(base_state)
		var prob = _estimate_global_probability(variant)
		variants.append({"state": variant, "probability": prob, "age": 0})
	
	for s in possible_scenarios:
		s.age += 1
		s.probability *= (1.0 - 0.02 * s.age)
	
	possible_scenarios += variants
	possible_scenarios.sort_custom(func(a,b): return a.probability > b.probability)
	if possible_scenarios.size() > max_scenarios * 2:
		possible_scenarios.resize(max_scenarios * 2)
	
	# ---- ГИПОТЕТИЧЕСКИЕ ЯКОРЯ (без порога) ----
	for s in possible_scenarios:
		if s.age < 4:
			var anchor_chance = awareness * 0.5 + (1.0 - entropy) * 0.3
			if randf() < anchor_chance * 0.25:
				_create_hypothetical_anchor(s)
				break
			
func _get_global_state_vector() -> Dictionary:
	var avg_mood = 0.0
	var avg_energy = 0.0
	var count = 0
	for a in SimManager.instance.agents:
		if a.alive:
			avg_mood += a.mood
			avg_energy += a.energy / a.max_energy
			count += 1
	if count > 0:
		avg_mood /= count
		avg_energy /= count
	return {
		"entropy": entropy,
		"awareness": awareness,
		"avg_mood": avg_mood,
		"avg_energy": avg_energy,
		"resonance_count": count,
		"time": SimManager.instance.time
	}

	
func _mutate_global_state(base: Dictionary) -> Dictionary:
	var variant = base.duplicate()
	var mutation = randi() % 3
	match mutation:
		0:
			variant.entropy = clamp(base.entropy + randf_range(-0.2, 0.2), 0.0, 1.0)
		1:
			variant.awareness = clamp(base.awareness + randf_range(-0.2, 0.2), 0.0, 1.0)
		2:
			variant.avg_mood = clamp(base.avg_mood + randf_range(-0.2, 0.2), 0.0, 1.0)
	return variant
	
func _estimate_global_probability(variant: Dictionary) -> float:
	var prob = 0.5
	prob += variant.awareness * 0.2
	var entropy_opt = 1.0 - abs(variant.entropy - 0.3) * 2.0
	prob += clamp(entropy_opt, 0.0, 0.3)
	prob += variant.avg_mood * 0.15
	return clamp(prob, 0.0, 1.0)
	
func _create_hypothetical_anchor(scenario: Dictionary):
	var state = scenario.state
	var text = ""
	var horizon = "medium"
	var weight = 0.2
	
	# ---- 1. ОПРЕДЕЛЯЕМ ГОРИЗОНТ ИЗ СОСТОЯНИЯ ----
	# Если entropy низкая — мир предсказуем, можно думать о далёком
	if state.has("entropy"):
		if state.entropy < 0.3:
			horizon = "long"
			weight += 0.1
		elif state.entropy > 0.7:
			horizon = "short"
			weight -= 0.05
	# Если awareness высокая — горизонт расширяется
	if state.has("awareness") and state.awareness > 0.7:
		if horizon != "short":
			horizon = "long"
			weight += 0.1
	# Если avg_mood низкая — горизонт сужается до выживания
	if state.has("avg_mood") and state.avg_mood < 0.3:
		horizon = "short"
		weight -= 0.05
	
	# ---- 2. ГЕНЕРИРУЕМ ТЕКСТ ИЗ СОСТОЯНИЯ ----
	var parts = []
	if state.has("entropy"):
		if state.entropy < 0.3:
			parts.append("order")
		elif state.entropy > 0.7:
			parts.append("chaos")
		else:
			parts.append("balance")
	if state.has("awareness") and state.awareness > 0.6:
		parts.append("awareness")
	if state.has("avg_mood"):
		if state.avg_mood > 0.6:
			parts.append("joy")
		elif state.avg_mood < 0.4:
			parts.append("sorrow")
	if state.has("avg_energy") and state.avg_energy > 0.6:
		parts.append("energy")
	
	# ---- 3. СОБИРАЕМ ФРАЗУ ИЗ ЧАСТЕЙ ----
	if parts.is_empty():
		text = "The world may change"
	else:
		var base_text = ""
		match horizon:
			"short":
				base_text = "Soon, " + "_".join(parts) + " will come"
			"medium":
				base_text = "If " + "_".join(parts) + " continues, we will adapt"
			"long":
				base_text = "In the end, " + "_".join(parts) + " will define us"
		text = base_text
	
	# ---- 4. ДОБАВЛЯЕМ УНИКАЛЬНОСТЬ НА ОСНОВЕ ВЕРОЯТНОСТИ ----
	if scenario.probability > 0.8:
		text += " (likely)"
	elif scenario.probability < 0.3:
		text += " (uncertain)"
	
	# ---- 5. СОЗДАЁМ АНКОР ----
	var anchor = {
		"text": text,
		"weight": clamp(weight, 0.05, 0.5),
		"scenario": state,
		"horizon": horizon,
		"probability": scenario.probability,
		"time": SimManager.instance.time if SimManager.instance else 0
	}
	hypothetical_anchors.append(anchor)
	# Также сохраняем в temporal_anchors для временной привязки
	var temp_anchor = {
		"text": text,
		"horizon": horizon,
		"weight": anchor.weight,
		"time": anchor.time
	}
	temporal_anchors.append(temp_anchor)
	
	# ---- 6. ОГРАНИЧИВАЕМ РАЗМЕР ----
	if hypothetical_anchors.size() > 10:
		hypothetical_anchors.pop_front()
	if temporal_anchors.size() > 10:
		temporal_anchors.pop_front()
	
	# ---- 7. ЛОГИРУЕМ ТОЛЬКО ВАЖНЫЕ ----
	if scenario.probability > 0.7:
		SimManager.instance.add_log("[GlobalBrain] Temporal anchor (" + horizon + "): " + text)
func _analyze_pattern_field():
	var sim = SimManager.instance
	if not sim:
		return
	
	# Собираем все паттерны, переданные через поле (долговременные следы)
	var pattern_traces = []
	for trace in sim.field_system.long_term_traces:
		if "pattern_" in trace.type:
			pattern_traces.append(trace)
	
	if pattern_traces.size() < 2:
		return
	
	# Выбираем два случайных паттерна и сравниваем
	var t1 = pattern_traces[randi() % pattern_traces.size()]
	var t2 = pattern_traces[randi() % pattern_traces.size()]
	if t1 == t2 and pattern_traces.size() > 1:
		t2 = pattern_traces[(pattern_traces.find(t1) + 1) % pattern_traces.size()]
	
	# Если паттерны похожи, создаём якорь
	if abs(t1.strength - t2.strength) < 0.1 and randf() < 0.01:
		var anchor_text = "Pattern resonance detected: " + t1.type + " ↔ " + t2.type
		anchor_memory.append({"text": anchor_text, "weight": 0.2})
		SimManager.instance.add_log("[GlobalBrain] Pattern resonance: " + anchor_text)
