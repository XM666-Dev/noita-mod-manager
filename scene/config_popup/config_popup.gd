extends Popup


func _on_game_dir_edit_visibility_changed() -> void:
	if %GameDirEdit.is_visible_in_tree():
		%GameDirEdit.text = Main.config.game_dir


func _on_game_dir_edit_editing_toggled(toggled_on: bool) -> void:
	if !toggled_on:
		Main.config.game_dir = %GameDirEdit.text


func _on_game_dir_select_button_pressed() -> void:
	Main.file_dialog.popup()
	Main.file_dialog.dir_selected.connect(func(dir: String) -> void:
		%GameDirEdit.text = dir
	, CONNECT_ONE_SHOT)
