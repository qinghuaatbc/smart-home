extends StaticBody3D

var is_on = false
var device_name = "Smart Device"
var action_type = "toggle"

func interact():
	if action_type == "toggle":
		is_on = !is_on
		_on_state_changed()
	
	print(device_name, " -> ", "ON" if is_on else "OFF")

func _on_state_changed():
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh and mesh.get_surface_override_material(0):
		var mat = mesh.get_surface_override_material(0)
		if is_on:
			mat.emission_enabled = true
			mat.emission = Color(1, 0.9, 0.5)
			mat.emission_energy_multiplier = 1.0
		else:
			mat.emission_enabled = false