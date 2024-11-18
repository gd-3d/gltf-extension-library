@tool
extends EditorPlugin
var library = []

## TODO RE-ADD gizmo (from seat?)

## if this list gets very long, we can one day procedurally import these classes.
func _init():
	print("Initializing GLTF Extension Library")
	var load_order = [
						GLTFDocumentExtensionOMIPhysicsBody.new(),
						GLTFDocumentExtensionKHR_XMP.new(),
						GLTFDocumentExtensionGODOTNodeLock.new(),
						GLTFDocumentExtensionKHRNodeVisibility.new(),
						GLTFDocumentExtensionOMIPhysicsJoint.new(),
						GLTFDocumentExtensionKHRAudioEmitter.new(),
				
						GLTFDocumentExtensionOMISpawnPoint.new(),
						GLTFDocumentExtensionOMIVehicle.new(),
						GLTFDocumentExtensionOMISeat.new(),
					]
	print("Extensions loaded")
	library = load_order

	
func _enter_tree() -> void:
	print("\n=== Entering GLTF Extension Library tree ===")
	for extension in library:
		var ext_class = extension.get_class()
		var ext_name = extension.get_name()
		print("Registering extension: ", ext_class)
		print("Extension name: ", ext_name)
		print("Supported extensions: ", extension._get_supported_extensions())
		
		# Register with verification
		GLTFDocument.register_gltf_document_extension(extension, true)
		
	print("=== All extensions registered ===\n")

func _exit_tree():
	print("\n=== Exiting GLTF Extension Library tree ===")
	for extension in library:
		print("Unregistering extension: ", extension.get_class())
		GLTFDocument.unregister_gltf_document_extension(extension)
	print("=== All extensions unregistered ===\n")
