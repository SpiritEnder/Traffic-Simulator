@tool
class_name Road extends Line2D
# =================================== 参数 ===================================
## 区域宽度（仅在路线多于两条时生效）
@export_range(0.0, 50.0, 1.0) var seperation: float = 10.0

# 是否为单行道，仅在道路为两条时使用
@export var is_oneway: bool = false

@export var sign:String = "road"

# 道路长度
var road_length:float = 0

# 被选中节点索引
var _target_point_index:int = -1

# =================================== 子节点 ===================================
@onready var path_list: Array[Path2D]
@onready var io_list: Array[IOPoint]

# 连接的路口节点
#@export var input_node: Node
#@export var output_node: Node

# =================================== 方法 ===================================

# 获取出入口
func get_input_pair() -> IOPoint:
	for iop in io_list:
		if iop.type in [-1,1] and iop.pair != null:
			return iop.pair
	return null
func get_output_pair() -> IOPoint:
	for iop in io_list:
		if iop.type in [-1,0] and iop.pair != null:
			return iop.pair
	return null

# 获取出入口（以路段为参考）
func get_start_pair() -> IOPoint:
	for iop in io_list:
		if iop.point_index == 1 and iop.pair != null:
			return iop.pair
	return null
func get_end_pair() -> IOPoint:
	for iop in io_list:
		if iop.point_index == 0 and iop.pair != null:
			return iop.pair
	return null

# 获取道路另一个端点
func get_another_pair(iop:IOPoint) -> IOPoint:
	if iop in io_list:
		if io_list.find(iop) == 0:
			return io_list[1].pair
		else:
			return io_list[0].pair
	return null






@export_tool_button("更新") var update_action = update_path
# 更新路线
func update_path():
	# 更新子节点列表
	path_list.clear()
	io_list.clear()
	for child in self.get_children():
		if child is Path2D:
			path_list.append(child)
		if child is IOPoint:
			io_list.append(child)
			child.place()
	_io_list_check()
	var paths:Array[PackedVector2Array]
	for path in path_list:
		paths.append(PackedVector2Array())
		path.curve.clear_points()
	
	if is_oneway:
		if io_list[0].point_index == 1:
			io_list[0].type = 1
			io_list[1].type = 0
		else:
			io_list[0].type = 0
			io_list[1].type = 1
	else:
		io_list[0].type = -1
		io_list[1].type = -1
	
	
	road_length = 0.0
	
	for i in range(points.size()):
		# 更新道路长度
		if i != 0:
			road_length += points[i - 1].distance_to(points[i])
		
		var seperation_mid = float(paths.size() - 1) / 2.0
		if i > 0 and i < points.size() - 1:
			# 计算点在前后路径的起终点，并算得延长线交点（不知道咋解释）
			var tangent_a = points[i] - points[i - 1]
			var normal_a = Vector2(-tangent_a.y, tangent_a.x).normalized()
			var tangent_b = points[i + 1] - points[i]
			var normal_b = Vector2(-tangent_b.y, tangent_b.x).normalized()
			for j in range(paths.size()):
				if j != seperation_mid:
					#paths[j].curve.add_point(points[i] + normal_a * seperation)
					#paths[j].curve.add_point(points[i] + normal_b * seperation)
					var point_a = points[i] + normal_a * seperation * (j - seperation_mid)
					var point_b = points[i] + normal_b * seperation * (j - seperation_mid)
					paths[j].append(find_intersection_point(point_a,tangent_a,point_b,tangent_b))
				else:
					paths[j].append(points[i])
		else:
			var tangent
			if i == 0:
				tangent = points[i + 1] - points[i]
			else:
				tangent = points[i] - points[i - 1]
			var normal = Vector2(-tangent.y, tangent.x).normalized()
			for j in range(paths.size()):
				if j != seperation_mid:
					paths[j].append(points[i] + normal * seperation * (j - seperation_mid))
				else:
					paths[j].append(points[i])
	
	# 判断是否为双行道，是则反向
	if paths.size() % 2 == 0 and not is_oneway:
		for i in range(paths.size() / 2):
			paths[i].reverse()
			
	# 设置path点
	for i in range(paths.size()):
		for point in paths[i]:
			path_list[i].curve.add_point(point)
			#print(point)
		#polygon_right_points.reverse()
		#polygon_left_points.append_array(polygon_right_points)
		#polygon_2d.polygon = polygon_left_points

# 计算两条直线的交点
func find_intersection_point(point1: Vector2, direction1: Vector2, point2: Vector2, direction2: Vector2) -> Vector2:
	# 方向向量归一化
	var dir1 = direction1.normalized()
	var dir2 = direction2.normalized()

	# 计算行列式
	var determinant = dir1.x * dir2.y - dir1.y * dir2.x
	# print(dir1,dir2)

	# 如果行列式为零，说明两条直线平行或重合，没有交点
	if determinant == 0:
		return Vector2(0,0)

	# 计算交点
	var t = ((point2 - point1).x * dir2.y - (point2 - point1).y * dir2.x) / determinant
	var intersection_point = point1 + dir1 * t

	# print(intersection_point)
	return intersection_point

func path_generator(new_count:int):
	var count = path_list.size()
	if new_count > count:
		for i in range(new_count - count):
			var p2d = Path2D.new()
			p2d.curve = Curve2D.new()
			add_child(p2d)
	elif new_count < count:
		for i in range(count - new_count):
			var target = path_list.pop_at(0)
			target.queue_free()


func _io_list_check() -> bool:
	if io_list.size() != 2:
		push_error('路段需要有且仅有两个出入口',io_list)
		return false
	if not (io_list[0].type + io_list[1].type) in [-2,1]:
		push_error('路段出入口类型不匹配')
		return false
	for iop in io_list:
		if iop.pair == null:
			push_error('路段出入口两端均需要连接入口或销毁点。')
			return false
	return true


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

# =================================== 虚函数 ===================================
func _ready():
	update_path()

func _destroy() -> void:
	for iop in io_list:
		iop.unpaired(iop)
	return

func serialize() -> Dictionary:
	var data:Dictionary = {}
	data["width"] = width
	data["is_oneway"] = is_oneway
	data["sign"] = sign
	data["points"] = points
	data["path_count"] = path_list.size()
	data["io_in"] = %IOPointIn.serialize()
	data["io_out"] = %IOPointOut.serialize()
	data["position"] = position
	return data

func deserialize(data:Dictionary) -> bool:
	_deserialize_data = data
	width = data["width"]
	is_oneway = data["is_oneway"]
	sign = data["sign"]
	points = data["points"]
	position = data["position"]
	path_generator(data["path_count"])
	return true

var _deserialize_data
func deserialize_children():
	%IOPointIn.deserialize(_deserialize_data["io_in"])
	%IOPointOut.deserialize(_deserialize_data["io_out"])

func get_self_index():
	var graph:TrafficGraph = get_parent()
	return graph.graph_roads.find(self)
