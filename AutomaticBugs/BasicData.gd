extends Node

### Contains info about disabled classes and allows to take info about allowed methods

# Globablly disabled functions for all classes
var function_exceptions: Array = [
	# They exists without assigment like Class.method, because they may be a parent of other objects and children also should have disabled child.method, its children also etc. which is too much to do
	"get_packet",  # TODO
	"_gui_input",  # TODO probably missing cherrypick #GH 47636
	"_input",
	"_unhandled_input",
	"_unhandled_key_input",
	"connect_to_signal",  # Should be chrrypicked
	"_editor_settings_changed",  # GH 45979
	"_submenu_timeout",  # GH 45981
	"_thread_done",  #GH 46000
	"generate",  #GH 46001
	"_proximity_group_broadcast",  #GH 46002
	"_direct_state_changed",  #GH 46003
	"create_from",  #GH 46004
	"create_from_blend_shape",  #GH 46004
	"append_from",  #GH 46004
	"_set_tile_data",  #GH 46015
	"get",  #GH 46019
	"instance_has",  #GH 46020
	"get_var",  #GH 46096
	"set_script",  #GH 46120
	"getvar",  #GH 46019
	"get_available_chars",  #GH 46118
	"open_midi_inputs",  #GH 46183
	"set_icon",  #GH 46189
	"get_latin_keyboard_variant",  #GH  TODO Memory Leak
	"set_editor_hint",  #GH 46252
	"get_item_at_position",  #TODO hard to find
	"set_probe_data",  #GH 46570
	"_range_click_timeout",  #GH 46648
	"get_indexed",  #GH 46019
	"add_vertex",  #GH 47066
	"create_client",  # TODO, strange memory leak
	"create_shape_owner",  #47135
	"shape_owner_get_owner",  #47135
	"get_bind_bone",  #GH 47358
	"get_bind_name",  #GH 47358
	"get_bind_pose",  #GH 47358
	# Not worth using
	"propagate_notification",
	"notification",
	# TODO Adds big spam when i>100 - look for possiblity to
	"add_sphere",
	"_update_inputs",  # Cause big spam with add_input
	# Spam when i~1000 - change to specific
	"update_bitmask_region",
	"set_enabled_inputs",
	# Slow Function
	"_update_sky",
	# Undo/Redo function which doesn't provide enough information about types of objects, probably due vararg(variable size argument)
	"add_do_method",
	"add_undo_method",
	# Do not save files and create files and folders
	"pck_start",
	"save",
	"save_png",
	"save_to_wav",
	"save_to_file",
	"make_dir",
	"make_dir_recursive",
	"save_encrypted",
	"save_encrypted_pass",
	"save_exr",
	"dump_resources_to_file",
	"dump_memory_to_file",
	# This also allow to save files
	"open",
	"open_encrypted",
	"open_encrypted_with_pass",
	"open_compressed",
	# Do not warp mouse
	"warp_mouse",
	"warp_mouse_position",
	# OS
	"kill",
	"shell_open",
	"execute",
	"delay_usec",
	"delay_msec",
	"alert",  # Stupid alert window opens
	# Godot Freeze
	"wait_to_finish",
	"accept_stream",
	"connect_to_stream",
	"discover",
	"wait",
	"debug_bake",
	"bake",
	"_create",  # TODO Check
	"set_gizmo",  # Stupid function, needs as parameter an object which can't be instanced # TODO, create issue to hide it
	# Spams Output
	"print_tree",
	"print_stray_nodes",
	"print_tree_pretty",
	"print_all_textures_by_size",
	"print_all_resources",
	"print_resources_in_use",
	# Do not call other functions
	"_call_function",
	"call",
	"call_deferred",
	"callv",
	# Looks like a bug in FuncRef, probably but not needed, because it call other functions
	"call_func",
	# Too dangerous, because add, mix and remove randomly nodes and objects
	"replace_by",
	"create_instance",
	"set_owner",
	"set_root_node",
	"instance",
	"init_ref",
	"reference",
	"unreference",
	"new",
	"duplicate",
	"queue_free",
	"free",
	"remove_and_skip",
	"remove_child",
	"move_child",
	"raise",
	"add_child",
	"add_child_below_node",
	"add_sibling",
]

# Globally disabled classes which causes bugs or are very hard to use properly
var disabled_classes: Array = [
	"ProjectSettings",  # Don't mess with project settings, because they can broke entire your workflow
	"EditorSettings",  # Also don't mess with editor settings
	"_OS",  # This may sometimes crash compositor, but it should be tested manually sometimes
	"GDScript",  # Broke scripts
	# This classes have problems with static/non static methods
	"PhysicsDirectSpaceState",
	"Physics2DDirectSpaceState",
	"PhysicsDirectBodyState",
	"Physics2DDirectBodyState",
	"BulletPhysicsDirectSpaceState",
	"InputDefault",
	"IP_Unix",
	"JNISingleton",
	
	# Backported Navigation changes also backport bugged classes
	"NavigationAgent2D", 
	"NavigationAgent", 
	
	# Only one class - JavaClass returns Null when using JavaClass.new().get_class()
	"JavaClass",
	# Just don't use these because they are not normal things
	"_Thread",
	"_Semaphore",
	"_Mutex",
]


# Checks if function can be executed
# Looks at its arguments and checks if are recognized and supported
func check_if_is_allowed(method_data: Dictionary) -> bool:
	# Function is virtual or vararg, so we just skip it
	if method_data["flags"] == method_data["flags"] | METHOD_FLAG_VIRTUAL:
		return false
	if method_data["flags"] == method_data["flags"] | 128:  # VARARG TODO, Godot issue, add missing flag binding
		return false

	for arg in method_data["args"]:
		var name_of_class: String = arg["class_name"]
		if name_of_class.empty():
			continue
		if name_of_class in disabled_classes:
			return false

		if !ClassDB.class_exists(name_of_class):
			return false

		if !ClassDB.is_parent_class(name_of_class, "Node") && !ClassDB.is_parent_class(name_of_class, "Reference"):
			return false

		if name_of_class.find("Editor") != -1 || name_of_class.find("SkinReference") != -1:
			return false

		# In case of adding new type, this prevents from crashing due not recognizing this type
		# In case of removing/rename type, just comment e.g. TYPE_ARRAY and all occurencies on e.g. switch statement with it
		var t: int = arg["type"]
		if !(
			t == TYPE_NIL
			|| t == TYPE_AABB
			|| t == TYPE_ARRAY
			|| t == TYPE_BASIS
			|| t == TYPE_BOOL
			|| t == TYPE_COLOR
			|| t == TYPE_COLOR_ARRAY
			|| t == TYPE_DICTIONARY
			|| t == TYPE_INT
			|| t == TYPE_INT_ARRAY
			|| t == TYPE_NODE_PATH
			|| t == TYPE_OBJECT
			|| t == TYPE_PLANE
			|| t == TYPE_QUAT
			|| t == TYPE_RAW_ARRAY
			|| t == TYPE_REAL
			|| t == TYPE_REAL_ARRAY
			|| t == TYPE_RECT2
			|| t == TYPE_RID
			|| t == TYPE_STRING
			|| t == TYPE_TRANSFORM
			|| t == TYPE_TRANSFORM2D
			|| t == TYPE_VECTOR2
			|| t == TYPE_VECTOR2_ARRAY
			|| t == TYPE_VECTOR3
			|| t == TYPE_VECTOR3_ARRAY
		):
			print("----------------------------------------------------------- TODO - MISSING TYPE, ADD SUPPORT IT")  # Add assert here to get info which type is missing
			return false

	return true


# Removes disabled methods from classes
func remove_disabled_methods(method_list: Array, exceptions: Array) -> void:
	for exception in exceptions:
		var index: int = -1
		for method_index in range(method_list.size()):
			if method_list[method_index]["name"] == exception:
				index = method_index
				break
		if index != -1:
			method_list.remove(index)


# Return all available classes which can be used
func get_list_of_available_classes(must_be_instantable: bool = true) -> Array:
	var full_class_list: Array = Array(ClassDB.get_class_list())
	var classes: Array = []
	full_class_list.sort()
	var c = 0
	for name_of_class in full_class_list:
		if name_of_class in disabled_classes:
			continue

		#This is only for RegressionTestProject, because it needs for now clear visual info what is going on screen, but some nodes broke view
		if !ClassDB.is_parent_class(name_of_class, "Node") && !ClassDB.is_parent_class(name_of_class, "Reference"):
			continue
		# Don't test Servers objects like TranslationServer
		if name_of_class.find("Server") != -1:
			continue
		# Don't test Editor nodes
		if name_of_class.find("Editor") != -1:
			continue

		if !must_be_instantable || ClassDB.can_instance(name_of_class):
			classes.push_back(name_of_class)
			c += 1

	print(str(c) + " choosen classes from all " + str(full_class_list.size()) + " classes.")
	return classes
