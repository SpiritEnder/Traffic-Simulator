@tool
class_name Intersection extends Line2D

# 是否为销毁点
@export var is_destruction:bool = false

# 是否为环岛
@export var is_roundabout:bool = false

# 接入点列表
@export var io_list:Array[IOPoint]

# 可用道路列表
var path_list:Array[Path2D]

@export var sign:String = "intersection"
# 被选中节点索引
var _target_point_index:int = -1


# 更新显示
@export_tool_button("更新") var update_action = update_path
func update_path() -> void:
	# 更新子节点列表
	path_list.clear()
	io_list.clear()
	for child in self.get_children():
		if child is Path2D:
			path_list.append(child)
		if child is IOPoint:
			io_list.append(child)
			#print(type_string(typeof(child)))
			child.place()
	return


func flush() -> void:
	for child in get_children():
		child.queue_free()


func _ray_cast() -> int:
	%RayCast2D.enabled = true
	for i in range(self.points.size()):
		%RayCast2D.position = self.points[i]
		if i == self.points.size() - 1:
			%RayCast2D.target_position = self.points[0] - self.points[i]
		else:
			%RayCast2D.target_position = self.points[i + 1] - self.points[i]
		%RayCast2D.force_raycast_update()
		if %RayCast2D.is_colliding():
			var collision_point:Vector2 = %RayCast2D.get_collision_point()
			var distance = collision_point.distance_squared_to(%RayCast2D.position + self.position + %RayCast2D.target_position)
			#print(distance)
			if distance < 400:
				%RayCast2D.enabled = false
				return 0 if i == self.points.size() - 1 else i + 1
			else:
				%RayCast2D.enabled = false
				return i
	%RayCast2D.enabled = false
	return -1


func _ready() -> void:
	update_path()

func _destroy() -> void:
	for iop in io_list:
		iop.unpaired(iop)
	return

func serialize() -> Dictionary:
	var data:Dictionary = {}
	data["width"] = width
	data["is_roundabout"] = is_roundabout
	data["is_destruction"] = is_destruction
	data["sign"] = sign
	data["points"] = points
	data["position"] = position
	#data["path_count"] = path_list.size()
	var ioarr = []
	for io in io_list:
		ioarr.append(io.serialize())
	data["ios"] = ioarr
	return data

func deserialize(data:Dictionary) -> bool:
	_deserialize_data = data
	width = data["width"]
	is_destruction = data["is_destruction"]
	is_roundabout = data["is_roundabout"]
	sign = data["sign"]
	points = data["points"]
	position = data["position"]
	_iop_generator(data["ios"].size())
	#path_generator(data["path_count"])
	return true

var _deserialize_data
func deserialize_children():
	var datas = _deserialize_data["ios"]
	for i in datas.size():
		io_list[i].deserialize(datas[i])

func _iop_generator(count):
	if count > 1:
		for i in range(count - 1):
			var io = IOPoint.new()
			self.add_child(io)

func get_self_index():
	var graph:TrafficGraph = get_parent()
	return graph.graph_intersections.find(self)
