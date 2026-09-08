extends RefCounted
class_name DeathReincarnationSystem

# ============================================================
#  КОНСТАНТЫ (только для инициализации)
# ============================================================
const REINCARNATION_DELAY_MIN: int = 30
const REINCARNATION_DELAY_MAX: int = 100
const INHERITANCE_MUTATION_RATE: float = 0.05
const INHERITANCE_MUTATION_STRENGTH: float = 0.2

# ============================================================
#  ИНИЦИАЛИЗАЦИЯ АГЕНТА (при создании)
# ============================================================
func init_agent(agent):
	agent.alive = true
	agent.is_ghost = false
	agent.ghost_message = ""
	agent.past_life_memories = []
	agent.reincarnation_awareness = false
	agent.use_reincarnation = true
	agent.use_ghosts = true
	agent._soul_data = null   # для хранения данных перед реинкарнацией

# ============================================================
#  СМЕРТЬ — СОБИРАЕМ ДУШУ
# ============================================================
func die(agent: Agent, reason: String):
	if not agent.alive:
		return
	agent.alive = false

	# ---- 1. СОХРАНЯЕМ ВСЁ, ЧТО БЫЛО ----
	var soul = _collect_soul(agent, reason)
	agent._soul_data = soul

	# ---- 2. ОСТАВЛЯЕМ СЛЕД В ПОЛЕ ----
	if agent.field_system:
		agent.field_system.create_rupture(agent.pos)
		# Долговременный след смерти (зона пониженной когерентности)
		agent.field_system.add_long_term_trace(agent.pos, "death", 0.3)

	# ---- 3. СОЗДАЁМ АРТЕФАКТ (если есть инсайты) ----
	if agent.memory_anchors > 0:
		var content = agent.narrative if agent.narrative != "" else agent.self_name if agent.has_name else "unknown"
		var symbol = randf()
		SimManager.instance.add_artifact(agent.pos, symbol, "death_artifact", content, agent.id)

	# ---- 4. ЗАПИСЬ В ПАМЯТЬ МИРА ----
	SimManager.instance.add_global_memory({
		"type": "death",
		"agent_id": agent.id,
		"name": agent.self_name if agent.has_name else "unnamed",
		"reason": reason,
		"position": agent.pos,
		"time": SimManager.instance.time
	})

	# ---- 5. ЛОГИРОВАНИЕ ----
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") died of " + reason)
	else:
		SimManager.instance.add_log(str(agent.id) + " died of " + reason)

	# ---- 6. ПЛАНИРУЕМ РЕИНКАРНАЦИЮ (если есть душа) ----
	if soul != null and agent.use_reincarnation:
		var delay = randi_range(REINCARNATION_DELAY_MIN, REINCARNATION_DELAY_MAX)
		SimManager.instance.schedule_rebirth(agent.pos, soul, delay)
		SimManager.instance.add_log("Реинкарнация запланирована для " + str(agent.id) + " через " + str(delay) + " шагов")

# ============================================================
#  СОБИРАЕМ ДУШУ (ВСЕ ДАННЫЕ АГЕНТА)
# ============================================================
func _collect_soul(agent: Agent, reason: String) -> Dictionary:
	var soul = {
		"type": "past_life",
		"agent_id": agent.id,
		"name": agent.self_name if agent.has_name else "unnamed",
		"reason_of_death": reason,
		"time_of_death": SimManager.instance.time,
		"position": agent.pos,
		"neuro_sensitivity": agent.neuro_sensitivity,
		"dopamine": agent.dopamine,
		"serotonin": agent.serotonin,
		"cortisol": agent.cortisol,
		"oxytocin": agent.oxytocin,
		"receptors": agent.receptors,
		"enzymes": agent.enzymes,
		# ---- БАЗОВЫЕ ПАРАМЕТРЫ ----
		"energy": agent.energy,
		"max_energy": agent.max_energy,
		"health": agent.health,
		"speed": agent.speed,
		"max_age": agent.max_age,
		"aging_rate": agent.aging_rate,
		"critical_energy_threshold": agent.critical_energy_threshold,
		"field_radius": agent.field_radius,
		"soliton_amplitude": agent.soliton_amplitude,
		"semantic_memory": agent.semantic_memory.clone() if agent.semantic_memory else null,
		# ---- СОСТОЯНИЯ ----
		"mood": agent.mood,
		"stress": agent.stress,
		"curiosity": agent.curiosity,
		"creative_immunity": agent.creative_immunity,
		"resonance_fatigue": agent.resonance_fatigue,
		"resonance_fatigue_decay": agent.resonance_fatigue_decay,
		"well_being": agent.well_being,
		"total_stability": agent.total_stability,
		"self_coherence": agent.self_coherence,
		"meta_identity": agent.meta_identity,
		"contradiction_tolerance": agent.contradiction_tolerance,
		"identity_erosion": agent.identity_erosion,
		"body_boundary": agent.body_boundary,
		"mental_map": agent.mental_map.clone() if agent.mental_map else null,
		# ---- ПОТРЕБНОСТИ ----
		"hunger": agent.hunger,
		"hunger_rate": agent.hunger_rate,
		"hunger_threshold": agent.hunger_threshold,
		"fatigue": agent.fatigue,
		"fatigue_rate": agent.fatigue_rate,
		"fatigue_threshold": agent.fatigue_threshold,
		"safety": agent.safety,
		"safety_decay_rate": agent.safety_decay_rate,
		"safety_threshold": agent.safety_threshold,

		# ---- ДВИЖЕНИЕ ----
		"momentum": agent.momentum,
		"momentum_decay": agent.momentum_decay,
		"sensitivity": agent.sensitivity,

		# ---- ИМЯ И ИДЕНТИЧНОСТЬ ----
		"self_name": agent.self_name,
		"has_name": agent.has_name,
		"identity": agent.identity,
		"narrative": agent.narrative,
		"myth": agent.myth,
		"anchors": agent.anchors,
		"anchors_list": agent.anchors_list,
		"memory_anchors": agent.memory_anchors,

		# ---- ПАМЯТЬ ----
		"memory": agent.memory.duplicate(true),
		"past_life_memories": agent.past_life_memories.duplicate(true),
		"reincarnation_awareness": agent.reincarnation_awareness,
		"personal_archetype": agent.personal_archetype,
		"archetype_links": agent.archetype_links,

		# ---- ЯЗЫК ----
		"markov_chain": agent.markov_chain.duplicate(true),
		"language_memory": agent.language_memory.duplicate(true),
		"word_usage": agent.word_usage.duplicate(true),
		"syllables": agent.syllables.duplicate(true),
		"meanings": agent.meanings.duplicate(true),
		"grammar_order": agent.grammar_order.duplicate(true),
		"language_insights": agent.language_insights.duplicate(true),
		"language_experience": agent.language_experience,
		"talk_modifier": agent.talk_modifier,
		"last_word": agent.last_word,

		# ---- СОЦИАЛЬНОЕ ----
		"trust": agent.trust.duplicate(true),
		"trust_bonus": agent.trust_bonus,
		"social_buffers": agent.social_buffers.duplicate(true),
		"resonance_history": agent.resonance_history.duplicate(true),
		"shadow_depth": agent.shadow_depth,
		"shadow_integrated": agent.shadow_integrated,

		# ---- ТЕЛЕСНОСТЬ ----
		"cell_body": agent.cell_body.duplicate(true),

		# ---- ПАРАМЕТРЫ ОБУЧЕНИЯ (HEBB) ----
		"hebb_params": {
			"sensory_rate": agent.sensory_ganglion.hebb_rate if agent.sensory_ganglion else 0.01,
			"sensory_decay": agent.sensory_ganglion.hebb_decay if agent.sensory_ganglion else 0.001,
			"sensory_threshold": agent.sensory_ganglion.hebb_threshold if agent.sensory_ganglion else 0.1,
			"sensory_momentum": agent.sensory_ganglion.hebb_momentum if agent.sensory_ganglion else 0.9,
			"proprioceptive_rate": agent.proprioceptive_ganglion.hebb_rate if agent.proprioceptive_ganglion else 0.01,
			"proprioceptive_decay": agent.proprioceptive_ganglion.hebb_decay if agent.proprioceptive_ganglion else 0.001,
			"proprioceptive_threshold": agent.proprioceptive_ganglion.hebb_threshold if agent.proprioceptive_ganglion else 0.1,
			"proprioceptive_momentum": agent.proprioceptive_ganglion.hebb_momentum if agent.proprioceptive_ganglion else 0.9,
			"social_rate": agent.social_ganglion.hebb_rate if agent.social_ganglion else 0.01,
			"social_decay": agent.social_ganglion.hebb_decay if agent.social_ganglion else 0.001,
			"social_threshold": agent.social_ganglion.hebb_threshold if agent.social_ganglion else 0.1,
			"social_momentum": agent.social_ganglion.hebb_momentum if agent.social_ganglion else 0.9,
			"motor_rate": agent.motor_ganglion.hebb_rate if agent.motor_ganglion else 0.01,
			"motor_decay": agent.motor_ganglion.hebb_decay if agent.motor_ganglion else 0.001,
			"motor_threshold": agent.motor_ganglion.hebb_threshold if agent.motor_ganglion else 0.1,
			"motor_momentum": agent.motor_ganglion.hebb_momentum if agent.motor_ganglion else 0.9,
			"meta_rate": agent.meta_ganglion.hebb_rate if agent.meta_ganglion else 0.01,
			"meta_decay": agent.meta_ganglion.hebb_decay if agent.meta_ganglion else 0.001,
			"meta_threshold": agent.meta_ganglion.hebb_threshold if agent.meta_ganglion else 0.1,
			"meta_momentum": agent.meta_ganglion.hebb_momentum if agent.meta_ganglion else 0.9,
			"meta_meta_rate": agent.meta_meta_ganglion.hebb_rate if agent.meta_meta_ganglion else 0.01,
			"meta_meta_decay": agent.meta_meta_ganglion.hebb_decay if agent.meta_meta_ganglion else 0.001,
			"meta_meta_threshold": agent.meta_meta_ganglion.hebb_threshold if agent.meta_meta_ganglion else 0.1,
			"meta_meta_momentum": agent.meta_meta_ganglion.hebb_momentum if agent.meta_meta_ganglion else 0.9,
		},

		# ---- ПАРАМЕТРЫ МЕТА-МЕТА ----
		"meta_meta_hebb_rate": agent.meta_meta_hebb_rate,
		"meta_meta_hebb_decay": agent.meta_meta_hebb_decay,
		"meta_meta_hebb_threshold": agent.meta_meta_hebb_threshold,
		"meta_meta_hebb_momentum": agent.meta_meta_hebb_momentum,

		# ---- ПАРАМЕТРЫ РЕФЛЕКСИИ ----
		"reflection_params": agent._reflection_params.duplicate(true) if agent.has_method("get_reflection_params") else {},

		# ---- СОЦИАЛЬНЫЕ ПАРАМЕТРЫ ----
		"social_params": agent._social_params.duplicate(true) if agent.has_method("get_social_params") else {},

		# ---- РИТУАЛЫ (НОВОЕ) ----
		"current_ritual": agent.current_ritual.duplicate() if agent.has_method("get_current_ritual") else [],
		"ritual_memory": agent.ritual_memory.duplicate(true) if agent.has_method("get_ritual_memory") else {},
		"ritual_activation_threshold": agent.ritual_activation_threshold if agent.has_method("get_ritual_activation_threshold") else 0.3,

		# ---- ПОВЕДЕНЧЕСКИЙ ГРАФ ----
		"behavior_graph": agent.behavior_graph.duplicate(true),
		"current_state": agent.current_state,
		"graph_version": agent.graph_version,
		"invented_states": agent.invented_states.duplicate(true),

		# ---- РЕСУРСЫ ----
		"has_key": agent.has_key,
		"has_home": agent.has_home,

		# ---- ИСТОРИЯ СОСТОЯНИЙ И ОШИБОК ----
		"state_history": agent.state_history.duplicate(true),
		"prediction_error_history": agent.prediction_error_history.duplicate(true),

		# ---- СЧЁТЧИКИ ----
		"free_will_acts": agent.free_will_acts,
		"trade_history": agent.trade_history.duplicate(true),

		# ---- ГАНГЛИИ (веса и архитектура) ----
		"ganglia": _collect_ganglia(agent)
	}
	return soul

# ---- СБОР ВЕСОВ ГАНГЛИЕВ ----
func _collect_ganglia(agent: Agent) -> Dictionary:
	var ganglia = {}
	if agent.sensory_ganglion:
		ganglia["sensory"] = agent.sensory_ganglion
	if agent.proprioceptive_ganglion:
		ganglia["proprioceptive"] = agent.proprioceptive_ganglion
	if agent.social_ganglion:
		ganglia["social"] = agent.social_ganglion
	if agent.motor_ganglion:
		ganglia["motor"] = agent.motor_ganglion
	if agent.meta_ganglion:
		ganglia["meta"] = agent.meta_ganglion
	if agent.meta_meta_ganglion:
		ganglia["meta_meta"] = agent.meta_meta_ganglion
	return ganglia

# ============================================================
#  РЕИНКАРНАЦИЯ — ЗАГРУЖАЕМ ДУШУ В НОВОГО АГЕНТА
# ============================================================
func reincarnate(agent: Agent, new_pos: Vector2, soul_data: Dictionary) -> bool:
	if not agent.use_reincarnation:
		return false
	if soul_data.is_empty():
		return false

	# ---- 1. ВОССТАНАВЛИВАЕМ БАЗОВЫЕ ПАРАМЕТРЫ ----
	agent.energy = soul_data.get("energy", 1.0)
	agent.max_energy = soul_data.get("max_energy", 5.0)
	agent.health = soul_data.get("health", 1.0)
	agent.speed = soul_data.get("speed", 0.15)
	agent.max_age = soul_data.get("max_age", 5000)
	agent.aging_rate = soul_data.get("aging_rate", 0.001)
	agent.critical_energy_threshold = soul_data.get("critical_energy_threshold", 0.2)
	agent.field_radius = soul_data.get("field_radius", 3)
	agent.soliton_amplitude = soul_data.get("soliton_amplitude", 1.0)
	agent.neuro_sensitivity = soul_data.get("neuro_sensitivity", {})
	agent.dopamine = soul_data.get("dopamine", 0.5)
	agent.serotonin = soul_data.get("serotonin", 0.5)
	agent.cortisol = soul_data.get("cortisol", 0.5)
	agent.oxytocin = soul_data.get("oxytocin", 0.3)
	agent.mood = soul_data.get("mood", 0.5)
	agent.stress = soul_data.get("stress", 0.0)
	agent.curiosity = soul_data.get("curiosity", 0.5)
	agent.creative_immunity = soul_data.get("creative_immunity", 0.0)
	agent.resonance_fatigue = soul_data.get("resonance_fatigue", 0.0)
	agent.resonance_fatigue_decay = soul_data.get("resonance_fatigue_decay", 0.01)
	agent.well_being = soul_data.get("well_being", 0.5)
	agent.total_stability = soul_data.get("total_stability", 0.5)
	agent.self_coherence = soul_data.get("self_coherence", 0.7)
	agent.meta_identity = soul_data.get("meta_identity", 0.0)
	agent.contradiction_tolerance = soul_data.get("contradiction_tolerance", 0.0)
	agent.identity_erosion = soul_data.get("identity_erosion", 0.0)
	agent.body_boundary = soul_data.get("body_boundary", 1.0)
	agent.receptors = soul_data.get("receptors", {})
	agent.enzymes = soul_data.get("enzymes", {})
	# Мутация при реинкарнации
	agent._mutate_receptors_and_enzymes(0.07)

	# ---- 2. ПОТРЕБНОСТИ ----
	agent.hunger = soul_data.get("hunger", 0.0)
	agent.hunger_rate = soul_data.get("hunger_rate", 0.003)
	agent.hunger_threshold = soul_data.get("hunger_threshold", 0.6)
	agent.fatigue = soul_data.get("fatigue", 0.0)
	agent.fatigue_rate = soul_data.get("fatigue_rate", 0.002)
	agent.fatigue_threshold = soul_data.get("fatigue_threshold", 0.6)
	agent.safety = soul_data.get("safety", 1.0)
	agent.safety_decay_rate = soul_data.get("safety_decay_rate", 0.001)
	agent.safety_threshold = soul_data.get("safety_threshold", 0.3)

	# ---- 3. ДВИЖЕНИЕ ----
	agent.momentum = soul_data.get("momentum", Vector2.ZERO)
	agent.momentum_decay = soul_data.get("momentum_decay", 0.9)
	agent.sensitivity = soul_data.get("sensitivity", 0.5)

	# ---- 4. ИМЯ И ИДЕНТИЧНОСТЬ ----
	agent.self_name = soul_data.get("self_name", "")
	agent.has_name = soul_data.get("has_name", false)
	agent.identity = soul_data.get("identity", "")
	agent.narrative = soul_data.get("narrative", "")
	agent.myth = soul_data.get("myth", "")
	agent.anchors = soul_data.get("anchors", {})
	agent.anchors_list = soul_data.get("anchors_list", [])
	agent.memory_anchors = soul_data.get("memory_anchors", 0)

	# ---- 5. ПАМЯТЬ ----
	agent.memory = soul_data.get("memory", [])
	agent.past_life_memories = soul_data.get("past_life_memories", [])
	agent.reincarnation_awareness = soul_data.get("reincarnation_awareness", false)
	agent.personal_archetype = soul_data.get("personal_archetype", "")
	agent.archetype_links = soul_data.get("archetype_links", [])
	if soul_data.has("mental_map") and soul_data.mental_map:
		agent.mental_map = soul_data.mental_map
		agent.mental_map.mutate(0.1, 0.3)  # мутация при рождении
	else:
		agent.mental_map = MentalMap.new(16, 12, 16)
	# ---- 6. ЯЗЫК ----
	agent.markov_chain = soul_data.get("markov_chain", {})
	agent.language_memory = soul_data.get("language_memory", {})
	agent.word_usage = soul_data.get("word_usage", {})
	agent.syllables = soul_data.get("syllables", {})
	agent.meanings = soul_data.get("meanings", {})
	agent.grammar_order = soul_data.get("grammar_order", ["subject", "action", "object"])
	agent.language_insights = soul_data.get("language_insights", [])
	agent.language_experience = soul_data.get("language_experience", 0)
	agent.talk_modifier = soul_data.get("talk_modifier", 0.0)
	agent.last_word = soul_data.get("last_word", "")

	# ---- 7. СОЦИАЛЬНОЕ ----
	agent.trust = soul_data.get("trust", {})
	agent.trust_bonus = soul_data.get("trust_bonus", 0.0)
	agent.social_buffers = soul_data.get("social_buffers", [])
	agent.resonance_history = soul_data.get("resonance_history", [])
	agent.shadow_depth = soul_data.get("shadow_depth", 0.0)
	agent.shadow_integrated = soul_data.get("shadow_integrated", false)

	# ---- 8. ТЕЛЕСНОСТЬ ----
	agent.cell_body = soul_data.get("cell_body", agent.cell_body)

	# ---- 9. ПАРАМЕТРЫ HEBB ----
	var hebb = soul_data.get("hebb_params", {})
	_apply_hebb_params(agent, hebb)

	# ---- 10. МЕТА-МЕТА ПАРАМЕТРЫ ----
	agent.meta_meta_hebb_rate = soul_data.get("meta_meta_hebb_rate", 0.01)
	agent.meta_meta_hebb_decay = soul_data.get("meta_meta_hebb_decay", 0.001)
	agent.meta_meta_hebb_threshold = soul_data.get("meta_meta_hebb_threshold", 0.1)
	agent.meta_meta_hebb_momentum = soul_data.get("meta_meta_hebb_momentum", 0.9)

	# ---- 11. ПАРАМЕТРЫ РЕФЛЕКСИИ ----
	agent._reflection_params = soul_data.get("reflection_params", {})
	if agent._reflection_params.is_empty():
		agent._reflection_params = {
			"base_frequency": 0.01 + randf() * 0.03,
			"prediction_window": 3 + randi() % 5,
			"error_threshold": 0.1 + randf() * 0.2,
			"meta_gain": 0.01 + randf() * 0.02,
			"alter_ego_threshold": 0.4 + randf() * 0.3,
			"superposition_threshold": 0.5 + randf() * 0.3,
		}

	# ---- 12. СОЦИАЛЬНЫЕ ПАРАМЕТРЫ ----
	agent._social_params = soul_data.get("social_params", {})
	if agent._social_params.is_empty():
		agent._social_params = {
			"resonance_range": 5.0 + randf() * 4.0,
			"speech_range": 4.0 + randf() * 3.0,
			"cooperation_threshold": 0.3 + randf() * 0.4,
			"aggression_threshold": 0.6 + randf() * 0.3,
			"trust_decay": 0.001 + randf() * 0.002,
			"social_learning_rate": 0.1 + randf() * 0.2,
		}

	# ---- 13. РИТУАЛЫ (НОВОЕ) ----
	agent.current_ritual = soul_data.get("current_ritual", [])
	agent.ritual_memory = soul_data.get("ritual_memory", {})
	agent.ritual_activation_threshold = soul_data.get("ritual_activation_threshold", 0.3 + randf() * 0.3)

	# ---- 14. ПОВЕДЕНЧЕСКИЙ ГРАФ ----
	agent.behavior_graph = soul_data.get("behavior_graph", {})
	agent.current_state = soul_data.get("current_state", "idle")
	agent.graph_version = soul_data.get("graph_version", 1)
	agent.invented_states = soul_data.get("invented_states", [])

	# ---- 15. РЕСУРСЫ ----
	agent.has_key = soul_data.get("has_key", false)
	agent.has_home = soul_data.get("has_home", false)

	# ---- 16. ИСТОРИЯ ----
	agent.state_history = soul_data.get("state_history", [])
	agent.prediction_error_history = soul_data.get("prediction_error_history", [])

	# ---- 17. СЧЁТЧИКИ ----
	agent.free_will_acts = soul_data.get("free_will_acts", 0)
	agent.trade_history = soul_data.get("trade_history", [])
	if soul_data.has("semantic_memory") and soul_data.semantic_memory:
		agent.semantic_memory = soul_data.semantic_memory
		agent.semantic_memory.mutate(0.1, 0.2)  # небольшая мутация при рождении
	else:
		agent.semantic_memory = SemanticMemory.new()
		agent.semantic_memory.embedding_dim = 8
		agent.semantic_memory.learning_rate = randf_range(0.05, 0.15)
	# ---- 18. ГАНГЛИИ (с мутацией) ----
	var ganglia = soul_data.get("ganglia", {})
	if ganglia.is_empty():
		agent._init_ganglia()
	else:
		_restore_ganglia(agent, ganglia)

	# ---- 19. ФИНАЛЬНЫЕ НАСТРОЙКИ ----
	agent.alive = true
	agent.is_ghost = false
	agent.ghost_message = ""
	agent.age = 0
	agent.pos = new_pos
	agent.resonance_active = false
	agent.resonance_partner = null
	agent.resonance_depth = 0.0

	# ---- 20. ИНСАЙТ О РЕИНКАРНАЦИИ ----
	if agent.memory_system:
		var past_name = soul_data.get("name", "unknown")
		var insight = "I remember: I was " + past_name + ". I have lived before."
		agent.memory_system.add_insight(agent, insight, agent.pos)
		if agent.reincarnation_awareness:
			agent.memory_system.add_insight(agent, "I have died before. I know this cycle.", agent.pos)

	# ---- 21. ЛОГИРОВАНИЕ ----
	var name_display = agent.self_name if agent.has_name else "unnamed"
	SimManager.instance.add_log("Реинкарнация: " + name_display + " родился заново в " + str(new_pos))
	# В конце reincarnate, перед возвратом
	agent._mutate_neuro_sensitivity()
	return true

# ---- ПРИМЕНЕНИЕ ПАРАМЕТРОВ HEBB ----
func _apply_hebb_params(agent: Agent, hebb: Dictionary):
	if agent.sensory_ganglion:
		agent.sensory_ganglion.hebb_rate = hebb.get("sensory_rate", 0.01)
		agent.sensory_ganglion.hebb_decay = hebb.get("sensory_decay", 0.001)
		agent.sensory_ganglion.hebb_threshold = hebb.get("sensory_threshold", 0.1)
		agent.sensory_ganglion.hebb_momentum = hebb.get("sensory_momentum", 0.9)
	if agent.proprioceptive_ganglion:
		agent.proprioceptive_ganglion.hebb_rate = hebb.get("proprioceptive_rate", 0.01)
		agent.proprioceptive_ganglion.hebb_decay = hebb.get("proprioceptive_decay", 0.001)
		agent.proprioceptive_ganglion.hebb_threshold = hebb.get("proprioceptive_threshold", 0.1)
		agent.proprioceptive_ganglion.hebb_momentum = hebb.get("proprioceptive_momentum", 0.9)
	if agent.social_ganglion:
		agent.social_ganglion.hebb_rate = hebb.get("social_rate", 0.01)
		agent.social_ganglion.hebb_decay = hebb.get("social_decay", 0.001)
		agent.social_ganglion.hebb_threshold = hebb.get("social_threshold", 0.1)
		agent.social_ganglion.hebb_momentum = hebb.get("social_momentum", 0.9)
	if agent.motor_ganglion:
		agent.motor_ganglion.hebb_rate = hebb.get("motor_rate", 0.01)
		agent.motor_ganglion.hebb_decay = hebb.get("motor_decay", 0.001)
		agent.motor_ganglion.hebb_threshold = hebb.get("motor_threshold", 0.1)
		agent.motor_ganglion.hebb_momentum = hebb.get("motor_momentum", 0.9)
	if agent.meta_ganglion:
		agent.meta_ganglion.hebb_rate = hebb.get("meta_rate", 0.01)
		agent.meta_ganglion.hebb_decay = hebb.get("meta_decay", 0.001)
		agent.meta_ganglion.hebb_threshold = hebb.get("meta_threshold", 0.1)
		agent.meta_ganglion.hebb_momentum = hebb.get("meta_momentum", 0.9)
	if agent.meta_meta_ganglion:
		agent.meta_meta_ganglion.hebb_rate = hebb.get("meta_meta_rate", 0.01)
		agent.meta_meta_ganglion.hebb_decay = hebb.get("meta_meta_decay", 0.001)
		agent.meta_meta_ganglion.hebb_threshold = hebb.get("meta_meta_threshold", 0.1)
		agent.meta_meta_ganglion.hebb_momentum = hebb.get("meta_meta_momentum", 0.9)

# ---- ВОССТАНОВЛЕНИЕ ГАНГЛИЕВ (С МУТАЦИЕЙ) ----
func _restore_ganglia(agent: Agent, ganglia: Dictionary):
	if ganglia.has("sensory"):
		agent.sensory_ganglion = ganglia["sensory"].clone(true)
		agent.sensory_ganglion.mutate(INHERITANCE_MUTATION_RATE, INHERITANCE_MUTATION_STRENGTH)
	else:
		agent.sensory_ganglion = Ganglion.new(6, 12, 4)
	if ganglia.has("proprioceptive"):
		agent.proprioceptive_ganglion = ganglia["proprioceptive"].clone(true)
		agent.proprioceptive_ganglion.mutate(INHERITANCE_MUTATION_RATE, INHERITANCE_MUTATION_STRENGTH)
	else:
		agent.proprioceptive_ganglion = Ganglion.new(6, 12, 3)
	if ganglia.has("social"):
		agent.social_ganglion = ganglia["social"].clone(true)
		agent.social_ganglion.mutate(INHERITANCE_MUTATION_RATE, INHERITANCE_MUTATION_STRENGTH)
	else:
		agent.social_ganglion = Ganglion.new(5, 16, 4)
	if ganglia.has("motor"):
		agent.motor_ganglion = ganglia["motor"].clone(true)
		agent.motor_ganglion.mutate(INHERITANCE_MUTATION_RATE, INHERITANCE_MUTATION_STRENGTH)
	else:
		agent.motor_ganglion = Ganglion.new(17, 16, 6)
	if ganglia.has("meta"):
		agent.meta_ganglion = ganglia["meta"].clone(true)
		agent.meta_ganglion.mutate(INHERITANCE_MUTATION_RATE, INHERITANCE_MUTATION_STRENGTH)
	else:
		agent.meta_ganglion = Ganglion.new(11, 16, 6)
	if ganglia.has("meta_meta"):
		agent.meta_meta_ganglion = ganglia["meta_meta"].clone(true)
		agent.meta_meta_ganglion.mutate(INHERITANCE_MUTATION_RATE, INHERITANCE_MUTATION_STRENGTH)
	else:
		agent.meta_meta_ganglion = Ganglion.new(12, 16, 4)

# ============================================================
#  ПРОВЕРКА СМЕРТИ (ВЫЗЫВАЕТСЯ ИЗ AGENT)
# ============================================================
func check_death(agent: Agent):
	if not agent.alive:
		return
	if agent.is_global_brain:
		return	
	if agent.energy <= 0.0:
		die(agent, "exhaustion")
		return
	if agent.health <= 0.0:
		die(agent, "disease")
		return

# ============================================================
#  ОБНОВЛЕНИЕ (ВЫЗЫВАЕТСЯ В AGENT.UPDATE)
# ============================================================
func update_agent(agent, delta: float):
	if agent.is_ghost:
		update_ghost(agent, delta)
	if not agent.alive and not agent.is_ghost:
		return

# ============================================================
#  ПРИЗРАКИ (ДЛЯ ПАМЯТИ)
# ============================================================
func update_ghost(agent, delta: float):
	if not agent.is_ghost:
		return
	agent.age += 1
	if agent.age > 1000:  # призрак исчезает
		agent.is_ghost = false
		agent.ghost_message = ""
		if agent.has_name:
			SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") ghost faded away")

func _become_ghost(agent, message: String):
	agent.is_ghost = true
	agent.ghost_message = message
	if agent.field_system:
		var amplitude = 0.1 + agent.memory_anchors * 0.01
		var radius = 4
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var pos = agent.pos + Vector2(dx, dy)
				var dist = Vector2(dx, dy).length()
				if dist > radius: continue
				var influence = amplitude * (1.0 - dist / radius)
				agent.field_system.set_field_at(pos, agent.field_system.get_field_at(pos) + influence)
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") became a ghost: " + message)
