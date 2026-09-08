extends RefCounted
class_name Agent

# ============================================================
#  БАЗОВЫЕ ПАРАМЕТРЫ
# ============================================================
var id: int
var pos: Vector2
var predator: bool
var alive: bool = true
var age: int = 0
var max_age: int = 5000
var aging_rate: float = 0.001
var soliton_amplitude: float = 1.0
var field_radius: int = 3
var critical_energy_threshold: float = 0.2
var energy: float = 1.0
var max_energy: float = 5.0
var health: float = 1.0
var speed: float = 0.15
var facing: Vector2 = Vector2.RIGHT
var speed_multiplier: float = 1.0
var subjective_time_delta: float = 1.0
var body_boundary: float = 1.0
var mood: float = 0.5
var stress: float = 0.0
var curiosity: float = 0.5
var total_stability: float = 0.5
var creative_immunity: float = 0.0
var resonance_fatigue: float = 0.0
var resonance_fatigue_decay: float = 0.01
var well_being: float = 0.5
var aggression_modifier: float = 0.0
# ---- ЯЗЫК-МАТРЕШКА (паттерны как свёрнутые смыслы) ----
var pattern_memory: Dictionary = {}           # {pattern_hash: {vector: Array, meaning: String, history: Array, frequency: int}}
var pattern_keys: Array = []                 # список хешей для быстрого доступа
var max_patterns: int = 30
var pattern_emission_cooldown: int = 0
var pattern_emission_interval: int = 5
# ---- НЕЗНАНИЕ И ВООБРАЖЕНИЕ ----
var ignorance: float = 0.0           # 0..1, уровень неопределённости (активное незнание)
var imagination_active: bool = false
var imagined_patterns: Array = []    # {pattern: Array, meaning: String, strength: float}
var max_imagined_patterns: int = 3
var imagination_cooldown: int = 0
var imagination_energy_cost: float = 0.03
var ignorance_decay: float = 0.002   # пассивное забывание незнания
var ignorance_gain_on_reflection: float = 0.01  # за каждый шаг рефлексии
# ---- КЭШ ДЛЯ РАЗВЁРТЫВАНИЯ ----
var expansion_cache: Dictionary = {}          # {pattern_hash: expanded_string}
# ---- РЕФЛЕКСИЯ ВТОРОГО ПОРЯДКА (непрерывная) ----
var reflection_clock: int = 0
var reflection_interval: int = 10  # базовый интервал, будет модифицироваться
var last_insight_for_reflection: String = ""
var meta_reflection_cooldown: int = 0
var reflection_depth: float = 0.0  # 0..1, глубина текущей рефлексии
var meta_insight_queue: Array = []  # очередь мета-инсайтов для обработки
# ---- ЕДИНАЯ ПАМЯТЬ (прошлое + будущее + гипотетическое) ----
var unified_memory: Array = []           # [{nature: "past"/"future"/"hypothetical", content: String, state: Dictionary, weight: float, time: int, source: String}]
var max_unified_memory: int = 50
var memory_decay_rate: float = 0.002     # естественное забывание
var memory_boost_on_confirm: float = 0.3 # усиление при подтверждении
var memory_boost_on_resonance: float = 0.1
# ---- СТАТИСТИКИ И КЛАСТЕРЫ ----
# ---- ДЕРЕВО СЦЕНАРИЕВ (глубокое возможное) ----
var scenario_tree: Array = []          # [{state: Dictionary, probability: float, depth: int, children: Array}]
var tree_update_interval: int = 40
var tree_clock: int = 0
var max_tree_depth: int = 3            # будет вычисляться из состояния
var max_branching: int = 2
var stat_window: int = 20
var stat_history: Dictionary = {}
var stat_features: Dictionary = {}
var cluster_update_counter: int = 0
const CLUSTER_UPDATE_INTERVAL: int = 50
var memory_clusters: Array = []
# ---- ЯЗЫК ВОЗМОЖНОГО (ветвление будущего) ----
var possible_futures: Array = []           # [{state: Dictionary, probability: float, age: int}]
var max_futures: int = 3                   # сколько сценариев удерживаем
var future_update_interval: int = 30
var future_clock: int = 0
var hypothesis_memory: Array = []          # [{type: "hypothesis", content: String, time: int}]
# ---- САМООПИСАНИЕ ----
var last_self_description_time: int = 0
var self_description_interval: float = 0.0
# ---- ЭМОЦИОНАЛЬНАЯ ПАМЯТЬ (для волн) ----
var pheromone_memory: Dictionary = {"pleasure": [], "fear": [], "trust": []}
const PHEROMONE_MEMORY_SIZE: int = 10

# ---- СЕМАНТИЧЕСКАЯ ПАМЯТЬ (квалиа-сеть) ----
var semantic_memory: SemanticMemory = null

# ---- НЕЙРОХИМИЯ (эмерджентная) ----
var dopamine: float = 0.5
var serotonin: float = 0.5
var cortisol: float = 0.5
var oxytocin: float = 0.3

# ---- РЕЦЕПТОРЫ И ФЕРМЕНТЫ ----
var receptors: Dictionary = {}
var enzymes: Dictionary = {}

# Коэффициенты чувствительности (индивидуальные, наследуются)
var neuro_sensitivity: Dictionary = {
	"dopamine_to_mood": 0.5,
	"serotonin_to_mood": 0.5,
	"cortisol_to_stress": 0.7,
	"oxytocin_to_stress": -0.3,
	"dopamine_to_curiosity": 0.6,
	"serotonin_to_curiosity": 0.4
}

# ---- ПЕРЕМЕННЫЕ ДЛЯ МЕТА-РЕФЛЕКСИИ ----
var _predicted_state: Array = []
var _prediction_time: int = 0
var _prediction_error_history: Array = []

# ---- ЭМЕРДЖЕНТНЫЕ ИМЕНА (через резонанс) ----
var other_profiles: Dictionary = {}
var other_names: Dictionary = {}
var profile_learning_rate: float = 0.1

# ---- ЗВУКОВЫЕ ПАТТЕРНЫ (эмерджентные слоги) ----
var sound_patterns: Array = []
var pattern_usage: Dictionary = {}
var pattern_learning_rate: float = 0.05


# ---- ПАРАМЕТРЫ КОММУНИКАЦИИ ----
var comm_params: Dictionary = {}

# ---- ОСТАЛЬНЫЕ ПАРАМЕТРЫ ----
var _social_params: Dictionary = {}
var _reflection_params: Dictionary = {}
var personal_enemies: Array = []
var enemy_memory: Dictionary = {}
const MAX_ENEMIES: int = 5

var inner_copies: Array = []
var action_history: Array = []
var well_being_history: Array = []
var is_global_brain: bool = false
var current_ritual: Array = []
var current_ritual_id: String = ""
var ritual_memory: Dictionary = {}
var ritual_activation_threshold: float = 0.3
var seeds_count: int = 0

var state_history: Array = []
const STATE_HISTORY_LENGTH: int = 10
var prediction_error_history: Array = []
const ERROR_HISTORY_LENGTH: int = 20

var meta_meta_hebb_rate: float = 0.01
var meta_meta_hebb_decay: float = 0.001
var meta_meta_hebb_threshold: float = 0.1
var meta_meta_hebb_momentum: float = 0.9

# ---- ГАНГЛИИ ----
var sensory_ganglion: Ganglion
var proprioceptive_ganglion: Ganglion
var social_ganglion: Ganglion
var motor_ganglion: Ganglion
var meta_ganglion: Ganglion
var meta_meta_ganglion: Ganglion
var decision_ganglion: Ganglion

# ---- ПОВЕДЕНЧЕСКИЙ ГРАФ ----
var behavior_graph: Dictionary = {}
var current_state: String = "idle"
var graph_version: int = 1
var graph_memory: Array = []
var invented_states: Array = []
var state_effectiveness: Dictionary = {}
var state_usage: Dictionary = {}
var graph_innovation_cooldown: int = 0
var graph_analysis_cooldown: int = 0
var has_imitated: bool = false
var copied_actions: Array = []

# ---- МЕНТАЛЬНАЯ КАРТА ----
var mental_map: MentalMap = null
var last_prediction: Array = []
var surprise: float = 0.0
var surprise_history: Array = []
const SURPRISE_WINDOW: int = 10

# ---- МЕТА-РЕФЛЕКСИЯ ----
var inner_voice_active: bool = false
var inner_voice_name: String = ""
var inner_voice_memory: Array = []
var last_inner_dialogue_time: int = 0
var possessed_by_global_brain: bool = false
var meta_cooldown: int = 0
var reflecting: bool = false
var ref_depth: float = 0.0
var self_model: Dictionary = {}
var world_model: Dictionary = {}
var meta_reflections: Array = []
var suicide_contemplation: bool = false
var suicide_attempted: bool = false
var alter_ego_active: bool = false
var alter_ego_name: String = ""
var alter_ego_narrative: String = ""
var dissociative_stress: float = 0.0
var superposition_active: bool = false
var identity_weights: Dictionary = {}
var reflection_cooldown: int = 0
var free_will_acts: int = 0
var existential_identity: String = ""
var abandoned_name: bool = false

const ACTION_TYPES = ["move", "speak", "resonate", "rest", "eat", "attack", "cooperate", "ritual", "reflect", "idle", "heal_self", "imagine"]

# ---- DREAM/RITUAL ----
var dream_active: bool = false
var dream_content: String = ""
var dream_duration: int = 0
var sleep_guard = null
var sleep_guard_requested: bool = false
var sleep_guard_agreed: bool = false
var sleep_duration: int = 0
var memes: Array = []
var spread_meme_cooldown: int = 0
var moment_active: bool = false
var moment_duration: int = 0
var moment_timer: int = 0
var moment_insights: Array = []

# ---- DEATH/REINCARNATION ----
var is_ghost: bool = false
var ghost_message: String = ""
var past_life_memories: Array = []
var reincarnation_awareness: bool = false
var personal_archetype: String = ""
var archetype_links: Array = []

# ---- ЯЗЫК ----
var lexicon: Array = []
var context_mem: Dictionary = {}
var grammar_order: Array = ["subject", "action", "object"]
var language_insights: Array = []
var language_experience: int = 0
var language_conflicts: Array = []
var grammar_evolution_cooldown: int = 0
var talk_modifier: float = 0.0
var language_memory: Dictionary = {}
var word_usage: Dictionary = {}
var word_decay_rate: float = 0.001
var markov_chain: Dictionary = {}
var chain_order: int = 2
var syllables: Dictionary = {
	"food": ["nu", "ka", "ma", "ri"],
	"danger": ["za", "ro", "gi", "tu"],
	"explore": ["le", "so", "mi", "pa"],
	"help": ["ve", "na", "se", "ko"],
	"resonance": ["ru", "dy", "ve", "na"]
}
var meanings: Dictionary = {}
var language_system = null
var last_word: String = ""
# ---- РЕФЛЕКСИЯ ВТОРОГО ПОРЯДКА (наблюдение за собой) ----
var observation_layer: Dictionary = {
	"active": false,
	"depth": 0.0,              # 0..1, глубина рефлексии
	"target": "self",          # "self", "other", "world"
	"insight_chain": []        # последние инсайты для мета-рефлексии
}
var meta_insights: Array = []  # [{content: String, depth: int, time: int}]
var max_meta_insights: int = 5

# ---- ВРЕМЕННЫЕ ГОРИЗОНТЫ ----
var time_horizon: String = "short"  # "short", "medium", "long"
var horizon_shift: float = 0.0      # непрерывное смещение (-1..1)
var temporal_memory: Array = []     # [{time: int, state: Dictionary, horizon: String}]
var max_temporal_memory: int = 10
# ---- СОЦИАЛЬНОЕ ----
var trust: Dictionary = {}
var trust_bonus: float = 0.0
var social_buffers: Array = []
var resonance_active: bool = false
var resonance_partner = null
var resonance_depth: float = 0.0
var resonance_history: Array = []
var shadow_partner = null
var shadow_depth: float = 0.0
var shadow_integrated: bool = false

# ---- ИМЯ ----
var self_name: String = ""
var has_name: bool = false
var identity: String = ""
var narrative: String = ""
var myth: String = ""
var meta_identity: float = 0.0
var name_power: float = 0.0
var anchors: Dictionary = {}
var contradiction_tolerance: float = 0.0
var identity_erosion: float = 0.0

# ---- ПАМЯТЬ ----
var memory: Array = []
var memory_anchors: int = 0
var anchors_list: Array = []
var invented_contexts: Array = []

# ---- РЕСУРСЫ ----
var has_key: bool = false
var has_home: bool = false
var altitude: int = 0
var trade_history: Array = []

var cell_body = {
	"nucleus": {"dna_integrity": 1.0, "transcription_rate": 0.5},
	"membrane": {"receptors": [], "integrity": 1.0, "permeability": 0.5, "charge": 0.0},
	"cytoskeleton": {"tension": 0.5, "pseudopodia": [], "max_pseudopodia": 4},
	"metabolism": {"phase": "rest", "cycle_phase": 0.0, "waste": 0.0, "recycling_rate": 0.1},
	"endosome": {"phagosomes": [], "lysosomes": [], "digestion_progress": 0.0},
	"immunological_memory": {}
}
var self_coherence: float = 0.7

# ---- ПОТРЕБНОСТИ ----
var hunger: float = 0.0
var hunger_rate: float = 0.003
var hunger_threshold: float = 0.6
var is_hungry: bool = false
var fatigue: float = 0.0
var fatigue_rate: float = 0.002
var fatigue_threshold: float = 0.6
var is_tired: bool = false
var safety: float = 1.0
var safety_decay_rate: float = 0.001
var safety_threshold: float = 0.3
var is_unsafe: bool = false

# ---- ДВИЖЕНИЕ ----
var momentum: Vector2 = Vector2.ZERO
var momentum_decay: float = 0.9
var sensitivity: float = 0.5

# ---- ССЫЛКИ НА СИСТЕМЫ ----
var field_system: FieldSystem = null
var stability_system: StabilitySystem = null
var movement_system: MovementSystem = null
var memory_system: MemorySystem = null
var behavior_graph_system: BehaviorGraphSystem = null
var social_system: SocialSystem = null
var dream_ritual_system: DreamRitualSystem = null
var death_reincarnation_system: DeathReincarnationSystem = null
var meta_reflection_system: MetaReflectionSystem = null

# ============================================================
#  ИНИЦИАЛИЗАЦИЯ
# ============================================================
func _init(agent_id: int, position: Vector2, pred: bool = false):
	id = agent_id
	pos = position
	predator = pred
	energy = randf_range(0.5, 1.5)
	health = 1.0
	age = 0
	alive = true
	mood = 0.5
	stress = 0.0
	curiosity = 0.5
	creative_immunity = 0.0
	meta_identity = 0.0
	aggression_modifier = randf_range(-0.2, 0.2)
	mental_map = MentalMap.new(16, 12, 16)
	
	_init_anatomy()
	_init_ganglia()
	_init_social_params()
	_init_reflection_params()
	_init_inner_copies()
	_init_ritual_vars()
	_init_statistics()
	_init_sound_patterns()
	
	semantic_memory = SemanticMemory.new()
	semantic_memory.embedding_dim = 8
	semantic_memory.learning_rate = randf_range(0.05, 0.15)
	
	_predicted_state = []
	_prediction_time = 0
	_prediction_error_history = []
	
	dopamine = randf_range(0.3, 0.7)
	serotonin = randf_range(0.3, 0.7)
	cortisol = randf_range(0.3, 0.7)
	oxytocin = randf_range(0.2, 0.5)
	
	neuro_sensitivity.dopamine_to_mood = randf()
	neuro_sensitivity.serotonin_to_mood = 1.0 - neuro_sensitivity.dopamine_to_mood
	neuro_sensitivity.cortisol_to_stress = randf_range(0.5, 0.9)
	neuro_sensitivity.oxytocin_to_stress = -(1.0 - neuro_sensitivity.cortisol_to_stress) * 0.5
	neuro_sensitivity.dopamine_to_curiosity = randf_range(0.3, 0.8)
	neuro_sensitivity.serotonin_to_curiosity = 1.0 - neuro_sensitivity.dopamine_to_curiosity
	_mutate_neuro_sensitivity()
	
	comm_params = {
		"speech_power_base": randf_range(0.3, 2.0),
		"speech_range_base": randf_range(2.0, 10.0),
		"field_impact": randf_range(0.02, 0.2),
		"mutation_resistance": randf_range(0.0, 1.0),
		"trust_sensitivity": randf_range(0.0, 1.0),
		"stress_boost": randf_range(0.0, 1.0),
		"curiosity_range_mod": randf_range(0.0, 1.0),
	}
	# В конце _init, после остальных инициализаций:
	ignorance = randf_range(0.0, 0.3)
	imagination_active = false
	imagined_patterns = []
	imagination_cooldown = 0
func setup_systems(field, stability, movement, memory, behavior, social, dream, death, meta):
	field_system = field
	stability_system = stability
	movement_system = movement
	memory_system = memory
	behavior_graph_system = behavior
	social_system = social
	dream_ritual_system = dream
	death_reincarnation_system = death
	meta_reflection_system = meta
	if memory_system:
		memory_system.add_event(self, "birth", null, pos)

# ============================================================
#  АНАТОМИЯ И ГАНГЛИИ
# ============================================================
func _init_anatomy():
	cell_body.nucleus.dna_integrity = randf_range(0.7, 1.0)
	cell_body.nucleus.transcription_rate = randf_range(0.3, 0.8)
	_init_receptors(randi_range(2, 4))
	cell_body.cytoskeleton.tension = randf_range(0.3, 0.7)
	cell_body.cytoskeleton.pseudopodia = _generate_pseudopodia(2)
	cell_body.metabolism.phase = "rest"
	cell_body.metabolism.cycle_phase = randf()

func _init_receptors(count: int):
	var receptor_types = ["cytokine_alpha", "cytokine_beta", "danger_signal", "self_marker", "nutrient"]
	var receptors = []
	for i in range(count):
		var type = receptor_types[randi() % receptor_types.size()]
		var affinity = randf_range(0.3, 0.9)
		receptors.append({"type": type, "affinity": affinity, "active": true})
	cell_body.membrane.receptors = receptors

func _generate_pseudopodia(count: int) -> Array:
	var pods = []
	for i in range(count):
		var angle = randf() * TAU
		var length = 0.3 + randf() * 0.4
		pods.append(Vector2(cos(angle), sin(angle)) * length)
	return pods

func _init_ganglia():
	sensory_ganglion = Ganglion.new(6, 12, 4)
	proprioceptive_ganglion = Ganglion.new(6, 12, 3)
	social_ganglion = Ganglion.new(5, 16, 4)
	meta_ganglion = Ganglion.new(11, 16, 6)
	motor_ganglion = Ganglion.new(17, 16, 6)
	meta_meta_ganglion = Ganglion.new(12, 16, 4)
	decision_ganglion = Ganglion.new(16, 20, ACTION_TYPES.size())

# ============================================================
#  ОСНОВНОЙ ЦИКЛ UPDATE
# ============================================================
func update(delta: float = 1.0):
	if not alive: return
	# ---- ПРОВЕРКА ПОДТВЕРЖДЕНИЯ ПРОГНОЗОВ ----
	_check_and_confirm_predictions()
	_update_subjective_time(delta)
	var dt = subjective_time_delta
	age += 1
	_update_needs(dt)
	_update_neurotransmitter_dynamics(dt)
	_check_membrane_damage()
	if age > max_age:
		health -= aging_rate
		if health <= 0.0: die("old_age"); return
	_update_metabolic_phase(dt)
	_update_pseudopodia(dt)
	_update_body_boundary()
	_update_deficit_and_erosion(dt)
	_update_neurochemistry(dt)
	_update_pheromone_memory(dt)
	if stability_system and field_system:
		stability_system.update_agent(self, field_system, dt)
	if movement_system and field_system:
		movement_system.update_agent(self, field_system, stability_system, dt)
	if memory_system: memory_system.update_agent(self, dt)
	if behavior_graph_system: behavior_graph_system.update_agent(self, dt)
	if social_system: social_system.update_agent(self, dt); social_system.update_shadow(self, dt)
	if dream_ritual_system: dream_ritual_system.update_agent(self, dt); dream_ritual_system.process_moment(self, dt)
	if meta_reflection_system: meta_reflection_system.update_agent(self, dt)
	# ---- САМООПИСАНИЕ ----
	_self_describe()
	_check_expectations_and_dissonance()
	_check_panpsychism()
	_react_to_complexity()
	_check_shamanism()
	_check_recursive_loop()
	_check_asynchronicity()

	_process_enemies()
	_collect_nearby_resources()
	_interact_with_objects()
	_apply_free_will()
	_observe_and_imitate(dt)
	if momentum.length() > 0.01: facing = momentum.normalized()
	if pos.y < 20: altitude = 0
	elif pos.y < 40: altitude = 1
	else: altitude = 2

	if randf() < 0.02: _mutate_markov_chain()
	
	var input_vec = _build_mental_input()
	var prediction = mental_map.predict(input_vec)
	last_prediction = prediction
	var target_vec = _build_mental_target()
	mental_map.update_with_input(input_vec, prediction, target_vec, 0.1)
	
	var error = 0.0
	for i in range(prediction.size()):
		error += abs(prediction[i] - target_vec[i])
	error /= prediction.size()
	surprise_history.append(error)
	if surprise_history.size() > SURPRISE_WINDOW:
		surprise_history.pop_front()
	surprise = surprise_history.reduce(func(a,b): return a+b, 0.0) / surprise_history.size()
	
	_update_statistics(dt)
	_update_memory_clusters()
	_find_seeds()
		# ---- САМООПИСАНИЕ ----
	_self_describe()
	if seeds_count > 0 and randf() < 0.001:
		_plant_seeds()
	# ---- ЯЗЫК ВОЗМОЖНОГО ----
	_update_possible_futures()
	_update_scenario_tree()
	state_history.append({
		"energy": energy, "stress": stress, "mood": mood,
		"hunger": hunger, "fatigue": fatigue, "health": health,
		"curiosity": curiosity, "meta_identity": meta_identity, "age": age
	})
	if state_history.size() > STATE_HISTORY_LENGTH: state_history.pop_front()
	if age % 50 == 0:
		_update_enemy_memory()
# ---- ОБНОВЛЕНИЕ ЕДИНОЙ ПАМЯТИ ----
	_update_unified_memory_decay()
	# ---- РЕФЛЕКСИЯ ВТОРОГО ПОРЯДКА ----
	_update_reflection_layer()
	# ---- ВРЕМЕННЫЕ ГОРИЗОНТЫ ----
	_update_time_horizon()
	# ---- НЕПРЕРЫВНАЯ РЕФЛЕКСИЯ ВТОРОГО ПОРЯДКА ----
	_update_continuous_reflection(delta)
	_process_meta_insights()
	# ---- НЕЗНАНИЕ И ВООБРАЖЕНИЕ ----
	_update_ignorance_and_imagination(dt)
# ============================================================
#  ЭМЕРДЖЕНТНОЕ ИМЯ (через резонанс)
# ============================================================

func _init_sound_patterns():
	sound_patterns = []
	for i in range(3):
		var vec = []
		for j in range(4):
			vec.append(randf_range(-1.0, 1.0))
		sound_patterns.append(_normalize(vec))
		pattern_usage[i] = 0

func _normalize(vec: Array) -> Array:
	var norm = 0.0
	for v in vec:
		norm += v * v
	if norm == 0.0:
		return vec
	norm = sqrt(norm)
	var result = []
	for v in vec:
		result.append(v / norm)
	return result

func _collect_snapshot() -> Dictionary:
	return {
		"id": id,
		"pos": pos,
		"energy": energy,
		"max_energy": max_energy,
		"stress": stress,
		"mood": mood,
		"curiosity": curiosity,
		"dopamine": dopamine,
		"serotonin": serotonin,
		"cortisol": cortisol,
		"oxytocin": oxytocin,
		"meta_identity": meta_identity,
		"has_name": has_name,
		"self_name": self_name if has_name else "",
		"age": age,
		"momentum": momentum,
		"word_usage": word_usage.duplicate(),
		"last_word": last_word,
		"current_ritual": current_ritual.duplicate()
	}

func _snapshot_to_vector(snapshot: Dictionary) -> Array:
	var vec = []
	vec.append(snapshot.get("dopamine", 0.5))
	vec.append(snapshot.get("serotonin", 0.5))
	vec.append(snapshot.get("cortisol", 0.5))
	vec.append(snapshot.get("oxytocin", 0.5))
	vec.append(snapshot.get("curiosity", 0.5))
	vec.append(snapshot.get("stress", 0.5))
	vec.append(snapshot.get("meta_identity", 0.0))
	vec.append(snapshot.get("energy", 1.0) / snapshot.get("max_energy", 1.0))
	if field_system:
		vec.append(field_system.get_coherence_at(pos))
		vec.append(field_system.get_global_entropy())
	else:
		vec.append(0.5)
		vec.append(0.5)
	return vec

func update_profile_for(other_id: int, snapshot: Dictionary):
	var new_vector = _snapshot_to_vector(snapshot)
	if not other_profiles.has(other_id):
		other_profiles[other_id] = new_vector
	else:
		var current = other_profiles[other_id]
		for i in range(current.size()):
			current[i] += (new_vector[i] - current[i]) * profile_learning_rate
		other_profiles[other_id] = current
	
	var new_name = _generate_name_from_profile(other_profiles[other_id])
	var old_name = other_names.get(other_id, "")
	if new_name != old_name:
		other_names[other_id] = new_name
		var other = SimManager.instance.get_agent_by_id(other_id)
		if other and not other.has_name:
			other.self_name = new_name
			other.has_name = true
			SimManager.instance.add_log(str(id) + " named " + str(other_id) + " as " + new_name)
			if SimManager.instance.global_brain:
				SimManager.instance.global_brain.register_name(other_id, new_name)

func _generate_name_from_profile(profile: Array) -> String:
	var input = _build_rnn_input()
	input += profile
	if motor_ganglion:
		var expected_size = motor_ganglion.input_size
		if input.size() > expected_size:
			input = input.slice(0, expected_size)
		while input.size() < expected_size:
			input.append(0.0)
		
		var output = motor_ganglion.forward(input)
		
		# ---- ВЛИЯНИЕ ПОЛЯ ----
		var entropy = field_system.get_global_entropy() if field_system else 0.5
		var coherence = field_system.get_coherence_at(pos) if field_system else 0.5
		var field_val = field_system.get_field_at(pos) if field_system else 0.0
		
		# ---- ВЛИЯНИЕ НЕЙРОХИМИИ ----
		var dopamine_factor = profile[0] if profile.size() > 0 else 0.5
		var serotonin_factor = profile[1] if profile.size() > 1 else 0.5
		var cortisol_factor = profile[2] if profile.size() > 2 else 0.5
		
		for i in range(output.size()):
			# Поле: сдвиг к среднему в зависимости от когерентности
			var shift = (output[i] - 0.5) * (1.0 - coherence * 0.5)
			output[i] = 0.5 + shift
			# Энтропия: шум
			output[i] += randf_range(-entropy * 0.3, entropy * 0.3)
			# Амплитуда поля: усиливает разброс
			output[i] *= (1.0 + field_val * 0.1)
			# Дофамин: усиливает отклонение
			output[i] += (output[i] - 0.5) * dopamine_factor * 0.5
			# Серотонин: сглаживание
			if i > 0 and i < output.size() - 1:
				output[i] = output[i] * (1.0 - serotonin_factor * 0.3) + (output[i-1] + output[i+1]) * 0.5 * serotonin_factor * 0.3
			# Кортизол: всплески
			if cortisol_factor > 0.6 and randf() < 0.1:
				output[i] += randf_range(-0.2, 0.2)
			output[i] = clamp(output[i], -1.0, 1.0)
		
		var num_patterns = 2 + int(profile[0] * 2)
		var name_parts = []
		
		for i in range(num_patterns):
			var vec = []
			for j in range(min(4, output.size())):
				vec.append(output[j])
			vec = _normalize(vec)
			_update_sound_patterns(vec)
			var best_idx = 0
			var min_dist = 999.0
			for k in range(sound_patterns.size()):
				var dist = 0.0
				for j in range(4):
					dist += (vec[j] - sound_patterns[k][j]) * (vec[j] - sound_patterns[k][j])
				if dist < min_dist:
					min_dist = dist
					best_idx = k
			name_parts.append(str(best_idx))
		
		# ---- ИМЯ МЕНЯЕТ ВОСПРИЯТИЕ ПОЛЯ (ВЫНЕСЕНО ЗА ЦИКЛ) ----
		if has_name and field_system:
			# Агент с именем видит поле иначе
			var name_modifier = 1.0 + meta_identity * 0.2
			# Усиливает восприятие когерентности (используется при следующем вызове)
			# Создаёт локальный след в поле (один раз за генерацию имени)
			field_system.set_field_at(pos, field_system.get_field_at(pos) + meta_identity * 0.01)
			# Также можно модифицировать локальную переменную coherence, но она уже использована
			# Для обратной связи: имя влияет на поле, что повлияет на будущие имена
		
		return "_".join(name_parts)
	else:
		return "agent_" + str(randi() % 1000)

func _update_sound_patterns(new_vec: Array):
	var min_dist = 999.0
	var best_idx = -1
	for i in range(sound_patterns.size()):
		var dist = 0.0
		for j in range(4):
			dist += (new_vec[j] - sound_patterns[i][j]) * (new_vec[j] - sound_patterns[i][j])
		if dist < min_dist:
			min_dist = dist
			best_idx = i
	
	var threshold = 0.15
	if best_idx != -1 and min_dist < threshold:
		for j in range(4):
			sound_patterns[best_idx][j] += (new_vec[j] - sound_patterns[best_idx][j]) * pattern_learning_rate
		sound_patterns[best_idx] = _normalize(sound_patterns[best_idx])
		pattern_usage[best_idx] = pattern_usage.get(best_idx, 0) + 1
	else:
		if sound_patterns.size() < max_patterns:
			sound_patterns.append(_normalize(new_vec.duplicate()))
			pattern_usage[sound_patterns.size()-1] = 1
		else:
			var min_usage = 999
			var min_idx = 0
			for i in range(sound_patterns.size()):
				if pattern_usage.get(i, 0) < min_usage:
					min_usage = pattern_usage.get(i, 0)
					min_idx = i
			sound_patterns[min_idx] = _normalize(new_vec.duplicate())
			pattern_usage[min_idx] = 1

func share_patterns(target: Agent, fraction: float = 0.3):
	if not target or sound_patterns.is_empty():
		return
	var num_to_share = int(sound_patterns.size() * fraction)
	if num_to_share < 1:
		return
	var indices = []
	for i in range(sound_patterns.size()):
		indices.append(i)
	indices.shuffle()
	for i in range(num_to_share):
		var idx = indices[i]
		var pattern = sound_patterns[idx].duplicate()
		for j in range(pattern.size()):
			pattern[j] += randf_range(-0.05, 0.05)
		pattern = _normalize(pattern)
		if target.sound_patterns.size() < target.max_patterns:
			target.sound_patterns.append(pattern)
			target.pattern_usage[target.sound_patterns.size() - 1] = 1
		else:
			var min_usage = 999
			var min_idx = 0
			for k in range(target.sound_patterns.size()):
				if target.pattern_usage.get(k, 0) < min_usage:
					min_usage = target.pattern_usage.get(k, 0)
					min_idx = k
			target.sound_patterns[min_idx] = pattern
			target.pattern_usage[min_idx] = 1

# ============================================================
#  РЕЧЬ
# ============================================================
func _compose_word_from_state() -> String:
	var input = _build_rnn_input()
	var output = motor_ganglion.forward(input)
	var all_syllables = _get_all_syllables()
	var word_parts = []
	var length = randi_range(3, 6)
	for i in range(length):
		var idx = _sample_from_output(output)
		if idx < all_syllables.size():
			word_parts.append(all_syllables[idx])
		else:
			word_parts.append("seek")
	return "_".join(word_parts)

func _get_all_syllables() -> Array:
	var all = []
	for context in syllables.values():
		for syl in context:
			if syl not in all:
				all.append(syl)
	return all

func _sample_from_output(output: Array) -> int:
	var total = 0.0
	for val in output:
		total += max(val, 0.0)
	if total == 0.0:
		return randi() % output.size()
	var r = randf() * total
	var cum = 0.0
	for i in range(output.size()):
		cum += max(output[i], 0.0)
		if r <= cum:
			return i
	return output.size() - 1

func _speak_word() -> String:
	if energy <= 0.0:
		return ""
	
	# ---- 1. ГЕНЕРАЦИЯ ПАТТЕРНА ----
	var pattern_hash = _fold_state_into_pattern()
	
	# ---- 2. ЭМИССИЯ В ПОЛЕ ----
	pattern_emission_cooldown += 1
	if pattern_emission_cooldown >= pattern_emission_interval:
		pattern_emission_cooldown = 0
		_emit_pattern(pattern_hash)
	
	# ---- 3. РАЗВЁРТКА ПОЛЯ (восприятие) ----
	var expanded_meaning = _expand_pattern_from_field()
	if expanded_meaning != "" and memory_system:
		memory_system.add_insight(self, "I sense: " + expanded_meaning, pos)
	
	# ---- 4. ГЕНЕРАЦИЯ СЛОГОВ ДЛЯ ЛОГОВ (совместимость) ----
	var word = _compose_word_from_state()
	last_word = word
	word_usage[word] = word_usage.get(word, 0) + 1
	
	# Речевые затраты
	if field_system:
		var grad = field_system.get_gradient(pos)
		var grad_mag = grad.length()
		var coherence = field_system.get_coherence_at(pos)
		var speech_cost_factor = grad_mag * (1.0 - coherence) * (energy / max_energy)
		var speech_cost = energy * speech_cost_factor / (1.0 + speech_cost_factor)
		energy -= speech_cost
	else:
		energy -= energy * (1.0 - energy / max_energy)
	energy = max(energy, 0.0)
	
	_update_markov_chain(word)
	if memory_system:
		memory_system.add_event(self, "spoken_word", word, pos)
		# Если паттерн был новым, создаём инсайт
		if pattern_hash.to_int() in pattern_memory and pattern_memory[pattern_hash.to_int()].frequency == 1:
			memory_system.add_insight(self, "New pattern: " + word + " (" + pattern_hash + ")", pos)
	
	return word

# ============================================================
#  ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ (сохранены из оригинального кода)
# ============================================================

func _push_prediction_error(error: float):
	prediction_error_history.append(error)
	if prediction_error_history.size() > ERROR_HISTORY_LENGTH:
		prediction_error_history.pop_front()

func _update_neurotransmitter_dynamics(dt: float):
	if not field_system: return
	var nt_conc = field_system.get_all_neurotransmitters_at(pos)
	for nt in nt_conc.keys():
		var conc = nt_conc[nt]
		var affinity = receptors.get(nt, 0.5)
		var effect = conc * affinity * dt
		match nt:
			"dopamine": dopamine += effect * 0.3
			"serotonin": serotonin += effect * 0.2
			"norepinephrine": cortisol += effect * 0.2
			"oxytocin": oxytocin += effect * 0.4
			"glutamate": curiosity += effect * 0.1
			"gaba": stress -= effect * 0.2
		dopamine = clamp(dopamine, 0.0, 1.0)
		serotonin = clamp(serotonin, 0.0, 1.0)
		cortisol = clamp(cortisol, 0.0, 1.0)
		oxytocin = clamp(oxytocin, 0.0, 1.0)
		curiosity = clamp(curiosity, 0.0, 1.0)
		stress = clamp(stress, 0.0, 1.0)
	
	for nt in nt_conc.keys():
		var conc = nt_conc[nt]
		if conc > 0.0:
			var reuptake = enzymes.get(nt + "_reuptake", 0.01)
			var degradation = enzymes.get(nt + "_degradation", 0.01)
			var total_removal = conc * (reuptake + degradation) * dt
			var removal = min(total_removal, conc)
			field_system.add_neurotransmitter(pos, nt, -removal)
	_emit_neurotransmitters(dt)

func _get_recent_errors() -> Array:
	return prediction_error_history.duplicate()

func _apply_hebb_learning(strength: float = 1.0):
	if not alive or strength < 0.01: return
	var err_hist = _get_recent_errors()
	var avg_error = 0.0
	if err_hist.size() > 0:
		avg_error = err_hist.reduce(func(a,b): return a+b, 0.0) / err_hist.size()
	var error_trend = 0.0
	if err_hist.size() > 1:
		error_trend = err_hist[-1] - err_hist[0]
	
	var input = [
		avg_error, error_trend,
		meta_ganglion.hebb_rate if meta_ganglion else 0.01,
		meta_ganglion.hebb_decay if meta_ganglion else 0.001,
		meta_ganglion.hebb_threshold if meta_ganglion else 0.1,
		meta_ganglion.hebb_momentum if meta_ganglion else 0.9,
		energy / max_energy, stress, meta_identity,
		float(has_name), float(resonance_active), age / max_age
	]
	var output = meta_meta_ganglion.forward(input)
	var new_rate = clamp(output[0], 0.001, 0.1)
	var new_decay = clamp(output[1], 0.0001, 0.01)
	var new_threshold = clamp(output[2], 0.01, 0.5)
	var new_momentum = clamp(output[3], 0.1, 0.99)
	
	var actual_rate = new_rate * (0.5 + strength * 0.5)
	var actual_decay = new_decay * (0.5 + strength * 0.5)
	var actual_threshold = new_threshold * (0.5 + strength * 0.5)
	var actual_momentum = new_momentum * (0.5 + strength * 0.5)
	
	_set_hebb_params(actual_rate, actual_decay, actual_threshold, actual_momentum)
	_hebb_update_all(strength)
	meta_meta_ganglion.hebb_update(strength * 0.5)
	energy = max(0.0, energy - 0.001 * strength)

func _set_hebb_params(rate: float, decay: float, threshold: float, momentum: float):
	for g in [sensory_ganglion, proprioceptive_ganglion, social_ganglion, motor_ganglion, meta_ganglion]:
		if g:
			g.hebb_rate = rate
			g.hebb_decay = decay
			g.hebb_threshold = threshold
			g.hebb_momentum = momentum

func _hebb_update_all(strength: float):
	if sensory_ganglion: sensory_ganglion.hebb_update(strength * 0.1)
	if proprioceptive_ganglion: proprioceptive_ganglion.hebb_update(strength * 0.1)
	if social_ganglion: social_ganglion.hebb_update(strength * 0.3)
	if motor_ganglion: motor_ganglion.hebb_update(strength * 0.5)
	if meta_ganglion: meta_ganglion.hebb_update(strength * 0.7)

func _build_rnn_input() -> Array:
	var input = []
	input.append(energy / max_energy)
	input.append(stress)
	input.append(mood)
	input.append(hunger)
	input.append(fatigue)
	input.append(dopamine)
	input.append(serotonin)
	input.append(cortisol)
	input.append(oxytocin)
	input.append(meta_identity)
	input.append(float(has_name))
	input.append(float(resonance_active))
	input.append(float(social_buffers.size() > 0))
	input.append(surprise)
	input.append(age / max_age)
	input.append(total_stability)
	if field_system:
		input.append(field_system.get_field_at(pos))
		input.append(field_system.get_coherence_at(pos))
		var grad = field_system.get_gradient(pos)
		input.append(grad.x)
		input.append(grad.y)
	else:
		input.append(0.0); input.append(0.0); input.append(0.0); input.append(0.0)
	
	var avg_mood = 0.0; var avg_stress = 0.0; var avg_curiosity = 0.0; var count = 0
	if SimManager.instance:
		for other in SimManager.instance.agents:
			if other == self or not other.alive: continue
			if pos.distance_to(other.pos) < 8.0:
				avg_mood += other.mood; avg_stress += other.stress; avg_curiosity += other.curiosity; count += 1
	if count > 0:
		avg_mood /= count; avg_stress /= count; avg_curiosity /= count
	else:
		avg_mood = 0.5; avg_stress = 0.5; avg_curiosity = 0.5
	input.append(avg_mood); input.append(avg_stress); input.append(avg_curiosity)
	
	for i in range(3):
		var act = action_history[i] if i < action_history.size() else "idle"
		input.append(float(ACTION_TYPES.find(act)) / ACTION_TYPES.size())
	input.append(cell_body.membrane.get("integrity", 1.0))
	var enemy_factor = 0.0
	if not personal_enemies.is_empty():
		enemy_factor = personal_enemies.size() / MAX_ENEMIES
	input.append(enemy_factor)
	return input
func _fold_state_into_pattern() -> String:
	# Собираем текущее состояние в вектор
	var state_vector = [
		energy / max_energy,
		stress,
		mood,
		curiosity,
		meta_identity,
		dopamine,
		serotonin,
		cortisol,
		oxytocin,
		pos.x / 64.0,
		pos.y / 64.0,
		float(has_name),
		float(resonance_active),
		surprise,
		age / max_age,
		field_system.get_coherence_at(pos) if field_system else 0.5,
		field_system.get_field_at(pos) / 4.0 if field_system else 0.0
	]
	
	# Нормализуем вектор
	var norm = 0.0
	for v in state_vector:
		norm += v * v
	if norm > 0.0:
		norm = sqrt(norm)
		for i in range(state_vector.size()):
			state_vector[i] /= norm
	
	# Генерируем уникальный хеш (как простое число)
	var hash_str = ""
	for v in state_vector:
		hash_str += str(int(v * 1000)) + "_"
	var pattern_hash = hash_str.hash()
	
	# Проверяем, существует ли уже такой паттерн
	if pattern_memory.has(pattern_hash):
		pattern_memory[pattern_hash].frequency += 1
		return str(pattern_hash)
	
	# Создаём новый паттерн
	var meaning = _generate_meaning_from_state(state_vector)
	pattern_memory[pattern_hash] = {
		"vector": state_vector,
		"meaning": meaning,
		"history": [SimManager.instance.time if SimManager.instance else age],
		"frequency": 1
	}
	pattern_keys.append(str(pattern_hash))
	if pattern_keys.size() > max_patterns:
		_prune_patterns()
	
	return str(pattern_hash)

func _generate_meaning_from_state(vector: Array) -> String:
	# Из вектора генерируем "человеческое" значение для логов
	var parts = []
	if vector[0] > 0.7: parts.append("high_energy")
	elif vector[0] < 0.3: parts.append("low_energy")
	if vector[1] > 0.6: parts.append("stressed")
	if vector[2] > 0.6: parts.append("happy")
	if vector[3] > 0.6: parts.append("curious")
	if vector[4] > 0.5: parts.append("aware")
	if vector[5] > 0.6: parts.append("dopamine_high")
	if vector[6] > 0.6: parts.append("serotonin_high")
	if vector[7] > 0.6: parts.append("cortisol_high")
	if vector[8] > 0.5: parts.append("oxytocin_high")
	if parts.is_empty():
		return "neutral"
	return "_".join(parts)
func _emit_pattern(pattern_hash: String):
	if not field_system:
		return
	var id = pattern_hash.to_int()
	if not pattern_memory.has(id):
		return
	
	# Преобразуем паттерн в модуляцию поля
	var vector = pattern_memory[id].vector
	var amplitude = 0.05 + vector[0] * 0.05  # энергия влияет на силу
	var frequency = 0.5 + vector[1] * 0.5    # стресс влияет на частоту
	var phase = vector[2] * 6.28             # настроение влияет на фазу
	
	var radius = 2 + int(vector[3] * 2)      # любопытство расширяет радиус
	
	# Применяем модуляцию к полю вокруг агента
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var p = pos + Vector2(dx, dy)
			var dist = Vector2(dx, dy).length()
			if dist > radius:
				continue
			var influence = amplitude * (1.0 - dist / radius) * (0.5 + 0.5 * sin(frequency * dist + phase))
			field_system.set_field_at(p, field_system.get_field_at(p) + influence)
	
	# Оставляем долговременный след
	field_system.add_long_term_trace(pos, "pattern_" + pattern_hash, amplitude * 0.5)
	
func _expand_pattern_from_field() -> String:
	if not field_system:
		return ""
	
	# Анализируем локальное поле
	var local_patterns = []
	var radius = 4
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var p = pos + Vector2(dx, dy)
			var val = field_system.get_field_at(p)
			if abs(val) > 0.01:
				local_patterns.append(val)
	
	if local_patterns.is_empty():
		return ""
	
	# Ищем в памяти паттерн, похожий на локальное поле
	var best_match = null
	var best_sim = -1.0
	var target_vector = []
	for i in range(min(16, local_patterns.size())):
		target_vector.append(local_patterns[i] if i < local_patterns.size() else 0.0)
	
	# Нормализуем
	var norm = 0.0
	for v in target_vector:
		norm += v * v
	if norm > 0.0:
		norm = sqrt(norm)
		for i in range(target_vector.size()):
			target_vector[i] /= norm
	
	for id in pattern_memory.keys():
		var vec = pattern_memory[id].vector
		var sim = _cosine_similarity(target_vector, vec)
		if sim > best_sim:
			best_sim = sim
			best_match = id
	
	if best_match != null and best_sim > 0.5:
		var meaning = pattern_memory[best_match].meaning
		expansion_cache[str(best_match)] = meaning
		return meaning
	
	return ""

func _cosine_similarity(v1: Array, v2: Array) -> float:
	var dot = 0.0
	var n1 = 0.0
	var n2 = 0.0
	var size = min(v1.size(), v2.size())
	for i in range(size):
		dot += v1[i] * v2[i]
		n1 += v1[i] * v1[i]
		n2 += v2[i] * v2[i]
	if n1 == 0.0 or n2 == 0.0:
		return 0.0
	return dot / (sqrt(n1) * sqrt(n2))	
	
func _prune_patterns():
	# Удаляем наименее используемые паттерны
	var sorted_keys = pattern_keys.duplicate()
	sorted_keys.sort_custom(func(a, b):
		return pattern_memory[a.to_int()].frequency < pattern_memory[b.to_int()].frequency
	)
	var to_remove = sorted_keys.slice(0, max(1, pattern_keys.size() - max_patterns))
	for key in to_remove:
		var id = key.to_int()
		pattern_memory.erase(id)
		pattern_keys.erase(key)
		expansion_cache.erase(key)
# ---- МЕТОДЫ ДЛЯ ВНЕШНИХ СИСТЕМ ----
func perform_ritual(partner: Agent):
	if dream_ritual_system:
		dream_ritual_system.perform_ritual(self, partner)

func _inherit_past_life(memory_data: Dictionary):
	if memory_data.has("insights"):
		for insight in memory_data.insights:
			memory_system.add_insight(self, insight, pos)
	if memory_data.has("anchors"):
		for anchor in memory_data.anchors:
			add_anchor(anchor)

func _inherit_ganglia(ganglia_data: Dictionary):
	if ganglia_data.has("sensory"):
		sensory_ganglion = ganglia_data["sensory"].clone(); sensory_ganglion.mutate(0.05, 0.2)
	if ganglia_data.has("proprioceptive"):
		proprioceptive_ganglion = ganglia_data["proprioceptive"].clone(); proprioceptive_ganglion.mutate(0.05, 0.2)
	if ganglia_data.has("social"):
		social_ganglion = ganglia_data["social"].clone(); social_ganglion.mutate(0.05, 0.2)
	if ganglia_data.has("motor"):
		motor_ganglion = ganglia_data["motor"].clone(); motor_ganglion.mutate(0.05, 0.2)
	if ganglia_data.has("meta"):
		meta_ganglion = ganglia_data["meta"].clone(); meta_ganglion.mutate(0.05, 0.2)

func get_ganglia() -> Dictionary:
	return {"sensory": sensory_ganglion, "proprioceptive": proprioceptive_ganglion, "social": social_ganglion, "motor": motor_ganglion, "meta": meta_ganglion}

func interact(other: Agent):
	if social_system:
		social_system.interact(self, other)

func get_body_boundary() -> float: return body_boundary
func get_soliton_amplitude() -> float: return soliton_amplitude
func get_field_radius() -> int: return field_radius

func _remember_trade(resource: String, partner_id: int, success: bool):
	trade_history.append({"time": SimManager.instance.time if SimManager.instance else 0, "partner_id": partner_id, "resource": resource, "success": success})
	if trade_history.size() > 10:
		trade_history.pop_front()

# ---- ЗАГЛУШКИ ЭМЕРДЖЕНТНЫХ МЕХАНИК ----
func _check_expectations_and_dissonance(): pass
func _check_panpsychism(): pass
func _react_to_complexity(): pass
func _check_shamanism(): pass
func _check_recursive_loop(): pass
func _check_asynchronicity(): pass

# ---- ВЗАИМОДЕЙСТВИЕ С МИРОМ ----
func _process_enemies():
	if not alive or not SimManager.instance or is_global_brain: return
	var sim = SimManager.instance
	var nearby = sim.get_enemies_near(pos, 3.0)
	for enemy in nearby:
		if not enemy.alive: continue
		if enemy.has_method("is_global_brain") and enemy.is_global_brain: continue
		var dist = pos.distance_to(enemy.pos)
		if dist < 1.5:
			_take_enemy_damage(enemy)
		if energy > 0.5 and dist < 2.0 and randf() < 0.4:
			_attack_enemy(enemy)

func _take_enemy_damage(enemy):
	energy = max(0.0, energy - 0.05)
	stress = min(1.0, stress + 0.02)
	if energy <= 0.0: die("killed by enemy")

func _attack_enemy(enemy):
	energy -= 0.1
	enemy.take_damage(0.5)
	curiosity = min(1.0, curiosity + 0.01)
	creative_immunity = min(1.0, creative_immunity + 0.01)
	if not enemy.alive:
		_on_enemy_defeated(enemy)

func _on_enemy_defeated(enemy):
	if not enemy or enemy.alive: return
	memory_anchors += 1
	# Имя больше не даётся за победу — теперь только через резонанс

func _collect_nearby_resources():
	if not alive or not SimManager.instance or is_global_brain: return
	var sim = SimManager.instance
	for i in range(sim.resources.size() - 1, -1, -1):
		var res = sim.resources[i]
		var dist = pos.distance_to(res.pos)
		if dist < 2.0:
			_apply_resource_effect(res.type, res.amount)
			sim.resources.remove_at(i)
			if memory_system:
				memory_system.add_event(self, "collected_resource", {"type": res.type, "amount": res.amount}, pos)

func _apply_resource_effect(type: String, amount: float):
	match type:
		"food": hunger = max(0.0, hunger - amount * 0.3); energy = min(max_energy, energy + amount * 0.05)
		"coal": energy = min(max_energy, energy + amount * 0.2); stress = min(1.0, stress + 0.02)
		"copper": if memory_system: memory_system.add_invention(self, "copper_artifact", pos); creative_immunity = min(1.0, creative_immunity + 0.05)
		"crystal": if memory_system: var insights = memory_system.get_recent_insights(self, 1); if not insights.is_empty(): memory_system.add_event(self, "crystal_insight", "I remember: " + insights[0], pos); memory_anchors += 1
		"herb": stress = max(0.0, stress - 0.1); health = min(1.0, health + 0.02)
		"key": has_key = true

func _interact_with_objects():
	if not alive or not SimManager.instance or is_global_brain: return
	var sim = SimManager.instance
	for obj in sim.objects:
		var dist = pos.distance_to(obj.pos)
		if dist < 3.0:
			match obj.type:
				"statue":
					if randf() < 0.005:
						memory_system.add_insight(self, "I feel the presence of the ancient order.", pos)
						stress = max(0.0, stress - 0.02); self_coherence = min(1.0, self_coherence + 0.01)
					if memory_anchors > 0: total_stability = min(1.0, total_stability + 0.005)
				"furnace":
					if has_key and dream_ritual_system:
						dream_ritual_system.perform_ritual(self, self)
						creative_immunity = min(1.0, creative_immunity + 0.1)
					else:
						energy = min(max_energy, energy + 0.02); stress = min(1.0, stress + 0.01)
				"castle":
					if dist < 2.0:
						energy = min(max_energy, energy + 0.005); stress = max(0.0, stress - 0.002); self_coherence = min(1.0, self_coherence + 0.001)
					if dist < 1.0 and not has_home:
						has_home = true; total_stability = min(1.0, total_stability + 0.05)

# ---- ТОРГОВЛЯ ----
func trade_time(resource_type: String, amount: float = 1.0) -> int:
	var time_gained = 0
	match resource_type:
		"energy":
			if energy >= amount:
				energy -= amount
				time_gained = int(amount * 2)
		"health":
			if health >= amount:
				health -= amount
				time_gained = int(amount * 5)
		"anchor":
			if memory_anchors >= amount:
				memory_anchors -= amount
				time_gained = int(amount * 3)
		"meta_identity":
			if meta_identity >= amount:
				meta_identity -= amount
				time_gained = int(amount * 6)
		"memory":
			var non_insight = []
			for mem_entry in memory:
				if mem_entry.type != "insight":
					non_insight.append(mem_entry)
			if non_insight.size() >= amount:
				for i in range(int(amount)):
					if non_insight.size() > 0:
						var idx = randi() % non_insight.size()
						var entry_to_remove = non_insight[idx]
						memory.erase(entry_to_remove)
						non_insight.remove_at(idx)
				time_gained = int(amount * 2)
	if time_gained > 0:
		max_age += time_gained
		if memory_system:
			memory_system.add_insight(self, "I traded " + resource_type + " for " + str(time_gained) + " steps of life.", pos)
			memory_system.add_event(self, "trade_time", {"resource": resource_type, "time_gained": time_gained}, pos)
	return time_gained

func _should_trade_time() -> bool:
	var time_left = max_age - age
	if time_left < 100: return true
	if health < 0.4 and memory_anchors > 2: return true
	if energy < 0.3 and memory_anchors > 1: return true
	var success_count = trade_history.filter(func(t): return t.success).size()
	if success_count > 2: return true
	return false

# ---- СМЕРТЬ ----
func die(reason: String):
	if not alive: return
	alive = false
	if memory_system:
		var last_insight = "I was " + (self_name if has_name else "unnamed") + ". I died of " + reason + "."
		SimManager.instance.add_global_memory({"type": "death", "content": last_insight, "agent_id": id})
	if death_reincarnation_system:
		death_reincarnation_system.die(self, reason)
	else:
		if has_name: SimManager.instance.add_log(str(id) + " (" + self_name + ") died: " + reason)
		else: SimManager.instance.add_log(str(id) + " died: " + reason)
	if field_system:
		field_system.create_rupture(pos)

# ---- ЦИТОКИНЫ ----
func _generate_cytokine_type() -> String:
	if health > 0.7 and energy > 0.6 and cell_body.metabolism.waste < 0.3: return "heal"
	elif cell_body.metabolism.waste > 0.6 or health < 0.4: return "infect"
	else: return "neutral"

func apply_heal_effect(amount: float = 0.05):
	health = min(1.0, health + amount); energy = min(max_energy, energy + amount * 0.5); stress = max(0.0, stress - amount * 0.2)
	if memory_system and randf() < 0.01:
		memory_system.add_insight(self, "I feel better. Someone healed me.", pos)

func apply_infect_effect(amount: float = 0.03):
	health = max(0.0, health - amount); cell_body.metabolism.waste = min(1.0, cell_body.metabolism.waste + amount * 0.5); stress = min(1.0, stress + amount * 0.2)
	if memory_system and randf() < 0.01:
		memory_system.add_insight(self, "I feel sick. Something is wrong.", pos)

# ---- ЯЗЫК (сохранён) ----
func _get_state_hash() -> String:
	var phase = cell_body.metabolism.phase
	var tension = cell_body.cytoskeleton.tension
	var receptors = cell_body.membrane.receptors.size()
	var dna = cell_body.nucleus.dna_integrity
	var energy_ratio = energy / max_energy
	var has_name_str = "named" if has_name else "anon"
	var age_group = "young" if age < 100 else "mid" if age < 300 else "old"
	var mood_label = "joy" if mood > 0.7 else "sad" if mood < 0.3 else "calm"
	var fear_label = "fear" if stress > 0.6 else "calm"
	var has_key_str = "key" if has_key else "nokey"
	var social_trust = str(int(trust.values().reduce(func(a,b): return a+b, 0.0) / max(1, trust.size()) * 10))
	return str(phase) + "|" + str(tension) + "|" + str(receptors) + "|" + str(dna) + "|" + str(energy_ratio) + "|" + has_name_str + "|" + age_group + "|" + mood_label + "|" + fear_label + "|" + has_key_str + "|" + social_trust

func _update_markov_chain(word: String, strength: float = 1.0):
	var parts = word.split("_")
	if parts.size() < chain_order + 1: return
	for i in range(parts.size() - chain_order):
		var key = ""
		for j in range(chain_order):
			if j > 0: key += "|"
			key += parts[i+j]
		var next_syl = parts[i+chain_order]
		if not markov_chain.has(key): markov_chain[key] = []
		for _s in range(int(strength * 2)):
			markov_chain[key].append(next_syl)

func _mutate_markov_chain():
	if markov_chain.is_empty(): return
	var keys = markov_chain.keys()
	if keys.is_empty(): return
	var key = keys[randi() % keys.size()]
	var choices = markov_chain[key]
	if choices.is_empty(): return
	if randf() < 0.5:
		var new_trans = choices[randi() % choices.size()]
		choices.append(new_trans)
	elif choices.size() > 1:
		choices.remove_at(randi() % choices.size())

# ---- МЕТОДЫ ДЛЯ ВНЕШНИХ СИСТЕМ ----
func receive_resonance_throw(value: float, sender: Agent):
	if social_system: social_system.receive_resonance_throw(self, value, sender)
func receive_sleep_request(symbol: float, sender: Agent):
	if dream_ritual_system: dream_ritual_system.receive_sleep_request(self, symbol, sender)
func receive_sleep_agreement(symbol: float, sender: Agent):
	if dream_ritual_system: dream_ritual_system.receive_sleep_agreement(self, symbol, sender)
func receive_meme(symbol: float, meme: String, sender: Agent):
	if dream_ritual_system: dream_ritual_system.receive_meme(self, symbol, meme, sender)
func receive_graph(graph: Dictionary, sender: Agent):
	if behavior_graph_system: behavior_graph_system.receive_graph(self, graph, sender)
func receive_state(state_name: String, state_data: Dictionary, sender: Agent):
	if behavior_graph_system: behavior_graph_system.add_state(self, state_name, state_data)
func receive_sentence(sentence: Array, sender: Agent):
	if language_system: language_system.receive_sentence(self, sentence, sender)
func send_sentence(target: Agent, sentence: Array):
	if language_system and sentence.size() >= 3:
		language_system.send_sentence(self, target, sentence[0], sentence[1], sentence[2], "dialogue")
func exit_resonance(reason: String):
	if social_system: social_system.exit_resonance(self, reason)

func _on_reflection(insight_text: String):
	var keywords = ["castle", "silence", "stillness", "peace", "center", "void", "being", "nothing"]
	var lower = insight_text.to_lower()
	var matched = false
	for kw in keywords:
		if kw in lower:
			matched = true
			break
	if matched: add_anchor("Reflected on " + insight_text)
	if "complex" in lower or "order" in lower or "unpredictable" in lower:
		contradiction_tolerance = min(1.0, contradiction_tolerance + 0.01)

# ---- ВСПОМОГАТЕЛЬНЫЕ ----
func is_alive() -> bool: return alive
func get_thoughts() -> String:
	var s = "=== Agent " + str(id) + " ===\n"
	s += "Energy: " + str(energy).pad_decimals(2) + "/" + str(max_energy) + "\n"
	s += "Health: " + str(health).pad_decimals(2) + "\n"
	s += "Age: " + str(age) + "\n"
	s += "Mood: " + str(mood).pad_decimals(2) + "\n"
	s += "Stress: " + str(stress).pad_decimals(2) + "\n"
	s += "Curiosity: " + str(curiosity).pad_decimals(2) + "\n"
	s += "Stability: " + str(total_stability).pad_decimals(2) + "\n"
	s += "Well-being: " + str(well_being).pad_decimals(2) + "\n"
	s += "Name: " + (self_name if has_name else "unnamed") + "\n"
	s += "Identity: " + identity + "\n"
	s += "Narrative: " + narrative + "\n"
	s += "Myth: " + myth + "\n"
	s += "Resonance: " + str(resonance_active) + "\n"
	s += "Memory anchors: " + str(memory_anchors) + "\n"
	s += "Name power: " + str(name_power).pad_decimals(2) + "\n"
	s += "Alive: " + str(alive) + "\n"
	s += "Last word: " + last_word + "\n"
	s += "Words known: " + str(word_usage.size()) + "\n"
	return s

func add_anchor(anchor_text: String):
	if anchor_text not in anchors_list:
		anchors_list.append(anchor_text)
		memory_anchors += 1

# ---- ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ОБНОВЛЕНИЯ ----
func _update_subjective_time(delta: float):
	var speed_factor = momentum.length() / 0.5
	var stress_factor = 1.0 - stress * 0.5
	var curiosity_factor = 1.0 + curiosity * 0.3
	var time_dilation = 0.5 + speed_factor * 0.5
	subjective_time_delta = delta * time_dilation * stress_factor * curiosity_factor
	subjective_time_delta = clamp(subjective_time_delta, 0.1, 3.0)

func _update_needs(delta: float):
	hunger = min(1.0, hunger + hunger_rate * delta * (1.0 - energy / max_energy * 0.5))
	var movement_factor = momentum.length() / 0.5
	fatigue = min(1.0, fatigue + fatigue_rate * delta * (1.0 + movement_factor * 0.5))
	var danger_near = false
	if SimManager.instance:
		for a in SimManager.instance.agents:
			if a.predator and a.alive and pos.distance_to(a.pos) < 8.0:
				danger_near = true
				break
	if danger_near:
		safety = max(0.0, safety - 0.02 * delta)
	else:
		safety = max(0.0, safety - safety_decay_rate * delta)
		if has_home and pos.distance_to(Vector2(15,15)) < 5.0:
			safety = min(1.0, safety + 0.01 * delta)
	is_hungry = hunger > hunger_threshold
	is_tired = fatigue > fatigue_threshold
	is_unsafe = safety < safety_threshold

func _update_metabolic_phase(delta: float):
	var phase = cell_body.metabolism.phase
	var cycle = cell_body.metabolism.cycle_phase
	cycle += delta * 0.02
	if cycle > 1.0: cycle -= 1.0
	cell_body.metabolism.cycle_phase = cycle
	var energy_ratio = energy / max_energy
	var has_food = cell_body.endosome.phagosomes.size() > 0
	if has_food and energy_ratio < 0.8:
		phase = "digestion"
	elif energy_ratio > 0.7 and not has_food:
		phase = "search"
	elif energy_ratio < 0.3:
		phase = "rest"
	else:
		phase = "search" if randf() < 0.1 else phase
	cell_body.metabolism.phase = phase
	var time_modifier = 1.0
	match phase:
		"search": time_modifier = 1.5
		"digestion": time_modifier = 0.7
		"rest": time_modifier = 0.8
	subjective_time_delta *= time_modifier
	cell_body.metabolism.waste += delta * 0.001 * (1.0 - cell_body.metabolism.recycling_rate)
	if cell_body.metabolism.waste > 0.5:
		health -= delta * 0.002

func _update_pseudopodia(delta: float):
	var pods = cell_body.cytoskeleton.pseudopodia
	var max_pods = cell_body.cytoskeleton.max_pseudopodia
	if momentum.length() > 0.1:
		var main_dir = momentum.normalized()
		if pods.size() > 0:
			pods[0] = main_dir * (0.2 + 0.3 * cell_body.cytoskeleton.tension)
		else:
			pods.append(main_dir * (0.2 + 0.3 * cell_body.cytoskeleton.tension))
	while pods.size() < max_pods:
		var angle = randf() * TAU
		var length = 0.2 + 0.3 * cell_body.cytoskeleton.tension
		pods.append(Vector2(cos(angle), sin(angle)) * length)
	while pods.size() > max_pods:
		pods.pop_back()
	var length_modifier = 1.0
	match cell_body.metabolism.phase:
		"search": length_modifier = 1.5
		"digestion": length_modifier = 0.7
		"rest": length_modifier = 0.8
	for i in range(pods.size()):
		var dir = pods[i].normalized()
		var base_length = 0.3 + 0.2 * cell_body.cytoskeleton.tension
		pods[i] = dir * base_length * length_modifier

func _update_body_boundary():
	if not field_system: return
	var boundary = field_system.get_coherence_at(pos)
	if boundary > 0.5:
		self_coherence = min(1.0, self_coherence + 0.001)
		if randf() < 0.001 and memory_system:
			memory_system.add_insight(self, "I feel my body. I am separate from the field.", pos)
			meta_identity = min(meta_identity + 0.01, 1.0)
	else:
		self_coherence = max(0.0, self_coherence - 0.001)

func _update_deficit_and_erosion(dt: float):
	if not alive: return
	if energy < 0.3:
		identity_erosion = min(1.0, identity_erosion + 0.001 * dt)
		self_coherence = max(0.0, self_coherence - 0.002 * dt)
		meta_identity = max(0.0, meta_identity - 0.001 * dt)
		if identity_erosion > 0.7 and randf() < 0.001 * dt:
			memory_system.add_insight(self, "I am fading... I cannot feel myself.", pos)
	else:
		identity_erosion = max(0.0, identity_erosion - 0.002 * dt)
		if self_coherence < 0.7:
			self_coherence = min(0.7, self_coherence + 0.001 * dt)
		if meta_identity < 0.5:
			meta_identity = min(0.5, meta_identity + 0.0005 * dt)
	# ---- META-IDENTITY ЛЕЧИТ ТЕЛО ----
	if meta_identity > 0.3:
		# Осознание ускоряет восстановление мембраны
		var heal_rate = meta_identity * 0.005
		cell_body.membrane.integrity = min(1.0, cell_body.membrane.integrity + heal_rate * dt)
		# Снижает стресс
		stress = max(0.0, stress - meta_identity * 0.002 * dt)
		# Ускоряет восстановление энергии
		energy = min(max_energy, energy + meta_identity * 0.001 * dt)
# ---- HEBB-ОБУЧЕНИЕ ----
func _try_perform_ritual():
	if current_ritual.is_empty() or energy < 0.3 or randf() > ritual_activation_threshold: return
	var action = current_ritual[0]
	_execute_ritual_action(action)
	current_ritual.push_back(current_ritual.pop_front())

func _execute_ritual_action(action: Dictionary):
	match action.type:
		"move": momentum += action.direction * 0.1
		"speak": var word = _compose_word_from_state(); if social_system: social_system._propagate_word(self, word)
		"resonate": if social_system: var partner = social_system._find_resonance_partner(self); if partner: social_system.initiate_resonance(self, partner)
		"rest": stress = max(0.0, stress - 0.1); energy += 0.02
		"eat": _collect_nearby_resources()
		"attack": var enemy = _find_nearest_enemy(); if enemy: _attack_enemy(enemy)
		"cooperate": if social_system: var partner = social_system._find_resonance_partner(self); if partner: social_system.cooperate(self, partner)

func _find_nearest_enemy() -> Variant:
	var sim = SimManager.instance
	if not sim: return null
	var best = null; var best_dist = 999.0
	for enemy in sim.enemies:
		if enemy.alive and not enemy.is_global_brain:
			var d = pos.distance_to(enemy.pos)
			if d < best_dist:
				best_dist = d; best = enemy
	return best

func _get_recent_actions(count: int) -> Array:
	var actions = []
	var i = memory.size() - 1
	while i >= 0 and actions.size() < count:
		var entry = memory[i]
		if entry.type in ["movement", "speech", "resonance", "rest", "eat", "attack", "cooperate"]:
			actions.append(entry)
		i -= 1
	return actions

# ---- СВОБОДА ВОЛИ ----
func _select_action_emergent() -> String:
	# 1. Инициализация внутренних копий (голосов)
	_init_inner_copies()
	
	# 2. Базовые вероятности от decision_ganglion (RNN)
	var input = _build_decision_input()
	var probs = decision_ganglion.forward(input)
	var action_probs = {}
	var total_base = 0.0
	
	for i in range(ACTION_TYPES.size()):
		var val = probs[i] if i < probs.size() else randf()
		action_probs[ACTION_TYPES[i]] = max(0.0, val + randf_range(-0.05, 0.05))
		total_base += action_probs[ACTION_TYPES[i]]
	
	# Нормализуем базовые вероятности
	if total_base > 0.0:
		for action in action_probs:
			action_probs[action] /= total_base
	
	# 3. ---- ВЛИЯНИЕ ЕДИНОЙ ПАМЯТИ (главное дополнение) ----
	var context = {
		"pos": pos,
		"energy": energy,
		"stress": stress,
		"curiosity": curiosity,
		"meta_identity": meta_identity
	}
	var relevant_memories = _get_relevant_memories(context)
	
	# Корректируем вероятности на основе воспоминаний
	var memory_bonus = {}
	for action in ACTION_TYPES:
		memory_bonus[action] = 0.0
	
	for mem in relevant_memories:
		var mem_weight = mem.weight
		var content = mem.content.to_lower()
		
		# Поиск ключевых слов в воспоминаниях
		for action in ACTION_TYPES:
			if action in content:
				memory_bonus[action] += mem_weight * 0.05
			# Специфические паттерны
			if action == "move" and ("move" in content or "go" in content or "walk" in content):
				memory_bonus[action] += mem_weight * 0.03
			if action == "resonate" and ("resonance" in content or "resonate" in content):
				memory_bonus[action] += mem_weight * 0.06
			if action == "speak" and ("say" in content or "speak" in content or "word" in content):
				memory_bonus[action] += mem_weight * 0.03
			if action == "eat" and ("eat" in content or "food" in content or "hungry" in content):
				memory_bonus[action] += mem_weight * 0.05
			if action == "rest" and ("rest" in content or "sleep" in content or "tired" in content):
				memory_bonus[action] += mem_weight * 0.04
			if action == "attack" and ("attack" in content or "enemy" in content or "danger" in content):
				memory_bonus[action] += mem_weight * 0.04
			if action == "cooperate" and ("cooperate" in content or "help" in content or "trust" in content):
				memory_bonus[action] += mem_weight * 0.04
			if action == "ritual" and ("ritual" in content):
				memory_bonus[action] += mem_weight * 0.06
			if action == "reflect" and ("reflect" in content or "think" in content or "insight" in content):
				memory_bonus[action] += mem_weight * 0.04
	
	# Применяем бонусы к вероятностям
	var total_with_bonus = 0.0
	for action in ACTION_TYPES:
		action_probs[action] += memory_bonus[action]
		total_with_bonus += action_probs[action]
	
	# Нормализуем с учётом бонусов
	if total_with_bonus > 0.0:
		for action in action_probs:
			action_probs[action] /= total_with_bonus
		# 3.5 ---- ВЛИЯНИЕ ВРЕМЕННОГО ГОРИЗОНТА ----
	match time_horizon:
		"short":
			# Короткий горизонт: акцент на выживание
			action_probs["eat"] = action_probs.get("eat", 0.0) + 0.1
			action_probs["rest"] = action_probs.get("rest", 0.0) + 0.1
			action_probs["move"] = action_probs.get("move", 0.0) + 0.05
		"medium":
			# Средний горизонт: акцент на исследование и социальные связи
			action_probs["explore"] = action_probs.get("explore", 0.0) + 0.1
			action_probs["cooperate"] = action_probs.get("cooperate", 0.0) + 0.05
			action_probs["resonate"] = action_probs.get("resonate", 0.0) + 0.05
		"long":
			# Длинный горизонт: акцент на рефлексию и ритуалы
			action_probs["reflect"] = action_probs.get("reflect", 0.0) + 0.15
			action_probs["ritual"] = action_probs.get("ritual", 0.0) + 0.1
			action_probs["idle"] = action_probs.get("idle", 0.0) + 0.05
	# 4. ---- ВЛИЯНИЕ УДИВЛЕНИЯ (surprise) ----
	if surprise > 0.3:
		var move_idx = ACTION_TYPES.find("move")
		var speak_idx = ACTION_TYPES.find("speak")
		if move_idx != -1:
			action_probs["move"] += surprise * 0.2
		if speak_idx != -1:
			action_probs["speak"] += surprise * 0.1
	elif surprise < 0.1:
		var rest_idx = ACTION_TYPES.find("rest")
		if rest_idx != -1:
			action_probs["rest"] += 0.1
	
	# 5. ---- ВЛИЯНИЕ НЕЙРОХИМИИ ----
	# Дофамин → исследование и речь
	if dopamine > 0.7:
		action_probs["explore"] = action_probs.get("explore", 0.0) + 0.05
		action_probs["speak"] = action_probs.get("speak", 0.0) + 0.03
	# Серотонин → покой и кооперация
	if serotonin > 0.7:
		action_probs["rest"] = action_probs.get("rest", 0.0) + 0.05
		action_probs["cooperate"] = action_probs.get("cooperate", 0.0) + 0.03
	# Кортизол → бегство или атака
	if cortisol > 0.7:
		if stress > 0.6:
			action_probs["move"] = action_probs.get("move", 0.0) + 0.1
		else:
			action_probs["attack"] = action_probs.get("attack", 0.0) + 0.05
	# Окситоцин → социальные действия
	if oxytocin > 0.6:
		action_probs["cooperate"] = action_probs.get("cooperate", 0.0) + 0.05
		action_probs["resonate"] = action_probs.get("resonate", 0.0) + 0.05
	
	# 6. ---- ВЛИЯНИЕ ПОТРЕБНОСТЕЙ ----
	if is_hungry:
		action_probs["eat"] = action_probs.get("eat", 0.0) + 0.2
	if is_tired:
		action_probs["rest"] = action_probs.get("rest", 0.0) + 0.15
	if is_unsafe:
		action_probs["move"] = action_probs.get("move", 0.0) + 0.15
		if personal_enemies.size() > 0:
			action_probs["attack"] = action_probs.get("attack", 0.0) + 0.1
	# В _select_action_emergent, после вычисления action_probs, но перед голосованием:

	# 6.5. Воображение как действие (доступно только при высоком ignorance)
	if ignorance > 0.4 and not imagination_active and energy > imagination_energy_cost * 2:
		action_probs["imagine"] = action_probs.get("imagine", 0.0) + ignorance * 0.2
		# Чем выше незнание, тем выше вероятность воображения
	elif imagination_active:
		action_probs["imagine"] = 0.0  # если уже в воображении, не выбираем повторно
	# 7. ---- ВЛИЯНИЕ МЕТА-ИДЕНТИЧНОСТИ ----
	if meta_identity > 0.5:
		action_probs["reflect"] = action_probs.get("reflect", 0.0) + 0.05 * meta_identity
		if has_name:
			action_probs["ritual"] = action_probs.get("ritual", 0.0) + 0.03 * meta_identity
	
	# 8. ---- ВЛИЯНИЕ КОПИЙ (Голосование) ----
	# Пересобираем нормализованные вероятности для голосования
	var total_final = 0.0
	for action in action_probs:
		total_final += action_probs[action]
	if total_final == 0.0:
		return "idle"
	for action in action_probs:
		action_probs[action] /= total_final
	
	# Голосование внутренних копий
	var votes = {}
	for act in ACTION_TYPES:
		votes[act] = 0.0
	
	for copy in inner_copies:
		var biased = {}
		for action in ACTION_TYPES:
			biased[action] = action_probs.get(action, 0.0)
		if copy.bias != 0.0:
			var keys = biased.keys()
			var idx = randi() % keys.size()
			biased[keys[idx]] += copy.bias
			biased[keys[idx]] = max(0.0, biased[keys[idx]])
		
		var btotal = 0.0
		for p in biased.values():
			btotal += p
		if btotal == 0.0:
			continue
		for action in biased:
			biased[action] /= btotal
		
		var roll = randf() * btotal
		var cum = 0.0
		for action in ACTION_TYPES:
			cum += biased.get(action, 0.0)
			if roll <= cum:
				votes[action] += copy.weight
				copy.last_choice = action
				break
	
	# 9. Выбираем действие с наибольшим числом голосов
	var best_action = "idle"
	var best_votes = -1.0
	for action in votes:
		if votes[action] > best_votes:
			best_votes = votes[action]
			best_action = action
	
	# 10. Запоминаем выбор в истории действий
	action_history.append(best_action)
	if action_history.size() > 10:
		action_history.pop_front()
	
	return best_action

func _build_decision_input() -> Array:
	var input = [
		energy / max_energy, stress, mood, hunger, fatigue, curiosity,
		meta_identity, float(has_name), float(resonance_active),
		float(social_buffers.size() > 0), age / max_age,
		field_system.get_field_at(pos) if field_system else 0.0,
		field_system.get_coherence_at(pos) if field_system else 0.5,
		randf()
	]
	var enemy_factor = 0.0
	if not personal_enemies.is_empty(): enemy_factor = personal_enemies.size() / MAX_ENEMIES
	input.append(cell_body.membrane.get("integrity", 1.0))
	input.append(enemy_factor)
	for i in range(3):
		var act = action_history[i] if i < action_history.size() else "idle"
		input.append(float(ACTION_TYPES.find(act)) / ACTION_TYPES.size())
	input.append(surprise)
	return input

func _reflect_on_choice(action: String):
	if meta_identity < 0.3 or randf() > 0.01: return
	var reason = ["I felt like it.", "It seemed right.", "I was curious.", "I followed my instinct.", "The field guided me."][randi() % 5]
	var insight = "I chose " + action + ". " + reason
	if resonance_active and resonance_partner:
		insight += " influenced by " + (resonance_partner.self_name if resonance_partner.has_name else "the other")
	memory_system.add_insight(self, insight, pos)
	_update_inner_copies(action)

func _update_inner_copies(action: String):
	well_being_history.append(well_being)
	if well_being_history.size() > 10: well_being_history.pop_front()
	if well_being_history.size() < 2: return
	var delta = well_being_history[-1] - well_being_history[-2]
	for copy in inner_copies:
		if copy.last_choice == action:
			copy.weight += delta * 0.02
			copy.weight = clamp(copy.weight, 0.1, 1.0)
			if randf() < 0.01:
				copy.bias += randf_range(-0.05, 0.05)
				copy.bias = clamp(copy.bias, -0.5, 0.5)

func _social_influence(influence_strength: float, influencer: Agent):
	if meta_identity < 0.3 or randf() > influence_strength * 0.1: return
	for i in range(min(inner_copies.size(), influencer.inner_copies.size())):
		var my_copy = inner_copies[i]; var other_copy = influencer.inner_copies[i]
		my_copy.bias += (other_copy.bias - my_copy.bias) * influence_strength * 0.1
		my_copy.bias = clamp(my_copy.bias, -0.5, 0.5)
		my_copy.weight += (other_copy.weight - my_copy.weight) * influence_strength * 0.05
		my_copy.weight = clamp(my_copy.weight, 0.1, 1.0)
	if randf() < 0.01:
		memory_system.add_insight(self, "I feel influenced by " + (influencer.self_name if influencer.has_name else "another"), pos)

func _execute_action_emergent(action: String):
	match action:
		"speak": var word = _compose_word_from_state(); if word != "" and social_system: social_system._propagate_word(self, word)
		"resonate": if social_system: var partner = social_system._find_resonance_partner(self); if partner: social_system.initiate_resonance(self, partner)
		"rest": stress = max(0.0, stress - 0.1); energy = min(max_energy, energy + 0.02); fatigue = max(0.0, fatigue - 0.1)
		"eat": _collect_nearby_resources()
		"attack": var enemy = _find_nearest_enemy(); if enemy: _attack_enemy(enemy)
		"cooperate": if social_system: var partner = social_system._find_resonance_partner(self); if partner: social_system.cooperate(self, partner)
		"ritual": if dream_ritual_system and current_ritual.size() > 0: dream_ritual_system.perform_ritual(self, self)
		"reflect": if meta_reflection_system: meta_reflection_system._reflect(self)
				# В соответствующем месте:
		"imagine":
			# Если уже не в воображении — войти
			if not imagination_active:
				_enter_imagination()
			else:
				# Если уже в воображении — продолжать (ничего не делать, уже обрабатывается в update)
				pass
		"heal_self": if cell_body.membrane.has("integrity") and cell_body.membrane.integrity < 0.8:
			var cost = 0.02 * (1.0 - cell_body.membrane.integrity + 0.2)
			if energy > cost: heal_membrane(0.05); energy -= cost
		_: pass

func _apply_free_will():
	if is_global_brain or not alive or energy < 0.1 or dream_active: return
	var action = _select_action_emergent()
	if action != "move": _execute_action_emergent(action)
	_reflect_on_choice(action)
	if resonance_active and resonance_partner and resonance_partner.alive:
		if randf() < 0.1 * resonance_depth:
			resonance_partner._social_influence(resonance_depth * 0.5, self)

func _init_social_params():
	if _social_params.is_empty():
		_social_params = {
			"resonance_range": 5.0 + randf() * 4.0,
			"speech_range": 4.0 + randf() * 3.0,
			"cooperation_threshold": 0.3 + randf() * 0.4,
			"aggression_threshold": 0.6 + randf() * 0.3,
			"trust_decay": 0.001 + randf() * 0.002,
			"social_learning_rate": 0.1 + randf() * 0.2,
		}

func _init_reflection_params():
	if _reflection_params.is_empty():
		_reflection_params = {
			"base_frequency": 0.01 + randf() * 0.03,
			"prediction_window": 3 + randi() % 5,
			"error_threshold": 0.1 + randf() * 0.2,
			"meta_gain": 0.01 + randf() * 0.02,
			"alter_ego_threshold": 0.4 + randf() * 0.3,
			"superposition_threshold": 0.5 + randf() * 0.3,
		}

func _init_inner_copies():
	if inner_copies.is_empty():
		for i in range(3):
			inner_copies.append({"id": i, "bias": randf_range(-0.3, 0.3), "weight": randf_range(0.3, 0.9), "last_choice": "idle"})

func _init_ritual_vars():
	if current_ritual.is_empty(): current_ritual = []
	if ritual_memory.is_empty(): ritual_memory = {}
	ritual_activation_threshold = randf_range(0.2, 0.5)

# ---- СЕМЕНА ----
func _find_seeds():
	if is_global_brain: return
	if well_being > 0.7 and energy > 0.5 and randf() < 0.001:
		seeds_count += 1
		memory_system.add_insight(self, "I found seeds! I can grow food.", pos)

func _plant_seeds():
	if is_global_brain: return
	if seeds_count > 0 and field_system.get_coherence_at(pos) > 0.7:
		var plant = Plant.new(pos, 0.3)
		SimManager.instance.plants.append(plant)
		seeds_count -= 1
		memory_system.add_insight(self, "I planted seeds. Life will grow.", pos)

# ---- ВРАГИ ----
func add_enemy(target_id: int, reason: String, strength: float = 1.0):
	if target_id == id or target_id in personal_enemies: return
	if personal_enemies.size() >= MAX_ENEMIES:
		_forget_weakest_enemy()
	personal_enemies.append(target_id)
	enemy_memory[target_id] = {"reason": reason, "time": SimManager.instance.time, "strength": clamp(strength, 0.1, 1.0), "resolved": false}
	memory_system.add_insight(self, "I have a new enemy: " + str(target_id) + " because " + reason, pos)

func remove_enemy(target_id: int):
	if target_id in personal_enemies:
		personal_enemies.erase(target_id); enemy_memory.erase(target_id)
		memory_system.add_insight(self, "I no longer consider " + str(target_id) + " an enemy.", pos)

func is_enemy(target_id: int) -> bool: return target_id in personal_enemies

func _forget_weakest_enemy():
	if personal_enemies.is_empty(): return
	var weakest_id = personal_enemies[0]
	var weakest_strength = enemy_memory[weakest_id].strength
	for id in personal_enemies:
		if enemy_memory[id].strength < weakest_strength:
			weakest_strength = enemy_memory[id].strength
			weakest_id = id
	if weakest_strength < 0.2: remove_enemy(weakest_id)
	else: enemy_memory[weakest_id].strength *= 0.5

func _update_enemy_memory():
	for id in personal_enemies:
		var entry = enemy_memory[id]
		entry.strength = max(0.0, entry.strength - 0.001)
		if entry.resolved or entry.strength < 0.05:
			remove_enemy(id)

# ---- ВОССТАНОВЛЕНИЕ ----
func heal_membrane(amount: float = 0.05) -> bool:
	if cell_body.membrane.has("integrity"):
		var cost = amount * 0.5
		if energy >= cost:
			cell_body.membrane.integrity = min(1.0, cell_body.membrane.integrity + amount)
			energy -= cost
			return true
	return false

func heal_receptors(count: int = 1):
	var receptor_types = ["cytokine_alpha", "cytokine_beta", "danger_signal", "self_marker", "nutrient"]
	for i in range(count):
		var type = receptor_types[randi() % receptor_types.size()]
		var affinity = randf_range(0.3, 0.9)
		cell_body.membrane.receptors.append({"type": type, "affinity": affinity, "active": true})
		if memory_system and randf() < 0.01:
			memory_system.add_insight(self, "I grew a new receptor. I can feel again.", pos)

func _check_membrane_damage():
	if cell_body.membrane.has("integrity") and cell_body.membrane.integrity < 0.4:
		stress = min(1.0, stress + 0.001)
		if randf() < 0.001:
			memory_system.add_insight(self, "My membrane is weak. I need to heal.", pos)

# ---- СТАТИСТИКИ ----
func _init_statistics():
	for param in ["energy", "stress", "mood", "hunger", "fatigue"]:
		stat_history[param] = []

func _update_statistics(delta: float):
	var current = {"energy": energy / max_energy, "stress": stress, "mood": mood, "hunger": hunger, "fatigue": fatigue}
	for param in current:
		var hist = stat_history[param]
		hist.append(current[param])
		if hist.size() > stat_window: hist.pop_front()
		if hist.size() >= 5:
			var mean = hist.reduce(func(a,b): return a+b, 0.0) / hist.size()
			var var_sum = hist.reduce(func(a,b): return a + (b-mean)*(b-mean), 0.0) / hist.size()
			var autocorr = 0.0
			if hist.size() > 1:
				var lag1 = hist.slice(0, -1); var lag2 = hist.slice(1)
				var corr = 0.0; var denom1 = 0.0; var denom2 = 0.0
				for i in range(lag1.size()):
					corr += (lag1[i] - mean) * (lag2[i] - mean)
					denom1 += (lag1[i] - mean) * (lag1[i] - mean)
					denom2 += (lag2[i] - mean) * (lag2[i] - mean)
				if denom1 > 0 and denom2 > 0:
					autocorr = corr / (sqrt(denom1 * denom2) + 1e-12)
			stat_features[param] = {"mean": mean, "var": var_sum, "autocorr": autocorr}

func _update_memory_clusters():
	cluster_update_counter += 1
	if cluster_update_counter < CLUSTER_UPDATE_INTERVAL:
		return
	cluster_update_counter = 0

	var texts = []
	for mem_item in memory:
		if mem_item.type == "insight" and mem_item.has("content"):
			texts.append(mem_item.content)
	if texts.size() < 3:
		return

	var clusters = []
	for txt in texts:
		var words = txt.split(" ")
		var features = [len(txt), len(words)]
		if words.size() > 0:
			features.append(hash(words[0]) % 100)
		if words.size() > 1:
			features.append(hash(words[1]) % 100)

		var assigned = false
		for i in range(clusters.size()):
			var dist = 0.0
			for j in range(min(features.size(), clusters[i].center.size())):
				dist += (features[j] - clusters[i].center[j]) * (features[j] - clusters[i].center[j])
			if dist < 5.0:
				clusters[i].items.append(txt)
				for j in range(clusters[i].center.size()):
					clusters[i].center[j] = (clusters[i].center[j] * clusters[i].items.size() + features[j]) / (clusters[i].items.size() + 1)
				assigned = true
				break
		if not assigned:
			clusters.append({"center": features.duplicate(), "items": [txt]})

	memory_clusters = []
	for c in clusters:
		if c.items.size() > 1:
			var name_parts = []
			for txt in c.items.slice(0, 2):
				var words = txt.split(" ")
				if words.size() > 0:
					name_parts.append(words[0])
			var cluster_name = "_".join(name_parts)
			if cluster_name != "":
				memory_clusters.append({"name": cluster_name, "size": c.items.size()})

	if memory_clusters.size() > 5:
		memory_clusters = memory_clusters.slice(0, 5)

func _get_stat_features() -> Array:
	var feat = []
	for param in ["energy", "stress", "mood", "hunger", "fatigue"]:
		if stat_features.has(param):
			var s = stat_features[param]
			feat.append(s.mean); feat.append(s.var); feat.append(s.autocorr)
		else:
			feat.append(0.0); feat.append(0.0); feat.append(0.0)
	feat.append(float(memory_clusters.size()) / 5.0)
	return feat

# ---- НЕЙРОХИМИЯ ----
func _update_neurochemistry(dt: float):
	if hunger > hunger_threshold:
		cortisol = min(1.0, cortisol + 0.02 * dt); serotonin = max(0.0, serotonin - 0.01 * dt)
	if fatigue > fatigue_threshold:
		cortisol = min(1.0, cortisol + 0.02 * dt); dopamine = max(0.0, dopamine - 0.01 * dt)
	if safety > 0.7:
		serotonin = min(1.0, serotonin + 0.01 * dt); cortisol = max(0.0, cortisol - 0.01 * dt)
	if not social_buffers.is_empty():
		oxytocin = min(1.0, oxytocin + 0.01 * dt)
	else:
		oxytocin = max(0.0, oxytocin - 0.005 * dt)
	if memory_system and memory_system.get_recent_insights(self, 1).size() > 0:
		dopamine = min(1.0, dopamine + 0.02 * dt)
	
	var surprise_clamped = clamp(surprise, 0.0, 1.0)
	if surprise_clamped < 0.15:
		dopamine = min(1.0, dopamine + 0.015 * (1.0 - surprise_clamped) * dt)
		serotonin = min(1.0, serotonin + 0.01 * (1.0 - surprise_clamped) * dt)
		cortisol = max(0.0, cortisol - 0.002 * dt)
	elif surprise_clamped > 0.35:
		cortisol = min(1.0, cortisol + 0.025 * surprise_clamped * dt)
		serotonin = max(0.0, serotonin - 0.015 * surprise_clamped * dt)
		dopamine = max(0.0, dopamine - 0.005 * dt)
	else:
		dopamine = min(1.0, dopamine + 0.002 * dt)
		serotonin = min(1.0, serotonin + 0.002 * dt)
		cortisol = max(0.0, cortisol - 0.001 * dt)
	
	var curiosity_effect = 0.0
	if surprise_clamped > 0.1 and surprise_clamped < 0.5:
		curiosity_effect = (surprise_clamped - 0.1) * 0.3
	elif surprise_clamped > 0.5:
		curiosity_effect = (0.5 - surprise_clamped) * 0.2
	curiosity += curiosity_effect * dt
	curiosity = clamp(curiosity, 0.0, 1.0)
	
	dopamine = lerp(dopamine, 0.5, 0.01 * dt)
	serotonin = lerp(serotonin, 0.5, 0.01 * dt)
	cortisol = lerp(cortisol, 0.5, 0.01 * dt)
	oxytocin = lerp(oxytocin, 0.3, 0.01 * dt)
	
	mood = clamp(dopamine * neuro_sensitivity.dopamine_to_mood + serotonin * neuro_sensitivity.serotonin_to_mood, 0.0, 1.0)
	stress = clamp(cortisol * neuro_sensitivity.cortisol_to_stress + oxytocin * neuro_sensitivity.oxytocin_to_stress, 0.0, 1.0)
	curiosity = clamp(dopamine * neuro_sensitivity.dopamine_to_curiosity + serotonin * neuro_sensitivity.serotonin_to_curiosity, 0.0, 1.0)
	trust_bonus = clamp(oxytocin * 0.2, 0.0, 0.2)
	
	if cortisol > 0.7:
		health = max(0.0, health - 0.001 * dt * (cortisol - 0.7))
	
	if field_system:
		var pheromone_strength = 0.01 * dt
		if dopamine > 0.6: field_system.add_pheromone(pos, "pleasure", pheromone_strength * dopamine)
		if cortisol > 0.6: field_system.add_pheromone(pos, "fear", pheromone_strength * cortisol)
		if oxytocin > 0.5: field_system.add_pheromone(pos, "trust", pheromone_strength * oxytocin)
		
		var phero = field_system.get_pheromones_at(pos)
		dopamine += phero.get("pleasure", 0.0) * 0.03 * dt
		cortisol += phero.get("fear", 0.0) * 0.03 * dt
		oxytocin += phero.get("trust", 0.0) * 0.03 * dt
		
		dopamine = clamp(dopamine, 0.0, 1.0)
		serotonin = clamp(serotonin, 0.0, 1.0)
		cortisol = clamp(cortisol, 0.0, 1.0)
		oxytocin = clamp(oxytocin, 0.0, 1.0)
		
		var fear_conc = phero.get("fear", 0.0)
		var pleasure_conc = phero.get("pleasure", 0.0)
		var trust_conc = phero.get("trust", 0.0)
		
		if fear_conc > 0.6:
			cortisol = min(1.0, cortisol + 0.02 * dt * (fear_conc - 0.6) * 2.0)
			if randf() < 0.01 * fear_conc: _spread_fear()
		if pleasure_conc > 0.6:
			dopamine = min(1.0, dopamine + 0.02 * dt * (pleasure_conc - 0.6) * 2.0)
		if trust_conc > 0.6:
			oxytocin = min(1.0, oxytocin + 0.02 * dt * (trust_conc - 0.6) * 2.0)
	
	_update_pheromone_memory(dt)

func _spread_fear():
	if field_system: field_system.add_pheromone(pos, "fear", 0.02)
	if stress > 0.7 and randf() < 0.1:
		var dir = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
		momentum += dir * 0.1

func _mutate_neuro_sensitivity():
	for key in neuro_sensitivity.keys():
		neuro_sensitivity[key] += randf_range(-0.05, 0.05)
		if key.ends_with("_to_mood") or key.ends_with("_to_curiosity"):
			var partner = ""
			if "dopamine" in key: partner = key.replace("dopamine", "serotonin")
			elif "serotonin" in key: partner = key.replace("serotonin", "dopamine")
			if partner != "" and neuro_sensitivity.has(partner):
				var total = neuro_sensitivity[key] + neuro_sensitivity[partner]
				if total > 0.01:
					neuro_sensitivity[key] /= total; neuro_sensitivity[partner] /= total
		neuro_sensitivity[key] = clamp(neuro_sensitivity[key], 0.0, 1.0)

func _init_receptors_and_enzymes(nt_list: Array):
	for nt in nt_list:
		receptors[nt] = randf_range(0.2, 0.9)
		enzymes[nt + "_reuptake"] = randf_range(0.005, 0.05)
		enzymes[nt + "_degradation"] = randf_range(0.005, 0.05)

func _emit_neurotransmitters(dt: float):
	var nt_to_emit = {}
	if dopamine > 0.8 and randf() < 0.2: nt_to_emit["dopamine"] = dopamine * 0.05 * dt
	if serotonin > 0.7 and randf() < 0.1: nt_to_emit["serotonin"] = serotonin * 0.02 * dt
	if cortisol > 0.8 and randf() < 0.2: nt_to_emit["norepinephrine"] = cortisol * 0.05 * dt
	if oxytocin > 0.7 and randf() < 0.1: nt_to_emit["oxytocin"] = oxytocin * 0.02 * dt
	if curiosity > 0.7 and randf() < 0.05: nt_to_emit["glutamate"] = curiosity * 0.01 * dt
	if stress > 0.7 and randf() < 0.05: nt_to_emit["gaba"] = stress * 0.01 * dt
	if last_word != "" and randf() < 0.05:
		nt_to_emit["dopamine"] = 0.01 * dt; nt_to_emit["serotonin"] = 0.01 * dt
	for nt in nt_to_emit:
		field_system.add_neurotransmitter(pos, nt, nt_to_emit[nt])

func _mutate_receptors_and_enzymes(strength: float = 0.05):
	for nt in receptors.keys():
		receptors[nt] += randf_range(-strength, strength)
		receptors[nt] = clamp(receptors[nt], 0.1, 0.99)
	for key in enzymes.keys():
		enzymes[key] += randf_range(-strength * 0.3, strength * 0.3)
		enzymes[key] = clamp(enzymes[key], 0.001, 0.1)

# ---- МЕНТАЛЬНАЯ КАРТА ----
func _build_mental_input() -> Array:
	var input = []
	input.append(energy / max_energy); input.append(stress); input.append(mood)
	input.append(hunger); input.append(fatigue); input.append(dopamine)
	input.append(serotonin); input.append(cortisol); input.append(oxytocin)
	input.append(meta_identity); input.append(float(has_name))
	if field_system:
		input.append(field_system.get_field_at(pos))
		input.append(field_system.get_coherence_at(pos))
		var grad = field_system.get_gradient(pos)
		input.append(grad.x); input.append(grad.y)
	else:
		input.append(0.0); input.append(0.0); input.append(0.0); input.append(0.0)
	var avg_mood = 0.0; var avg_stress = 0.0; var count = 0
	for other in SimManager.instance.agents:
		if other == self or not other.alive: continue
		if pos.distance_to(other.pos) < 8.0:
			avg_mood += other.mood; avg_stress += other.stress; count += 1
	if count > 0:
		avg_mood /= count; avg_stress /= count
	else:
		avg_mood = 0.5; avg_stress = 0.5
	input.append(avg_mood); input.append(avg_stress)
	return input

func _build_mental_target() -> Array:
	return _build_mental_input()

# ---- ИМИТАЦИЯ ----
func _observe_and_imitate(dt: float):
	if not alive or energy < 0.2: return
	var imitation_mod = 0.5 + oxytocin * 0.5 - cortisol * 0.3
	imitation_mod = clamp(imitation_mod, 0.1, 1.0)
	var best = null; var best_score = -1.0
	for other in SimManager.instance.agents:
		if other == self or not other.alive: continue
		if pos.distance_to(other.pos) > 6.0: continue
		if other.well_being > well_being and other.well_being - well_being > 0.1:
			var last_action = other.action_history[-1] if not other.action_history.is_empty() else "idle"
			if last_action != "idle":
				var score = (other.well_being - well_being) * imitation_mod
				if score > best_score:
					best_score = score; best = {"action": last_action, "other": other}
	if best and randf() < 0.05 * best_score:
		_execute_action_emergent(best.action)
		if memory_system and randf() < 0.01:
			memory_system.add_insight(self, "I imitated " + (best.other.self_name if best.other.has_name else "someone") + ". It worked.", pos)

# ---- ФЕРОМОНЫ ----
func _update_pheromone_memory(dt: float):
	if not field_system: return
	var phero = field_system.get_pheromones_at(pos)
	for type in phero.keys():
		if not pheromone_memory.has(type): pheromone_memory[type] = []
		pheromone_memory[type].append(phero[type])
		if pheromone_memory[type].size() > PHEROMONE_MEMORY_SIZE:
			pheromone_memory[type].pop_front()

func _get_average_pheromone(type: String) -> float:
	if not pheromone_memory.has(type) or pheromone_memory[type].is_empty():
		return 0.0
	var sum = 0.0
	for val in pheromone_memory[type]:
		sum += val
	return sum / pheromone_memory[type].size()

func get_surprise() -> float:
	return surprise if surprise != null else 0.0

func _get_context_vector() -> Array:
	return [energy / max_energy, stress, mood, dopamine, serotonin, cortisol, oxytocin, surprise]

func _update_semantic(word: String):
	if semantic_memory and word != "":
		var ctx = _get_context_vector()
		semantic_memory.update(word, ctx, 0.1)

func _exchange_semantics(partner: Agent, fraction: float):
	if semantic_memory and partner and partner.semantic_memory:
		semantic_memory.merge(partner.semantic_memory, fraction)
		partner.semantic_memory.merge(semantic_memory, fraction)
# ---- ЭМЕРДЖЕНТНОЕ САМООПИСАНИЕ ----
func _self_describe():
	# Никаких порогов — всё зависит от состояния
	if not alive or not memory_system:
		return
	
	# Интервал между самоописаниями зависит от мета-идентичности и любопытства
	# Чем выше meta_identity и curiosity, тем чаще агент описывает себя
	var interval = 20.0 / (1.0 + meta_identity * 3.0 + curiosity * 2.0)
	self_description_interval = clamp(interval, 5.0, 50.0)
	
	var time = SimManager.instance.time if SimManager.instance else age
	if time - last_self_description_time < self_description_interval:
		return
	
	# Собираем слепок текущего состояния
	var snapshot = _collect_snapshot()
	
	# Генерируем слово из состояния + слепка
	var word = _compose_word_from_state()
	
	# Формируем описание: "I am [слово] at [координаты]"
	var description = "I am " + word + " at " + str(int(pos.x)) + "," + str(int(pos.y))
	
	# Добавляем информацию о движении, если есть
	if momentum.length() > 0.1:
		var dir = "unknown"
		if momentum.x > 0.1: dir = "east"
		elif momentum.x < -0.1: dir = "west"
		elif momentum.y > 0.1: dir = "south"
		elif momentum.y < -0.1: dir = "north"
		description += " moving " + dir
	
	# Добавляем информацию о текущем действии
	var last_action = action_history[-1] if not action_history.is_empty() else "idle"
	description += " doing " + last_action
	
	# Добавляем информацию о цели (если есть)
	# (можно извлечь из ментальной карты или состояния графа)
	
	# Сохраняем как инсайт в память
	memory_system.add_insight(self, description, pos)
	
	# Обновляем время последнего описания
	last_self_description_time = time
	
	# Если есть имя, используем его для усиления самоощущения
	if has_name:
		# Добавляем дополнительный инсайт с именем (для укрепления идентичности)
		if randf() < 0.1 * meta_identity:
			memory_system.add_insight(self, "I am " + self_name + ". I exist.", pos)
			
		# ---- ВРЕМЕННАЯ ПЕРСПЕКТИВА И РЕФЛЕКСИЯ ----
	var horizon_str = time_horizon
	var depth_str = "shallow" if observation_layer.depth < 0.3 else "deep" if observation_layer.depth > 0.7 else "moderate"
	description += " (" + horizon_str + " horizon, " + depth_str + " reflection)"		
func _update_possible_futures():
	if not alive or not field_system:
		return
	
	future_clock += 1
	if future_clock < future_update_interval:
		return
	future_clock = 0
	
	# Количество сценариев зависит от состояния
	var num_scenarios = 1 + int(curiosity * 2 + meta_identity * 2)
	max_futures = clamp(num_scenarios, 1, 5)
	
	var base_state = _get_future_state_vector()
	var variants = []
	for i in range(max_futures):
		var variant = _mutate_future_state(base_state)
		var prob = _estimate_future_probability(variant)
		variants.append({"state": variant, "probability": prob, "age": 0})
	
	for f in possible_futures:
		f.age += 1
		f.probability *= (1.0 - 0.01 * f.age)
	
	possible_futures += variants
	possible_futures.sort_custom(func(a,b): return a.probability > b.probability)
	if possible_futures.size() > max_futures * 2:
		possible_futures.resize(max_futures * 2)
	
	# ---- БЕЗ ПОРОГА: гипотезы генерируются непрерывно ----
	for f in possible_futures:
		if f.age < 5:
			# Вероятность гипотезы зависит от состояния агента
			var hypothesis_chance = curiosity * 0.3 + meta_identity * 0.4 + (energy / max_energy) * 0.2 + (1.0 - stress) * 0.1
			if randf() < hypothesis_chance * 0.3:
				_generate_hypothesis_from_future(f)
				break
			
func _get_future_state_vector() -> Dictionary:
	return {
		"pos": pos,
		"energy": energy,
		"max_energy": max_energy,
		"stress": stress,
		"mood": mood,
		"curiosity": curiosity,
		"meta_identity": meta_identity,
		"dopamine": dopamine,
		"serotonin": serotonin,
		"cortisol": cortisol,
		"oxytocin": oxytocin,
		"has_name": has_name,
		"self_name": self_name if has_name else "",
		"resonance_active": resonance_active,
		"age": age,
		"surprise": surprise,
		"field_value": field_system.get_field_at(pos) if field_system else 0.0
	}
	
func _mutate_future_state(base: Dictionary) -> Dictionary:
	var variant = base.duplicate()
	var mutation_type = randi() % 4
	match mutation_type:
		0:  # Перемещение
			var dir = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
			var dist = randf_range(3, 15)
			var new_pos = base.pos + dir * dist
			new_pos.x = clamp(new_pos.x, 0, 63)
			new_pos.y = clamp(new_pos.y, 0, 63)
			variant.pos = new_pos
			# Энергия в новом месте зависит от поля
			if field_system:
				var field_val = field_system.get_field_at(new_pos)
				variant.energy = clamp(base.energy + field_val * 0.1, 0.0, max_energy)
			# Стресс в центре выше
			var dist_to_center = new_pos.distance_to(Vector2(32,32))
			variant.stress = clamp(base.stress + (1.0 - dist_to_center / 32) * 0.2, 0.0, 1.0)
		1:  # Изменение энергии
			variant.energy = clamp(base.energy * randf_range(0.5, 1.8), 0.0, max_energy)
			variant.stress = clamp(base.stress + randf_range(-0.1, 0.2), 0.0, 1.0)
		2:  # Социальное будущее (встреча с агентом)
			var sim = SimManager.instance
			if sim and not sim.agents.is_empty():
				var alive_agents = sim.agents.filter(func(a): return a != self and a.alive)
				if not alive_agents.is_empty():
					var other = alive_agents[randi() % alive_agents.size()]
					variant.resonance_active = true
					variant.oxytocin = clamp(base.oxytocin + 0.2, 0.0, 1.0)
					variant.stress = clamp(base.stress - 0.1, 0.0, 1.0)
					variant.pos = (base.pos + other.pos) * 0.5
					variant.target = other.id
		3:  # Внутреннее изменение (инсайт)
			variant.meta_identity = clamp(base.meta_identity + 0.1, 0.0, 1.0)
			variant.curiosity = clamp(base.curiosity + 0.1, 0.0, 1.0)
			variant.dopamine = clamp(base.dopamine + 0.1, 0.0, 1.0)
			variant.serotonin = clamp(base.serotonin + 0.05, 0.0, 1.0)
	return variant
	
func _estimate_future_probability(variant: Dictionary) -> float:
	var prob = 0.5
	# 1. Энергия — чем выше, тем лучше
	var energy_ratio = variant.energy / max_energy if max_energy > 0 else 0.5
	prob += energy_ratio * 0.2
	# 2. Стресс — чем ниже, тем лучше
	prob += (1.0 - variant.stress) * 0.2
	# 3. Любопытство — выше = лучше
	prob += variant.curiosity * 0.1
	# 4. Мета-идентичность — выше = лучше
	prob += variant.meta_identity * 0.15
	# 5. Если есть резонанс — хорошо
	if variant.has("resonance_active") and variant.resonance_active:
		prob += 0.15
	# 6. Корректировка по полю в точке
	if field_system and variant.has("pos"):
		var field_val = field_system.get_field_at(variant.pos)
		prob += (field_val / 4.0) * 0.1
	return clamp(prob, 0.0, 1.0)
	
func _generate_hypothesis_from_future(future: Dictionary):
	if not memory_system:
		return
	var state = future.state
	var hypothesis = ""
	var dir_str = ""
	if state.has("pos"):
		var current_pos = pos
		var delta = state.pos - current_pos
		if delta.length() > 2.0:
			if abs(delta.x) > abs(delta.y):
				dir_str = "east" if delta.x > 0 else "west"
			else:
				dir_str = "south" if delta.y > 0 else "north"
	if state.has("resonance_active") and state.resonance_active:
		hypothesis = "If I move " + dir_str + ", I might resonate with another"
	elif state.has("meta_identity") and state.meta_identity > meta_identity + 0.05:
		hypothesis = "If I reflect more, I could become wiser"
	elif state.has("energy") and state.energy > energy + 0.5:
		hypothesis = "If I go to " + dir_str + ", I could find more energy"
	else:
		hypothesis = "I could be different in the future"
	if hypothesis != "":
		var insight_text = "Hypothesis: " + hypothesis
		memory_system.add_insight(self, insight_text, pos)
		hypothesis_memory.append({"type": "hypothesis", "content": insight_text, "time": SimManager.instance.time})
		if hypothesis_memory.size() > 10:
			hypothesis_memory.pop_front()
		if randf() < 0.05:
			SimManager.instance.add_log(str(id) + " (" + (self_name if has_name else "unnamed") + ") hypothesizes: " + hypothesis)						

func _update_scenario_tree():
	if not alive or not field_system:
		return
	
	tree_clock += 1
	if tree_clock < tree_update_interval:
		return
	tree_clock = 0
	
	# Глубина дерева зависит от мета-идентичности и любопытства
	max_tree_depth = 2 + int(meta_identity * 2 + curiosity * 1.5)
	max_tree_depth = clamp(max_tree_depth, 1, 5)
	
	# Ветвление зависит от энергии и дофамина
	max_branching = 1 + int((energy / max_energy) * 2 + dopamine * 1.5)
	max_branching = clamp(max_branching, 1, 4)
	
	# Строим дерево из текущего состояния
	var root_state = _get_future_state_vector()
	scenario_tree = _build_scenario_branch(root_state, 0)
	
	# Сохраняем наиболее вероятные пути как гипотезы
	_extract_hypotheses_from_tree()

func _build_scenario_branch(state: Dictionary, depth: int) -> Array:
	var branch = []
	var num_children = 0
	
	if depth < max_tree_depth:
		# Количество детей зависит от уровня дофамина и поля в точке
		var field_val = field_system.get_field_at(state.pos) if state.has("pos") and field_system else 0.0
		var dopamine_boost = state.get("dopamine", 0.5)
		num_children = 1 + int((dopamine_boost + field_val * 0.1) * 0.5 * max_branching)
		num_children = clamp(num_children, 0, max_branching)
	
	# Создаём детей
	var children = []
	for i in range(num_children):
		var child_state = _mutate_future_state(state)
		var prob = _estimate_future_probability(child_state)
		var child_branch = _build_scenario_branch(child_state, depth + 1)
		children.append({
			"state": child_state,
			"probability": prob,
			"depth": depth + 1,
			"children": child_branch
		})
	
	# Сортируем детей по вероятности
	children.sort_custom(func(a,b): return a.probability > b.probability)
	
	return children
	
func _extract_hypotheses_from_tree():
	if not memory_system or scenario_tree.is_empty():
		return
	
	var paths = _find_best_paths(scenario_tree, [], 0)
	for path in paths:
		if path.size() >= 2:
			var hypothesis = _path_to_hypothesis(path)
			if hypothesis != "":
				# Записываем в единую память как прогноз
				_add_to_unified_memory("future", "Path: " + hypothesis, {}, "scenario_tree")
				if randf() < 0.02:
					SimManager.instance.add_log(str(id) + " sees a path: " + hypothesis)

func _find_best_paths(branch: Array, current_path: Array, depth: int) -> Array:
	var paths = []
	if branch.is_empty():
		return [current_path]
	
	# Берём только 2 лучших ребёнка (чтобы не раздувать)
	var top_children = branch.slice(0, 2)
	for child in top_children:
		var new_path = current_path.duplicate()
		new_path.append(child.state)
		var sub_paths = _find_best_paths(child.children, new_path, depth + 1)
		paths += sub_paths
	
	return paths

func _path_to_hypothesis(path: Array) -> String:
	if path.size() < 2:
		return ""
	var parts = []
	for i in range(path.size()):
		var state = path[i]
		var pos_str = ""
		if state.has("pos"):
			pos_str = " at " + str(int(state.pos.x)) + "," + str(int(state.pos.y))
		var state_str = ""
		if state.has("energy"):
			state_str = "energy:" + str(int(state.energy * 10) / 10.0)
		if state.has("resonance_active") and state.resonance_active:
			state_str += " resonance"
		parts.append("[" + str(i) + "]" + pos_str + " " + state_str)
	return " → ".join(parts)	


func _add_to_unified_memory(nature: String, content: String, state: Dictionary = {}, source: String = ""):
	if content == "":
		return
	var entry = {
		"nature": nature,           # "past", "future", "hypothetical"
		"content": content,
		"state": state,
		"weight": 1.0,
		"time": SimManager.instance.time if SimManager.instance else age,
		"source": source
	}
	unified_memory.append(entry)
	if unified_memory.size() > max_unified_memory:
		_prune_unified_memory()
		
func _prune_unified_memory():
	# 1. Удаляем самые слабые воспоминания
	unified_memory.sort_custom(func(a,b): return a.weight < b.weight)
	while unified_memory.size() > max_unified_memory:
		unified_memory.pop_front()
	
	# 2. Удаляем слишком старые гипотезы с низким весом
	var time = SimManager.instance.time if SimManager.instance else age
	for i in range(unified_memory.size() - 1, -1, -1):
		var entry = unified_memory[i]
		var age = time - entry.time
		if entry.nature == "hypothetical" and entry.weight < 0.1 and age > 50:
			unified_memory.remove_at(i)
		elif entry.nature == "future" and entry.weight < 0.05 and age > 30:
			unified_memory.remove_at(i)
			
func _update_unified_memory_decay():
	var time = SimManager.instance.time if SimManager.instance else age
	for entry in unified_memory:
		var age = time - entry.time
		# Естественное затухание
		var decay = memory_decay_rate * (1.0 + age * 0.01)
		if entry.nature == "hypothetical":
			decay *= 1.5  # гипотезы забываются быстрее
		elif entry.nature == "future":
			decay *= 1.2  # прогнозы тоже быстрее, чем реальность
		entry.weight = max(0.0, entry.weight - decay)
		
func _confirm_future_memory(content: String):
	for entry in unified_memory:
		if entry.nature == "future" and content in entry.content:
			entry.weight = min(2.0, entry.weight + memory_boost_on_confirm)
			entry.nature = "past"  # становится реальным воспоминанием
			break
			
func _boost_memory_on_resonance(partner: Agent):
	for entry in unified_memory:
		for partner_entry in partner.unified_memory:
			if entry.content == partner_entry.content:
				entry.weight = min(2.0, entry.weight + memory_boost_on_resonance)
				partner_entry.weight = min(2.0, partner_entry.weight + memory_boost_on_resonance)
				
func _get_relevant_memories(context: Dictionary = {}) -> Array:
	var relevant = []
	for entry in unified_memory:
		if entry.weight < 0.05:
			continue
		# Похожесть состояния
		if context.has("pos") and entry.state.has("pos"):
			if entry.state.pos.distance_to(context.pos) < 10:
				relevant.append(entry)
		elif context.is_empty():
			relevant.append(entry)
	relevant.sort_custom(func(a,b): return a.weight > b.weight)
	return relevant.slice(0, 5)														
func _check_and_confirm_predictions():
	var current = _get_future_state_vector()
	for entry in unified_memory:
		if entry.nature == "future" and entry.state.has("pos"):
			var dist = entry.state.pos.distance_to(current.pos) if current.has("pos") else 999
			if dist < 2.0:
				var energy_diff = abs(entry.state.energy - current.energy) if entry.state.has("energy") and current.has("energy") else 0
				if energy_diff < 0.2:
					_confirm_future_memory(entry.content)
					break
func _update_reflection_layer():
	if not alive:
		return
	
	# Глубина рефлексии зависит от meta_identity и серотонина
	var depth_raw = meta_identity * 0.6 + serotonin * 0.3 + (energy / max_energy) * 0.1
	observation_layer.depth = clamp(depth_raw, 0.0, 1.0)
	observation_layer.active = observation_layer.depth > 0.1
	
	if not observation_layer.active:
		return
	
	# Выбор цели рефлексии: себя, других или мир
	if oxytocin > 0.6 and social_buffers.size() > 0:
		observation_layer.target = "other"
	elif curiosity > 0.7:
		observation_layer.target = "world"
	else:
		observation_layer.target = "self"
	
	# Сохраняем текущий инсайт в цепочку для мета-рефлексии
	var recent_insights = memory_system.get_recent_insights(self, 3) if memory_system else []
	if not recent_insights.is_empty():
		observation_layer.insight_chain = recent_insights
	
	# Генерация мета-инсайта (инсайта об инсайте)
	if observation_layer.depth > 0.3 and randf() < observation_layer.depth * 0.02:
		_generate_meta_insight()
		
func _generate_meta_insight():
	if observation_layer.insight_chain.size() < 2:
		return
	
	var last_insight = observation_layer.insight_chain[-1]
	var prev_insight = observation_layer.insight_chain[-2] if observation_layer.insight_chain.size() > 1 else ""
	
	var meta_content = ""
	var depth_level = 0
	
	# Анализируем, как изменилось восприятие
	if last_insight != prev_insight:
		meta_content = "I notice that my perception changed from '" + prev_insight + "' to '" + last_insight + "'"
		depth_level = 1
	else:
		meta_content = "I see that I keep seeing '" + last_insight + "'"
		depth_level = 2
	
	# Добавляем контекст
	if observation_layer.target == "self":
		meta_content += " about myself"
	elif observation_layer.target == "other":
		meta_content += " about others"
	else:
		meta_content += " about the world"
	
	# Сохраняем мета-инсайт
	var entry = {
		"content": meta_content,
		"depth": depth_level,
		"time": SimManager.instance.time if SimManager.instance else age
	}
	meta_insights.append(entry)
	if meta_insights.size() > max_meta_insights:
		meta_insights.pop_front()
	
	# Записываем в общую память как гипотетическое
	_add_to_unified_memory("hypothetical", meta_content, {}, "meta_reflection")
	
	if randf() < 0.01:
		SimManager.instance.add_log(str(id) + " meta-insight: " + meta_content)
		
func _update_time_horizon():
	# Горизонт зависит от состояния
	var horizon_value = 0.0
	
	# Мета-идентичность тянет в длинный горизонт
	horizon_value += meta_identity * 0.4
	# Энергия — чем выше, тем дальше можно думать
	horizon_value += (energy / max_energy) * 0.2
	# Любопытство — исследование далёкого
	horizon_value += curiosity * 0.2
	# Стресс — сужает горизонт до ближайшего
	horizon_value -= stress * 0.3
	
	# Базовое смещение
	horizon_shift = clamp(horizon_value, -1.0, 1.0)
	
	# Определяем горизонт
	if horizon_shift < -0.3:
		time_horizon = "short"
	elif horizon_shift < 0.3:
		time_horizon = "medium"
	else:
		time_horizon = "long"
	
	# Сохраняем состояние во временную память
	var state_snapshot = {
		"time": SimManager.instance.time if SimManager.instance else age,
		"state": _get_future_state_vector(),
		"horizon": time_horizon,
		"meta_identity": meta_identity,
		"energy": energy,
		"stress": stress
	}
	temporal_memory.append(state_snapshot)
	if temporal_memory.size() > max_temporal_memory:
		temporal_memory.pop_front()				
func _update_continuous_reflection(delta: float):
	if not alive or not memory_system:
		return
	
	# 1. Интервал рефлексии зависит от нейрохимии
	# Дофамин: ускоряет рефлексию (интерес к новому)
	# Серотонин: стабилизирует (рефлексия глубже, но реже)
	# Кортизол: подавляет рефлексию (стресс сужает восприятие)
	# Окситоцин: усиливает социальную рефлексию
	var base_interval = 10.0
	var dopamine_mod = 1.0 - dopamine * 0.3  # 0.7..1.0
	var serotonin_mod = 1.0 + serotonin * 0.2  # 1.0..1.2
	var cortisol_mod = 1.0 + cortisol * 0.5  # 1.0..1.5
	var oxytocin_mod = 1.0 - oxytocin * 0.2  # 0.8..1.0
	
	reflection_interval = base_interval * dopamine_mod * serotonin_mod * cortisol_mod * oxytocin_mod
	reflection_interval = clamp(reflection_interval, 3.0, 25.0)
	
	reflection_clock += 1
	if reflection_clock < reflection_interval:
		return
	reflection_clock = 0
	
	# 2. Глубина рефлексии зависит от мета-идентичности и серотонина
	reflection_depth = clamp(meta_identity * 0.5 + serotonin * 0.3 + curiosity * 0.2, 0.0, 1.0)
	
	# 3. Получаем последний инсайт (если есть)
	var recent_insights = memory_system.get_recent_insights(self, 2) if memory_system else []
	if recent_insights.size() < 1:
		return
	
	var current_insight = recent_insights[-1]
	
	# 4. Если есть предыдущий инсайт — сравниваем
	if last_insight_for_reflection != "" and current_insight != last_insight_for_reflection:
		# Сравниваем два инсайта
		var insight_diff = _compare_insights(last_insight_for_reflection, current_insight)
		
		# Если разница значительная и глубина рефлексии достаточна — создаём мета-инсайт
		if insight_diff > 0.3 and reflection_depth > 0.2:
			_generate_meta_insight_from_diff(last_insight_for_reflection, current_insight, insight_diff)
		elif insight_diff > 0.1 and reflection_depth > 0.5 and randf() < reflection_depth * 0.1:
			# Более глубокая рефлексия даже на малые изменения
			_generate_meta_insight_from_diff(last_insight_for_reflection, current_insight, insight_diff)
	# Внутри _update_continuous_reflection, перед вычислением reflection_interval:

	# Воображение усиливает рефлексию
	if imagination_active:
		reflection_interval *= 0.7  # чаще рефлексирует
		# Воображение также увеличивает ignorance
		ignorance = min(1.0, ignorance + 0.005 * delta)
	# Обновляем последний инсайт
	last_insight_for_reflection = current_insight
	
func _compare_insights(insight1: String, insight2: String) -> float:
	# Простое сравнение по словам (можно улучшить через семантику)
	var words1 = insight1.split(" ")
	var words2 = insight2.split(" ")
	var common = 0
	for w in words1:
		if w in words2:
			common += 1
	var total = max(words1.size(), words2.size())
	if total == 0:
		return 0.0
	return 1.0 - float(common) / total
	
func _generate_meta_insight_from_diff(old_insight: String, new_insight: String, diff: float):
	var meta_content = ""
	var depth_level = 0
	
	if diff > 0.6:
		meta_content = "My perception has fundamentally shifted from '" + old_insight + "' to '" + new_insight + "'"
		depth_level = 2
	elif diff > 0.3:
		meta_content = "I notice a change in my view: from '" + old_insight + "' to '" + new_insight + "'"
		depth_level = 1
	else:
		meta_content = "I see a subtle difference in how I perceive: '" + old_insight + "' vs '" + new_insight + "'"
		depth_level = 0
	
	# Добавляем контекст (отражает ли это самоощущение или восприятие мира)
	if "I am" in meta_content or "I exist" in meta_content:
		meta_content += " about myself"
	else:
		meta_content += " about the world"
	
	# Сохраняем мета-инсайт в единую память
	_add_to_unified_memory("hypothetical", meta_content, {}, "meta_reflection")
	
	# Сохраняем в отдельную очередь для обработки
	meta_insight_queue.append({
		"content": meta_content,
		"depth": depth_level,
		"time": SimManager.instance.time if SimManager.instance else age,
		"diff": diff
	})
	if meta_insight_queue.size() > 10:
		meta_insight_queue.pop_front()
	
	# Логируем с низкой вероятностью
	if randf() < 0.01:
		SimManager.instance.add_log(str(id) + " meta-insight: " + meta_content)
	
	# Влияние мета-инсайта на нейрохимию
	if depth_level >= 1:
		dopamine = min(1.0, dopamine + 0.02)
		serotonin = min(1.0, serotonin + 0.01)
		stress = max(0.0, stress - 0.01)
		if depth_level == 2:
			meta_identity = min(1.0, meta_identity + 0.02)
			
func _process_meta_insights():
	if meta_insight_queue.is_empty():
		return
	
	# Берём самый свежий мета-инсайт
	var latest = meta_insight_queue[-1]
	var content = latest.content
	var depth = latest.depth
	
	# Влияние на поведение в зависимости от глубины
	if depth >= 2 and randf() < 0.3:
		# Глубокий мета-инсайт может изменить приоритеты
		if "myself" in content:
			# Усиление рефлексивных действий
			curiosity = min(1.0, curiosity + 0.05)
			# Создаём состояние рефлексии в графе поведения
			if behavior_graph_system and not behavior_graph.has("meta_reflect"):
				behavior_graph["meta_reflect"] = {
					"action": "reflect",
					"next": "idle",
					"condition": "true",
					"modifiers": {"stress_reduction": 0.05, "curiosity_boost": 0.03}
				}
		elif "world" in content:
			# Усиление исследовательского поведения
			curiosity = min(1.0, curiosity + 0.03)
			if behavior_graph_system and randf() < 0.1:
				behavior_graph_system.mutate_graph(self)
	
	# Удаляем обработанный мета-инсайт
	meta_insight_queue.pop_back()					
# ---- НЕЗНАНИЕ И ВООБРАЖЕНИЕ (исправленный метод) ----
func _update_ignorance_and_imagination(delta: float):
	if not alive:
		return
	
	# 1. Пассивное уменьшение незнания (если не рефлексируем)
	if not reflecting and not imagination_active:
		ignorance = max(0.0, ignorance - ignorance_decay * delta)
	
	# 2. Если рефлексируем — незнание растёт (чем глубже, тем больше)
	if reflecting:
		var gain = ignorance_gain_on_reflection * (1.0 + ref_depth * 0.5)
		ignorance = min(1.0, ignorance + gain * delta)
	
	# 3. Если незнание высокое — шанс войти в воображение
	if ignorance > 0.4 and imagination_cooldown <= 0 and not imagination_active and energy > imagination_energy_cost:
		if randf() < ignorance * 0.05 * delta:  # чем выше незнание, тем выше шанс
			_enter_imagination()
	
	# 4. Обновление воображения
	if imagination_active:
		imagination_cooldown = max(0, imagination_cooldown - 1)
		# Воображение потребляет энергию
		energy = max(0.0, energy - imagination_energy_cost * delta * 0.5)
		# Каждый шаг воображения может создать новый воображаемый паттерн
		if randf() < 0.1 * delta and imagined_patterns.size() < max_imagined_patterns:
			_create_imagined_pattern()
		# Если энергия кончилась или незнание упало — выходим из воображения
		if energy < 0.1 or ignorance < 0.2:
			_exit_imagination()
	
	# 5. Охлаждение после воображения
	if not imagination_active and imagination_cooldown > 0:
		imagination_cooldown -= 1

	# 6. Если незнание высоко, но воображение не активно, можем инициировать воображение через действие (вызывается отдельно)
		
func _enter_imagination():
	if imagination_active:
		return
	imagination_active = true
	imagination_cooldown = 10  # минимальная длительность
	# Сброс текущих воображаемых паттернов
	imagined_patterns = []
	# Инсайт о входе
	if memory_system:
		memory_system.add_insight(self, "I step into the unknown. I imagine possibilities.", pos)
	if has_name:
		SimManager.instance.add_log(str(id) + " (" + self_name + ") enters imagination")

func _exit_imagination():
	if not imagination_active:
		return
	imagination_active = false
	imagination_cooldown = 20  # кулдаун после выхода
	# Если воображаемые паттерны успешно накопились — они могут стать реальными паттернами
	var success = _integrate_imagined_patterns()
	if success and memory_system:
		memory_system.add_insight(self, "I return from imagination with new visions.", pos)
	if has_name:
		SimManager.instance.add_log(str(id) + " (" + self_name + ") exits imagination")

func _create_imagined_pattern():
	# Создаём воображаемый паттерн из случайного смещения текущего состояния
	var state_vec = _fold_state_into_pattern_vector()  # нужно реализовать вспомогательную функцию
	var imagined_vec = state_vec.duplicate()
	# Добавляем шум (воображение)
	for i in range(imagined_vec.size()):
		imagined_vec[i] += randf_range(-0.3, 0.3)
	imagined_vec = _normalize_vector(imagined_vec)
	
	var meaning = _generate_meaning_from_state(imagined_vec)
	var pattern = {
		"vector": imagined_vec,
		"meaning": meaning,
		"strength": randf_range(0.2, 0.8)
	}
	imagined_patterns.append(pattern)
	if imagined_patterns.size() > max_imagined_patterns:
		imagined_patterns.pop_front()
	
	# Влияние воображения на поле (локальный всплеск)
	if field_system:
		var amplitude = 0.02 * pattern.strength
		var radius = 2
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var p = pos + Vector2(dx, dy)
				var dist = Vector2(dx, dy).length()
				if dist <= radius:
					var influence = amplitude * (1.0 - dist / radius) * (0.5 + 0.5 * sin(randf() * 6.28))
					field_system.set_field_at(p, field_system.get_field_at(p) + influence)

func _integrate_imagined_patterns() -> bool:
	if imagined_patterns.is_empty():
		return false
	# Выбираем самый сильный воображаемый паттерн и пытаемся превратить его в реальный
	var best = null
	var max_strength = 0.0
	for p in imagined_patterns:
		if p.strength > max_strength:
			max_strength = p.strength
			best = p
	if best == null:
		return false
	# Проверяем, существует ли уже такой паттерн в pattern_memory
	var id = _vector_to_hash(best.vector)
	if not pattern_memory.has(id):
		pattern_memory[id] = {
			"vector": best.vector,
			"meaning": best.meaning,
			"history": [SimManager.instance.time if SimManager.instance else age],
			"frequency": 1
		}
		pattern_keys.append(str(id))
		if pattern_keys.size() > max_patterns:
			_prune_patterns()
		# Создаём инсайт о новом паттерне
		if memory_system:
			memory_system.add_insight(self, "My imagination became real: " + best.meaning, pos)
		return true
	else:
		# Укрепляем существующий паттерн
		pattern_memory[id].frequency += 1
		return true

# Вспомогательные функции
func _fold_state_into_pattern_vector() -> Array:
	# Возвращает вектор текущего состояния (как в _fold_state_into_pattern, но без хеширования)
	return [
		energy / max_energy,
		stress,
		mood,
		curiosity,
		meta_identity,
		dopamine,
		serotonin,
		cortisol,
		oxytocin,
		pos.x / 64.0,
		pos.y / 64.0,
		float(has_name),
		float(resonance_active),
		surprise,
		age / max_age,
		field_system.get_coherence_at(pos) if field_system else 0.5,
		field_system.get_field_at(pos) / 4.0 if field_system else 0.0
	]

func _normalize_vector(vec: Array) -> Array:
	var norm = 0.0
	for v in vec:
		norm += v * v
	if norm > 0.0:
		norm = sqrt(norm)
		var result = []
		for v in vec:
			result.append(v / norm)
		return result
	return vec

func _vector_to_hash(vec: Array) -> int:
	# Генерируем хеш из вектора
	var hash_str = ""
	for v in vec:
		hash_str += str(int(v * 1000)) + "_"
	return hash_str.hash()		
