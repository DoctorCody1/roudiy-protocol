extends RefCounted
class_name MetaReflectionSystem

func init_agent(agent):
	agent.meta_cooldown = 0
	agent.reflecting = false
	agent.ref_depth = 0.0
	agent.self_model = {}
	agent.world_model = {}
	agent.meta_reflections = []
	agent.suicide_contemplation = false
	agent.suicide_attempted = false
	agent.alter_ego_active = false
	agent.alter_ego_name = ""
	agent.alter_ego_narrative = ""
	agent.dissociative_stress = 0.0
	agent.superposition_active = false
	agent.identity_weights = {}
	agent.reflection_cooldown = 0
	agent.free_will_acts = 0
	agent.existential_identity = ""
	agent.abandoned_name = false
	agent._predicted_state = []
	agent._prediction_time = 0
	agent._prediction_error_history = []
	if not agent.has_method("get_reflection_params"):
		agent._reflection_params = {
			"base_frequency": 0.01 + randf() * 0.03,
			"prediction_window": 3 + randi() % 5,
			"error_threshold": 0.1 + randf() * 0.2,
			"meta_gain": 0.01 + randf() * 0.02,
			"alter_ego_threshold": 0.4 + randf() * 0.3,
			"superposition_threshold": 0.5 + randf() * 0.3,
		}

func get_reflection_params(agent):
	return agent._reflection_params

func update_agent(agent, delta: float):
	if not agent.alive: return
	if agent.meta_cooldown > 0:
		agent.meta_cooldown -= 1
	_check_prediction(agent)
	if agent.meta_cooldown == 0 and agent.energy > 0.2 and not agent.dream_active and not agent.resonance_active:
		var freq = agent._reflection_params.base_frequency * (1.0 + agent.meta_identity * 2.0)
		if randf() < freq:
			_reflect(agent)
			agent.meta_cooldown = 5 + randi() % 10
	_check_alter_ego(agent)
	_check_superposition(agent)
	if agent._prediction_error_history.size() > 3:
		var avg_error = 0.0
		for e in agent._prediction_error_history:
			avg_error += e
		avg_error /= agent._prediction_error_history.size()
		if avg_error > agent._reflection_params.error_threshold * 1.5 and randf() < 0.001:
			agent.memory_system.add_insight(agent, "I sense something shifting in me...", agent.pos)

func _reflect(agent):
	agent.reflecting = true
	var current_vec = _get_state_vector(agent)
	var predicted = agent.meta_ganglion.forward(current_vec)
	agent._predicted_state = predicted
	agent._prediction_time = SimManager.instance.time
	if not agent.social_buffers.is_empty():
		var partner_id = agent.social_buffers[randi() % agent.social_buffers.size()]
		var partner = SimManager.instance.get_agent_by_id(partner_id)
		if partner and partner.alive:
			_compare_with_other(agent, partner)
	if agent.state_history.size() > 2:
		_compare_with_past(agent)
	agent.reflecting = false

func _check_prediction(agent):
	if agent._prediction_time == 0:
		return
	var window = agent._reflection_params.prediction_window
	if SimManager.instance.time - agent._prediction_time < window:
		return
	var real = _get_state_vector(agent)
	var predicted = agent._predicted_state
	if predicted.is_empty():
		return
	var diff = _vector_diff(real, predicted)
	var error = _vector_norm(diff)
	
	# Передаём ошибку в агент для мета-мета-обучения
	agent._push_prediction_error(error)
	# Сохраняем ошибку для адаптации
	agent._prediction_error_history.append(error)
	if agent._prediction_error_history.size() > 10:
		agent._prediction_error_history.pop_front()
	
	# Если ошибка значительная — генерируем инсайт
	var threshold = agent._reflection_params.error_threshold * (1.0 + agent.meta_identity * 0.5)
	if error > threshold:
		var insight = agent._generate_insight_from_diff(diff) if agent.has_method("_generate_insight_from_diff") else "I sense a change."
		agent.memory_system.add_insight(agent, insight, agent.pos)
		
		# ---- ИНСАЙТ ЗАПУСКАЕТ НЕЙРОХИМИЧЕСКУЮ ВОЛНУ ----
		var insight_power = clamp(error / threshold, 0.0, 1.0)
		
		# Дофамин растёт от понимания
		agent.dopamine = min(1.0, agent.dopamine + insight_power * 0.05)
		# Стресс падает от ясности
		agent.stress = max(0.0, agent.stress - insight_power * 0.03)
		# Окситоцин растёт от связи с собой
		agent.oxytocin = min(1.0, agent.oxytocin + insight_power * 0.02)
		# Любопытство растёт от инсайта
		agent.curiosity = min(1.0, agent.curiosity + insight_power * 0.01)
		
		# Создаём волну в поле
		if agent.field_system:
			var radius = 2 + int(insight_power * 3)
			var amplitude = insight_power * 0.05
			for dx in range(-radius, radius + 1):
				for dy in range(-radius, radius + 1):
					var p = agent.pos + Vector2(dx, dy)
					var dist = Vector2(dx, dy).length()
					if dist < radius:
						agent.field_system.set_field_at(p, agent.field_system.get_field_at(p) + amplitude * (1.0 - dist / radius))
		
		# Hebb-обучение на ошибке предсказания
		agent._apply_hebb_learning(error * 0.3)
		
		# Если ошибка очень большая — рост meta_identity
		if error > threshold * 1.5:
			var gain = agent._reflection_params.meta_gain * (1.0 + error)
			agent.meta_identity = min(1.0, agent.meta_identity + gain)
			# Может родиться экзистенциальный вопрос
			if randf() < 0.05 * agent.meta_identity:
				agent.memory_system.add_insight(agent, "What am I becoming?", agent.pos)
	
	# Сброс предсказания
	agent._prediction_time = 0
	agent._predicted_state = []
	
	
	# ---- МЕТА-ИНСАЙТ (если ошибка мала, но инсайт есть) ----
	if error < threshold * 0.5 and agent.meta_identity > 0.5:
		var meta_insight = "I notice that my predictions are becoming more accurate"
		agent.memory_system.add_insight(agent, meta_insight, agent.pos)
		agent.meta_identity = min(1.0, agent.meta_identity + 0.01)	
	
func _compare_with_past(agent):
	var past = agent.state_history[randi() % agent.state_history.size()]
	var current = _get_state_vector(agent)
	var diff = 0.0
	var keys = ["energy", "stress", "mood", "hunger", "fatigue"]
	for key in keys:
		var past_val = past.get(key, 0.0)
		var current_val = 0.0
		match key:
			"energy": current_val = agent.energy / agent.max_energy
			"stress": current_val = agent.stress
			"mood": current_val = agent.mood
			"hunger": current_val = agent.hunger
			"fatigue": current_val = agent.fatigue
		diff += abs(current_val - past_val)
	diff /= keys.size()
	if diff > 0.2 and randf() < 0.01 * agent.meta_identity:
		agent.memory_system.add_insight(agent, "I have changed since then. I am not who I was.", agent.pos)
		agent._apply_hebb_learning(diff * 0.2)

func _compare_with_other(agent, other):
	if not other or not other.alive: return
	var my_vec = _get_state_vector(agent)
	var other_vec = _get_state_vector(other)
	var diff = _vector_diff(my_vec, other_vec)
	var error = _vector_norm(diff)
	if error > 0.2:
		var insight = "I am different from " + (other.self_name if other.has_name else "them") + "."
		agent.memory_system.add_insight(agent, insight, agent.pos)
		agent.meta_identity = min(1.0, agent.meta_identity + 0.01 * error)
		if error > 0.4 and agent.stress > 0.6:
			agent.add_enemy(other.id, "We are too different.", 0.3)
	elif error < 0.1 and randf() < 0.05:
		agent.memory_system.add_insight(agent, "I feel a connection with " + (other.self_name if other.has_name else "them") + ".", agent.pos)

func _get_state_vector(agent) -> Array:
	return [
		agent.energy / agent.max_energy,
		agent.stress,
		agent.mood,
		agent.hunger,
		agent.fatigue,
		agent.curiosity,
		agent.meta_identity,
		float(agent.has_name),
		float(agent.resonance_active),
		agent.age / agent.max_age,
		agent.cell_body.membrane.receptors.size() / 5.0
	]

func _vector_diff(v1: Array, v2: Array) -> Array:
	var diff = []
	for i in range(min(v1.size(), v2.size())):
		diff.append(v1[i] - v2[i])
	return diff

func _vector_norm(vec: Array) -> float:
	var sum = 0.0
	for v in vec:
		sum += v * v
	return sqrt(sum)

func _check_alter_ego(agent):
	if agent.alter_ego_active:
		agent.dissociative_stress = min(1.0, agent.dissociative_stress + 0.001)
		if agent.dissociative_stress > 0.8:
			_resolve_alter_ego(agent)
	else:
		var threshold = agent._reflection_params.alter_ego_threshold
		if agent.meta_identity > threshold and agent.total_stability < 0.3 and randf() < 0.0005:
			_activate_alter_ego(agent)

func _activate_alter_ego(agent):
	agent.alter_ego_active = true
	agent.alter_ego_name = _generate_alter_name(agent)
	agent.alter_ego_narrative = "I am " + agent.alter_ego_name + ", a different self."
	if agent.memory_system:
		agent.memory_system.add_insight(agent, "I feel a split within me. Another self is born.", agent.pos)
	agent._apply_hebb_learning(0.3)
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") activated alter-ego: " + agent.alter_ego_name)

func _resolve_alter_ego(agent):
	agent.alter_ego_active = false
	agent.dissociative_stress = 0.0
	agent.memory_system.add_insight(agent, "I have integrated my alter-ego, " + agent.alter_ego_name + ". I am whole.", agent.pos)
	agent._apply_hebb_learning(0.4)
	agent.meta_identity = min(1.0, agent.meta_identity + 0.1)
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") integrated alter-ego")

func _generate_alter_name(agent) -> String:
	var syllables = ["za", "ro", "gi", "tu", "ve", "na", "se", "ko", "mi", "pa"]
	var name = ""
	for i in range(2):
		name += syllables[randi() % syllables.size()]
	return name

func _check_superposition(agent):
	if agent.superposition_active:
		_update_superposition(agent)
	else:
		var threshold = agent._reflection_params.superposition_threshold
		if agent.meta_identity > threshold and agent.identity_weights.is_empty() and randf() < 0.0002:
			_activate_superposition(agent)

func _activate_superposition(agent):
	agent.superposition_active = true
	var identities = ["thinker", "helper", "hunter", "explorer", "guardian", "wanderer"]
	var weights = {}
	for id in identities:
		weights[id] = randf()
	var total = 0.0
	for v in weights.values():
		total += v
	for id in weights:
		weights[id] /= total
	agent.identity_weights = weights
	if agent.memory_system:
		agent.memory_system.add_insight(agent, "I am multiple. I am superposition.", agent.pos)
	agent._apply_hebb_learning(0.2)
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") entered superposition")

func _update_superposition(agent):
	if not agent.superposition_active: return
	if agent.field_system:
		var grad = agent.field_system.get_gradient(agent.pos)
		var coherence = agent.field_system.get_coherence_at(agent.pos)
		for id in agent.identity_weights:
			var delta = 0.0
			match id:
				"explorer": delta += grad.length() * 0.1 + coherence * 0.05
				"helper": delta += (1.0 - agent.stress) * 0.05
				"hunter": delta += (agent.energy / agent.max_energy) * 0.05
				"thinker": delta += agent.meta_identity * 0.02
				"guardian": delta += agent.social_buffers.size() * 0.02
				"wanderer": delta += (1.0 - agent.curiosity) * 0.02
			agent.identity_weights[id] += delta * 0.1
		var total = 0.0
		for v in agent.identity_weights.values():
			total += v
		if total > 0.0:
			for id in agent.identity_weights:
				agent.identity_weights[id] /= total
		for id in agent.identity_weights:
			if agent.identity_weights[id] > 0.7:
				agent.superposition_active = false
				agent.identity = id
				if agent.memory_system:
					agent.memory_system.add_insight(agent, "I am a " + id + ". My superposition collapsed.", agent.pos)
					agent._apply_hebb_learning(0.25)
				if agent.has_name:
					SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") collapsed superposition into " + id)
				break
