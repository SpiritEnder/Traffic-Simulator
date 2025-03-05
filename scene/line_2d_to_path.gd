@tool
class_name Line2DToPath2D extends Line2D
# =================================== 参数 ===================================
## 区域宽度（仅在路线多于两条时生效）
@export_range(0.0, 50.0, 1.0) var seperation: float = 10.0:
	set(val):
		seperation = val
		update_path()

# 是否为单行道，仅在道路为两条时使用
@export var is_oneway: bool = false

@export_tool_button("更新") var update_action = update_path

# =================================== 子节点 ===================================
@onready var path_2d_s: Array[Node] = self.get_children()

# =================================== 方法 ===================================
# 更新路线
func update_path():
	var paths:Array[PackedVector2Array]
	for path in path_2d_s:
		paths.append(PackedVector2Array())
		path.curve.clear_points()
	
	for i in range(points.size()):
		if i > 0 and i < points.size() - 1:
			# 计算点在前后路径的起终点，并算得延长线交点（不知道咋解释）
			var tangent_a = points[i] - points[i - 1]
			var normal_a = Vector2(-tangent_a.y, tangent_a.x).normalized()
			var tangent_b = points[i + 1] - points[i]
			var normal_b = Vector2(-tangent_b.y, tangent_b.x).normalized()
			for j in range(paths.size()):
				if j > float(paths.size() - 1) / 2.0:
					#paths[j].curve.add_point(points[i] + normal_a * seperation)
					#paths[j].curve.add_point(points[i] + normal_b * seperation)
					var point_a = points[i] + normal_a * seperation
					var point_b = points[i] + normal_b * seperation
					paths[j].append(find_intersection_point(point_a,tangent_a,point_b,tangent_b))
				elif j < float(paths.size() - 1) / 2.0:
					#paths[j].curve.add_point(points[i] - normal_a * seperation)
					#paths[j].curve.add_point(points[i] - normal_b * seperation)
					var point_a = points[i] - normal_a * seperation
					var point_b = points[i] - normal_b * seperation
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
				if j > float(paths.size() - 1) / 2.0:
					paths[j].append(points[i] + normal * seperation)
				elif j < float(paths.size() - 1) / 2.0:
					paths[j].append(points[i] - normal * seperation)
				else:
					paths[j].append(points[i])
	
	# 判断是否为双行道，是则反向
	if paths.size() % 2 == 0 and not is_oneway:
		for i in range(paths.size() / 2):
			paths[i].reverse()
			
	# 设置path点
	for i in range(paths.size()):
		for point in paths[i]:
			path_2d_s[i].curve.add_point(point)
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
# =================================== 虚函数 ===================================
func _ready():
	update_path()
