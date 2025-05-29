class_name IOPoint extends Node2D

# position 位置

# 连接的io点
@export var pair: IOPoint

# 自动调整位置
#@export_tool_button('调整位置') var _tool_update_position = _update_position
#@export_tool_button('调整同伴位置') var _tool_update_pair_position = _update_pair_position
# 出入方向
@export_enum('both:-1','output:0','input:1') var type: int = -1

# 所属点位
@export var point_index:int = 0
@export_range(0.0, 1.0, 0.05) var length_scale:float = 0.0

func place(_point_index:int = point_index, _length_scale:float = length_scale) -> Vector2:
	var points:PackedVector2Array = parent().points
	var result:Vector2
	if parent() is Intersection:
		if _point_index in range(points.size() - 1):
			result = points[_point_index] + (points[_point_index + 1] - points[_point_index]) * _length_scale
			point_index = _point_index
		else:
			result = points[-1] + (points[0] - points[-1]) * _length_scale
	else:
		if _point_index == 0: # 道路末端
			result = points[-1]
		else: # 道路起始点
			result = points[0]
	self.position = result
	return result


func _pair_check(iop:IOPoint) -> bool:
	if iop.type == self.type and self.type == -1:
		return true
	elif iop.type == 0 and self.type == 1:
		return true
	elif iop.type == 1 and self.type == 0:
		return true
	else:
		return false

# 解除配对
# 当我解除自己的配对时，我会同步解除原配的配对。为了防止无限递归，我会查询请求是否来源与原配
func unpaired(origin_pair:IOPoint) -> void:
	if pair != null and pair != origin_pair:
		pair.unpaired(self)
	pair = null
	return

# 进行配对
func paired(new_iop) -> bool:
	if _pair_check(new_iop):
		self.unpaired(self)
		pair = new_iop
		new_iop.pair = self
		return true
	else:
		return false


##========== 属性访问
func parent() -> Line2D:
	var _parent = get_parent()
	if _parent is not Line2D:
		return null
	return _parent


func _update_position() -> bool:
	if parent() is Intersection:
		place(point_index,length_scale)
		return true
	elif parent() is Road:
		if not point_index in [0,1]:
			point_index = 0
		# 道路尽头出入口
		if point_index == 0:
			position = parent().points[-1]
		# 道路开头出入口
		elif point_index == 1:
			position = parent().points[0]
		else:
			return false
		return true
	else:
		push_error('需要父节点为Line2D')
		return false


func update_pair_position() -> bool:
	if pair == null:
		return false
	return _update_pair_position()
func _update_pair_position() -> bool:
	if parent() is Road:
		self.position = pair.position + pair.parent().position - parent().position
		if point_index == 0:
			parent().set_point_position(parent().points.size() - 1,self.position)
			_update_position()
		elif point_index == 1:
			parent().set_point_position(0,self.position)
			_update_position()
		else:
			return false
		return true
	else:
		pair._update_pair_position()
	return false




func serialize() -> Dictionary:
	var data:Dictionary = {}
	data["type"] = type
	data["point_index"] = point_index
	data["length_scale"] = length_scale
	data["position"] = position
	if pair == null:
		data["pair"] = -1
	else:
		# 指向parent的类型
		if pair.parent() is Road:
			data["pair"] = 0
			data["pair_line_index"] = pair.parent().get_self_index()
			data["pair_io_index"] = pair.get_self_index()
		elif pair.parent() is Intersection:
			data["pair"] = 1
			data["pair_line_index"] = pair.parent().get_self_index()
			data["pair_io_index"] = pair.get_self_index()
	return data

func deserialize(data:Dictionary) -> bool:
	var graph:TrafficGraph = parent().get_parent()
	type = data["type"]
	point_index = data["point_index"]
	length_scale = data["length_scale"]
	position = data["position"]
	if data["pair"] != -1:
		# 道路
		if data["pair"] == 0:
			var target_road = graph.graph_roads[data["pair_line_index"]]
			var iop = target_road.io_list[data["pair_io_index"]]
			if not paired(iop):
				push_error("配对失败")
		# 路口
		if data["pair"] == 1:
			var target_intersections = graph.graph_intersections[data["pair_line_index"]]
			var iop = target_intersections.io_list[data["pair_io_index"]]
			if not paired(iop):
				push_error("配对失败")
				
	return true

func get_self_index():
	var line2d = parent()
	return line2d.io_list.find(self)
