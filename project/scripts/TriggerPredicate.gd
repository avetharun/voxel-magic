# Generic runtime entity/node filtering
class_name TriggerPredicate extends Resource
enum TriggerOperation { OR, AND, NOT }
func _init(_name:String, _predicate:Predicate) -> void:
	self.name = _name
	self.predicate = _predicate
var name : String
var predicate : Predicate
var next : TriggerPredicate
var operation : TriggerOperation
static var custom_filters : Dictionary[StringName, TriggerPredicate] = {}
static func get_filter(_name:StringName) -> TriggerPredicate:
	match _name:
		"false": return _FilterAlwaysFalse
		"true": return _FilterAlwaysTrue
		"node_property": return _FilterNodeProperty
		_: return custom_filters.get(_name, null)
static func register_filter(_name:StringName, filter:TriggerPredicate):
	custom_filters[_name] = filter
static func clear_custom_filters():
	custom_filters.clear()
func _to_string() -> String:
	if operation == TriggerOperation.NOT:
		return "not %s%s" %[name, "" if next==null else next._to_string()]
	return "%s %s %s" %[name, TriggerOperation.keys()[operation] if next != null else "", "" if next==null else next._to_string()]

static func _Tokenize(expr : String) -> Array[String]:
	var result : Array[String] = []
	var sb : String = ""

	for c in expr:
		if c == " ":
			if sb.length() > 0:
				result.push_back(sb)
				sb = ""
		elif c in ["(", ")", ","]:
			if sb.length() > 0:
				result.push_back(sb)
				sb = ""
			result.push_back(c)
		else:
			sb += c

	if sb.length() > 0:
		result.push_back(sb)

	return result
static func _ParseArgs() -> Array[String]:
	var args : Array[String] = []
	if __tokens[__index] != "(":
		return args

	__index += 1

	while __index < __tokens.size() and __tokens[__index] != ")":
		var tok = __tokens[__index]
		if tok != ",":
			args.append(tok)
		__index += 1

	if __index < __tokens.size() and __tokens[__index] == ")":
		__index += 1

	return args

static var __index:int = 0
static var __tokens:Array[String] = []
static func _ParsePrimary() -> TriggerPredicate:
	var filter : TriggerPredicate = null

	if __index >= __tokens.size():
		print("Unexpected end of expression")
		return _FilterInvalidExpression

	if __tokens[__index] == "not":
		__index += 1
		var inner := _ParsePrimary()
		filter = TriggerPredicate.new(inner.name, inner.predicate)
		filter.operation = TriggerOperation.NOT
		return filter if filter != null else _FilterInvalidExpression

	if __tokens[__index] == "(":
		__index += 1
		var inner = _ParseOr()
		if __index >= __tokens.size() or __tokens[__index] != ")":
			print("Missing closing parenthesis")
			return _FilterInvalidExpression
		__index += 1
		return inner if inner != null else _FilterInvalidExpression

	var filter_name = __tokens[__index]
	__index += 1
	var args : Array[String] = []
	if __index < __tokens.size() and __tokens[__index] == "(":
		args = _ParseArgs()

	filter = get_filter(filter_name)
	if filter == null:
		print("Unknown filter: %s" % filter_name)
		return _FilterInvalidExpression
	#var new_filter = TriggerPredicate.new(filter.name, filter.predicate)
	#new_filter.predicate.set_params(args)
	var pred = filter.predicate
	var new_pred = null

	if pred is FuncPredicate:
		new_pred = FuncPredicate.new(pred._func)
	elif pred is AlwaysTruePredicate:
		new_pred = AlwaysTruePredicate.new()
	elif pred is AlwaysFalsePredicate:
		new_pred = AlwaysFalsePredicate.new()
	else:
		new_pred = Predicate.new()

	var new_filter = TriggerPredicate.new(filter.name, new_pred)
	new_filter.predicate.set_params(args)


	return new_filter if new_filter != null else _FilterInvalidExpression

static func _ParseAnd() -> TriggerPredicate:
	var left := _ParsePrimary()
	while (__index < __tokens.size() and __tokens[__index] == "and"):
		__index+=1
		var right := _ParsePrimary()
		left = TriggerPredicate.new(left.name, left.predicate)
		left.operation = TriggerOperation.AND
		left.next = right
	return left if left != null else _FilterInvalidExpression
static func _ParseOr() -> TriggerPredicate:
	var left := _ParseAnd()
	while (__index < __tokens.size() and __tokens[__index] == "or"):
		__index+=1
		var right := _ParseAnd()
		left = TriggerPredicate.new(left.name, left.predicate)
		left.operation = TriggerOperation.OR
		left.next = right
	return left if left != null else _FilterInvalidExpression
static func parse_expression(expression:String):
	__tokens = _Tokenize(expression.to_lower())
	var _out = _ParseOr()
	__tokens.clear()
	__index = 0
	return _out if _out != null else _FilterInvalidExpression
func is_valid(node:Node) -> bool:
	match operation:
		TriggerOperation.AND: 
			var _ret : bool = predicate.passes(node)
			if next and next.predicate: _ret = _ret and next.is_valid(node)
			return _ret
		TriggerOperation.OR:
			var _ret : bool = predicate.passes(node)
			if next and next.predicate: _ret = _ret or next.is_valid(node)
			return _ret
		TriggerOperation.NOT: return not predicate.passes(node)
		_: return false

class Predicate:
	var params : Array[String] = []
	func set_params(p:Array[String]):
		params = p
	func get_params() -> Array[String]:
		return params
	func passes(node:Node):return node != null
class FuncPredicate extends Predicate:
	func _init(__func:Callable) -> void:
		self._func = __func
	@export var _func : Callable
	func passes(node:Node):
		return _func.call(node, params)
class InvertedPredicate extends Predicate:
	var predicate : Predicate
	func _init(_predicate:Predicate):
		self.predicate = _predicate
	func passes(node:Node):
		return not self.predicate.passes(node) if predicate != null else true
class AlwaysFalsePredicate extends Predicate:func passes(node:Node):return false
class AlwaysTruePredicate extends Predicate:func passes(node:Node):return true


static func _parse_game_value_expression(expr: String) -> Dictionary:
	var ops = ["==", "!=", "<=", ">=", "<", ">", "is_null", "not_null", "is_absent", "is_present"]

	for op in ops:
		if expr.contains(op):
			var parts = expr.split(op, false, 1)
			var key = parts[0].strip_edges()
			var value = parts[1].strip_edges() if parts.size() > 1 else ""
			return {
				"key": key,
				"op": op,
				"value": value
			}
	return {
		"key": expr.strip_edges(),
		"op": "is_present",
		"value": ""
	}
static func _cast_value(val: String) -> Variant:
	val = _strip_quotes(val)
	if val.begins_with("int(") and val.ends_with(")"):
		return int(val.substr(4, val.length() - 5))

	if val.begins_with("float(") and val.ends_with(")"):
		return float(val.substr(6, val.length() - 7))

	if val.begins_with("bool(") and val.ends_with(")"):
		var inner = val.substr(5, val.length() - 6).to_lower()
		return inner == "true"
	
	var lower = val.to_lower()

	if lower == "true": return true
	if lower == "false": return false

	if val.is_valid_int(): return int(val)
	if val.is_valid_float(): return float(val)

	return val  # default: string
static func _compare_values(actual: Variant, op: String, expected: Variant) -> bool:
	if typeof(actual) == typeof(expected):
		match op:
			"==": return actual == expected
			"!=": return actual != expected
			"<":  return actual < expected
			">":  return actual > expected
			"<=": return actual <= expected
			">=": return actual >= expected
			_: return false
	return false
static func _strip_quotes(val: String) -> String:
	if val.length() >= 2 and val[0] == '"' and val[val.length() - 1] == '"':
		return val.substr(1, val.length() - 2)
	return val

func invert(new_name:String = "not_"+name) -> TriggerPredicate:
	return TriggerPredicate.new(new_name, InvertedPredicate.new(predicate))
	

static var _FilterAlwaysFalse := TriggerPredicate.new("false", AlwaysFalsePredicate.new())
static var _FilterAlwaysTrue := TriggerPredicate.new("true", AlwaysTruePredicate.new())
static var _FilterInvalidExpression := TriggerPredicate.new("invalid_expression", AlwaysFalsePredicate.new())

static var _FilterNodeProperty := TriggerPredicate.new("node_property", FuncPredicate.new(func(node : Node, params):
	var game_values = node.get_property_list()
	if params.size() == 0:
		return !game_values.is_empty()

	var expr: String = params[0]

	# Parse operator
	var parsed = TriggerPredicate._parse_game_value_expression(expr)
	var key = parsed["key"]
	var op = parsed["op"]
	var raw_value = parsed["value"]

	var has_key = key in node
	var actual = node.get(key) if has_key else null
	#print(op, " ", has_key)
	# Presence operators
	match op:
		"is_null": return actual == null
		"not_null": return actual != null
		"is_absent": return !has_key
		"is_present": return has_key

	# Comparison operators
	if not has_key:
		return false

	var expected = TriggerPredicate._cast_value(raw_value)

	return TriggerPredicate._compare_values(actual, op, expected)
))
