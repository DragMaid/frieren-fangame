extends CharacterBody2D

signal player_damaged(damage)

@onready var animation = get_node("AnimationPlayer")
@export var shield_scene : PackedScene
@export var zoltraak_scene : PackedScene

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

const SPEED : float = 300.0
const JUMP_VELOCITY : float = -400.0
const JUMP_HEIGHT : float = 120.0
const DOWN_TIME : float = 1.0

var is_casting : bool = false
var is_on_cooldown : bool = false 
var is_charged : bool = false
var is_knock_back : bool = false
var is_hit : bool = false
var is_floating : bool = false
var is_gravity_on : bool = true

var direction_x : float = 0.0
var direction_y : float = 0.0
var old_height : float = 0.0
var x_hit_direction : float = 1.0
var y_hit_direction : float = -1.0
var knock_back_height : float = 0.0

var zoltraak : Node
@onready var down_timer : Timer = $down_timer

var mode : String = "zoltraak"
var icon_path : String = "res://sprite/icons/"
var state : String = "idle"

################################################################
###################    INITIALIZATION    #######################
################################################################

func _ready() -> void:
	animation.play("idle")
	down_count_down_setup()

func _physics_process(delta) -> void:
	gravity_process(delta)
	state_controller(delta)
	animation_controller()
	move_and_slide()

################################################################
##################  USER INPUT CONTROLLER  #####################
################################################################

func _unhandled_input(event) -> void:
	if event is InputEventKey and event.pressed:
		keyboard_input(event)
							
	elif event is InputEventMouseButton:
		mouse_input(event)

func keyboard_input(event : InputEventKey) -> void:

	if not (is_hit):
		if event.keycode == KEY_SPACE:
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
				animation.play("jump")
			else:
				is_floating = true
				velocity.y = 0
				gravity_toggle(false)


	match event.keycode:
		KEY_Q:
			change_spell("zoltraak")
		KEY_W:
			change_spell("shield")	

func mouse_input(_event : InputEventMouseButton) -> void:
	if Input.is_action_just_pressed("left_mouse_click"):
		match mode:
			"zoltraak": zoltraak_fire()
			"shield": shield_cast()

################################################################
################ BASIC STATE CONTROL MACHINE ###################
################################################################

func change_state(type : String) -> void:
	state = type

func get_state() -> String:
	return state

func gravity_toggle(opt : bool) -> void:
	is_gravity_on = opt

func state_controller(delta : float) -> void:
	if is_hit:
		is_hit_process(delta)
	else:
		movement_process()

func animation_controller() -> void:
	animation.play(state)
	if (direction_x == -1): 
		get_node("AnimatedSprite2D").flip_h = true
	elif (direction_x == 1):
		get_node("AnimatedSprite2D").flip_h = false		
		
################################################################
#################### MOVEMENT CONTROLLER  ######################
################################################################

func gravity_process(delta : float) -> void:
	if (is_gravity_on):
		if not is_on_floor():
			velocity.y += gravity * delta

func movement_process() -> void:
	direction_x = Input.get_axis("ui_left", "ui_right")
	direction_y = Input.get_axis("ui_up", "ui_down")

	if is_on_floor():
		is_floating = false
		gravity_toggle(true)

	if (is_floating):
		change_state("float")
		gravity_toggle(false)
		x_movement("float", "float")
		y_movement("float", "float")
	else:
		x_movement("run", "idle")
		if (velocity.y > 0):
			change_state("fall")


func x_movement(m_anim : String, s_anim : String) -> void:
	if direction_x:
		velocity.x = direction_x * SPEED
		change_state(m_anim)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		change_state(s_anim)

func y_movement(m_anim : String, s_anim : String) -> void:
	if direction_y:
		velocity.y = direction_y * SPEED
		change_state(m_anim)
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
		change_state(s_anim)

	
func is_hit_process(delta : float) -> void:
	if (is_knock_back):
		if (knock_back_height >= JUMP_HEIGHT):
			y_hit_direction = 0.0
			velocity.y += gravity * delta
		position.x += SPEED * delta * x_hit_direction
		position.y += SPEED * delta * y_hit_direction
		knock_back_height += SPEED * delta
		animation.seek(1, true)
		
	if is_on_floor() and knock_back_height >= JUMP_HEIGHT:
		is_knock_back = false
		knock_back_height = 0.0
		y_hit_direction = -1.0
		animation.seek(2, true)
		down_timer.start()

################################################################
####################        ADDONS        ######################
################################################################

func down_count_down_setup() -> void:
	down_timer.wait_time = DOWN_TIME
	down_timer.one_shot = true
	down_timer.connect("timeout", func(): is_hit = false)

func get_damaged(damage : int, _way : int) -> void:
	if not is_hit: is_hit = true
	down_timer.stop()
	is_floating = false
	is_knock_back = true
	x_hit_direction = _way
	change_state("knock_back")
	reset_speed()
	animation.seek(0, true)
	player_damaged.emit(damage)

func _on_area_2d_body_entered(_body) -> void:
	if (is_knock_back):
		is_knock_back = false
		knock_back_height = JUMP_HEIGHT

func reset_speed() -> void:
	velocity.x = 0
	velocity.y = 0

################################################################
#####################     SPELL CASTS    #######################
################################################################

func change_spell(spell: String) -> void:
	mode = spell
	var texture_path : String = icon_path + spell + "-icon.png"
	$spell_panel.get_node("spell_ui").texture = load(texture_path)

func shield_cast() -> void:
	var des = get_global_mouse_position()
	var angle = atan ((des.y - self.position.y) / (des.x - self.position.x)) 
	var shield = shield_scene.instantiate()
	shield.rotation = angle
	shield.position = des
	get_parent().add_child(shield)
	
func zoltraak_fire() -> void:
	if not (is_casting) and not (is_on_cooldown):
		var des = get_global_mouse_position()
		zoltraak = zoltraak_scene.instantiate()
		zoltraak.position = des
		get_parent().add_child(zoltraak)
		
		is_casting = true
		is_on_cooldown = true
		
		var charge_timer = get_tree().create_timer(0.3)
		charge_timer.connect("timeout", func(): is_charged = true)
		
		var	spell_timer = get_tree().create_timer(0.6)
		spell_timer.connect("timeout", func(): is_on_cooldown = false)
		
	else:
		if (zoltraak != null):
			is_casting = false
			is_charged = false
			zoltraak.shoot_beam()
				
