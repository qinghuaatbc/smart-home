extends Camera3D

var player: CharacterBody3D
var current_view = "third_person"

var views = {
	"first_person": Vector3(0, 1.75, 0.8),
	"third_person": Vector3(0, 2, 5),
	"top_down": Vector3(0, 15, 0)
}

var follow_speed = 5.0

func _ready():
	player = get_parent().get_node("Player")

func _physics_process(_delta):
	if not player:
		return
	
	if Input.is_key_pressed(KEY_SPACE):
		_switch_view()
		await get_tree().create_timer(0.5).timeout
	
	if current_view == "first_person":
		rotation.y = player.rotation.y
	
	var target_pos = player.global_position + views[current_view]
	global_position = global_position.lerp(target_pos, follow_speed * _delta)
	
	if current_view == "first_person":
		rotation.x = -0.3
		rotation.y = player.rotation.y
	elif current_view == "top_down":
		look_at(player.global_position, Vector3.UP)
	else:
		look_at(player.global_position)

func _switch_view():
	var view_keys = views.keys()
	var current_index = view_keys.find(current_view)
	var next_index = (current_index + 1) % view_keys.size()
	current_view = view_keys[next_index]