class_name Dot
extends Node2D

var agent: Agent
var glow_pulse: float = 0.0

func _init(ag: Agent):
	agent = ag

func _draw():
	if not agent or not agent.alive:
		return

	if agent.is_global_brain:
		_draw_global_brain()
		return

	_draw_normal_agent()

func _draw_normal_agent():
	var base_color = Color(1.0, 0.9, 0.2)
	var energy_factor = clamp(agent.energy / 5.0, 0.2, 1.0)
	var color = base_color.lerp(Color.WHITE, energy_factor * 0.3)
	var scale = 0.6 + agent.energy * 0.08
	if agent.energy < 0.4:
		color = color.darkened(0.2)
		scale *= 0.7
	var pos = Vector2.ZERO

	var glow_radius = 9 * scale
	draw_circle(pos, glow_radius, Color(1.0, 0.9, 0.2, 0.12))
	draw_circle(pos, glow_radius * 0.5, Color(1.0, 0.9, 0.2, 0.08))

	draw_circle(pos + Vector2(0, -10) * scale, 5 * scale, color)
	if agent.energy > 0.15:
		draw_circle(pos + Vector2(-2.5, -11) * scale, 1.8 * scale, Color.WHITE)
		draw_circle(pos + Vector2(2.5, -11) * scale, 1.8 * scale, Color.WHITE)
		draw_circle(pos + Vector2(-2.5, -11) * scale, 0.9 * scale, Color.BLACK)
		draw_circle(pos + Vector2(2.5, -11) * scale, 0.9 * scale, Color.BLACK)

	draw_line(pos + Vector2(0, -5) * scale, pos + Vector2(0, 6) * scale, color, 2.2 * scale)
	draw_line(pos + Vector2(0, -1) * scale, pos + Vector2(-6, 2) * scale, color, 1.6 * scale)
	draw_line(pos + Vector2(0, -1) * scale, pos + Vector2(6, 2) * scale, color, 1.6 * scale)
	draw_line(pos + Vector2(0, 6) * scale, pos + Vector2(-4, 12) * scale, color, 1.6 * scale)
	draw_line(pos + Vector2(0, 6) * scale, pos + Vector2(4, 12) * scale, color, 1.6 * scale)

	if agent.stress > 0.3:
		draw_circle(pos + Vector2(-7, -8) * scale, 1.2 * scale, Color.RED)
		draw_circle(pos + Vector2(7, -8) * scale, 1.2 * scale, Color.RED)
	if agent.imagination_active:
		var glow = Color(0.8, 0.2, 0.8, 0.2 + 0.3 * sin(Time.get_ticks_msec() * 0.005))
		draw_circle(pos, 15 * scale, glow)
func _draw_global_brain():
	var pos = Vector2.ZERO
	var scale = 2.0
	var pulse = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.003)

	var glow_radius = 20 * scale * pulse
	draw_circle(pos, glow_radius, Color(1.0, 0.9, 0.2, 0.08 * pulse))
	draw_circle(pos, glow_radius * 0.6, Color(1.0, 0.9, 0.2, 0.12 * pulse))

	var head_color = Color(1.0, 0.9, 0.2)
	draw_circle(pos + Vector2(0, -10) * scale, 8 * scale, head_color)
	draw_circle(pos + Vector2(-4, -11) * scale, 2.5 * scale, Color.WHITE)
	draw_circle(pos + Vector2(4, -11) * scale, 2.5 * scale, Color.WHITE)
	draw_circle(pos + Vector2(-4, -11) * scale, 1.5 * scale, Color.BLACK)
	draw_circle(pos + Vector2(4, -11) * scale, 1.5 * scale, Color.BLACK)

	var body_color = Color(1.0, 0.9, 0.2)
	draw_line(pos + Vector2(0, -5) * scale, pos + Vector2(0, 8) * scale, body_color, 4 * scale)
	draw_line(pos + Vector2(0, -1) * scale, pos + Vector2(-8, 3) * scale, body_color, 3 * scale)
	draw_line(pos + Vector2(0, -1) * scale, pos + Vector2(8, 3) * scale, body_color, 3 * scale)
	draw_line(pos + Vector2(0, 8) * scale, pos + Vector2(-6, 16) * scale, body_color, 3 * scale)
	draw_line(pos + Vector2(0, 8) * scale, pos + Vector2(6, 16) * scale, body_color, 3 * scale)

	var crown_color = Color(1.0, 0.8, 0.0)
	draw_circle(pos + Vector2(0, -18) * scale, 3 * scale, crown_color)
	draw_circle(pos + Vector2(-6, -16) * scale, 2 * scale, crown_color)
	draw_circle(pos + Vector2(6, -16) * scale, 2 * scale, crown_color)

	draw_arc(pos, 12 * scale, 0, TAU, 16, Color(1.0, 0.9, 0.2, 0.3 * pulse), 2 * scale)

func _process(delta):
	if agent and agent.alive:
		position = agent.pos * 10
		queue_redraw()
	else:
		queue_free()
