extends Node2D

@export var beam_scene : PackedScene
var is_fired : bool = false
var is_on : bool = true

func _ready() -> void:
	pass

func shoot_beam() -> void:
	if not (is_fired) and (is_on):
		is_fired = true
		var target : Vector2 = get_global_mouse_position()
		look_at(target)
		$Beam.fire_beam(target)

func spell_fade() -> void: 
	var tween = create_tween()
	tween.tween_property($MagicCircle, "self_modulate:a", 0, 0.1)
	tween.tween_callback(
		func():
			await get_tree().create_timer(2).timeout
			self.queue_free()
	)

func _process(_delta : float) -> void:
	pass

func _on_beam_spell_done():
	spell_fade()
