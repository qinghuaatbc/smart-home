extends StaticBody3D

var is_open = false
var door_mesh: Node3D
var pivot_node: Node3D

func _ready():
	door_mesh = $MeshInstance3D
	if not door_mesh:
		for child in get_children():
			if child is MeshInstance3D:
				door_mesh = child
				break

func interact():
	is_open = !is_open
	print(name, " -> ", "OPEN" if is_open else "CLOSED")

func _process(delta):
	if door_mesh:
		var target = PI / 2 if is_open else 0.0
		door_mesh.rotation.y = lerp(door_mesh.rotation.y, target, 5 * delta)