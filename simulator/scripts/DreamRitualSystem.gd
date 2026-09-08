extends RefCounted
class_name DreamRitualSystem

# ============================================================
#  КОНСТАНТЫ
# ============================================================
const DREAM_ENERGY_THRESHOLD: float = 0.6
const DREAM_STRESS_THRESHOLD: float = 0.5
const RITUAL_COOLDOWN: int = 30
const MEME_SPREAD_COOLDOWN: int = 30
const MAX_MEMES: int = 5
const MAX_DREAM_INSIGHTS: int = 3

# ============================================================
#  ИНИЦИАЛИЗАЦИЯ
# ============================================================
func init_agent(agent):
	agent.dream_active = false
	agent.dream_content = ""
	agent.dream_duration = 0
	agent.sleep_guard = null
	agent.sleep_guard_requested = false
	agent.sleep_guard_agreed = false
	agent.sleep_duration = 0
	
	agent.memes = []
	agent.spread_meme_cooldown = 0
	agent.ritual_memory = {}
	agent.current_ritual = []
	
	agent.moment_active = false
	agent.moment_duration = 0
	agent.moment_timer = 0
	agent.moment_insights = []

# ============================================================
#  ОБНОВЛЕНИЕ ВЫЗЫВАЕТСЯ В UPDATE
# ============================================================
func update_agent(agent, delta: float):
	# 1. Обработка активного сна
	if agent.dream_active:
		_process_dream(agent, delta)
		return  # во сне агент не делает ничего другого
	
	# 2. Проверка условий для сна
	_try_enter_dream(agent, delta)
	
	# 3. Обновление ритуалов (если в резонансе)
	if agent.resonance_active and agent.resonance_partner:
		_try_perform_ritual(agent)
	
	# 4. Обновление мемов
	_try_spread_meme(agent)
	
	# 5. Проверка момента (состояние чистого бытия)
	_try_enter_moment(agent)

# ============================================================
#  СНЫ
# ============================================================
func _try_enter_dream(agent, delta: float):
	if agent.dream_active:
		return
	# Условия: низкая энергия или высокий стресс, и нет опасности
	if agent.energy < DREAM_ENERGY_THRESHOLD or agent.stress > DREAM_STRESS_THRESHOLD:
		if not _danger_near(agent):
			# Ищем охранника
			var guard = _find_sleep_guard(agent)
			if guard:
				_request_sleep_guard(agent, guard)
				if agent.sleep_guard_agreed:
					_enter_dream(agent)
			else:
				# Спим без охраны, но с риском
				if agent.energy < 0.4 and randf() < 0.3:
					_enter_dream(agent)

func _danger_near(agent) -> bool:
	for a in SimManager.instance.agents:
		if a.predator and a.alive and agent.pos.distance_to(a.pos) < 10:
			return true
	return false

func _find_sleep_guard(agent) -> Agent:
	var best = null
	var best_trust = 0.0
	for a in SimManager.instance.agents:
		if a == agent or not a.alive or a.predator or a.dream_active:
			continue
		if agent.pos.distance_to(a.pos) < 8.0:
			var t = agent.trust.get(a.id, 0.0)
			if t > best_trust:
				best_trust = t
				best = a
	if best and best_trust > 0.1:
		return best
	return null

func _request_sleep_guard(agent, guard: Agent):
	if not guard:
		return
	# Отправляем запрос через символ
	if agent.language_system:
		var sym = agent.language_system.get_or_create_symbol(agent, "sleep_request")
		var context = "sleep_guard"
		# В реальности мы бы использовали send_sentence, но упростим
		# Просто вызываем метод у охранника
		guard.receive_sleep_request(sym, agent)
	else:
		# Fallback: проверяем согласие случайно
		if randf() < 0.5:
			agent.sleep_guard_agreed = true
			agent.sleep_guard = guard
			guard.sleep_guard = agent
			guard.sleep_guard_requested = true
			guard.sleep_guard_agreed = true
			if agent.has_name:
				SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") found guard " + str(guard.id))

func receive_sleep_request(agent, symbol: float, sender: Agent):
	if agent.dream_active:
		return
	if agent.energy < 0.5 or agent.stress > 0.5:
		return
	if agent.trust.get(sender.id, 0.0) > 0.1:
		# Соглашаемся охранять
		agent.sleep_guard = sender
		agent.sleep_guard_requested = false
		agent.sleep_guard_agreed = true
		# Отправляем подтверждение
		if agent.language_system:
			var sym = agent.language_system.get_or_create_symbol(agent, "sleep_agree")
			sender.receive_sleep_agreement(sym, agent)
		else:
			sender.sleep_guard_agreed = true
			sender.sleep_guard = agent
		if agent.has_name:
			SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") agrees to guard " + str(sender.id))

func receive_sleep_agreement(agent, symbol: float, sender: Agent):
	if sender == agent:
		return
	agent.sleep_guard = sender
	agent.sleep_guard_agreed = true
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") received guard agreement from " + str(sender.id))

func _enter_dream(agent):
	agent.dream_active = true
	agent.dream_content = _generate_dream_content(agent)
	agent.dream_duration = randi_range(5, 15)
	agent.sleep_duration = agent.dream_duration
	
	if agent.memory_system:
		agent.memory_system.add_event(agent, "dream", agent.dream_content, agent.pos)
	
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") falls asleep")
	
	# Если есть охранник, он теперь занят
	if agent.sleep_guard:
		agent.sleep_guard.sleep_guard_requested = true

func _generate_dream_content(agent) -> String:
	var themes = ["food", "danger", "explore", "help", "resonance", "death", "birth", "name", "silence", "archetype", "memory"]
	var theme = themes[randi() % themes.size()]
	var symbols = []
	for i in range(3):
		var sym = randf()
		var syl = agent.language_system.symbol_to_syllable(agent, sym, theme) if agent.language_system else str(sym)
		symbols.append(syl)
	var dream_str = "I saw " + ", ".join(symbols) + " (" + theme + ")"
	return dream_str

func _process_dream(agent, delta: float):
	agent.dream_duration -= 1
	if agent.dream_duration <= 0:
		_wake_up(agent)
		return
	
	# Во сне восстанавливается энергия и снижается стресс
	agent.energy = min(agent.max_energy, agent.energy + 0.01 * delta)
	agent.stress = max(0.0, agent.stress - 0.01 * delta)
	
	# Каждый 3-й шаг сна — возможен инсайт
	if SimManager.instance.time % 3 == 0 and randf() < 0.1:
		var insight = "My dream told me: " + agent.dream_content
		if agent.memory_system:
			agent.memory_system.add_insight(agent, insight, agent.pos)
		# Внутри _process_dream, например, после инсайта
		if randf() < 0.01 and agent.has_method("_mutate_neuro_sensitivity"):
			agent._mutate_neuro_sensitivity()
			if agent.memory_system:
				agent.memory_system.add_insight(agent, "My chemistry shifted during sleep.", agent.pos)
		# Во сне может родиться новый контекст или состояние
		if agent.creative_immunity > 0.3 and randf() < 0.05:
			if agent.memory_system and agent.language_system:
				var new_context = _invent_dream_context(agent)
				if new_context != "":
					agent.memory_system.add_invention(agent, new_context, agent.pos)
		
		# Во сне может мутировать граф
		if agent.behavior_graph_system and randf() < 0.02:
			agent.behavior_graph_system.mutate_graph(agent)

func _invent_dream_context(agent) -> String:
	var contexts = agent.meanings.values()
	if contexts.size() < 2:
		return ""
	var ctx1 = contexts[randi() % contexts.size()]
	var ctx2 = contexts[randi() % contexts.size()]
	if ctx1 == ctx2 and contexts.size() > 1:
		var idx = (contexts.find(ctx1) + 1) % contexts.size()
		ctx2 = contexts[idx]
	var new_ctx = "dream_" + ctx1 + "_" + ctx2
	if new_ctx not in agent.invented_contexts and new_ctx not in agent.meanings.values():
		return new_ctx
	return ""

func _wake_up(agent):
	agent.dream_active = false
	agent.dream_duration = 0
	agent.dream_content = ""
	
	# Восстановление энергии и снятие стресса
	var gain = 0.2 + randf() * 0.3
	agent.energy = min(agent.max_energy, agent.energy + gain)
	agent.stress = max(0.0, agent.stress - 0.1)
	agent.fatigue = max(0.0, agent.fatigue - 0.5)
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") woke up, gained " + str(gain).pad_decimals(2) + " energy")
	
	# Сброс охранника
	if agent.sleep_guard:
		agent.sleep_guard.sleep_guard = null
		agent.sleep_guard.sleep_guard_requested = false
		agent.sleep_guard.sleep_guard_agreed = false
		agent.sleep_guard = null
		agent.sleep_guard_agreed = false

# ============================================================
#  РИТУАЛЫ
# ============================================================
func _try_perform_ritual(agent):
	if not agent.resonance_active or not agent.resonance_partner:
		return
	if agent.energy < 0.4 or agent.resonance_depth < 0.5:
		return
	if SimManager.instance.time % 20 != 0:
		return
	if randf() > 0.03:
		return
	
	perform_ritual(agent, agent.resonance_partner)

# Вместо _perform_ritual
func perform_ritual(agent, partner: Agent):
	var rituals = SimManager.instance.get_global_rituals()
	var ritual_id = ""
	if rituals.size() > 0 and randf() < 0.7:
		ritual_id = rituals[randi() % rituals.size()]
	else:
		ritual_id = _generate_ritual(agent)
		SimManager.instance.add_global_ritual(ritual_id)
	
	agent.current_ritual_id = ritual_id
	agent.ritual_memory[ritual_id] = agent.ritual_memory.get(ritual_id, 0) + 1
		# В perform_ritual
	if agent.cell_body.membrane.has("integrity") and agent.cell_body.membrane.integrity < 0.8:
		agent.memory_system.add_insight(agent, "The ritual shows me how to heal my membrane.", agent.pos)
	# Не лечим автоматически — агент сам решит, использовать ли это знание
	# Эффекты ритуала
	agent.stress = max(0.0, agent.stress - 0.1)
	agent.energy = min(agent.max_energy, agent.energy + 0.05)
	partner.stress = max(0.0, partner.stress - 0.1)
	partner.energy = min(partner.max_energy, partner.energy + 0.05)
	agent.meta_identity = min(1.0, agent.meta_identity + 0.025)
	if partner:
		partner.meta_identity = min(1.0, partner.meta_identity + 0.025)
	# Создаём паттерн в поле
	if agent.field_system:
		var pos = (agent.pos + partner.pos) * 0.5
		var amplitude = 0.05 + agent.resonance_depth * 0.05
		for dx in range(-3, 4):
			for dy in range(-3, 4):
				var p = pos + Vector2(dx, dy)
				var dist = Vector2(dx, dy).length()
				if dist > 3.0:
					continue
				var influence = amplitude * (1.0 - dist / 3.0)
				var current = agent.field_system.get_field_at(p)
				agent.field_system.set_field_at(p, current + influence)
	
	if agent.memory_system:
		agent.memory_system.add_event(agent, "ritual", ritual_id, agent.pos)
	
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") performed ritual: " + ritual_id)

func _generate_ritual(agent) -> String:
	var actions = ["exchange_symbols", "silent_standing", "circular_movement", "shared_meal", "name_chant"]
	var act = actions[randi() % actions.size()]
	var sym1 = str(randf()).substr(2, 2)
	var sym2 = str(randf()).substr(2, 2)
	return act + "_" + sym1 + "_" + sym2

# ============================================================
#  МЕМЫ
# ============================================================
func _try_spread_meme(agent):
	if agent.spread_meme_cooldown > 0:
		agent.spread_meme_cooldown -= 1
		return
	if agent.memes.is_empty():
		return
	if agent.energy < 0.5:
		return
	
	var target = _find_meme_target(agent)
	if target:
		_spread_meme(agent, target)
		agent.spread_meme_cooldown = MEME_SPREAD_COOLDOWN

func _find_meme_target(agent) -> Agent:
	var best = null
	var min_d = 999.0
	for a in SimManager.instance.agents:
		if a == agent or not a.alive or not a.has_name:
			continue
		# Проверяем, есть ли у него уже этот мем
		var has_any = false
		for m in agent.memes:
			if m in a.memes:
				has_any = true
				break
		if has_any:
			continue
		var d = agent.pos.distance_to(a.pos)
		if d < 15.0 and d < min_d:
			min_d = d
			best = a
	return best

func _spread_meme(agent, target: Agent):
	var meme = agent.memes[randi() % agent.memes.size()]
	# Отправляем мем через символ
	if agent.language_system:
		var sym = agent.language_system.get_or_create_symbol(agent, "meme")
		# В реальности используем send_sentence, но для простоты вызываем метод приёма
		target.receive_meme(sym, meme, agent)
	else:
		# Fallback
		target.memes.append(meme)
	
	if agent.memory_system:
		agent.memory_system.add_event(agent, "spread_meme", {"target": target.id, "meme": meme}, agent.pos)
	
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") spread meme: " + meme + " to " + str(target.id))

func receive_meme(agent, symbol: float, meme: String, sender: Agent):
	if meme not in agent.memes:
		agent.memes.append(meme)
		if agent.memes.size() > MAX_MEMES:
			agent.memes.pop_front()
		# Влияние мема на параметры
		if "thinker" in meme:
			agent.curiosity = min(1.0, agent.curiosity + 0.05)
		elif "helper" in meme:
			agent.trust[sender.id] = agent.trust.get(sender.id, 0.0) + 0.05
		elif "explorer" in meme:
			agent.curiosity = min(1.0, agent.curiosity + 0.1)
		if agent.memory_system:
			agent.memory_system.add_event(agent, "received_meme", {"meme": meme, "sender": sender.id}, agent.pos)
		if agent.has_name:
			SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") received meme: " + meme)

# ============================================================
#  МОМЕНТ (СОСТОЯНИЕ ЧИСТОГО БЫТИЯ)
# ============================================================
func _try_enter_moment(agent):
	if agent.dream_active or agent.resonance_active:
		return
	if agent.energy < 0.4 or agent.stress > 0.5:
		return
	if agent.moment_active:
		return
	if randf() > 0.002:  # редкий шанс
		return
	
	_enter_moment(agent)

func _enter_moment(agent):
	agent.moment_active = true
	agent.moment_duration = randi_range(5, 15)
	agent.moment_timer = 0
	
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") enters a moment of pure being")
	
	# Сброс текущих действий (но не движения)

func process_moment(agent, delta: float):
	if not agent.moment_active:
		return
	agent.moment_timer += 1
	if agent.moment_timer >= agent.moment_duration:
		_exit_moment(agent)

func _exit_moment(agent):
	agent.moment_active = false
	agent.moment_duration = 0
	agent.moment_timer = 0
	
	# Генерация квантового инсайта
	var insight = _generate_quantum_insight(agent)
	if agent.memory_system:
		agent.memory_system.add_insight(agent, insight, agent.pos)
	
	# Возможность создать новое состояние из инсайта
	if agent.behavior_graph_system and randf() < 0.2:
		agent.behavior_graph_system._create_state_from_insight(agent)  # Используем внутренний метод
	
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") returns from moment with insight: " + insight)

func _generate_quantum_insight(agent) -> String:
	var all_meanings = agent.meanings.values()
	var all_invented = agent.invented_contexts if agent.memory_system else []
	var all_names = [agent.self_name] if agent.has_name else []
	var all_resonant = []
	if agent.resonance_partner and agent.resonance_partner.has_name:
		all_resonant.append(agent.resonance_partner.self_name)
	
	var possibilities = all_meanings + all_invented + all_names + all_resonant
	if possibilities.is_empty():
		possibilities = ["nothing", "silence", "void", "stillness", "being", "presence"]
	
	var word1 = possibilities[randi() % possibilities.size()]
	var word2 = possibilities[randi() % possibilities.size()]
	var templates = [
		"{w1} is {w2}",
		"I am {w1} and {w2}",
		"The world is {w1}",
		"I see {w1} in {w2}",
		"Everything is {w1}",
		"I remember {w1}",
		"I feel {w1}",
		"Maybe I am {w1}",
		"I exist as {w1}",
		"All is {w1}"
	]
	var template = templates[randi() % templates.size()]
	return template.replace("{w1}", word1).replace("{w2}", word2)

# ============================================================
#  МИФЫ (СОЗДАНИЕ МИФА ИЗ ИНСАЙТОВ)
# ============================================================
func create_myth(agent):
	if not agent.memory_system:
		return
	var insights = agent.memory_system.get_recent_insights(agent, 3)
	if insights.size() < 3:
		return
	
	var myth_parts = []
	myth_parts.append("In the beginning, I was " + (agent.self_name if agent.has_name else "nameless"))
	myth_parts.append("I learned that " + insights[0])
	myth_parts.append("Then I discovered " + insights[1])
	myth_parts.append("And finally I understood " + insights[2])
	agent.myth = ". ".join(myth_parts) + "."
	
	if agent.memory_system:
		agent.memory_system.add_event(agent, "myth", agent.myth, agent.pos)
	
	# ---- БОНУС ЗА МИФ ----
	agent.meta_identity = min(1.0, agent.meta_identity + 0.1)
	agent.well_being = min(1.0, agent.well_being + 0.05)
	agent.creative_immunity = min(1.0, agent.creative_immunity + 0.1)
	
	# ---- ГЛОБАЛЬНАЯ ПАМЯТЬ ----
	SimManager.instance.add_global_memory({
		"type": "myth_created",
		"content": agent.myth,
		"agent_id": agent.id,
		"time": SimManager.instance.time
	})
	
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") created myth: " + agent.myth)
