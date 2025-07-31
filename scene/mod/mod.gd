class_name Mod extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var request_no_api_restrictions: bool = false
@export var is_game_mode: bool = false
@export var game_mode_supports_save_slots: bool = false
@export var ui_newgame_name: String = ""
@export var ui_newgame_description: String = ""
@export var ui_newgame_gfx_banner_bg: String = ""
@export var ui_newgame_gfx_banner_fg: String = ""
@export var workshop_id: int = 0
@export var workshop_name: String = ""
@export var workshop_description: String = ""
@export var workshop_tags: PackedStringArray = []
@export var workshop_preview_image: Texture2D = null
