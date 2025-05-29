extends Node

var random_key = 467

func _ready() -> void:
	var arr = [1,2,3,5123,5143,5323,6123]
	var enc_arr = []
	for i in arr:
		enc_arr.append(enc(i))
	
	# 查询
	var bob = enc(5122)
	var alice = enc(5150)
	print(query(bob,alice,enc_arr))
	


func f(index:int) -> int:
#	if randarr.size() > index:
#		return randarr[index]
	seed(index + random_key)
	return randi()
	
const MAX_LENGTH = 4

# 使用示例
func enc(num:int) -> String:
	var bit_sequence = get_bit_sequence(num)
	var bit_str := array_to_string(bit_sequence)
	#print("整数", num, "的比特序列是：", bit_str)
	# 空随机输入
	var enc_bits = str(f(-1) % 9 + int(bit_str[0]))
	# 正式输入
	for length in range(1,bit_sequence.size()):
		enc_bits += str(f(int(bit_str.substr(0,length))) % 9 + int(bit_str[length]))
	print("整数 ", num, "		加密得到", enc_bits)
	return enc_bits


func get_bit_sequence(number:int) -> PackedInt32Array:
	var snum = str(number)
	if snum.length() < MAX_LENGTH:
		for i in range(MAX_LENGTH - snum.length()):
			snum = "0" + snum
	var result := PackedInt32Array()
	for single_num in snum:
		result.append_array(_get_bit_sequence(int(single_num)))
	return result
	
func _get_bit_sequence(number:int) -> PackedInt32Array:
	var divider := 8
	var result := PackedInt32Array()
	while true:
		if number >= divider:
			number -= divider
			result.append(1)
		else:
			result.append(0)
		if divider != 1:
			divider /= 2
		else:
			break
	return result

func array_to_string(arr:PackedInt32Array) -> String:
	var bit_str := String()
	for i in arr:
		bit_str += str(i)
	return bit_str

func query(enca:String, encb:String, arr:Array) -> PackedStringArray:
	var result := []
	for i in arr:
		if test(i,enca) and test(encb,i):
			result.append(i)
	return result

func test(a:String, b:String) -> bool:
	for i in a.length():
		# 第一个不相同字符
		if a[i] != b[i]:
			if a[i] > b[i]:
				return true
			else:
				return false
	return false
