class_name GLTFDocumentExtensionOMIPhysicsBody
extends GLTFDocumentExtension


@export var collision_filter_type: PhysicsFilter.FilterType = PhysicsFilter.FilterType.AUTOMATIC


func _import_preflight(gltf_state: GLTFState, extensions: PackedStringArray) -> Error:
	if not "OMI_physics_body" in extensions:
		return ERR_SKIP
	if not gltf_state.json.has("extensions"):
		return ERR_SKIP
	var ext: Dictionary = gltf_state.json["extensions"]
	if not ext.has("OMI_physics_body"):
		return ERR_SKIP
	var omi_physics_body_doc_ext: Dictionary = ext["OMI_physics_body"]
	if not omi_physics_body_doc_ext.has("collisionFilters"):
		return ERR_SKIP
	var collision_filters_json: Array = omi_physics_body_doc_ext["collisionFilters"]
	var physics_filters: Array[PhysicsFilter] = []
	for collision_filter in collision_filters_json:
		var filter := PhysicsFilter.from_dictionary(collision_filter)
		physics_filters.append(filter)
	gltf_state.set_additional_data("GLTFPhysicsCollisionFilters", physics_filters)
	return OK


func _get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["OMI_physics_body"])


func _parse_node_extensions(gltf_state: GLTFState, gltf_node: GLTFNode, extensions: Dictionary) -> Error:
	if not extensions.has("OMI_physics_body"):
		return OK
	var omi_physics_body: Dictionary = extensions["OMI_physics_body"]
	var shape_data: Dictionary
	if omi_physics_body.has("collider"):
		shape_data = omi_physics_body["collider"]
	elif omi_physics_body.has("trigger"):
		shape_data = omi_physics_body["trigger"]
	else:
		return OK
	if not shape_data.has("collisionFilter"):
		return OK
	var collision_filter_index: int = shape_data["collisionFilter"]
	var physics_filters = gltf_state.get_additional_data("GLTFPhysicsCollisionFilters")
	if physics_filters == null:
		return ERR_FILE_CORRUPT
	if not (collision_filter_index is int) or collision_filter_index < 0 or collision_filter_index >= physics_filters.size():
		return ERR_FILE_CORRUPT
	gltf_node.set_additional_data("GLTFPhysicsCollisionFilter", physics_filters[collision_filter_index])
	return OK


func _get_collision_object(node: Node) -> CollisionObject3D:
	if node is CollisionObject3D:
		return node
	if node == null:
		return null
	return _get_collision_object(node.get_parent())


func _import_node(gltf_state: GLTFState, gltf_node: GLTFNode, json: Dictionary, scene_node: Node) -> Error:
	var physics_filter = gltf_node.get_additional_data("GLTFPhysicsCollisionFilter")
	if physics_filter == null:
		return OK
	var collision_object: CollisionObject3D = _get_collision_object(scene_node)
	if collision_object == null:
		return OK
	physics_filter.apply_to_collision_object(collision_object)
	return OK


func _convert_scene_node(gltf_state: GLTFState, gltf_node: GLTFNode, scene_node: Node) -> void:
	if not scene_node is CollisionShape3D:
		return
	var collision_object: CollisionObject3D = _get_collision_object(scene_node)
	if collision_object == null:
		return
	var physics_filter := PhysicsFilter.from_collision_object(collision_object)
	physics_filter.calculate_systems_from_layer_mask(collision_filter_type)
	gltf_node.set_additional_data("GLTFPhysicsCollisionFilter", physics_filter)


func _get_or_create_state_filters_in_state(gltf_state: GLTFState) -> Array:
	var state_json: Dictionary = gltf_state.json
	var state_extensions: Dictionary = state_json.get_or_add("extensions", {})
	var omi_physics_body_ext: Dictionary = state_extensions.get_or_add("OMI_physics_body", {})
	var collision_filters: Array = omi_physics_body_ext.get_or_add("collisionFilters", [])
	return collision_filters


func _insert_filter_in_state(gltf_state: GLTFState, physics_filter: PhysicsFilter) -> int:
	var filter_dict: Dictionary = physics_filter.to_dictionary()
	if filter_dict.is_empty():
		return -1
	var filters_json: Array = _get_or_create_state_filters_in_state(gltf_state)
	for i in range(filters_json.size()):
		if filters_json[i] == filter_dict:
			# De-duplication: If we already have an identical filter,
			# set the filter index to the existing one and return.
			return i
	var filter_index: int = filters_json.size()
	filters_json.append(filter_dict)
	return filter_index


func _export_node(gltf_state: GLTFState, gltf_node: GLTFNode, node_json: Dictionary, scene_node: Node) -> Error:
	var physics_filter = gltf_node.get_additional_data("GLTFPhysicsCollisionFilter")
	if physics_filter == null:
		return OK
	if not node_json.has("extensions"):
		return OK
	var node_extensions: Dictionary = node_json["extensions"]
	if not node_extensions.has("OMI_physics_body"):
		return OK
	var omi_physics_body_node_ext: Dictionary = node_extensions["OMI_physics_body"]
	var shape_data: Dictionary
	if omi_physics_body_node_ext.has("collider"):
		shape_data = omi_physics_body_node_ext["collider"]
	elif omi_physics_body_node_ext.has("trigger"):
		shape_data = omi_physics_body_node_ext["trigger"]
	else:
		return OK
	var filter_index: int = _insert_filter_in_state(gltf_state, physics_filter)
	if filter_index == -1:
		return OK
	shape_data["collisionFilter"] = filter_index
	return OK
