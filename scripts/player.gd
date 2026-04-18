extends CharacterBody3D

const SPEED = 1.0
const JUMP_VELOCITY = 4.5
const GRAVITY = 9.8

var anim_player: AnimationPlayer
var model: Node3D

var anim_names = []
var idle_anim = ""
var walk_anim = ""

var door_check_timer = 0.0
var door_states = {}
var door_targets = {}
var door_colliders = {}

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	
	model = $CharacterModel
	_find_animations()

func _find_animations():
	await get_tree().process_frame
	await get_tree().process_frame
	anim_player = _find_anim_player(self)
	if anim_player:
		anim_names = anim_player.get_animation_list()
		print("Animations: ", anim_names)
		for anim in anim_names:
			if "idle" in anim.to_lower():
				idle_anim = anim
			if "walk" in anim.to_lower() or "run" in anim.to_lower():
				walk_anim = anim

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node == null:
		return null
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_anim_player(child)
		if result:
			return result
	return null

func _physics_process(delta):
	door_check_timer += delta
	if door_check_timer > 1.0:
		door_check_timer = 0.0
		_check_door_proximity()
	
	if not anim_player:
		return
	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0
	
	if Input.is_key_pressed(KEY_Q):
		rotation.y += 3.0 * delta
	if Input.is_key_pressed(KEY_E):
		rotation.y -= 3.0 * delta
	
	var move_dir = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_dir.x += 1
	
	if Input.is_key_pressed(KEY_R):
		global_position = Vector3.ZERO
		rotation.y = 0
	
	move_and_slide()
	
	if move_dir.length() > 0:
		var direction = Vector3(move_dir.x, 0, move_dir.y).normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		if model:
			model.rotation.y = lerp_angle(model.rotation.y, atan2(direction.x, direction.z), 10 * delta)
		
		if walk_anim:
			anim_player.play(walk_anim)
		else:
			anim_player.play(anim_names[0] if anim_names.size() > 0 else "walking")
	else:
		velocity.x = 0
		velocity.z = 0
		if idle_anim:
			anim_player.play(idle_anim)
		else:
			anim_player.play(anim_names[0] if anim_names.size() > 0 else "idle")
	
	move_and_slide()
	_update_door_animations()

func _check_door_proximity():
	var all_nodes = get_tree().get_root().get_children()
	for node in all_nodes:
		_find_objects_recursive(node)

func _find_objects_recursive(node: Node):
	var name_lower = node.name.to_lower()
	
	if "_door" in name_lower or "door" in name_lower:
		var dist = global_position.distance_to(node.global_position)
		if dist < 2.5:
			_toggle_door(node, true)
		else:
			_toggle_door(node, false)
	elif "wall" in name_lower or "_wall" in name_lower:
		_check_wall_collision(node)
	
	for child in node.get_children():
		_find_objects_recursive(child)

var wall_collision_added = {}

func _check_wall_collision(wall_node: Node):
	if wall_collision_added.has(wall_node.get_instance_id()):
		return
	
	for child in wall_node.get_children():
		if child is MeshInstance3D:
			var collision = StaticBody3D.new()
			collision.name = "WallCollider"
			wall_node.add_child(collision)
			
			var shape = CollisionShape3D.new()
			var mesh = child.mesh
			if mesh:
				shape.shape = mesh.create_trimesh_shape()
			else:
				shape.shape = BoxShape3D.new()
				shape.shape.size = Vector3(0.1, 3, 2)
			collision.add_child(shape)
			
			wall_collision_added[wall_node.get_instance_id()] = true

func _toggle_door(door_node: Node, open: bool):
	if not door_states.has(door_node.get_instance_id()):
		door_states[door_node.get_instance_id()] = false
	
	var was_open = door_states[door_node.get_instance_id()]
	if was_open != open:
		door_states[door_node.get_instance_id()] = open
		var target = PI / 2 if open else 0.0
		door_targets[door_node.get_instance_id()] = target
		
		door_colliders[door_node.get_instance_id()] = not open
		
		_update_door_collision(door_node, not open)
		
		print(door_node.name, " -> ", "OPEN" if open else "CLOSED")

func _update_door_collision(door_node: Node, enabled: bool):
	pass

func _update_door_animations():
	for id in door_targets:
		var door = instance_from_id(id)
		if door:
			var target = door_targets[id]
			var meshes = _get_door_meshes(door)
			for mesh in meshes:
				var diff = target - mesh.rotation.y
				if abs(diff) > 0.01:
					mesh.rotation.y += diff * 0.02

func _get_door_meshes(node: Node) -> Array:
	var meshes = []
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		meshes.append_array(_get_door_meshes(child))
	return meshes

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		if model:
			model.visible = not model.visible
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var space_state = get_world_3d().direct_space_state
		var from = get_parent().get_node("Camera3D").global_position
		var to = from + get_parent().get_node("Camera3D").project_ray_normal(get_viewport().get_mouse_position()) * 10
		
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result:
			var collider = result.collider
			if collider.has_method("interact"):
				collider.interact()