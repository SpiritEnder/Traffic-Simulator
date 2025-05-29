@tool
extends Control

@export_tool_button("update") var update_button = update

@export var start_time = 0

func update() -> void:
	var items = %CharterItem.get_children()
	

func _on_v_scroll_bar_scrolling() -> void:
	pass # Replace with function body.
