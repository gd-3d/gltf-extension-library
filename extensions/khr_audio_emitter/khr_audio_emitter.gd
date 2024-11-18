@tool
class_name GLTFDocumentExtensionKHRAudioEmitter
extends GLTFDocumentExtension

## TODO, use 

func _import_preflight(_state: GLTFState, extensions: PackedStringArray) -> Error:
	if extensions.has("KHR_audio_emitter"):
		return OK
	return ERR_SKIP

func _get_supported_extensions() -> PackedStringArray:
	return PackedStringArray(["KHR_audio_emitter"])

func _import_node(_state: GLTFState, _gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	if not json.has("extensions"):
		return OK
	var extensions = json.get("extensions")
	if not extensions.has("KHR_audio_emitter"):
		return OK
	
	var audio_data = extensions.get("KHR_audio_emitter")
	if not audio_data is Dictionary:
		printerr("Error: KHR_audio_emitter extension should be a Dictionary.")
		return ERR_FILE_CORRUPT
	
	# Create AudioStreamPlayer3D node
	var audio_player = AudioStreamPlayer3D.new()
	
	# Set properties from the emitter data
	if audio_data.has("gain"):
		audio_player.volume_db = linear_to_db(audio_data.get("gain"))
	
	if audio_data.has("maxDistance"):
		audio_player.max_distance = audio_data.get("maxDistance")
	
	if audio_data.has("refDistance"):
		audio_player.unit_size = audio_data.get("refDistance")
	
	if audio_data.has("rolloffFactor"):
		audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	
	# Handle cone/directional audio properties
	if audio_data.has("coneInnerAngle"):
		audio_player.emission_angle_enabled = true
		#audio_player.emission_angle = deg_to_rad(audio_data.get("coneInnerAngle"))
	
	if audio_data.has("coneOuterGain"):
		audio_player.emission_angle_filter_attenuation_db = linear_to_db(audio_data.get("coneOuterGain"))
	
	# Set the name and replace the node
	audio_player.name = _gltf_node.get_name()
	node.replace_by(audio_player)
	
	return OK
