extends RefCounted
class_name Enemy

enum Type { RUSTY_MECHANISM, DUST_GOLEM, DUO_MECHANISM }

var type: Type
var pos: Vector2
var alive: bool = true
var health: float = 3.0   # базовое здоровье
var max_health: float = 3.0
var radius: float = 3.0   # радиус влияния на поле
var attack_cooldown: int = 0
var context_message: String = ""  # текст, который транслируется в поле

func _init(t: Type, position: Vector2):
	type = t
	pos = position
	match type:
		Type.RUSTY_MECHANISM:
			health = 3.0
			max_health = 3.0
			radius = 3.0
			context_message = "Rust consumes all. Bring iron to stop it."
		Type.DUST_GOLEM:
			health = 5.0
			max_health = 5.0
			radius = 4.0
			context_message = "Only water can settle the dust."
		Type.DUO_MECHANISM:
			health = 6.0
			max_health = 6.0
			radius = 4.0
			context_message = "Two hearts beat as one. Strike together."

func take_damage(amount: float):
	health -= amount
	if health <= 0:
		alive = false

func get_field_influence(pos: Vector2) -> float:
	# Возвращает влияние на поле в точке pos
	var dist = pos.distance_to(self.pos)
	if dist > radius:
		return 0.0
	match type:
		Type.RUSTY_MECHANISM:
			return -0.3 * (1.0 - dist / radius)   # отрицательное поле
		Type.DUST_GOLEM:
			return -0.5 * (1.0 - dist / radius)   # сильное поглощение
		Type.DUO_MECHANISM:
			# создаёт сложный паттерн: два пика
			var angle = atan2(pos.y - self.pos.y, pos.x - self.pos.x)
			var wave = sin(angle * 2.0 + dist * 0.5) * 0.4
			return wave * (1.0 - dist / radius)
	return 0.0
func get_fear_influence(agent_pos: Vector2) -> float:
	# Возвращает уровень страха (0..1) для агента в зависимости от расстояния
	var dist = agent_pos.distance_to(pos)
	if dist > radius:
		return 0.0
	var fear = 1.0 - dist / radius
	return fear * 0.8   # максимальный страх 0.8
func get_context_signal(agent_pos: Vector2) -> String:
	# Если агент близко и у него высокая мета-рефлексия, возвращаем сообщение
	if agent_pos.distance_to(pos) < radius * 1.5 and agent_pos.distance_to(pos) > radius * 0.5:
		return context_message
	return ""
func get_signal_text() -> String:
	return context_message
