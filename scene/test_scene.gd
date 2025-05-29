class_name TrafficGraph extends Node2D

func collision_test(cposition:Vector2) -> void :
	%TargetDetector.position = cposition
	var arr:Array[Line2D] = []
	for road in graph_roads:
		var result = road._ray_cast()
		if result != -1:
			#print("点击了这位：",road," 索引",result)
			road._target_point_index = result
			if result != road.points.size() - 1:
				_focus_sprite(true,road.points[result] + road.position,road.points[result + 1] - road.points[result])
			else:
				_focus_sprite(true,road.points[result] + road.position)
			if not arr.has(road):
				arr.append(road)
	for intersection in graph_intersections:
		var result = intersection._ray_cast()
		if result != -1:
			#print("点击了这位：",intersection," 索引",result)
			intersection._target_point_index = result
			if result != intersection.points.size() - 1:
				var vec = intersection.points[result + 1] - intersection.points[result]
				_focus_sprite(true,intersection.points[result] + intersection.position,vec)
			else:
				var vec = intersection.points[0] - intersection.points[result]
				_focus_sprite(true,intersection.points[result] + intersection.position,vec)
			if not arr.has(intersection):
				arr.append(intersection)
	%Control.flush_items(arr)
	if arr.size() == 0:
		_focus_sprite()
	#print(cposition)

@export var graph_intersections:Array[Intersection]
@export var graph_roads:Array[Road]

func _graph_generator() -> void:
	# 更新子节点列表
	graph_intersections.clear()
	graph_roads.clear()
	for child in self.get_children():
		if child is Intersection:
			graph_intersections.append(child)
		if child is Road:
			graph_roads.append(child)
	
	# 连接各道路
	for intersection in graph_intersections:
		intersection.update_path()
		for iop in intersection.io_list:
			iop.place(iop.point_index,iop.length_scale)
			iop.update_pair_position()
	
	for road in graph_roads:
		road.update_path()
	
	

func graph_init() -> void:
	_graph_generator()

var res_intersection := preload("res://scene/intersection_scene.tscn")
var res_road := preload("res://scene/road_scene.tscn")
func add_intersection() -> Intersection:
	var init_res = res_intersection.instantiate()
	self.add_child(init_res)
	graph_init()
	return init_res

func add_road() -> Road:
	var init_res = res_road.instantiate()
	self.add_child(init_res)
	graph_init()
	return init_res

func tick_init(seed:int):
	%CarProvider.init(seed)

func tick(delta):
	var data:Array = %CarProvider.tick()
	if data.size() > 0:
		var car:Car = data[0]
		%Cars.add_child(car)
		var result = %PathFinder.dijkstra(self,car)
		print(result)
		car.way_purpose = result
		car.belongs = car.start_road
		car.target_point_index = car.start_point_index
		car.position = car.start_road.position + car.start_road.points[car.start_point_index]
	for car:Car in %Cars.get_children():
		if not car.is_queued_for_deletion():
			car.tick(delta)

func tick_check() -> bool:
	for road in graph_roads:
		if not road._io_list_check():
			push_error("来源：",road.sign)
			return false
	return true

func flush():
	for i in %Cars.get_children():
		i.queue_free()
		

#@export_tool_button("保存当前路网") var _tool_save_graph = _save_graph
#@export_tool_button("读取已保存的路网") var _tool_load_graph = _load_graph

func _save_graph() -> void:
	graph_init()
	var file = FileAccess.open("user://save.dat",FileAccess.WRITE)
	var data:Dictionary = {}
	var roads:Array
	var intersections:Array
	for road in graph_roads:
		roads.append(road.serialize())
	for intersection in graph_intersections:
		intersections.append(intersection.serialize())
	data["roads"] = roads
	data["intersections"] = intersections
	data["control"] = %Control.serialize()
	file.store_var(data)
	file.close()
	return

func _load_graph() -> void:
	highlight_stop()
	for road in graph_roads:
		road._destroy()
		remove_child(road)
		road.queue_free()
	for intersection in graph_intersections:
		intersection._destroy()
		remove_child(intersection)
		intersection.queue_free()
	%Control.tip("已标记节点销毁")
	call_deferred("_load_graph_continue")

func _load_graph_continue():
	# 清空子节点列表
	graph_intersections.clear()
	graph_roads.clear()
	var file = FileAccess.open("user://save.dat",FileAccess.READ)
	var data:Dictionary = file.get_var()
	
	var roads:Array = data["roads"] 
	var intersections:Array = data["intersections"]
	%Control.deserialize(data["control"])
	
	# 一轮外层创建
	for road_data in roads:
		var road = add_road()
		road.deserialize(road_data)
	for intersection_data in intersections:
		var intersection = add_intersection()
		intersection.deserialize(intersection_data)
	
	file.close()
	%Control.tip("已完成初步创建")
	call_deferred("_load_graph_continue_2")
	return

func _load_graph_continue_2():
	graph_init()
	for road in graph_roads:
		road.deserialize_children()
	for intersection in graph_intersections:
		intersection.deserialize_children()
	%Control.tip("加载完成")

var _highlight_tween:Tween
var _highlight_obj:Line2D
func highlight_start(line2d:Line2D):
	highlight_stop()
	_highlight_obj = line2d
	_highlight_tween = create_tween()
	if _highlight_tween.is_valid():
		_highlight_tween.set_loops()
		_highlight_tween.tween_property(_highlight_obj,"modulate:a",0.5,1.0)
		_highlight_tween.tween_property(_highlight_obj,"modulate:a",1.0,1.0)

func highlight_stop():
	if _highlight_tween != null:
		if _highlight_tween.is_running():
			_highlight_tween.kill()
			if _highlight_obj != null:
				_highlight_obj.modulate.a = 1.0
		_highlight_tween.kill()
		_highlight_tween = null
		

func particle_send(vec2):
	%GPUParticles2D.position = vec2
	%GPUParticles2D.emitting = true
	#%GPUParticles2D.emit_particle()
	


func _focus_sprite(is_show:bool = false, pos:Vector2 = Vector2(0,0), forward_pos:Vector2 = Vector2(0,0)):
	%FocusSprite.visible = is_show
	%FocusSprite.position = pos
	%FocusLine2D.points[1] = forward_pos


func _ready() -> void:
	graph_init()
	%Control.camera = %Camera2D
	%Control.graph = self
	%Control.initing = false

var _ticking:bool = false
func _physics_process(delta: float) -> void:
	if _ticking:
		tick(delta)
