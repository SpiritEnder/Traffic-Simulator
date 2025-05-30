extends Control

var initing:bool = true
var graph:TrafficGraph
var camera: Camera2D
var camera_tween: Tween = self.create_tween()

# 鼠标右键拖动时的初始位置
var drag_start_position: Vector2
# 是否正在拖动
var is_dragging: bool = false

# 鼠标滚轮缩放的增量
const ZOOM_INCREMENT: float = 1.25
# 最小和最大缩放比例
const MIN_ZOOM: float = 0.5
const MAX_ZOOM: float = 5.0

# 拖动时的偏移量
var drag_offset: Vector2 = Vector2.ZERO

func tip(msg:String):
	%TipLabel.text = msg

# 处理输入事件
func _gui_input(event: InputEvent):
	if initing:
		accept_event()
		return
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)

# 处理鼠标滚轮事件
# 处理鼠标按钮事件
var _point_dragging:bool = false
var _line_dragging:bool = false
func _handle_mouse_button(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		# 获取当前缩放
		# 计算新的缩放
		# 限制缩放范围
		# 更新相机缩放
		#camera.set_zoom()
		_on_zoom_down_button_pressed()
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_on_zoom_up_button_pressed()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			# 开始拖动
			is_dragging = true
			drag_start_position = event.position
		else:
			# 结束拖动
			is_dragging = false
		return
	elif event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _mode_point_moving:
				_point_dragging = true
			elif _mode_line_moving:
				_line_dragging = true
			else:
				graph.collision_test((get_global_mouse_position() - self.size / 2) / camera.zoom.x + camera.offset) 
		else:
			_point_dragging = false
			_line_dragging = false
	else:
		return

# 处理鼠标移动事件
func _handle_mouse_motion(event: InputEventMouseMotion):
	# 计算鼠标移动的偏移量
	# 将偏移量转换为场景中的实际距离（考虑缩放）
	var delta = event.relative
	delta /= camera.get_zoom().x
	
	if is_dragging:
		# 更新相机位置
		camera.offset -= delta
	if _point_dragging:
		loc_current_line.set_point_position(poc_current_point_index,loc_current_line.points[poc_current_point_index] + delta)
		graph._focus_sprite(true,loc_current_line.points[poc_current_point_index] + loc_current_line.position)
	if _line_dragging:
		loc_current_line.position += delta
		graph._focus_sprite(false)
		
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		# 获取鼠标位置
		var mouse_pos = event.position
		var nodes_at_pos = randf()
		# 获取鼠标按下位置的节点
		for node in nodes_at_pos:
			if node is Line2D:
				print("鼠标按下的 Line2D 节点：", node.name)
				# 在这里可以添加对 Line2D 节点的进一步处理

func _on_zoom_up_button_pressed() -> void:
	_camera_zoom_setter(ZOOM_INCREMENT,1)
func _on_zoom_reset_button_pressed() -> void:
	_camera_zoom_setter(Vector2(1.0,1.0),0)
func _on_zoom_down_button_pressed() -> void:
	_camera_zoom_setter(1 / ZOOM_INCREMENT,1)

var _camera_current_zoom:Vector2 = Vector2(1,1)
func _camera_zoom_setter(param,type) -> void:
	var current_zoom = camera.get_zoom()
	var new_zoom
	match type:
		0:
			if param is Vector2:
				new_zoom = param
			else:
				new_zoom = Vector2(param,param)
		1:
			new_zoom = _camera_current_zoom * param
	new_zoom = new_zoom.clampf(MIN_ZOOM, MAX_ZOOM)
	if camera_tween.is_valid():
		camera_tween.kill()
	camera_tween = create_tween()
	camera_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	#camera_tween.tween_method(camera.set_zoom,current_zoom,new_zoom,0.5)
	camera_tween.tween_property(camera,"zoom",new_zoom,0.5)
	_camera_current_zoom = new_zoom
	%ZoomLabel.text = "Zoom: " + str(snapped(_camera_current_zoom.x,0.01))
	


func _on_button_pressed() -> void:
	graph.graph_init()
	graph.tick_init(int(%SeedLineEdit.text))


func _on_tick_button_pressed() -> void:
	if graph._ticking:
		graph._ticking = false
		graph.flush()
		tip("已停止模拟")
		%TickButton.text = "开始模拟"
	else:
		if graph.tick_check():
			tip("开始模拟")
			graph._ticking = true
			%TickButton.text = "停止"
		else:
			tip("有不合法的图数据，请查看控制台错误")


func flush_items(items:Array):
	#loc_current_line = null
	poc_current_point_index = -1
	iop_current_point_index = -1
	%ItemContainer.visible = true
	%LineOperatorContainer.visible = false
	%PointOperatorContainer.visible = false
	var ic = %ItemContainer
	for child in ic.get_children():
		child.queue_free()
	
	for item in items:
		var button := Button.new()
		button.text = item.sign
		var is_road = false
		button.icon = res_inter
		if item is Road:
			is_road = true
			button.icon = res_road
		button.pressed.connect(item_pressed.bind(item))
		%ItemContainer.add_child(button)

func item_pressed(line2d:Line2D):
	loc_current_line = line2d
	
	graph.highlight_start(line2d)
	
	# 用于配对
	if (_mode_pairing):
		_pair_line2d = line2d
		_pair_step = 1
		%TipLabel.text = '正在配对出入口：已选择：' + loc_current_line.sign + '，请从左侧列表选取一个io...'
	
	var ic = %PointContainer
	for child in ic.get_children():
		child.queue_free()
	for i in range(line2d.points.size()):
		var button := Button.new()
		button.text = str(i)
		button.pressed.connect(item_point_pressed.bind(line2d,i))
		#if (i == 0 or i == line2d.points.size() - 1) and line2d is Road:
		#	button.icon = res_inter
		%PointContainer.add_child(button)
	%DeleteLineButton.disabled = false
	%LineOperatorContainer.visible = true
	%MoveLineButton.visible = true
	%SignEdit.text = line2d.sign
	%LineSignLabel.text = '当前选中元素：' + line2d.sign
	%PathEdit.value = line2d.path_list.size()
	for i in range(line2d.io_list.size()):
		var button := Button.new()
		button.text = 'io ' + str(i)
		button.pressed.connect(item_iop_pressed.bind(line2d,i))
		button.icon = res_inter
		%PointContainer.add_child(button)
	if line2d is Road:
		%OnewayLabel.text = '单行道'
		%OneWayCheckBox.button_pressed = line2d.is_oneway
	elif line2d is Intersection:
		%OnewayLabel.text = '环岛'
		%OneWayCheckBox.button_pressed = line2d.is_roundabout
		%DestroyCheckBox.button_pressed = line2d.is_destruction
		

var loc_current_line:Line2D
var poc_current_point_index:int
func item_point_pressed(line,index):
	# 停止现有点的移动
	if _mode_point_moving:
		_on_stop_button_pressed()
	
	if line != null:
		if line.is_queued_for_deletion():
			return
	else:
		return
	
	# 设为新点
	poc_current_point_index = index
	%PointOperatorContainer.visible = true
	%IOPContainer.visible = false
	graph._focus_sprite(true,loc_current_line.points[poc_current_point_index] + loc_current_line.position)
	_on_delete_check()
	_on_updown_check()

var iop_current_point_index:int
func item_iop_pressed(line,index):
	# 停止现有点的移动
	if _mode_point_moving:
		_on_stop_button_pressed()
	
	_on_iop_check()
	if line != null:
		if line.is_queued_for_deletion():
			return
	else:
		return
	
	# 设为新点
	iop_current_point_index = index
	%PointOperatorContainer.visible = false
	%IOPContainer.visible = true
	var iop:IOPoint = loc_current_line.io_list[iop_current_point_index]
	
	# 继续配对
	if _mode_pairing && _pair_step == 1:
		if iop != _pair_iop and iop.parent() != _pair_iop.parent():
			if iop.paired(_pair_iop):
				%TipLabel.text = '配对完成'
				%StopButton.visible = false
				_mode_pairing = false
				iop.update_pair_position()
			else:
				%TipLabel.text = '配对失败，请另外选择一个'
	
	graph._focus_sprite(true,iop.position + loc_current_line.position)
	%IOPIndexSpinBox.max_value = float(loc_current_line.points.size() - 1)
	if iop.pair != null:
		for conn in %IOPLinkButton.pressed.get_connections():
			%IOPLinkButton.pressed.disconnect(conn.callable)
		%IOPLinkButton.pressed.connect(_on_iop_link.bind(iop.pair.parent()))
		%IOPLinkButton.disabled = false
		%IOPUnpairButton.disabled = false
	if loc_current_line is Intersection:
		%IOPIndexSpinBox.value = iop.point_index
		%IOPScaleSpinBox.value = iop.length_scale


func _on_iop_link(linkto:Line2D):
	item_pressed(linkto)


var res_road := preload("res://texture/normal_road_texture.png")
var res_inter := preload("res://texture/add-icon.png")


func _on_sign_text_changed(new_text: String) -> void:
	if loc_current_line != null:
		loc_current_line.sign = new_text
		%LineSignLabel.text = '当前选中元素：' + loc_current_line.sign


func _on_one_way_check_box_toggled(toggled_on: bool) -> void:
	if loc_current_line != null:
		if loc_current_line is Road:
			loc_current_line.is_oneway = toggled_on
		elif loc_current_line is Intersection:
			loc_current_line.is_roundabout = toggled_on
	

# 路段车道数量
func _on_path_edit_value_changed(value: float) -> void:
	pass


func _on_update_button_pressed() -> void:
	if loc_current_line != null:
		if loc_current_line is Road:
			var new_count = int(%PathEdit.value)
			loc_current_line.path_generator(new_count)
			loc_current_line.call_deferred("update_path")
		elif loc_current_line is Intersection:
			loc_current_line.call_deferred("update_path")
	

var _mode_point_moving:bool = false
func _on_move_point_button_pressed() -> void:
	if loc_current_line != null:
		if poc_current_point_index in range(loc_current_line.points.size()):
			%LineOperatorContainer.visible = false
			%PointOperatorContainer.visible = false
			%ItemContainer.visible = false
			%StopButton.visible = true
			_mode_point_moving = true
			%TipLabel.text = '正在移动' + loc_current_line.sign + '点' + str(poc_current_point_index)
	else:
		%TipLabel.text = '当前没有选中的路段或路口。'

var _mode_line_moving:bool = false
func _on_move_line_button_pressed() -> void:
	if loc_current_line != null:
		%LineOperatorContainer.visible = false
		%PointOperatorContainer.visible = false
		%ItemContainer.visible = false
		%StopButton.visible = true
		_mode_line_moving = true
		%TipLabel.text = '正在移动' + loc_current_line.sign
	else:
		%TipLabel.text = '当前没有选中的路段或路口。'
	%MoveLineButton.visible = false

func _on_stop_button_pressed() -> void:
	%StopButton.visible = false
	if _mode_point_moving or _mode_line_moving:
		_mode_point_moving = false
		_mode_line_moving = false
		%ItemContainer.visible = true
		%LineOperatorContainer.visible = true
		%PointOperatorContainer.visible = true
		%TipLabel.text = '已停止移动'
	if _mode_pairing:
		_mode_pairing = false
		%TipLabel.text = '已停止配对'


func _on_delete_io_point_button_pressed() -> void:
	if loc_current_line != null:
		var iop:IOPoint = loc_current_line.io_list.pop_at(iop_current_point_index)
		iop.unpaired(iop)
		iop.queue_free()
	_on_iop_check()
	_on_update_button_pressed()
	item_pressed(loc_current_line)


func _on_add_io_point_button_pressed() -> void:
	if loc_current_line != null:
		var iop := IOPoint.new()
		loc_current_line.add_child(iop)
		iop.place()
	_on_iop_check()
	if loc_current_line is Intersection:
		loc_current_line.update_path()
	item_pressed(loc_current_line)

func _on_iop_check():
	%IOPLinkButton.disabled = true
	%IOPUnpairButton.disabled = true
	%AddIOPointButton.disabled = true
	%DeleteIOPointButton.disabled = true
	%IOPIndexSpinBox.editable = false
	%IOPScaleSpinBox.editable = false
	if loc_current_line is Intersection:
		# 可以随便加，多于一个可以删
		%AddIOPointButton.disabled = false
		if loc_current_line.io_list.size() > 1:
			%DeleteIOPointButton.disabled = false
		# 可以调整位置
		%IOPIndexSpinBox.editable = true
		%IOPScaleSpinBox.editable = true
	return

func _on_iop_scale_spin_box_value_changed(value: float) -> void:
	if loc_current_line != null:
		loc_current_line.io_list[iop_current_point_index].length_scale = value
		loc_current_line.io_list[iop_current_point_index].place()
		graph._focus_sprite(true,loc_current_line.io_list[iop_current_point_index].position + loc_current_line.position)

func _on_iop_index_spin_box_value_changed(value: float) -> void:
	if loc_current_line != null:
		loc_current_line.io_list[iop_current_point_index].point_index = int(value)
		loc_current_line.io_list[iop_current_point_index].place()
		graph._focus_sprite(true,loc_current_line.io_list[iop_current_point_index].position + loc_current_line.position)


func _on_add_point_button_pressed() -> void:
	loc_current_line.add_point(loc_current_line.points[poc_current_point_index],poc_current_point_index + 1)
	_on_delete_check()


func _on_delete_point_button_pressed() -> void:
	loc_current_line.remove_point(poc_current_point_index)
	_on_delete_check()


func _on_up_point_button_pressed() -> void:
	if poc_current_point_index > 0:
		var points = loc_current_line.points
		loc_current_line.set_point_position(poc_current_point_index - 1,points[poc_current_point_index])
		loc_current_line.set_point_position(poc_current_point_index,points[poc_current_point_index - 1])
		poc_current_point_index -= 1
	_on_updown_check()


func _on_down_point_button_pressed() -> void:
	var points = loc_current_line.points
	loc_current_line.set_point_position(poc_current_point_index + 1,points[poc_current_point_index])
	loc_current_line.set_point_position(poc_current_point_index,points[poc_current_point_index + 1])
	poc_current_point_index += 1
	_on_updown_check()

func _on_updown_check() -> void:
	%UpPointButton.disabled = true
	%DownPointButton.disabled = true
	if poc_current_point_index > 0:
		%UpPointButton.disabled = false
	if poc_current_point_index < loc_current_line.points.size() - 1:
		%DownPointButton.disabled = false
	item_pressed(loc_current_line)

func _on_delete_check() -> void:
	%DeletePointButton.disabled = true
	if loc_current_line.points.size() > 2:
		%DeletePointButton.disabled = false
	item_pressed(loc_current_line)

var _accept_dialog:AcceptDialog
func _on_add_line_button_pressed() -> void:
	var ad := AcceptDialog.new()
	ad.get_ok_button().visible = false
	ad.title = "想要添加哪种节点类型？"
	ad.add_button("Road路段",false,"1")
	ad.add_button("Intersection路口",false,"2")
	ad.add_cancel_button("取消")
	ad.custom_action.connect(_on_add_line_button_custom_action)
	ad.canceled.connect(_on_add_line_button_custom_action.bind("0"))
	ad.visible = true
	ad.position = (self.size + Vector2(ad.size)) / 2
	self.add_child(ad)
	%AddLineButton.disabled = true
	_accept_dialog = ad

func _on_add_line_button_custom_action(custom_action:String):
	if custom_action == "1":
		var road = graph.add_road()
		road.sign = 'road'
		if loc_current_line:
			road.position = loc_current_line.position
	elif custom_action == "2":
		var intersection = graph.add_intersection()
		intersection.sign = 'intersection'
		if loc_current_line:
			intersection.position = loc_current_line.position
	%AddLineButton.disabled = false
	_accept_dialog.queue_free()


func _on_delete_line_button_pressed() -> void:
	if loc_current_line != null:
		if loc_current_line is Road:
			graph.graph_roads.erase(loc_current_line)
		else:
			graph.graph_intersections.erase(loc_current_line)
		graph.remove_child(loc_current_line)
		loc_current_line._destroy()
		loc_current_line.queue_free()
		%DeleteLineButton.disabled = true
		loc_current_line = null


var _mode_pairing:bool = false
var _pair_step:int = 0
var _pair_line2d:Line2D
var _pair_iop:IOPoint
func _on_iop_pair_button_pressed() -> void:
	_pair_iop = loc_current_line.io_list[iop_current_point_index]
	_mode_pairing = true
	_pair_step = 0
	%TipLabel.text = '正在配对出入口：请选中另一个路段或路口'
	%StopButton.visible = true


func _on_iop_unpair_button_pressed() -> void:
	var iop = loc_current_line.io_list[iop_current_point_index]
	iop.unpaired(iop)
	_on_iop_check()


func _on_save_button_pressed() -> void:
	graph._save_graph()


func _on_load_button_pressed() -> void:
	graph._load_graph()


func serialize() -> Dictionary:
	var data:Dictionary = {}
	data["seed"] = %SeedLineEdit.text
	return data

func deserialize(data:Dictionary) -> bool:
	%SeedLineEdit.text = data["seed"]
	return true


func _on_destroy_check_box_toggled(toggled_on: bool) -> void:
	if loc_current_line != null:
		if loc_current_line is Intersection:
			loc_current_line.is_destruction = toggled_on
		else:
			tip("该选项只对路口生效")


func _on_stat_button_pressed() -> void:
	if %StatPanel.visible:
		%StatPanel.visible = false
	else:
		var stat = graph.get_stat()
		%StatTickCount.text = "物理周期数 " + str(stat["tick"])
		%StatProvideCount.text = "车辆提供数 " + str(stat["provide"])
		%StatArriveCount.text = "车辆抵达终点 " + str(stat["arrive"])
		%StatDestructCount.text = "车辆被路口销毁 " + str(stat["destruct"])
		%StatPanel.visible = true
