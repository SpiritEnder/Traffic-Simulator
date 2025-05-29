class_name PathFinder extends Node


func dijkstra(network: TrafficGraph, car:Car) -> Array:
	var first_point:IOPoint
	if car.forward_direction == 0:
		first_point = car.start_road.get_end_pair()
	else:
		first_point = car.start_road.get_start_pair()
	
	var heap: Array = [[0, first_point.parent(), []]] # [ (cost, current_node, path) ]
	var visited: Array = []
	
	while heap.size() > 0:
		var heap_element = heap[0]
		var cost:float = heap_element[0]
		var current:Intersection = heap_element[1]
		var path:Array = heap_element[2]
		
		heap.pop_front()
		
		if visited.has(current):
			continue
		else:
			visited.append(current)
		
		if network.graph_intersections.has(current):
			for iop in current.io_list:
				if iop.pair == null:
					continue
				var linked_road:Road = iop.pair.parent()
				var neighbor_iop = linked_road.get_another_pair(iop.pair)
				if neighbor_iop == null:
					continue
				
				var neighbor:Intersection = neighbor_iop.parent()
				var edge_cost = linked_road.road_length
						
				if linked_road == car.end_road:
					path.append(iop.get_self_index())
					return path
				
				if not visited.has(neighbor):
					var new_cost = cost + edge_cost
					var new_path = path.duplicate(true)
					new_path.append(iop.get_self_index())
					heap.append([new_cost, neighbor, new_path])
					heap.sort_custom(func(a: Array, b: Array) -> int:
						return a[0] - b[0]
					)
	return []

# 示例用法
#func ready() -> void:
	#var net = RoadNetwork.new()
	#net.add_intersection("A", Vector2(0, 0), "cross")
	#net.add_intersection("B", Vector2(1, 0), "cross")
	#net.add_intersection("C", Vector2(1, 1), "roundabout")
#
	#net.add_road("AB", "A", "B", true)
	#net.add_road("BC", "B", "C", true)
	#net.add_road("CD", "C", "D", false)
	#
	#var result = dijkstra(net, "A", "C")
	#print("Shortest path from A to C:", result)
