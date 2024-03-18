extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$shield_sound.play()
	$Timer.start(0.5)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func _on_timer_timeout():
	queue_free()
