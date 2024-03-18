extends Node2D

@export var shield_scene : PackedScene
@export var zoltraak_scene : PackedScene
func _ready():
	pass # Replace with function body.

var is_casting : bool = false


func _on_frieren_player_damaged(damge : int):
	$game_hud.get_node("ProgressBar").value -= damge
