extends RefCounted
class_name LanguageSystem

# ============================================================
#  КОНСТАНТЫ
# ============================================================
const GRAMMAR_MUTATION_CHANCE: float = 0.02
const SYMBOL_FIELD_IMPACT: float = 0.01
const MAX_LANGUAGE_CONFLICTS: int = 20
const TALK_ENERGY_COST: float = 0.005

# ============================================================
#  ИНИЦИАЛИЗАЦИЯ
# ============================================================
func init_agent(agent):
	agent.lexicon = []
	agent.meanings = {}
	agent.context_mem = {}
	agent.grammar_order = ["subject", "action", "object"]
	agent.language_insights = []
	agent.language_experience = 0
	agent.language_conflicts = []
	agent.grammar_evolution_cooldown = 0
	agent.syllables = {
		"food": ["nu", "ka", "ma", "ri"],
		"danger": ["za", "ro", "gi", "tu"],
		"explore": ["le", "so", "mi", "pa"],
		"help": ["ve", "na", "se", "ko"],
		"resonance": ["ru", "dy", "ve", "na"]
	}
	agent.talk_modifier = 0.0

# ============================================================
#  РАБОТА С СИМВОЛАМИ
# ============================================================
func get_or_create_symbol(agent, context: String) -> float:
	for sym in agent.meanings.keys():
		if agent.meanings[sym] == context:
			return sym
	var new_sym = randf()
	agent.meanings[new_sym] = context
	# Создаём отпечаток в поле
	if agent.field_system:
		_imprint_symbol(agent, new_sym, context)
	return new_sym

func _imprint_symbol(agent, symbol: float, context: String):
	# Влияние на поле в точке агента
	var amplitude = SYMBOL_FIELD_IMPACT * (1.0 + agent.creative_immunity * 0.5)
	var phase = symbol * 6.28
	var radius = 2
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var pos = agent.pos + Vector2(dx, dy)
			var dist = Vector2(dx, dy).length()
			if dist > radius:
				continue
			var influence = amplitude * (1.0 - dist / radius) * (0.5 + 0.5 * sin(phase + dist * 0.3))
			var current = agent.field_system.get_field_at(pos)
			agent.field_system.set_field_at(pos, current + influence)

# ============================================================
#  КОММУНИКАЦИЯ (ОТПРАВКА / ПОЛУЧЕНИЕ)
# ============================================================
func send_sentence(agent, target, subject: float, action: float, object: float, context: String = "dialogue"):
	if not target or not target.alive:
		return
	if agent.energy < TALK_ENERGY_COST:
		return
	# Построение предложения по грамматике
	var sentence = []
	for role in agent.grammar_order:
		match role:
			"subject": sentence.append(subject)
			"action": sentence.append(action)
			"object": sentence.append(object)
	# Добавляем контекст как дополнительный символ
	var context_symbol = get_or_create_symbol(agent, context)
	sentence.append(context_symbol)
	
	# Отправляем целевому агенту
	target.receive_sentence(sentence, agent)
	
	# Списываем энергию
	agent.energy -= TALK_ENERGY_COST
	agent.language_experience += 1
	
	# Запоминаем отправку
	if agent.memory_system:
		agent.memory_system.add_event(agent, "sent_sentence", {"target": target.id, "sentence": sentence})

func receive_sentence(agent, sentence: Array, sender):
	if not agent.alive or not sender.alive:
		return
	if sentence.size() < 3:
		return
	# Извлекаем контекст (последний элемент)
	var context_symbol = sentence[-1] if sentence.size() > 3 else 0.0
	var context = ""
	for sym in agent.meanings.keys():
		if abs(sym - context_symbol) < 0.01:
			context = agent.meanings[sym]
			break
	# Декодируем по своей грамматике
	var decoded = {}
	var roles = agent.grammar_order.duplicate()
	for i in range(min(sentence.size()-1, roles.size())):
		var role = roles[i]
		decoded[role] = sentence[i]
	
	# Проверяем структуру
	if decoded.has("subject") and decoded.has("action") and decoded.has("object"):
		# Интерпретация в зависимости от контекста
		_interpret_sentence(agent, sender, decoded, context)
	else:
		_language_mismatch(agent, sender, decoded, "incomplete")
	
	# Запоминаем получение
	if agent.memory_system:
		agent.memory_system.add_event(agent, "received_sentence", {"sender": sender.id, "decoded": decoded})

func _interpret_sentence(agent, sender, decoded: Dictionary, context: String):
	# Простейшая реакция: доверие, изменение настроения, поведение
	var action_val = decoded.get("action", 0.5)
	if context == "food" and agent.energy < agent.max_energy * 0.5:
		# Отправитель сообщает о еде → повышаем доверие
		agent.trust[sender.id] = agent.trust.get(sender.id, 0.0) + 0.05
	elif context == "danger":
		agent.stress = min(1.0, agent.stress + 0.1)
	elif context == "help" and agent.energy > agent.max_energy * 0.6:
		# Готовность помочь
		if agent.social_system:
			agent.social_system.cooperate(agent, sender, 0.02)
	elif context == "resonance":
		# Проверяем, не хотим ли мы войти в резонанс
		if agent.social_system and agent.energy > 0.4 and agent.stress < 0.5:
			agent.social_system.initiate_resonance(agent, sender)
	# Обновляем social_buffers (если взаимодействие положительное)
	if context in ["food", "help", "resonance"]:
		if sender.id not in agent.social_buffers:
			agent.social_buffers.append(sender.id)

func _language_mismatch(agent, sender, decoded: Dictionary, reason: String):
	agent.language_conflicts.append({
		"sender": sender.id,
		"decoded": decoded,
		"reason": reason,
		"time": SimManager.instance.time
	})
	if agent.language_conflicts.size() > MAX_LANGUAGE_CONFLICTS:
		agent.language_conflicts.pop_front()
	
	if agent.language_conflicts.size() > 5:
		agent.stress = min(1.0, agent.stress + 0.05)
		# Возможность эволюции грамматики
		if agent.grammar_evolution_cooldown <= 0 and randf() < 0.1:
			evolve_grammar(agent)

# ============================================================
#  ЭВОЛЮЦИЯ ГРАММАТИКИ
# ============================================================
func evolve_grammar(agent):
	if agent.grammar_evolution_cooldown > 0:
		return
	if agent.language_experience < 3:
		return
	
	var possible_orders = [
		["subject", "action", "object"],
		["action", "subject", "object"],
		["object", "action", "subject"],
		["action", "object", "subject"],
		["subject", "object", "action"],
		["object", "subject", "action"]
	]
	var current_str = str(agent.grammar_order)
	var candidates = []
	for order in possible_orders:
		if str(order) != current_str:
			candidates.append(order)
	if candidates.is_empty():
		return
	var new_order = candidates[randi() % candidates.size()]
	agent.grammar_order = new_order
	agent.language_insights.append("I changed my grammar to " + str(new_order))
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") evolved grammar to " + str(new_order))
	agent.grammar_evolution_cooldown = 50
	agent.stress = min(1.0, agent.stress + 0.05)

# ============================================================
#  ОБНОВЛЕНИЕ ЯЗЫКОВОЙ СИСТЕМЫ (ВЫЗЫВАЕТСЯ В UPDATE)
# ============================================================
func update_agent(agent, delta: float):
	return
	# Охлаждение эволюции
	if agent.grammar_evolution_cooldown > 0:
		agent.grammar_evolution_cooldown -= 1
	
	# Проверка на языковые конфликты и попытка эволюции во сне (вызывается из DreamRitualSystem)
	# Здесь просто обрабатываем спонтанную мутацию, если есть творческий потенциал
	if agent.creative_immunity > 0.3 and randf() < 0.001:
		evolve_grammar(agent)
	
	# Обновление talk_modifier (влияние устойчивости на желание говорить)
	agent.talk_modifier = 0.1 * (1.0 - agent.total_stability) + 0.05 * agent.curiosity

# ============================================================
#  ВСПОМОГАТЕЛЬНОЕ: ПРЕОБРАЗОВАНИЕ СИМВОЛА В СЛОГ (для логов)
# ============================================================
func symbol_to_syllable(agent, symbol: float, context: String = "") -> String:
	var syl_list = agent.syllables.get(context, [])
	if syl_list.is_empty():
		# Собрать все слоги из всех контекстов
		for v in agent.syllables.values():
			syl_list += v
	if syl_list.is_empty():
		syl_list = ["mu", "da", "re", "ko"]
	var idx = int(symbol * syl_list.size()) % syl_list.size()
	return syl_list[idx]

func build_word(agent, symbol: float, context: String = "") -> String:
	var syl = symbol_to_syllable(agent, symbol, context)
	if randf() < 0.4:
		var second = symbol_to_syllable(agent, symbol + 0.1, context)
		return syl + second
	return syl
