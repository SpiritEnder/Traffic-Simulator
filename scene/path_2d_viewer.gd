@tool
class_name Path2DWithPolygon extends Path2D
# =================================== 参数 ===================================
## 区域宽度
@export_range(0.0, 50.0, 1.0) var width: float = 30.0:
	set(val):
		width = val
		update_polygon()

@export_range(0.0, 0.5, 0.01) var threshold: float = 0.45

# =================================== 子节点 ===================================
@onready var polygon_2d: Polygon2D = get_node("Polygon2D")

# =================================== 方法 ===================================
# 更新多边形
func update_polygon():
	var curve = get_curve()
	if not curve:
		return

	var points = curve.get_baked_points()
	var polygon_left_points:PackedVector2Array = []
	var polygon_right_points:PackedVector2Array = []
	var unit_length = curve.get_baked_length() / points.size()

	for i in range(points.size()):
		var point = points[i]
		var tangent = curve.sample_baked_with_rotation(i * unit_length).x
		var normal = Vector2(-tangent.y, tangent.x).normalized()

		var left_point = point + normal * width * 0.5
		var right_point = point - normal * width * 0.5

		polygon_left_points.append(left_point)
		polygon_right_points.append(right_point)

	# 确保多边形闭合
	if points.size() > 0:
		var last_point = points[points.size() - 1]
		var tangent = curve.sample_baked_with_rotation((points.size() - 1) * unit_length).x
		var normal = Vector2(-tangent.y, tangent.x).normalized()

		var left_point = last_point + normal * width * 0.5
		var right_point = last_point - normal * width * 0.5

		polygon_left_points.append(left_point)
		polygon_right_points.append(right_point)

	# 清理多边形点，删除内弯处多余的点
	polygon_left_points = clean_polygon_points(polygon_left_points)
	polygon_right_points = clean_polygon_points(polygon_right_points)

	# 设置多边形点
	if polygon_2d:
		polygon_right_points.reverse()
		polygon_left_points.append_array(polygon_right_points)
		polygon_2d.polygon = polygon_left_points

# 删除内弯处多余的点
func clean_polygon_points(polygon_points: PackedVector2Array) -> PackedVector2Array:
	var cleaned_points = PackedVector2Array()
	for point in polygon_points:
		# 计算点到曲线的距离
		var closest_point = curve.get_closest_point(point)
		var distance = point.distance_to(closest_point)
		# 如果距离大于阈值，则保留该点
		if distance >= threshold *  width:
			cleaned_points.append(point)
	return cleaned_points

# =================================== 虚函数 ===================================
func _ready():
	update_polygon()

func _process(delta: float) -> void:
	update_polygon()
