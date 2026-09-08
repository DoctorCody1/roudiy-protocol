extends RefCounted
class_name SemanticMemory

# ============================================================
#  СЕМАНТИЧЕСКАЯ ПАМЯТЬ (КВАЛИА-СЕТЬ)
#  Векторные представления слов, обучаемые через контекст
# ============================================================

# ---- ПАРАМЕТРЫ ----
var embedding_dim: int = 8
var memory: Dictionary = {}      # { "word": Array[float] }
var decay_rate: float = 0.01
var learning_rate: float = 0.1

# ---- СОЗДАНИЕ НОВОГО ВЕКТОРА ----
func _create_random_vector() -> Array:
	var vec = []
	for i in range(embedding_dim):
		vec.append(randf_range(-1.0, 1.0))
	return _normalize(vec)

func _normalize(vec: Array) -> Array:
	var norm = 0.0
	for v in vec:
		norm += v * v
	norm = sqrt(norm)
	if norm == 0.0:
		return vec
	var result = []
	for v in vec:
		result.append(v / norm)
	return result

# ---- ПОЛУЧЕНИЕ ВЕКТОРА СЛОВА ----
func get_vector(word: String) -> Array:
	if not memory.has(word):
		memory[word] = _create_random_vector()
	return memory[word]

# ---- ОБНОВЛЕНИЕ ВЕКТОРА НА ОСНОВЕ КОНТЕКСТА ----
func update(word: String, context_vector: Array, strength: float = 1.0):
	if not memory.has(word):
		memory[word] = _create_random_vector()
	var current = memory[word]
	# Усредняем с контекстом
	for i in range(embedding_dim):
		var context_val = context_vector[i] if i < context_vector.size() else 0.0
		current[i] = current[i] + (context_val - current[i]) * learning_rate * strength
	# Нормализация
	memory[word] = _normalize(current)

# ---- СМЕШИВАНИЕ С ДРУГИМ АГЕНТОМ (при резонансе) ----
func merge(other: SemanticMemory, fraction: float):
	for word in other.memory.keys():
		if not memory.has(word):
			memory[word] = other.memory[word].duplicate()
		else:
			var my_vec = memory[word]
			var other_vec = other.memory[word]
			for i in range(embedding_dim):
				my_vec[i] = my_vec[i] * (1.0 - fraction) + other_vec[i] * fraction
			memory[word] = _normalize(my_vec)

# ---- КОСИНУСНОЕ РАССТОЯНИЕ ----
func cosine_similarity(vec1: Array, vec2: Array) -> float:
	var dot = 0.0
	var norm1 = 0.0
	var norm2 = 0.0
	for i in range(embedding_dim):
		var v1 = vec1[i] if i < vec1.size() else 0.0
		var v2 = vec2[i] if i < vec2.size() else 0.0
		dot += v1 * v2
		norm1 += v1 * v1
		norm2 += v2 * v2
	norm1 = sqrt(norm1)
	norm2 = sqrt(norm2)
	if norm1 == 0.0 or norm2 == 0.0:
		return 0.0
	return dot / (norm1 * norm2)

# ---- ПОЛУЧИТЬ САМЫЕ БЛИЗКИЕ СЛОВА ----
func get_similar_words(word: String, top_n: int = 3) -> Array:
	if not memory.has(word):
		return []
	var target = memory[word]
	var candidates = []
	for w in memory.keys():
		if w == word:
			continue
		var sim = cosine_similarity(target, memory[w])
		candidates.append({"word": w, "similarity": sim})
	candidates.sort_custom(func(a, b): return a.similarity > b.similarity)
	var result = []
	for i in range(min(top_n, candidates.size())):
		result.append(candidates[i].word)
	return result

# ---- КЛОНИРОВАНИЕ ДЛЯ НАСЛЕДОВАНИЯ ----
func clone() -> SemanticMemory:
	var new = SemanticMemory.new()
	new.embedding_dim = embedding_dim
	new.learning_rate = learning_rate
	new.decay_rate = decay_rate
	for word in memory.keys():
		new.memory[word] = memory[word].duplicate()
	return new

# ---- МУТАЦИЯ ----
func mutate(rate: float = 0.05, strength: float = 0.1):
	for word in memory.keys():
		var vec = memory[word]
		for i in range(vec.size()):
			if randf() < rate:
				vec[i] += randf_range(-strength, strength)
		memory[word] = _normalize(vec)
	# Мутация параметров
	if randf() < 0.1:
		learning_rate += randf_range(-0.02, 0.02)
		learning_rate = clamp(learning_rate, 0.01, 0.5)
