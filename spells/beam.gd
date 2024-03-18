extends Node2D

signal spell_done
var cast_time = 0.3
# Speed at which the laser extends when first fired, in pixels per seconds.
var cast_speed = 7000.0
# Maximum length of the laser in pixels.
var max_length = 5000.0
# Base duration of the tween animation in seconds.
var disappear_time = 0.3
# Check wether spell has done damage
var damage_dealt = false

var collide = false;

@onready var fill := $FillLine2D
@onready var casting_particles := $CastingParticles2D
@onready var collision_particles := $CollisionParticles2D
@onready var beam_particles := $BeamParticles2D
@onready var line_width: float = fill.width
@onready var casts := [$RayCast2D, $RayCast2D2, $RayCast2D3]


func _ready() -> void:
	set_physics_process(false)
	fill.points[1] = Vector2.ZERO
		
func fire_beam(direction: Vector2) -> void:
	look_at(direction)
	$shoot_sound.play()
	await get_tree().create_timer(cast_time).timeout
	enable_raycast()
	set_physics_process(true)
	toggle_particles(true)

func enable_raycast() -> void:
	for index in casts.size():
		var cast = casts[index]
		cast.target_position = Vector2(max_length, 0.0)

func toggle_particles(state: bool) -> void:
	beam_particles.emitting = state
	casting_particles.emitting = state
	collision_particles.emitting = state
	
func _physics_process(_delta: float) -> void:
	for index in casts.size():
		var cast = casts[index]
		cast.force_raycast_update() 
		if (cast.is_colliding()):
			if not (collide):
				$impact_sound.play()
				collide = true
			var collider = cast.get_collider()
			if collider.has_method("get_damaged"):
				if not (damage_dealt):
					damage_dealt = true
					var direction = 1
					if (cast.global_transform.origin.x - cast.get_collision_point().x > 0):
						direction = -1
					collider.get_damaged(10, direction)
			var distance = cast.global_transform.origin.distance_to(cast.get_collision_point())
			fill.points[1] = Vector2(distance, 0.0)
			collision_particles.position = fill.points[1]
			collision_particles.process_material.direction = Vector3(
				 fill.points[1].x*-1,  fill.points[1].y*-1, 0
			)
			collision_particles.emitting = true
			disappear()
			break
		if not collide:
			fill.points[1] = Vector2(max_length, 0.0)
			disappear()

func free_memory() -> void:
	for index in casts.size():
		casts[index].enabled = false

func disappear() -> void:
	var tween = create_tween()
	tween.tween_property(fill, "width", 0, disappear_time)
	tween.tween_callback(
		func():
			set_physics_process(false)
			toggle_particles(false)
			free_memory()
			spell_done.emit()
	)
