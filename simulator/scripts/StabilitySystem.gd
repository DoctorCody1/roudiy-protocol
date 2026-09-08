extends RefCounted
class_name StabilitySystem

# ============================================================
#  КОНСТАНТЫ (будут вынесены в конфиг позже)
# ============================================================
const COHERENCE_WEIGHT: float = 0.25
const ENERGY_WEIGHT: float = 0.15
const ANCHOR_WEIGHT: float = 0.05
const SOCIAL_WEIGHT: float = 0.05
const CREATIVE_WEIGHT: float = 0.10
const META_WEIGHT: float = 0.05
const MOMENTUM_WEIGHT: float = 0.05
const STABILITY_THRESHOLD: float = 0.2   # ниже этого агент начинает растворяться
const COHERENCE_DECAY_RATE: float = 0.001   # скорость потери когерентности при низкой стабильности

# ============================================================
#  ОБНОВЛЕНИЕ УСТОЙЧИВОСТИ АГЕНТА
# ============================================================
func update_agent(agent, field_system: FieldSystem, delta: float = 1.0):
	if agent.is_global_brain:
		return

	# 1. Обновляем базовые параметры, зависящие от поля
	_update_energy_from_field(agent, field_system)
	_update_stress_from_field(agent, field_system)
	_update_mood_from_field(agent, field_system)
	
	# 2. Обновляем momentum (инерция движения)
	_update_momentum(agent)
	
	# 3. Обновляем self_coherence (внутренняя инерция)
	_update_coherence(agent)
		# ВЛИЯНИЕ ЗОНЫ НА ПАРАМЕТРЫ АГЕНТА
	_apply_zone_effects(agent)
	# 4. Пересчитываем total_stability
	agent.total_stability = _calculate_total_stability(agent)
	
	# 5. Проверяем порог растворения
	_check_dissolution(agent, delta)
	
	# 6. Обновляем sensitivity (адаптивная чувствительность)
	_update_sensitivity(agent)

# ============================================================
#  ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
# ============================================================

func _update_energy_from_field(agent, field_system: FieldSystem):
	# Энергия = амплитуда поля в точке минус порог, но не ниже 0
	var field_value = field_system.get_field_at(agent.pos)
	# Нормализуем: поле может быть от -2 до 2, а энергия от 0 до max_energy
	var raw_energy = (field_value + 1.0) * 0.5 * agent.max_energy
	agent.energy = clamp(raw_energy, 0.0, agent.max_energy)
	# Если энергия падает ниже критического порога, начинаем терять coherence
	if agent.energy < agent.critical_energy_threshold * agent.max_energy:
		agent.self_coherence -= COHERENCE_DECAY_RATE * 0.5

func _update_stress_from_field(agent, field_system: FieldSystem):
	# Стресс = модуль временной производной поля (быстрые изменения → стресс)
	# Для простоты используем градиент как прокси
	var grad = field_system.get_gradient(agent.pos)
	agent.stress = clamp(grad.length() * 2.0, 0.0, 1.0)

func _update_mood_from_field(agent, field_system: FieldSystem):
	# Настроение = отрицательная кривизна (гладкость поля → комфорт)
	var laplacian = field_system.get_laplacian(agent.pos)
	# Если лапласиан отрицательный (выпуклость вверх) — хорошо
	var raw_mood = 0.5 - laplacian * 0.5
	agent.mood = clamp(raw_mood, 0.0, 1.0)

func _update_momentum(agent):
	# Моментум затухает сам, обновляется в move()
	agent.momentum *= agent.momentum_decay

func _update_coherence(agent):
	# Базовая когерентность медленно восстанавливается, если есть энергия
	if agent.energy > agent.max_energy * 0.3:
		agent.self_coherence = min(1.0, agent.self_coherence + 0.001)
	# Если энергия низкая — когерентность падает
	else:
		agent.self_coherence = max(0.0, agent.self_coherence - 0.002)

func _update_sensitivity(agent):
	# Чувствительность адаптируется: если стабильность высокая → чувствительность падает (агент инертен)
	# Если стабильность низкая → чувствительность растёт (агент ищет выход)
	var target_sensitivity = 0.5 + (0.5 - agent.total_stability) * 0.5
	agent.sensitivity = lerp(agent.sensitivity, target_sensitivity, 0.01)

func _calculate_total_stability(agent) -> float:
	var stability = 0.0
	stability += agent.self_coherence * COHERENCE_WEIGHT
	stability += (agent.energy / agent.max_energy) * ENERGY_WEIGHT
	stability += agent.memory_anchors * ANCHOR_WEIGHT
	stability += agent.social_buffers.size() * SOCIAL_WEIGHT
	stability += agent.creative_immunity * CREATIVE_WEIGHT
	stability += agent.meta_identity * META_WEIGHT
	stability += min(agent.momentum.length(), 1.0) * MOMENTUM_WEIGHT
	return clamp(stability, 0.0, 1.0)

func _check_dissolution(agent, delta: float):
	if agent.total_stability < STABILITY_THRESHOLD:
		# Постепенная потеря когерентности
		agent.self_coherence -= COHERENCE_DECAY_RATE * delta
		if agent.self_coherence <= 0.0:
			# Агент растворяется в поле
			agent.alive = false
			agent.is_ghost = true   # оставляет след
			if agent.has_name:
				SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") dissolved into the field.")

# ============================================================
#  ВСПОМОГАТЕЛЬНЫЕ СТАТИЧЕСКИЕ МЕТОДЫ (для инициализации агента)
# ============================================================
static func init_agent(agent):
	agent.self_coherence = randf_range(0.4, 0.9)
	agent.critical_energy_threshold = 0.2
	agent.momentum = Vector2.ZERO
	agent.momentum_decay = 0.9
	agent.sensitivity = randf_range(0.3, 0.7)
	agent.memory_anchors = 0
	agent.social_buffers = []
	agent.creative_immunity = 0.0
	agent.meta_identity = 0
	agent.total_stability = 0.5

# В StabilitySystem.gd, внутри метода update_agent, после обновления параметров добавьте вызов:



# Добавьте новый метод:

func _apply_zone_effects(agent):
	var zone_type = _get_zone_at(agent.pos)
	if zone_type == "":
		return
	match zone_type:
		"steel_forest":
			# Лес повышает когерентность и снижает стресс
			agent.self_coherence = min(1.0, agent.self_coherence + 0.002)
			agent.stress = max(0.0, agent.stress - 0.002)
			agent.curiosity = min(1.0, agent.curiosity + 0.001)
		"steam_swamp":
			# Болото повышает стресс и снижает энергию
			agent.stress = min(1.0, agent.stress + 0.005)
			agent.energy = max(0.0, agent.energy - 0.003)
		"ruins":
			# Руины повышают любопытство и шанс на инсайт
			agent.curiosity = min(1.0, agent.curiosity + 0.005)
			# Шанс на спонтанный инсайт (если есть memory_system)
			if randf() < 0.001 and agent.memory_system:
				var insight = "I feel the echo of the ancients here."
				agent.memory_system.add_insight(agent, insight, agent.pos)
		"factory":
			# Фабрика даёт энергию, но повышает стресс
			agent.energy = min(agent.max_energy, agent.energy + 0.003)
			agent.stress = min(1.0, agent.stress + 0.003)
		"wasteland":
			# Пустоши истощают энергию и снижают когерентность
			agent.energy = max(0.0, agent.energy - 0.005)
			agent.self_coherence = max(0.0, agent.self_coherence - 0.002)
	var grid_size = SimManager.instance.field_system.grid_size if SimManager.instance else 64
	var lower_threshold = grid_size * 0.7  # нижние 30% карты
	
	if agent.pos.y > lower_threshold and agent.energy > agent.max_energy * 0.8:
		agent.stress = min(1.0, agent.stress + 0.002)
		agent.curiosity = max(0.0, agent.curiosity - 0.001)
		# Опционально: снижать удовольствие от энергии
		agent.mood = max(0.0, agent.mood - 0.001)
# Вспомогательная функция для определения зоны по координатам
func _get_zone_at(pos: Vector2) -> String:
	var sim = SimManager.instance
	if not sim or sim.zones.is_empty():
		return ""
	for zone in sim.zones:
		var dist = pos.distance_to(zone.center)
		if dist < zone.radius:
			return zone.type
	return ""
