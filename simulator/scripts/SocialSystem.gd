extends RefCounted
class_name SocialSystem

func init_agent(agent):
	agent.trust = {}
	agent.social_buffers = []
	agent.resonance_active = false
	agent.resonance_partner = null
	agent.resonance_depth = 0.0
	agent.resonance_history = []
	agent.shadow_partner = null
	agent.shadow_depth = 0.0
	agent.shadow_integrated = false
	if not agent.has_method("get_social_params"):
		agent._social_params = {
			"resonance_range": 5.0 + randf() * 4.0,
			"speech_range": 4.0 + randf() * 3.0,
			"cooperation_threshold": 0.3 + randf() * 0.4,
			"aggression_threshold": 0.6 + randf() * 0.3,
			"trust_decay": 0.001 + randf() * 0.002,
			"social_learning_rate": 0.1 + randf() * 0.2,
		}

func get_social_params(agent):
	return agent._social_params

func update_agent(agent, delta: float):
	if not agent.alive: return
	if agent.is_global_brain: return

	for aid in agent.trust.keys():
		agent.trust[aid] = max(0.0, agent.trust[aid] - agent._social_params.trust_decay)
		if agent.trust[aid] <= 0.0:
			agent.trust.erase(aid)
	if agent.resonance_active:
		_update_resonance(agent, delta)
	else:
		_try_initiate_resonance(agent)
	agent.social_buffers = agent.social_buffers.filter(func(id):
		var a = SimManager.instance.get_agent_by_id(id)
		return a != null and a.alive
	)
	if agent.energy > 0.1 and randf() < 0.02 * (1.0 + agent.curiosity):
		var word = agent._compose_word_from_state() if agent.has_method("_compose_word_from_state") else ""
		if word != "":
			_propagate_word(agent, word)

func _propagate_word(agent, word: String):
	var sim = SimManager.instance
	if not sim or not sim.field_system:
		return
	
	var field = sim.field_system
	var entropy = field.get_global_entropy()
	var coherence_at_agent = field.get_coherence_at(agent.pos)
	var grad = field.get_gradient(agent.pos)
	var grad_mag = grad.length()
	
	var energy_factor = agent.energy / agent.max_energy
	var power = energy_factor * agent.mood * agent.curiosity * (1.0 + agent.stress) * (1.0 - entropy)
	if word.ends_with("?"):
		power *= (1.0 + entropy)
	
	var avg_dist = 0.0
	var count = 0
	for a in sim.agents:
		if a != agent and a.alive:
			avg_dist += agent.pos.distance_to(a.pos)
			count += 1
	if count == 0: return
	avg_dist /= count
	
	var radius = energy_factor * coherence_at_agent * avg_dist
	if radius <= 0.0: return
	
	var amp = power * (1.0 - entropy) * grad_mag
	var field_radius = int(radius / avg_dist) if avg_dist > 0 else 0
	field_radius = max(field_radius, 1)
	var pos = agent.pos
	for dx in range(-field_radius, field_radius + 1):
		for dy in range(-field_radius, field_radius + 1):
			var p = pos + Vector2(dx, dy)
			var dist = Vector2(dx, dy).length()
			if dist < field_radius:
				field.set_field_at(p, field.get_field_at(p) + amp * (1.0 - dist / field_radius))
	
	for other in sim.agents:
		if other == agent or not other.alive:
			continue
		var dist = pos.distance_to(other.pos)
		if dist > radius:
			continue
		
		var proximity = 1.0 - dist / radius
		var listener_curiosity = other.curiosity
		var listener_energy = other.energy / other.max_energy
		var listener_stress = other.stress
		var listener_receptivity = listener_curiosity * (1.0 + listener_stress) * listener_energy * (1.0 - entropy)
		var effective = power * proximity * listener_receptivity
		
		var curiosity_delta = effective * (1.0 - entropy)
		other.curiosity = clamp(other.curiosity + curiosity_delta, 0.0, 1.0)
		
		var stress_delta = 0.0
		if sim.global_brain:
			var danger_anchor = sim.global_brain.get_anchor("danger")
			if not danger_anchor.is_empty():
				var sim_val = sim.global_brain.semantic_similarity(word, danger_anchor["text"])
				var avg_sim_global = 0.0
				var pairs = 0
				var keys = sim.global_brain.semantic_network.keys()
				for i in range(keys.size()):
					for j in range(i+1, keys.size()):
						var s = sim.global_brain.semantic_similarity(keys[i], keys[j])
						avg_sim_global += s
						pairs += 1
				if pairs > 0:
					avg_sim_global /= pairs
				else:
					avg_sim_global = 0.0
				if sim_val > avg_sim_global:
					stress_delta = effective * entropy
				else:
					stress_delta = -effective * (1.0 - entropy)
		else:
			var danger_chars = ["z","r","g","t"]
			var is_danger = false
			for ch in danger_chars:
				if ch in word:
					is_danger = true
					break
			stress_delta = effective * (1.0 if is_danger else -1.0)
		other.stress = clamp(other.stress + stress_delta, 0.0, 1.0)
		
		var trust_factor = agent.trust.get(other.id, 0.0)
		if effective > 0.0 and trust_factor > 0.0:
			var oxy_gain = effective * trust_factor * (1.0 - entropy)
			other.oxytocin = clamp(other.oxytocin + oxy_gain, 0.0, 1.0)
		
		var avg_receptivity = 0.0
		var rc = 0
		for a in sim.agents:
			if a != other and a.alive:
				avg_receptivity += (0.5 + a.curiosity * 0.5) * (1.0 + a.stress) * (a.energy / a.max_energy)
				rc += 1
		if rc > 0:
			avg_receptivity /= rc
		else:
			avg_receptivity = 0.0
		if listener_receptivity > avg_receptivity and other.stress > 0.5:
			var mutated = _mutate_word_by_perception(word, other)
			if mutated != word:
				var hash = other._get_state_hash() if other.has_method("_get_state_hash") else ""
				if hash != "":
					other.language_memory[hash] = mutated
				if other.memory_system:
					other.memory_system.add_event(other, "heard_word", mutated, other.pos)
				word = mutated
		
		if other.semantic_memory and effective > 0.0:
			var ctx = other._get_context_vector() if other.has_method("_get_context_vector") else []
			var learn_rate = (1.0 - entropy)
			other.semantic_memory.update(word, ctx, learn_rate * effective)
		
		var avg_effective = 0.0
		var ec = 0
		for a in sim.agents:
			if a != agent and a.alive:
				var d = agent.pos.distance_to(a.pos)
				if d < radius:
					var p = 1.0 - d / radius
					avg_effective += power * p * (0.5 + a.curiosity * 0.5) * (a.energy / a.max_energy) * (1.0 - entropy)
					ec += 1
		if ec > 0:
			avg_effective /= ec
		else:
			avg_effective = 0.0
		if effective > avg_effective:
			_observe_and_learn(agent, other)
		
		if effective > 0.0 and not other.is_global_brain:
			var trust_delta = 0.0
			if sim.global_brain:
				var pos_anchor = sim.global_brain.get_anchor("help")
				if not pos_anchor.is_empty():
					var sim_val = sim.global_brain.semantic_similarity(word, pos_anchor["text"])
					var avg_sim_global = 0.0
					var pairs = 0
					var keys = sim.global_brain.semantic_network.keys()
					for i in range(keys.size()):
						for j in range(i+1, keys.size()):
							var s = sim.global_brain.semantic_similarity(keys[i], keys[j])
							avg_sim_global += s
							pairs += 1
					if pairs > 0:
						avg_sim_global /= pairs
					else:
						avg_sim_global = 0.0
					if sim_val > avg_sim_global:
						trust_delta = effective * (1.0 - entropy)
					elif word.ends_with("?"):
						trust_delta = effective * (1.0 - entropy)
				else:
					if word.ends_with("?"):
						trust_delta = effective * (1.0 - entropy)
			else:
				if "help" in word or "food" in word or "resonance" in word:
					trust_delta = effective
				elif word.ends_with("?"):
					trust_delta = effective
			if trust_delta > 0.0:
				change_trust(other, agent.id, trust_delta)
	
	var display = word if not word.ends_with("?") else word + " (question)"
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") says: '" + display + "' at " + str(pos))
	else:
		SimManager.instance.add_log(str(agent.id) + " says: '" + display + "' at " + str(pos))
	
	if agent.memory_system:
		agent.memory_system.add_event(agent, "spoken_word", word, pos)
	
	if sim.global_brain:
		var state_hash = agent._get_state_hash() if agent.has_method("_get_state_hash") else ""
		sim.global_brain.receive_word(word, agent.id, agent.pos, state_hash)

func _mutate_word_by_perception(word: String, receiver) -> String:
	if randf() < 0.15:
		var predicted = receiver._compose_word_from_state() if receiver.has_method("_compose_word_from_state") else word
		if predicted != word and randf() < 0.3:
			var parts = word.split("_")
			var pred_parts = predicted.split("_")
			if parts.size() > 1 and pred_parts.size() > 1:
				var idx = randi() % parts.size()
				parts[idx] = pred_parts[idx % pred_parts.size()]
				return "_".join(parts)
	return word

func _observe_and_learn(agent, other):
	if agent.is_global_brain or other.is_global_brain: return
	if other.well_being > agent.well_being and randf() < 0.2:
		if agent.behavior_graph_system:
			var snippet = other.behavior_graph.duplicate()
			var keys = snippet.keys()
			if keys.size() > 1:
				var state = keys[randi() % keys.size()]
				if agent.behavior_graph.size() < 10:
					agent.behavior_graph[state] = snippet[state]
					agent.graph_version += 1
					SimManager.instance.add_log(str(agent.id) + " learned from " + str(other.id))
					if agent.has_method("_apply_hebb_learning"):
						agent._apply_hebb_learning(0.2)
	if other.cell_body.membrane.get("integrity", 1.0) > 0.9 and other.well_being > agent.well_being:
		if randf() < 0.1:
			var name = other.self_name if other.has_name else "another"
			agent.memory_system.add_insight(agent, "I saw " + name + " heal. I should try too.", agent.pos)
			if agent.has_method("_apply_hebb_learning"):
				agent._apply_hebb_learning(0.2)

func _try_initiate_resonance(agent):
	if agent.is_global_brain or agent.resonance_active or agent.energy < 0.2: return
	var candidates = _find_resonance_candidates(agent)
	if candidates.is_empty(): return
	var best = null; var best_gain = -1.0
	for other in candidates:
		var predicted_gain = _predict_resonance_gain(agent, other)
		if predicted_gain > best_gain:
			best_gain = predicted_gain; best = other
	if best and best_gain > 0.1:
		initiate_resonance(agent, best)

func _find_resonance_candidates(agent):
	var candidates = []
	var range_val = agent._social_params.resonance_range * (0.8 + 0.4 * agent.curiosity)
	for a in SimManager.instance.agents:
		if a == agent or not a.alive or a.is_global_brain or a.resonance_active:
			continue
		if agent.pos.distance_to(a.pos) > range_val:
			continue
		if a.energy < 0.2:
			continue
		candidates.append(a)
	return candidates

func _predict_resonance_gain(agent, other):
	if agent.is_global_brain or other.is_global_brain:
		return 0.0
	var sim = _compute_state_similarity(agent, other)
	var trust = agent.trust.get(other.id, 0.0)
	var gain = sim * 0.6 + trust * 0.4 - 0.2
	return clamp(gain, 0.0, 1.0)

func _compute_state_similarity(a, b) -> float:
	var v1 = _get_state_embedding(a)
	var v2 = _get_state_embedding(b)
	var diff = 0.0
	for i in range(min(v1.size(), v2.size())):
		diff += abs(v1[i] - v2[i])
	var base_similarity = 1.0 - diff / v1.size()
	var membrane_factor_a = a.cell_body.membrane.get("integrity", 1.0)
	var membrane_factor_b = b.cell_body.membrane.get("integrity", 1.0)
	var membrane_factor = (membrane_factor_a + membrane_factor_b) * 0.5
	var adjusted_similarity = base_similarity * (0.5 + 0.5 * membrane_factor)
	return clamp(adjusted_similarity, 0.0, 1.0)

func _get_state_embedding(agent) -> Array:
	return [
		agent.energy / agent.max_energy,
		agent.stress,
		agent.mood,
		agent.hunger,
		agent.fatigue,
		agent.curiosity,
		agent.meta_identity,
		float(agent.has_name),
		agent.age / agent.max_age,
		agent.cell_body.membrane.get("integrity", 1.0)
	]

func initiate_resonance(agent, target):
	if not agent.alive or not target.alive: return
	if agent.is_global_brain or target.is_global_brain: return
	if agent.resonance_active or target.resonance_active: return
	var range_val = agent._social_params.resonance_range * (0.8 + 0.4 * agent.curiosity)
	if agent.pos.distance_to(target.pos) > range_val: return
	var sim = _compute_state_similarity(agent, target)
	var depth = sim * 0.5 + randf() * 0.2
	agent.resonance_active = true
	agent.resonance_partner = target
	_exchange_snapshots(agent, target)
	agent.resonance_depth = depth
	if agent.semantic_memory and target.semantic_memory:
		var fraction = 0.1 + depth * 0.2
		agent._exchange_semantics(target, fraction)
	target.resonance_active = true
	target.resonance_partner = agent
	target.resonance_depth = depth * 0.9 + randf() * 0.1
	if agent.has_method("_social_influence"):
		agent._social_influence(depth * 0.3, target)
	if target.has_method("_social_influence"):
		target._social_influence(depth * 0.3, agent)
	if depth > 0.3:
		var frac = 0.2 + depth * 0.3
		if agent.has_method("_merge_markov_chain"):
			agent._merge_markov_chain(target.markov_chain, frac)
		if target.has_method("_merge_markov_chain"):
			target._merge_markov_chain(agent.markov_chain, frac)
		if agent.last_word != "" and agent.has_method("_update_markov_chain"):
			agent._update_markov_chain(agent.last_word, 1.0 + depth * 0.5)
		if target.last_word != "" and target.has_method("_update_markov_chain"):
			target._update_markov_chain(target.last_word, 1.0 + depth * 0.5)
	if depth > 0.5 and randf() < 0.3:
		_observe_and_learn(agent, target)
		_observe_and_learn(target, agent)
	change_trust(agent, target.id, 0.03 + depth * 0.05)
	change_trust(target, agent.id, 0.03 + depth * 0.04)
	_add_social_buffer(agent, target.id)
	_add_social_buffer(target, agent.id)
	agent.stress = max(0.0, agent.stress - 0.05)
	target.stress = max(0.0, target.stress - 0.05)
	agent.meta_identity = min(1.0, agent.meta_identity + 0.02)
	target.meta_identity = min(1.0, target.meta_identity + 0.02)
	if depth > 0.4:
		if agent.has_method("_apply_hebb_learning"):
			agent._apply_hebb_learning(depth * 0.5)
		if target.has_method("_apply_hebb_learning"):
			target._apply_hebb_learning(depth * 0.5)
	if agent.memory_system:
		agent.memory_system.add_event(agent, "resonance_start", {"partner": target.id}, agent.pos)
	if target.memory_system:
		target.memory_system.add_event(target, "resonance_start", {"partner": agent.id}, target.pos)
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") entered resonance with " + str(target.id) + " depth=" + str(agent.resonance_depth).pad_decimals(2))

func _update_resonance(agent, delta):
	if not agent.resonance_partner or not agent.resonance_partner.alive:
		exit_resonance(agent, "partner_lost")
		return
	if agent.energy < 0.2 or agent.stress > 0.8:
		exit_resonance(agent, "exhaustion")
		return
	var partner = agent.resonance_partner
	var sim = _compute_state_similarity(agent, partner)
	if sim > 0.6:
		agent.resonance_depth = min(1.0, agent.resonance_depth + 0.01)
	elif sim < 0.3:
		agent.resonance_depth = max(0.0, agent.resonance_depth - 0.01)
		if agent.resonance_depth < 0.1:
			exit_resonance(agent, "mismatch")
	if SimManager.instance.time % 3 == 0:
		var val = _get_state_value(agent) + randf_range(-0.05, 0.05)
		partner.receive_resonance_throw(clamp(val, 0.0, 1.0), agent)

func _get_state_value(agent) -> float:
	return (agent.energy / agent.max_energy) * 0.4 + (1.0 - agent.stress) * 0.3 + agent.curiosity * 0.3

func receive_resonance_throw(agent, value: float, sender):
	if not agent.resonance_active or agent.resonance_partner != sender:
		return
	var my_state = _get_state_value(agent)
	var gravity = 1.0 - abs(value - my_state)
	gravity = clamp(gravity, 0.0, 1.0)
	if gravity > 0.5:
		agent.resonance_depth = min(1.0, agent.resonance_depth + 0.02)
		agent.stress = max(0.0, agent.stress - 0.01)
		change_trust(agent, sender.id, 0.02)
	else:
		agent.resonance_depth = max(0.0, agent.resonance_depth - 0.01)
		if agent.resonance_depth < 0.1:
			exit_resonance(agent, "mismatch")

func exit_resonance(agent, reason: String):
	if not agent.resonance_active: return
	var partner = agent.resonance_partner
	agent.resonance_active = false
	agent.resonance_partner = null
	agent.resonance_depth = 0.0
	if agent.memory_system:
		agent.memory_system.add_event(agent, "resonance_end", {"reason": reason}, agent.pos)
	if partner and partner.alive and partner.resonance_active and partner.resonance_partner == agent:
		partner.exit_resonance("partner_exit")
	if agent.has_name:
		SimManager.instance.add_log(str(agent.id) + " (" + agent.self_name + ") exited resonance: " + reason)

func change_trust(agent, target_id: int, delta: float):
	if agent.is_global_brain: return
	var old = agent.trust.get(target_id, 0.0)
	var gain = delta * (1.0 + old) * 0.5
	agent.trust[target_id] = clamp(old + gain, 0.0, 1.0)

func interact(agent, other):
	if not agent.alive or not other.alive: return
	if agent == other or agent.is_global_brain or other.is_global_brain: return
	var range_val = agent._social_params.resonance_range * (0.8 + 0.4 * agent.curiosity)
	if agent.pos.distance_to(other.pos) > range_val: return
	var attack_gain = _predict_attack_gain(agent, other)
	var cooperate_gain = _predict_cooperate_gain(agent, other)
	if attack_gain > cooperate_gain and attack_gain > 0.2:
		_attack(agent, other)
		if other.alive:
			other.add_enemy(agent.id, "They attacked me.", 0.4)
			agent.add_enemy(other.id, "They resisted me.", 0.3)
	elif cooperate_gain > attack_gain and cooperate_gain > 0.1:
		cooperate(agent, other)
	else:
		if not agent.resonance_active and not other.resonance_active and randf() < 0.05:
			initiate_resonance(agent, other)

func _predict_attack_gain(agent, target) -> float:
	if agent.is_global_brain or target.is_global_brain: return 0.0
	var energy_diff = agent.energy - target.energy
	var risk = target.stress * 0.3 + target.curiosity * 0.1
	var gain = (energy_diff * 0.5 - risk) * (1.0 + (agent.aggression_modifier if agent.has_method("get_aggression_modifier") else 0.0))
	return clamp(gain, 0.0, 1.0)

func _predict_cooperate_gain(agent, target) -> float:
	if agent.is_global_brain or target.is_global_brain: return 0.0
	var trust = agent.trust.get(target.id, 0.0)
	var need = 1.0 - agent.energy / agent.max_energy
	var gain = trust * 0.5 + need * 0.3 - 0.1
	return clamp(gain, 0.0, 1.0)

func cooperate(agent, other, give: float = 0.04):
	if not agent.alive or not other.alive: return
	if agent.is_global_brain or other.is_global_brain: return
	if agent.energy < give: return
	agent.energy -= give
	other.energy = min(other.max_energy, other.energy + give)
	if agent.cell_body.membrane.has("integrity") and other.cell_body.membrane.has("integrity"):
		if agent.cell_body.membrane.integrity > 0.7 and other.cell_body.membrane.integrity < 0.5:
			var transfer = 0.02
			agent.cell_body.membrane.integrity -= transfer
			other.cell_body.membrane.integrity = min(1.0, other.cell_body.membrane.integrity + transfer)
			if agent.memory_system:
				agent.memory_system.add_insight(agent, "I gave some of my membrane integrity to " + (other.self_name if other.has_name else "another"), agent.pos)
			if other.memory_system:
				other.memory_system.add_insight(other, "I received membrane healing from " + (agent.self_name if agent.has_name else "another"), other.pos)
	change_trust(agent, other.id, 0.03)
	change_trust(other, agent.id, 0.02)
	_add_social_buffer(agent, other.id)
	_add_social_buffer(other, agent.id)
	if agent.has_method("_apply_hebb_learning"):
		agent._apply_hebb_learning(0.1)
	if other.has_method("_apply_hebb_learning"):
		other._apply_hebb_learning(0.1)
	if agent.memory_system:
		agent.memory_system.add_event(agent, "cooperation", {"target": other.id}, agent.pos)

func _attack(agent, target):
	if not agent.alive or not target.alive: return
	if agent.is_global_brain or target.is_global_brain: return
	var steal = min(0.05, target.energy)
	target.energy -= steal
	agent.energy = min(agent.max_energy, agent.energy + steal * 0.5)
	change_trust(target, agent.id, -0.1)
	if target.energy <= 0:
		target.die("killed by predator")
	if agent.memory_system:
		agent.memory_system.add_event(agent, "attack", {"target": target.id}, agent.pos)

func update_shadow(agent, delta):
	if agent.is_global_brain: return
	if not agent.shadow_partner or not agent.shadow_partner.alive:
		agent.shadow_depth = max(0.0, agent.shadow_depth - 0.01)
		if agent.shadow_depth <= 0.0:
			agent.shadow_partner = null
		return
	var similarity = _compute_state_similarity(agent, agent.shadow_partner)
	if similarity < 0.4:
		agent.shadow_depth = min(1.0, agent.shadow_depth + 0.02)
	else:
		agent.shadow_depth = max(0.0, agent.shadow_depth - 0.02)
	if agent.shadow_depth >= 0.8 and not agent.shadow_integrated:
		agent.shadow_integrated = true
		if agent.memory_system:
			agent.memory_system.add_insight(agent, "I have integrated my shadow.", agent.pos)

func _add_social_buffer(agent, other_id: int):
	if agent.is_global_brain: return
	if other_id not in agent.social_buffers:
		agent.social_buffers.append(other_id)
		if agent.social_buffers.size() > 5:
			agent.social_buffers.pop_front()

func _find_resonance_partner(agent):
	if agent.is_global_brain: return null
	var candidates = _find_resonance_candidates(agent)
	if candidates.is_empty(): return null
	return candidates[randi() % candidates.size()]

func _exchange_snapshots(agent: Agent, target: Agent):
	var snapshot_a = agent._collect_snapshot()
	var snapshot_b = target._collect_snapshot()
	agent.update_profile_for(target.id, snapshot_b)
	target.update_profile_for(agent.id, snapshot_a)
	
	# Передача паттернов (эмерджентное распространение языка)
	agent.share_patterns(target, 0.3)
	target.share_patterns(agent, 0.3)
	# ---- ПЕРЕДАЧА РИТУАЛОВ ЧЕРЕЗ РЕЗОНАНС ----
	if agent.resonance_depth > 0.4 and target.resonance_depth > 0.4:
		if randf() < 0.2:
			var mixed = _cross_rituals(agent.current_ritual, target.current_ritual)
			agent.current_ritual = mixed
			target.current_ritual = mixed.duplicate()
			_mutate_ritual(agent)
			_mutate_ritual(target)

	# ---- ПЕРЕДАЧА ГИПОТЕЗ (язык возможного) ----
	if agent.hypothesis_memory.size() > 0 and target.hypothesis_memory.size() > 0:
		# Обмениваемся гипотезами
		var my_hyp = agent.hypothesis_memory[randi() % agent.hypothesis_memory.size()]
		var their_hyp = target.hypothesis_memory[randi() % target.hypothesis_memory.size()]
		if my_hyp and their_hyp:
			# Если гипотезы схожи — усиливаем
			var sim = _compare_hypotheses(my_hyp.content, their_hyp.content)
			if sim > 0.5:
				if agent.memory_system:
					agent.memory_system.add_insight(agent, "Shared hypothesis: " + their_hyp.content, agent.pos)
				if target.memory_system:
					target.memory_system.add_insight(target, "Shared hypothesis: " + my_hyp.content, target.pos)
		# ---- ОБМЕН ПРОГНОЗАМИ И ВОСПОМИНАНИЯМИ ----
	agent._boost_memory_on_resonance(target)
	target._boost_memory_on_resonance(agent)
	
		# ---- ОБМЕН ПАТТЕРНАМИ (язык-матрешка) ----
	if agent.pattern_keys.size() > 0 and target.pattern_keys.size() > 0:
		# Каждый передаёт случайный паттерн
		var p1 = agent.pattern_keys[randi() % agent.pattern_keys.size()]
		var p2 = target.pattern_keys[randi() % target.pattern_keys.size()]
		
		# Передаём паттерны через поле
		agent._emit_pattern(p1)
		target._emit_pattern(p2)
		
		# Обмениваемся паттернами в памяти (для обучения)
		var id1 = p1.to_int()
		var id2 = p2.to_int()
		if agent.pattern_memory.has(id2) and not target.pattern_memory.has(id2):
			target.pattern_memory[id2] = agent.pattern_memory[id2].duplicate()
			target.pattern_keys.append(p2)
		if target.pattern_memory.has(id1) and not agent.pattern_memory.has(id1):
			agent.pattern_memory[id1] = target.pattern_memory[id1].duplicate()
			agent.pattern_keys.append(p1)
	
func _compare_hypotheses(h1: String, h2: String) -> float:
	var words1 = h1.split(" ")
	var words2 = h2.split(" ")
	var common = 0
	for w in words1:
		if w in words2:
			common += 1
	var total = max(words1.size(), words2.size())
	return float(common) / total if total > 0 else 0.0					
								
func _cross_rituals(r1: Array, r2: Array) -> Array:
	if r1.is_empty(): return r2.duplicate()
	if r2.is_empty(): return r1.duplicate()
	var result = []
	var split = randi() % min(r1.size(), r2.size())
	for i in range(split):
		result.append(r1[i])
	for i in range(split, r2.size()):
		result.append(r2[i])
	return result

func _mutate_ritual(agent):
	if agent.is_global_brain: return
	if randf() < 0.1:
		if agent.current_ritual.size() > 2:
			var idx = randi() % agent.current_ritual.size()
			agent.current_ritual.remove_at(idx)
	if randf() < 0.1:
		var new_action = _generate_random_action()
		agent.current_ritual.append(new_action)

func _generate_random_action() -> Dictionary:
	var action_types = ["move", "speak", "resonate", "rest", "eat", "attack", "cooperate", "ritual", "reflect"]
	var type = action_types[randi() % action_types.size()]
	var action = {"type": type}
	match type:
		"move":
			action["direction"] = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
		"speak":
			action["word"] = "seek_" + str(randi() % 10)
		"rest":
			action["duration"] = randi_range(1, 3)
		"eat":
			action["amount"] = randf_range(0.5, 1.0)
		"resonate":
			action["target"] = null
		"attack":
			action["target"] = null
		"cooperate":
			action["target"] = null
		"ritual":
			action["name"] = "ritual_" + str(randi() % 100)
		"reflect":
			action["depth"] = randf()
	return action
