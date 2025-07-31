class_name Main extends Control

const ModList := preload("res://scene/main/mod_list.gd")
const CONFIG_FILE: String = "user://config.json"
const SAVE_DIR: String = "C:/Users/Administrator/AppData/LocalLow/Nolla_Games_Noita"
const MOD_CONFIG_FILE: String = "save00/mod_config.xml"
const EXECUTABLE_FILE: String = "noita.exe"
const MODS_DIR: String = "mods"

static var mod_list: ModList = null
static var file_dialog: FileDialog = null
static var accept_dialog: AcceptDialog = null
static var config_popup: Popup = null
static var http_request: HTTPRequest = null
static var config: Config = null
static var mods: Array[Mod] = []

@export var default_config: Config = null

func _ready() -> void:
	mod_list = %ModList
	file_dialog = %FileDialog
	accept_dialog = %AcceptDialog
	config_popup = %ConfigPopup
	http_request = %HTTPRequest

	config = default_config.duplicate(true)
	var config_string := FileAccess.get_file_as_string(CONFIG_FILE)
	if !config_string.is_empty():
		var json: Variant = JSON.parse_string(config_string)
		if json is Dictionary:
			config.merge(json)
	if config.mod_config.is_empty():
		read_mod_config()

	Steam.steamInit(881100, true)
	var game_dir := get_game_dir()
	if is_game_dir_valid(game_dir):
		load_mod_list()
		return
	file_dialog.popup()

func get_game_dir() -> String:
	var game_dir := config.game_dir
	if is_game_dir_valid(game_dir):
		return game_dir
	var install_dir: String = Steam.getAppInstallDir(881100).get("directory", "")
	if is_game_dir_valid(install_dir):
		return install_dir
	return game_dir

func is_game_dir_valid(game_dir: String) -> bool:
	return IS.dir_exists_absolute(game_dir) && executable_file_exists(game_dir)

func executable_file_exists(game_dir: String) -> bool:
	var executable_path := game_dir.path_join(EXECUTABLE_FILE)
	return FileAccess.file_exists(executable_path)

func load_mod_list() -> void:
	mods.clear()
	load_mods()
	load_mods(true)
	mod_list.update()

func load_mods(workshop: bool = false) -> void:
	var mod_dirs: PackedStringArray = []
	var subscribed_items: Array = []
	if workshop:
		subscribed_items = Steam.getSubscribedItems()
		var folder_mapper := func(info: Dictionary) -> String: return info.folder
		mod_dirs = subscribed_items.map(Steam.getItemInstallInfo).map(folder_mapper)
	else:
		var mods_path := get_game_dir().path_join(MODS_DIR)
		mod_dirs = Array(DirAccess.get_directories_at(mods_path)).map(mods_path.path_join)

	var new_mods: Array[Mod] = []
	var mod_count := mod_dirs.size()
	new_mods.resize(mod_count)
	for mod_index in mod_count:
		new_mods[mod_index] = Mod.new()

	if workshop:
		Steam.ugc_query_completed.connect(on_ugc_query_completed.bind(new_mods), CONNECT_ONE_SHOT)
		var query_handle := Steam.createQueryUGCDetailsRequest(subscribed_items)
		Steam.sendQueryUGCRequest(query_handle)

	var parser = XMLParser.new()
	for mod_index in mod_count:
		var mod_dir := mod_dirs[mod_index]
		var mod := new_mods[mod_index]
		if workshop:
			var mod_id_file := mod_dir.path_join("mod_id.txt")
			mod.id = FileAccess.get_file_as_string(mod_id_file)
		else:
			mod.id = mod_dir.get_file()

		var mod_xml_file := mod_dir.path_join("mod.xml")
		if FileAccess.file_exists(mod_xml_file):
			parser.open(mod_xml_file)
			while parser.read() != ERR_FILE_EOF:
				if parser.get_node_type() != XMLParser.NODE_ELEMENT:
					continue
				var node_name := parser.get_node_name()
				if node_name != "Mod":
					continue
				var attributes := {}
				for index in parser.get_attribute_count():
					var attribute_name := parser.get_attribute_name(index)
					var attribute_value := parser.get_attribute_value(index)
					attributes[attribute_name] = attribute_value
				mod.name = attributes.get("name", "")
				mod.description = str(attributes.get("description", "")).xml_unescape()
				mod.request_no_api_restrictions = attributes.get("request_no_api_restrictions") != "0"
				mod.is_game_mode = attributes.get("is_game_mode") != "0"
				mod.game_mode_supports_save_slots = attributes.get("game_mode_supports_save_slots") != "0"
				mod.ui_newgame_name = attributes.get("ui_newgame_name", "")
				mod.ui_newgame_description = attributes.get("ui_newgame_description", "")
				mod.ui_newgame_gfx_banner_bg = attributes.get("ui_newgame_gfx_banner_bg", "")
				mod.ui_newgame_gfx_banner_fg = attributes.get("ui_newgame_gfx_banner_fg", "")

		if workshop:
			mod.workshop_id = int(mod_dir.get_file())

		var workshop_xml_file := mod_dir.path_join("workshop.xml")
		if FileAccess.file_exists(workshop_xml_file):
			parser.open(workshop_xml_file)
			while parser.read() != ERR_FILE_EOF:
				if parser.get_node_type() != XMLParser.NODE_ELEMENT:
					continue
				var node_name := parser.get_node_name()
				if node_name != "Mod":
					continue
				var attributes := {}
				for index in parser.get_attribute_count():
					var attribute_name := parser.get_attribute_name(index)
					var attribute_value := parser.get_attribute_value(index)
					attributes[attribute_name] = attribute_value
				mod.workshop_name = attributes.get("name", "")
				mod.workshop_description = attributes.get("description", "")
				var workshop_tags_string: String = attributes.get("tags", "")
				mod.workshop_tags = workshop_tags_string.split(",")

		if workshop:
			mod.workshop_preview_image = ImageTexture.new()
		else:
			var workshop_preview_image_file := mod_dir.path_join("workshop_preview_image.png")
			if FileAccess.file_exists(workshop_preview_image_file):
				var workshop_preview_image := Image.load_from_file(workshop_preview_image_file)
				mod.workshop_preview_image = ImageTexture.create_from_image(workshop_preview_image)

	mods.append_array(new_mods)

static func on_ugc_query_completed(handle: int, _result: int, results_returned: int, _total_matching: int, _cached: bool, new_mods: Array[Mod]) -> void:
	for index in results_returned:
		http_request.request_completed.connect(on_request_completed.bind(new_mods[index]), CONNECT_ONE_SHOT)
		var url := Steam.getQueryUGCPreviewURL(handle, index)
		var err := http_request.request(url)
		if err == OK:
			await http_request.request_completed
	Steam.releaseQueryUGCRequest(handle)

static func on_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray, mod: Mod) -> void:
	var image := Image.new()
	image.load_png_from_buffer(body)
	var image_texture: ImageTexture = mod.workshop_preview_image
	image_texture.set_image(image)

static func find_mod(mod_element: ModElement) -> Mod:
	var mod_finder := func(mod: Mod) -> bool:
		return mod.id == mod_element.name && mod.workshop_id == mod_element.workshop_item_id
	var mod_index := mods.find_custom(mod_finder)
	if mod_index != -1:
		return mods[mod_index]
	return null

static func read_mod_config() -> void:
	var mod_config: Array[ModElement] = []
	var mod_config_path := SAVE_DIR.path_join(MOD_CONFIG_FILE)
	var parser = XMLParser.new()
	parser.open(mod_config_path)
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		var node_name := parser.get_node_name()
		if node_name != "Mod":
			continue
		var attributes := {}
		for index in parser.get_attribute_count():
			var attribute_name := parser.get_attribute_name(index)
			var attribute_value := parser.get_attribute_value(index)
			attributes[attribute_name] = attribute_value
		var mod_element := ModElement.new()
		mod_element.name = attributes.name
		mod_element.enabled = attributes.enabled != "0"
		mod_element.settings_fold_open = attributes.settings_fold_open != "0"
		mod_element.workshop_item_id = int(attributes.workshop_item_id)
		mod_config.append(mod_element)
	config.mod_config = mod_config

static func write_mod_config() -> void:
	var mod_config_path := SAVE_DIR.path_join(MOD_CONFIG_FILE)
	var root := XMLNode.new()
	root.name = "Mods"
	for mod_element in config.mod_config:
		var child := XMLNode.new()
		child.name = "Mod"
		child.attributes.name = mod_element.name
		child.attributes.enabled = 1 if mod_element.enabled else 0
		child.attributes.settings_fold_open = 1 if mod_element.settings_fold_open else 0
		child.attributes.workshop_item_id = mod_element.workshop_item_id
		root.children.append(child)
	root.dump_file(mod_config_path)

func store() -> void:
	var config_file := FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
	var json: Dictionary = IS.json_from_native(config, {
		Config: Config.serialized_properties,
		ModElement: ModElement.serialized_properties
	})
	var json_string := JSON.stringify(json, "\t")
	config_file.store_string(json_string)

func set_setting(key: String, value: Variant) -> void:
	config[key] = value
	store()

func merge_settings(json: Dictionary) -> void:
	config.merge(json)
	store()


func _on_title_bar_gui_input(event: InputEvent) -> void:
	if IS.event_is_mouse_button_pressed(event, MOUSE_BUTTON_LEFT):
		get_window().start_drag()


func _on_config_button_pressed() -> void:
	config_popup.popup()


func _on_close_button_pressed() -> void:
	get_tree().quit()


func _on_refresh_button_pressed() -> void:
	load_mod_list()


func _on_file_dialog_dir_selected(dir: String) -> void:
	set_setting("game_dir", dir)
	if executable_file_exists(dir):
		load_mod_list()
		return
	accept_dialog.popup()


func _on_accept_dialog_confirmed() -> void:
	file_dialog.popup()


func _on_config_popup_popup_hide() -> void:
	store()
