class_name GLTFDocumentExtensionKHRNodeVisibility
extends GLTFDocumentExtension


# DOES NOT WORK due to GLTFDocument::_check_visibility.
enum VisibilityMode {
	INCLUDE_REQUIRED,
	INCLUDE_OPTIONAL,
}

# DOES NOT WORK due to GLTFDocument::_check_visibility.
@export var visibility_mode: VisibilityMode = VisibilityMode.INCLUDE_REQUIRED


# DOES NOT WORK FOR MESHES due to Godot's ImporterMeshInstance3D class.
func _import_preflight(state: GLTFState, extensions: PackedStringArray) -> Error:
	if "KHR_node_visibility" in extensions:
		return OK
	return ERR_SKIP

func _get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["KHR_node_visibility"])

# DOES NOT WORK FOR MESHES due to Godot's ImporterMeshInstance3D class.
func _parse_node_extensions(state: GLTFState, gltf_node: GLTFNode, extensions: Dictionary) -> Error:
	if not extensions.has("KHR_node_visibility"):
		return OK
	var khr_node_visibility: Dictionary = extensions["KHR_node_visibility"]
	if khr_node_visibility.has("visible"):
		gltf_node.set_additional_data(&"GLTFKHRNodeVisibilityVisible", khr_node_visibility["visible"])
	return OK


# DOES NOT WORK FOR MESHES due to Godot's ImporterMeshInstance3D class.
func _import_node(gltf_state: GLTFState, gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	var visible = gltf_node.get_additional_data(&"GLTFKHRNodeVisibilityVisible")
	if visible != null and "visible" in node:
		node.visible = visible
	return OK


# DOES NOT WORK due to GLTFDocument::_check_visibility.
func _convert_scene_node(state: GLTFState, gltf_node: GLTFNode, scene_node: Node) -> void:
	if "visible" in scene_node:
		var visible: bool = scene_node.visible
		if not visible:
			gltf_node.set_additional_data(&"GLTFKHRNodeVisibilityVisible", visible)


# DOES NOT WORK due to GLTFDocument::_check_visibility.
func _export_node(state: GLTFState, gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	var visible = gltf_node.get_additional_data(&"GLTFKHRNodeVisibilityVisible")
	if visible != null:
		var ext: Dictionary = json.get_or_add("extensions", {})
		var khr_node_visibility: Dictionary = ext.get_or_add("KHR_node_visibility", {})
		khr_node_visibility["visible"] = visible
		var is_required: bool = visibility_mode == VisibilityMode.INCLUDE_REQUIRED
		state.add_used_extension("KHR_node_visibility", is_required)
	return OK
