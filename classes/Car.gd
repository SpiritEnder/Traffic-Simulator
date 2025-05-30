class_name Car extends Sprite2D

signal stat(type:StringName)

# 起始点
var start_road:Road
var start_point_index:int
# 寻路方向
var forward_direction:int  = 0
# 终点
var end_road:Road
var end_point_index:int

# 寻路列表
var way_purpose: Array

# 所在路段
var belongs: Line2D
# 临时目标位置
var target_point_index: int
# 所在的io点索引（仅在路口使用）
var current_point_index: int


func _init() -> void:
	return

func tick(delta:float = 0.05) -> void:
	if self.is_queued_for_deletion():
		return
		

	# 如果车辆还在路段上，则进行路段前进逻辑
	if belongs is Road:
		# 距离目标节点的距离还没小到一定程度
		if position.distance_squared_to(belongs.points[target_point_index] + belongs.position) > 100:
			var sub = position - belongs.points[target_point_index] - belongs.position
			#继续前进
			velocity = -(sub).normalized() * 40
			#get_parent().get_parent()._focus_sprite(true,belongs.points[target_point_index] + belongs.position)
		else:
			# 否则将目标更新为下一节点
			
			# 如果已经到达路径终点
			if end_road == belongs and end_point_index == target_point_index:
				#print("arrive")
				stat.emit("arrive")
				get_parent().get_parent().particle_send(position)
				self.queue_free()
				return
			# 如果是路段起始且反向行进
			elif target_point_index == 0 and forward_direction == 1:
				# 将归属交给路口节点
				# 获取路段起始处的出入点
				var iop = belongs.get_start_pair()
				if iop == null:
					self.queue_free()
					return
				belongs = iop.parent()
				# 从寻路列表中得到目标出口
				if way_purpose.size() == 0:
					stat.emit("arrive")
					get_parent().get_parent().particle_send(position)
					self.queue_free()
					return
				target_point_index = way_purpose.pop_front()
				if not belongs.is_roundabout:
					current_point_index = target_point_index
				else:
					current_point_index = iop.point_index + 1
					if current_point_index >= belongs.points.size():
						current_point_index = 0
				
			# 如果是路段尽头且正向行进
			elif target_point_index == belongs.points.size() - 1 and forward_direction == 0:
				# 将归属交给路口节点
				# 获取路段尽头处的出入点
				var iop = belongs.get_end_pair()
				if iop == null:
					self.queue_free()
					return
				belongs = iop.parent()
				# 从寻路列表中得到目标出口
				if way_purpose.size() == 0:
					#print("destroy")
					stat.emit("arrive")
					get_parent().get_parent().particle_send(position)
					self.queue_free()
					return
				target_point_index = way_purpose.pop_front()
				if not belongs.is_roundabout:
					current_point_index = target_point_index
				else:
					current_point_index = iop.point_index + 1
					if current_point_index >= belongs.points.size():
						current_point_index = 0
			
		
			# 都不是，则前往下一个路径点
			else:
				if forward_direction == 0:
					target_point_index += 1
				else:
					target_point_index -= 1
	
	# 如果车辆在路口上
	elif belongs is Intersection:
		# 路口是销毁点
		if belongs.is_destruction:
			#print("inter destroy")
			stat.emit("destructed")
			get_parent().get_parent().particle_send(position)
			self.queue_free()
			return
		# 是否抵达指定出口
		else:
			# 始终检查是否到达出口
			if position.distance_squared_to(belongs.io_list[target_point_index].position + belongs.position) < 200:
				# 将车辆还给路段
				var iop:IOPoint = belongs.io_list[target_point_index]
				if iop == null:
					self.queue_free()
					return
				belongs = iop.pair.parent()
				# 设定新目标点
				# 从出口进来，则目标设为出口的前一个节点
				#print("回")
				if iop.pair.point_index == 0:
					target_point_index = belongs.points.size() - 2
					forward_direction = 1
				else:
					target_point_index = 1
					forward_direction = 0
			else:
				# 如果是环岛，必须按顺序行进
				if belongs.is_roundabout:
					var distance = position.distance_squared_to(belongs.points[current_point_index] + belongs.position)
					if distance > 200:
						#继续前进
						velocity = -(position - belongs.points[current_point_index] - belongs.position).normalized() * 40
						#get_parent().get_parent()._focus_sprite(true,belongs.io_list[current_point_index].position - belongs.position)
					# 到点了，继续转圈
					else:
						current_point_index += 1
						if current_point_index >= belongs.points.size():
							current_point_index = 0
				# 不是环岛，不需要按路径前进，向目标奔去
				else:
					velocity = -(position - belongs.io_list[target_point_index].position - belongs.position).normalized() * 40
			
				
	
	self.position += velocity * delta





var velocity:Vector2 = Vector2(0,0)
