extends RefCounted
class_name MemorySystem

# ============================================================
#  КОНСТАНТЫ
# ============================================================
const MAX_MEMORY_SIZE: int = 50
const ANCHOR_BONUS_PER_INSIGHT: float = 0.05
const ANCHOR_BONUS_PER_INVENTION: float = 0.08
const FIELD_IMPACT_FROM_ANCHOR: float = 0.02   # влияние одного якоря на поле вокруг агента
const MEMORY_DECAY_RATE: float = 0.001         # забывание старых событий (если не используется)

# ============================================================
#  ИНИЦИАЛИЗАЦИЯ
# ============================================================
func init_agent(agent):
	agent.memory = []
	agent.memory_anchors = 0
	agent.invented_contexts = []
	agent.moral_memory = {}
	agent.observed_actions = {}
	agent.narrative = ""
	agent.meta_narrative = ""
	agent.myth = ""

# ============================================================
#  ДОБАВЛЕНИЕ СОБЫТИЙ В ПАМЯТЬ
# ============================================================
func add_event(agent, event_type: String, content = null, position: Vector2 = Vector2.ZERO):
	var entry = {
		"type": event_type,
		"time": SimManager.instance.time,
		"content": content,
		"pos": position
	}
	agent.memory.append(entry)
	if agent.memory.size() > MAX_MEMORY_SIZE:
		agent.memory.pop_front()

# ============================================================
#  ОБРАБОТКА ИНСАЙТОВ
# ============================================================
func add_insight(agent, insight_text: String, position: Vector2 = Vector2.ZERO):
	add_event(agent, "insight", insight_text, position)
	# Увеличиваем количество якорей
	agent.memory_anchors += 1
	# Обновляем нарратив (если это значимый инсайт)
	if insight_text.length() > 20 and agent.narrative == "":
		agent.narrative = insight_text
	# Влияние на поле: создаём локальный паттерн в точке события
	_create_field_anchor(agent, position, insight_text)
	
	# Эффект на творческий иммунитет
	agent.creative_immunity = min(1.0, agent.creative_immunity + 0.02)
	var state = agent._get_future_state_vector()
	agent._add_to_unified_memory("past", insight_text, state, "insight")
func add_invention(agent, invention_name: String, position: Vector2 = Vector2.ZERO):
	add_event(agent, "invention", invention_name, position)
	agent.invented_contexts.append(invention_name)
	agent.memory_anchors += 1
	agent.creative_immunity = min(1.0, agent.creative_immunity + 0.05)
	# Создаём более сильный след в поле
	_create_field_anchor(agent, position, "invention:" + invention_name, 0.03)
# ============================================================
#  ВЛИЯНИЕ НА ПОЛЕ (создание якорей как паттернов)
# ============================================================
func _create_field_anchor(agent, position: Vector2, content: String, strength: float = 0.02):
	if not agent.field_system:
		return
	# Преобразуем содержимое в числовой паттерн (хеш)
	var hash = 0
	for ch in content:
		hash += ord(ch)
	var phase = (hash % 100) / 100.0   # 0..1
	var amplitude = strength * (1.0 + agent.creative_immunity * 0.5)
	# Добавляем в поле вокруг позиции колеблющийся паттерн
	var radius = 3
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var px = position.x + dx
			var py = position.y + dy
			var dist = Vector2(dx, dy).length()
			if dist > radius:
				continue
			var influence = amplitude * (1.0 - dist / radius) * (0.5 + 0.5 * sin(phase * 6.28 + dist * 0.5))
			var current = agent.field_system.get_field_at(Vector2(px, py))
			agent.field_system.set_field_at(Vector2(px, py), current + influence)

# ============================================================
#  ОБНОВЛЕНИЕ ПАМЯТИ (забывание, интеграция)
# ============================================================
func update_agent(agent, delta: float):
	# 1. Забывание старых, неиспользуемых событий (редко, только если слишком много)
	if agent.memory.size() > MAX_MEMORY_SIZE * 0.8:
		# Удаляем самые старые события, которые не являются инсайтами или изобретениями
		var to_remove = []
		for i in range(agent.memory.size()):
			var entry = agent.memory[i]
			if entry.type not in ["insight", "invention", "birth"] and i < agent.memory.size() * 0.3:
				to_remove.append(i)
		for i in to_remove.size():
			var idx = to_remove[i] - i
			agent.memory.remove_at(idx)
	
	# 2. Обновляем memory_anchors (пересчёт на основе инсайтов и изобретений)
	var anchor_count = 0
	for entry in agent.memory:
		if entry.type in ["insight", "invention"]:
			anchor_count += 1
	agent.memory_anchors = anchor_count
	# 3. Ретроспективное искажение (редко)
	if agent.memory.size() > 3 and randf() < 0.001 * delta:
		var idx = randi() % agent.memory.size()
		var entry = agent.memory[idx]
		if entry.type == "insight":
			# Искажаем содержание инсайта на основе текущего состояния
			var words = entry.content.split(" ")
			if words.size() > 2:
				# Заменяем одно слово на эмоционально окрашенное
				var emotions = ["strange", "amazing", "terrifying", "wonderful", "confusing"]
				var new_word = emotions[randi() % emotions.size()]
				words[randi() % words.size()] = new_word
				entry.content = " ".join(words)
				# Отмечаем как искажённое
				entry.distorted = true
				if agent.has_name:
					SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") distorted a memory.")
	
	# 4. Создание ложных воспоминаний
	if agent.memory_anchors > 2 and randf() < 0.0005 * delta:
		var fake_insight = _generate_fake_insight(agent)
		add_event(agent, "insight", fake_insight, agent.pos)
		if agent.has_name:
			SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") created a false memory: " + fake_insight)

func _generate_fake_insight(agent) -> String:
	var templates = [
		"I remember seeing a castle where there was none.",
		"I once felt a presence that wasn't there.",
		"I believe I have met another self in a dream.",
		"I recall a ritual that never happened.",
        "I am sure I have been here before, but I haven't."
	]
	return templates[randi() % templates.size()]
# ============================================================
#  ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
# ============================================================
func get_recent_insights(agent, count: int = 3) -> Array:
	var insights = []
	for entry in agent.memory.slice(-count):
		if entry.type == "insight":
			insights.append(entry.content)
	return insights

func get_narrative_summary(agent) -> String:
	if agent.narrative != "":
		return agent.narrative
	elif agent.memory_anchors > 0:
		return "I have " + str(agent.memory_anchors) + " anchors in my memory."
	else:
		return "I am new."

func create_myth(agent):
	if agent.memory_anchors < 3:
		return
	var insights = get_recent_insights(agent, 3)
	if insights.size() < 3:
		return
	var myth_parts = []
	myth_parts.append("In the beginning, I was " + (agent.self_name if agent.has_name else "nameless"))
	myth_parts.append("I learned that " + insights[0])
	myth_parts.append("Then I discovered " + insights[1])
	myth_parts.append("And finally I understood " + insights[2])
	agent.myth = ". ".join(myth_parts) + "."
	add_event(agent, "myth", agent.myth)
# В MemorySystem.gd
func add_thought_word(agent, word: String, position: Vector2 = Vector2.ZERO):
	add_event(agent, "thought_word", word, position)
	
func generate_insight_from_words(agent, word1: String, word2: String):
	var insight = "I think about '" + word1 + "' and '" + word2 + "'. They are connected."
	add_event(agent, "insight", insight, agent.pos)	
