class_name CarProvider extends Node

var parent:TrafficGraph

var res_car_icon := preload("res://texture/arr-icon.png")

func init(seed) -> void:
	seed(seed)
	randi()
	parent = get_parent()
	parent.graph_init()
	car_id = 0
	return

var car_id:int = 0

func tick() -> Array:
	# 生成随机数表
	var rand_list:Array
	for i in range(10):
		rand_list.append(randi())
	
	# 是否能生成车
	var is_generated:bool = true
	if rand_list.pop_back() % 20 != 0 :# or car_id != 0:
		is_generated = false
		return []
	
	# 起始点
	var start_road = rand_list.pop_back() % parent.graph_roads.size()
	var start_point_index = 1 + rand_list.pop_back() % (parent.graph_roads[start_road].points.size() - 2)
	# 寻路方向
	var forward_direction:int  = rand_list.pop_back() % 2
	# 终点
	var end_road = rand_list.pop_back() % parent.graph_roads.size()
	var end_point_index = 1 + rand_list.pop_back() % (parent.graph_roads[end_road].points.size() - 2)
	
	var car = Car.new()
	car.start_road = parent.graph_roads[start_road]
	car.end_road = parent.graph_roads[end_road]
	car.start_point_index = start_point_index
	car.end_point_index = end_point_index
	car.forward_direction = forward_direction
	
	car.texture = res_car_icon
	
	var label = Label.new()
	label.text = str(car_id)
	car.add_child(label)
	car_id += 1
	
	print(car.start_road.sign,' ',start_point_index,' ',car.end_road.sign,' ',end_point_index)
	return [car]
