extends RefCounted
class_name MovementSystem

# ============================================================
#  КОНСТАНТЫ (позже вынесем в конфиг)
# ============================================================
const BASE_SPEED: float = 0.12
const MOMENTUM_INFLUENCE: float = 0.3   # вес инерции
const FIELD_INFLUENCE: float = 0.5      # вес градиента поля
const NOISE_INFLUENCE: float = 0.2      # вес случайного шума
const ENERGY_COST_PER_STEP: float = 0.005   # базовые затраты на существование
const ENERGY_GAIN_FROM_FIELD: float = 0.01   # сколько энергии даёт единица поля (макс)

# ============================================================
#  ОСНОВНОЙ МЕТОД: ОБНОВЛЕНИЕ ПОЗИЦИИ И ЭНЕРГИИ
# ============================================================
func update_agent(agent, field_system: FieldSystem, stability_system: StabilitySystem, delta: float = 1.0):
	# GlobalBrain-агент не двигается через стандартную механику
	if agent.is_global_brain:
		return

	# 1. Вычисляем новое направление движения
	var direction = _calculate_direction(agent, field_system)
	
	# 2. Применяем движение с учётом чувствительности и скорости
	var effective_speed = BASE_SPEED * (1.0 + (1.0 - agent.sensitivity) * 0.5)
	var new_pos = agent.pos + direction * effective_speed * delta
	
	# 3. Ограничиваем по границам поля
	var grid_size = field_system.get_grid_size()
	new_pos.x = clamp(new_pos.x, 0.0, grid_size - 1.0)
	new_pos.y = clamp(new_pos.y, 0.0, grid_size - 1.0)
	
	# 4. Обновляем позицию
	agent.pos = new_pos
	
	# 5. Обновляем импульс (momentum) для следующего шага
	agent.momentum = agent.momentum * agent.momentum_decay + direction * 0.1
	
	# 6. Обновляем энергию
	_update_energy(agent, field_system, delta)

# ============================================================
#  ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
# ============================================================

func _calculate_direction(agent, field_system: FieldSystem) -> Vector2:
	# Получаем градиент поля в точке агента
	var grad = field_system.get_gradient(agent.pos)
	# Нормализуем градиент, если он не нулевой
	if grad.length() > 0.001:
		grad = grad.normalized()
	else:
		grad = Vector2.ZERO
	
	# Инерция (текущий momentum)
	var momentum_dir = agent.momentum.normalized() if agent.momentum.length() > 0.001 else Vector2.ZERO
	
	# Случайный шум (квантовые флуктуации)
	var noise = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * 0.3
	
	# Взвешенная сумма
	var raw_dir = (grad * FIELD_INFLUENCE + momentum_dir * MOMENTUM_INFLUENCE + noise * NOISE_INFLUENCE)
	
	# Если градиент слишком слабый (меньше sensitivity), игнорируем его
	var grad_strength = field_system.get_gradient(agent.pos).length()
	if grad_strength < agent.sensitivity * 0.5:
		# Убираем влияние поля, оставляем инерцию и шум
		raw_dir = momentum_dir * MOMENTUM_INFLUENCE + noise * NOISE_INFLUENCE
	
	# Нормализуем результат
	if raw_dir.length() > 0.001:
		return raw_dir.normalized()
	else:
		return Vector2.ZERO

func _update_energy(agent, field_system: FieldSystem, delta: float):
	# 1. Получаем амплитуду поля в точке
	var field_value = field_system.get_field_at(agent.pos)
	# Нормализуем поле в диапазон [0, max_energy]
	var energy_from_field = clamp((field_value + 1.0) * 0.15 * agent.max_energy, 0.0, agent.max_energy)
	
	# 2. Затраты на поддержание когерентности (чем выше coherence, тем больше затрат)
	var coherence_cost = agent.self_coherence * 0.01 * delta
	
	# 3. Затраты на движение (если агент двигается)
	var movement_cost = 0.0
	if agent.momentum.length() > 0.01:
		movement_cost = agent.momentum.length() * 0.007 * delta
	
	# 4. Итоговое изменение энергии
	var energy_delta = (energy_from_field - agent.energy) * 0.05  # плавное приближение к полю
	energy_delta -= coherence_cost
	energy_delta -= movement_cost
	# Базовые затраты на существование
	energy_delta -= ENERGY_COST_PER_STEP * delta
	
	# 5. Применяем изменение
	agent.energy = clamp(agent.energy + energy_delta, 0.0, agent.max_energy)
	
	# 6. Если энергия упала до нуля — агент умирает (будет обработано в StabilitySystem)
	if agent.energy <= 0.0:
		agent.alive = false
		agent.is_ghost = true
		if agent.has_name:
			SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") ran out of energy and dissolved.")
