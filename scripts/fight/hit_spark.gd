class_name HitSpark
extends Node2D
## A short burst drawn where a hit connects. Orange for hits, blue for blocks.

const LIFETIME := 0.22

var blocked := false
var heavy := false
var _age := 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := _age / LIFETIME
	var color := Color(0.5, 0.8, 1.0) if blocked else Color(1.0, 0.8, 0.3)
	color.a = 1.0 - t
	var radius := (40.0 if heavy else 26.0) * (0.4 + t)
	draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 1, 1, (1.0 - t) * 0.8))
	for i in 8:
		var dir := Vector2.RIGHT.rotated(TAU * i / 8.0 + 0.3)
		draw_line(dir * radius * 0.5, dir * radius * 1.3, color, 4.0 if heavy else 3.0)
