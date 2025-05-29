@tool
class_name CharterItem extends Label

@export var duration:int = 0
@export var level:int = 0
@export var dependency:Node = null:
	set(new_node):
		if new_node is CharterItem:
			dependency = new_node
			level = new_node.level + 1
			new_node.duration += duration
