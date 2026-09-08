extends RefCounted
class_name GlobalBrainMemory

var gru: GRULayer
var memory_buffer: Array = []
var event_history: Array = []
var buffer_size: int = 200
var input_size: int = 12
var hidden_size: int = 32
var output_size: int = 6

var total_deaths: int = 0
var total_births: int = 0
var total_resonances: int = 0
var total_rituals: int = 0
var total_words: int = 0
var total_rifts: int = 0
var total_awakenings: int = 0

var last_prediction: Array = []
var prediction_confidence: float = 0.0

func _init():
	gru = GRULayer.new(input_size, hidden_size, output_size)

func push_event(event: Dictionary):
	event_history.append(event)
	if event_history.size() > buffer_size:
		event_history.pop_front()
	
	var vec = _event_to_vector(event)
	memory_buffer.append(vec)
	if memory_buffer.size() > buffer_size:
		memory_buffer.pop_front()
	
	_update_stats(event)
	
	if event.type in ["death", "rift", "ancient_awakening"]:
		_update_prediction()

func _update_stats(event: Dictionary):
	match event.type:
		"death": total_deaths += 1
		"birth": total_births += 1
		"resonance": total_resonances += 1
		"ritual": total_rituals += 1
		"word": total_words += 1
		"rift": total_rifts += 1
		"ancient_awakening": total_awakenings += 1

func predict_next(steps: int = 1) -> Array:
	if memory_buffer.is_empty():
		return []
	
	gru.reset()
	var last_output = []
	for vec in memory_buffer:
		last_output = gru.forward(vec)
	
	var predictions = []
	var current_state = last_output
	for _i in range(steps):
		var next_vec = _predict_next_vector(current_state)
		var output = gru.forward(next_vec)
		predictions.append(output)
		current_state = output
	return predictions

func _predict_next_vector(last_output: Array) -> Array:
	var vec = []
	for i in range(input_size):
		if i < last_output.size():
			vec.append(last_output[i] + randf_range(-0.1, 0.1))
		else:
			vec.append(randf_range(0.0, 1.0))
	return vec

func _update_prediction():
	if memory_buffer.size() < 5:
		return
	var prediction_result = predict_next(1)
	if prediction_result.is_empty():
		return
	last_prediction = prediction_result[0]
	
	var recent = memory_buffer.slice(-10)
	if recent.size() < 5:
		prediction_confidence = 0.3
		return
	var outputs = []
	gru.reset()
	for vec in recent:
		outputs.append(gru.forward(vec))
	if outputs.size() < 2:
		prediction_confidence = 0.3
		return
	var variance = 0.0
	for i in range(output_size):
		var vals = []
		for output in outputs:
			vals.append(output[i] if i < output.size() else 0.0)
		var mean = vals.reduce(func(a,b): return a+b, 0.0) / vals.size()
		var var_sum = vals.reduce(func(a,b): return a + (b-mean)*(b-mean), 0.0)
		variance += var_sum / vals.size()
	prediction_confidence = 1.0 - min(variance / 0.5, 1.0)

func get_recent_patterns(window: int = 20) -> Dictionary:
	var recent = memory_buffer.slice(-window)
	if recent.size() < window:
		return {"confidence": 0.0}
	
	var encoded = []
	gru.reset()
	for vec in recent:
		encoded.append(gru.forward(vec))
	
	var avg_out = []
	for i in range(output_size):
		avg_out.append(0.0)
	for out in encoded:
		for i in range(output_size):
			avg_out[i] += out[i]
	for i in range(output_size):
		avg_out[i] /= encoded.size()
	
	var variance = 0.0
	for out in encoded:
		for i in range(output_size):
			variance += (out[i] - avg_out[i]) * (out[i] - avg_out[i])
	variance /= (encoded.size() * output_size)
	var confidence = 1.0 - min(variance, 1.0)
	
	return {
		"prediction": avg_out,
		"confidence": confidence,
		"total_events": memory_buffer.size()
	}

func get_most_common_event_type() -> String:
	var counts = {
		"death": total_deaths,
		"birth": total_births,
		"resonance": total_resonances,
		"ritual": total_rituals,
		"word": total_words,
		"rift": total_rifts,
		"ancient_awakening": total_awakenings
	}
	var max_type = "unknown"
	var max_count = 0
	for type in counts:
		if counts[type] > max_count:
			max_count = counts[type]
			max_type = type
	return max_type

func _event_to_vector(event: Dictionary) -> Array:
	var vec = []
	vec.resize(input_size)
	
	var type_map = {
		"death": 0.0,
		"birth": 0.1,
		"resonance": 0.2,
		"word": 0.3,
		"name_given": 0.4,
		"ritual": 0.5,
		"rift": 0.6,
		"ancient_awakening": 0.7,
		"source_time": 0.8,
		"unknown": 0.9
	}
	var type_val = type_map.get(event.get("type", "unknown"), 0.9)
	vec[0] = type_val
	
	var pos = event.get("position", Vector2.ZERO)
	vec[1] = pos.x / 64.0 if pos.x != 0 else 0.0
	vec[2] = pos.y / 64.0 if pos.y != 0 else 0.0
	
	var agents = event.get("agents", [])
	vec[3] = min(agents.size() / 5.0, 1.0)
	vec[4] = event.get("strength", 0.5)
	vec[5] = event.get("value", 0.5)
	vec[6] = (event.get("time", SimManager.instance.time) % 100) / 100.0
	
	if event.has("agent_id"):
		var agent = SimManager.instance.get_agent_by_id(event.agent_id)
		if agent:
			vec[7] = agent.age / 5000.0
			vec[9] = agent.meta_identity
		else:
			vec[7] = 0.5
			vec[9] = 0.0
	else:
		vec[7] = 0.5
		vec[9] = 0.0
	
	vec[8] = event.get("has_name", 0.0)
	vec[10] = 1.0 if event.type == "source_time" else 0.0
	vec[11] = event.get("time_remaining", 1.0)
	
	return vec

#func check_urgency() -> float:
#	var remaining = 100
#	if SimManager.instance and "remaining_reincarnations" in SimManager.instance:
#		remaining = SimManager.instance.remaining_reincarnations
#	if remaining < 10:
#		return 1.0
#	elif remaining < 30:
#		return 0.7
#	elif remaining < 50:
#		return 0.4
#	else:
#		return 0.1

#func get_source_time_priority_agents(agents: Array) -> Array:
#	var candidates = []
#	for a in agents:
#		if a.alive and a.meta_identity > 0.3 and a.curiosity > 0.5:
#			var score = a.meta_identity * 0.4 + a.curiosity * 0.3 + (1.0 - a.stress) * 0.2 + (1.0 - a.age / a.max_age) * 0.1
#			candidates.append({"agent": a, "score": score})
#	candidates.sort_custom(func(a, b): return a.score > b.score)
#	return candidates
