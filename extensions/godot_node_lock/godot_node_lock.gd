@tool
class_name GLTFDocumentExtensionGODOTNodeLock
extends GLTFDocumentExtension

func _import_preflight(_state: GLTFState, extensions: PackedStringArray) -> Error:
	if extensions.has("GODOT_node_lock"):
		return OK
	return ERR_SKIP

func _get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["GODOT_node_lock"])

func _import_node(_state: GLTFState, _gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	if not json.has("extensions"):
		return OK
	var extensions = json.get("extensions")
	if not extensions is Dictionary:
		printerr("Error: GLTF file is invalid, extensions should be a Dictionary.")
		return ERR_FILE_CORRUPT
	if not extensions.has("GODOT_node_lock"):
		return OK
	var lock_data = extensions.get("GODOT_node_lock")
	if not lock_data is Dictionary:
		printerr("Error: GODOT_node_lock extension should be a Dictionary.")
		return ERR_FILE_CORRUPT
	
	# Check if the node should be locked
	if lock_data.has("locked") and lock_data.get("locked"):
		node.set_meta("_edit_lock_", true)
	
	return OK
