class_name PhysicsFilter
extends Resource


enum FilterType {
	AUTOMATIC,
	DO_NOT_EXPORT,
	ALWAYS_EXPORT,
	COLLIDE_WITH_SYSTEMS,
	NOT_COLLIDE_WITH_SYSTEMS,
}

## Key: Layer index (0 for Layer 1, 1 for Layer 2, etc).
## Value: Friendly name from ProjectSettings, plus free spots may also be assigned new values
## ad-hoc when importing files to ensure consistency when importing multiple files.
static var _godot_layer_name_cache := PackedStringArray()
## Key: glTF physics collision filter system name.
## Value: Bitwise number of the layer (1, 2, 4, 8, 16, 32, etc).
static var _system_to_layer_map := Dictionary()

var collision_systems := PackedStringArray()
var collide_with_systems := PackedStringArray()
var not_collide_with_systems := PackedStringArray()
var collision_layer: int = 1
var collision_mask: int = 1


func _init() -> void:
	_godot_layer_name_cache.resize(32)
	for index in range(32):
		var layer_setting_name: String = "layer_names/3d_physics/layer_" + str(index + 1)
		var layer_name := ProjectSettings.get_setting(layer_setting_name, "")
		_godot_layer_name_cache[index] = layer_name
		if not layer_name.is_empty():
			_system_to_layer_map[layer_name] = 1 << index


func _assign_system_to_layer_map(system: String) -> void:
	# Check if we've already assigned something.
	if _system_to_layer_map.has(system):
		return
	# Check if this layer prefers to be on some number.
	var number: int = system.to_int()
	if 0 < number && number < 33:
		var index: int = number - 1
		_system_to_layer_map[system] = 1 << index
		return
	# Try to pick out a layer with no assigned name, from index 30 down (31).
	# Don't include the endpoints: layer index 0 (1) or layer index 31 (32).
	for index in range(30, 0, -1):
		if _godot_layer_name_cache[index].is_empty():
			push_warning("glTF: Collision filter '" + system + "' is specified in the glTF file but not in Godot's project settings. Assigning ad-hoc to layer index " + str(index) + " (Layer " + str(index + 1) + "). Consider adding '" + system + "' in Project Settings -> Layer Names -> 3D Physics to control how this is imported, then reimport the file.")
			_godot_layer_name_cache[index] = system
			_system_to_layer_map[system] = 1 << index
			return
	printerr("glTF: Collision filter '" + system + "' is specified in the glTF file but not in Godot's project settings. No available physics layers were found, so this cannot be imported. Consider adding '" + system + "' in Project Settings -> Layer Names -> 3D Physics to control how this is imported.")


func calculate_layer_mask_from_systems() -> void:
	var all_systems: PackedStringArray = collision_systems + collide_with_systems + not_collide_with_systems
	for system in all_systems:
		_assign_system_to_layer_map(system)
	# Assign the layer bitwise number based on the systems.
	collision_layer = 0
	for system in collision_systems:
		if _system_to_layer_map.has(system):
			collision_layer |= _system_to_layer_map[system]
	if collision_layer == 0:
		# Default to the first layer (like Godot's default layer).
		collision_layer = 1
	# Assign the mask bitwise number based on the systems.
	collision_mask = 0
	if collide_with_systems.is_empty():
		collision_mask = 0xFFFFFFFF
		if not_collide_with_systems.is_empty():
			# If both collideWithSystems and notCollideWithSystems are empty, the default is to collide with all systems.
			pass
		else:
			# Use notCollideWithSystems since it's the only one with content.
			for system in not_collide_with_systems:
				if _system_to_layer_map.has(system):
					collision_mask &= ~_system_to_layer_map[system]
	elif not_collide_with_systems.is_empty():
		# Use collideWithSystems since it's the only one with content.
		for system in collide_with_systems:
			if _system_to_layer_map.has(system):
				collision_mask |= _system_to_layer_map[system]
	else:
		# If both collideWithSystems and notCollideWithSystems have content, the collision filter is invalid.
		printerr("glTF: Collision filter has both collideWithSystems and notCollideWithSystems. This is invalid. A mask with only the default layer will be used as fallback.")
		collision_mask = 1


func calculate_systems_from_layer_mask(filter_type: FilterType) -> void:
	if filter_type == FilterType.DO_NOT_EXPORT:
		return
	# Nothing to export if zero. There is no way to represent not being on any layer.
	if collision_layer != 0:
		if collision_layer == 1 and _godot_layer_name_cache[0].is_empty() and filter_type == FilterType.AUTOMATIC:
			# If only the default layer is used and it's unnamed, don't export.
			# We want to avoid bloating glTF files with unnecessary data out of the box.
			# If the user hasn't touched the layers, we don't want to export them.
			pass
		else:
			# Assign the systems based on the layer bitwise number.
			collision_systems.clear()
			for index in range(32):
				if collision_layer & (1 << index):
					if _godot_layer_name_cache[index].is_empty():
						collision_systems.append("Layer " + str(index + 1))
					else:
						collision_systems.append(_godot_layer_name_cache[index])
	if collision_mask == 0:
		# Nothing to export if zero. There is no way to represent collision with nothing.
		return
	if collision_mask == 0xFFFFFFFF and filter_type != FilterType.COLLIDE_WITH_SYSTEMS:
		# If all layers are included, we don't need to list them all except if the
		# user explicitly wanted that. The default is to collide with all systems.
		return
	if collision_mask == 1 and _godot_layer_name_cache[0].is_empty() and filter_type == FilterType.AUTOMATIC:
		# If only the default layer is used and it's unnamed, don't export.
		# We want to avoid bloating glTF files with unnecessary data out of the box.
		# If the user hasn't touched the layers, we don't want to export them.
		return
	# Assign the systems based on the mask bitwise number.
	collide_with_systems.clear()
	not_collide_with_systems.clear()
	if filter_type != FilterType.NOT_COLLIDE_WITH_SYSTEMS:
		for index in range(32):
			if collision_mask & (1 << index):
				if _godot_layer_name_cache[index].is_empty():
					collide_with_systems.append("Layer " + str(index + 1))
				else:
					collide_with_systems.append(_godot_layer_name_cache[index])
	if filter_type != FilterType.COLLIDE_WITH_SYSTEMS:
		for index in range(32):
			if not collision_mask & (1 << index):
				if _godot_layer_name_cache[index].is_empty():
					not_collide_with_systems.append("Layer " + str(index + 1))
				else:
					not_collide_with_systems.append(_godot_layer_name_cache[index])
	if filter_type == FilterType.AUTOMATIC or filter_type == FilterType.ALWAYS_EXPORT:
		# Determine which filter type to use based on the number of systems.
		if collide_with_systems.size() > not_collide_with_systems.size():
			collide_with_systems.clear()
		else:
			not_collide_with_systems.clear()


func apply_to_collision_object(collision_object: CollisionObject3D) -> void:
	collision_object.collision_layer = collision_layer
	collision_object.collision_mask = collision_mask


func to_dictionary() -> Dictionary:
	var dict: Dictionary = {}
	if not collision_systems.is_empty():
		dict["collisionSystems"] = collision_systems
	if not collide_with_systems.is_empty():
		dict["collideWithSystems"] = collide_with_systems
	if not not_collide_with_systems.is_empty():
		dict["notCollideWithSystems"] = not_collide_with_systems
	return dict


static func from_collision_object(collision_object: CollisionObject3D) -> PhysicsFilter:
	var ret := PhysicsFilter.new()
	ret.collision_layer = collision_object.collision_layer
	ret.collision_mask = collision_object.collision_mask
	return ret


static func from_dictionary(dict: Dictionary) -> PhysicsFilter:
	var ret := PhysicsFilter.new()
	if dict.has("collisionSystems"):
		ret.collision_systems = dict["collisionSystems"]
	if dict.has("collideWithSystems"):
		ret.collide_with_systems = dict["collideWithSystems"]
	if dict.has("notCollideWithSystems"):
		ret.not_collide_with_systems = dict["notCollideWithSystems"]
	ret.calculate_layer_mask_from_systems()
	return ret
