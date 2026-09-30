extends RefCounted

# Safe evaluation of designer-written formulas with Godot's Expression. Formulas may only
# use their declared variables, numbers, arithmetic/comparison/logic operators and a
# whitelist of math functions; they run without a base instance, so they cannot touch
# any game object.
#
# Expression has two traps this guards against: it silently ignores trailing tokens
# ("level * 2 level" evaluates as "level * 2"), and it has no "a if c else b" (it
# evaluates to "a"). So every formula is first checked by the small parser below, which
# requires the whole text to be one well-formed expression.

const ALLOWED_FUNCTIONS := ["pow", "sqrt", "floor", "ceil", "round", "min", "max", "clamp", "abs", "lerp", "log", "exp", "int", "float"]
const WORD_OPERATORS := ["and", "or", "not"]
const LITERALS := ["true", "false"]
const COMPARISONS := ["==", "!=", "<", ">", "<=", ">="]


## Returns "" when `expr` is one well-formed formula over `vars`, else a message.
static func check(expr: String, vars: Array) -> String:
	if expr.strip_edges() == "":
		return "Công thức đang trống."
	var tokens := _tokenize(expr)
	if tokens.is_empty() or tokens[0] is String and tokens[0].begins_with("!ERR"):
		return tokens[0].substr(4) if not tokens.is_empty() else "Công thức đang trống."
	var parser := Parser.new(tokens, vars)
	parser.parse_expression()
	if parser.error == "" and parser.pos < tokens.size():
		parser.error = "Thừa '%s' ở cuối: thiếu dấu phép tính?" % tokens[parser.pos]["text"]
	return parser.error


## [Expression or null, error message].
static func compile(expr: String, vars: Array) -> Array:
	var problem := check(expr, vars)
	if problem != "":
		return [null, problem]
	var e := Expression.new()
	if e.parse(expr, PackedStringArray(vars)) != OK:
		return [null, "Sai cú pháp: " + e.get_error_text()]
	return [e, ""]


## [float value, error message]. Inputs are passed as floats so "/" never truncates.
static func run(e: Expression, vars: Array, inputs: Dictionary) -> Array:
	var args := []
	for v in vars:
		args.append(float(inputs.get(v, 0.0)))
	var result = e.execute(args, null, false)
	if e.has_execute_failed():
		return [0.0, "Lỗi khi tính: " + e.get_error_text()]
	if not (result is float or result is int or result is bool):
		return [0.0, "Kết quả không phải số."]
	var value := float(result)
	if is_nan(value) or is_inf(value):
		return [0.0, "Kết quả không hợp lệ (chia cho 0?)."]
	return [value, ""]


# Tokens are {"kind": "num"|"id"|"op", "text": String}. A tokenizing error is returned
# as a single String element starting with "!ERR".
static func _tokenize(expr: String) -> Array:
	var tokens := []
	var number := RegEx.create_from_string("^([0-9]+(\\.[0-9]*)?|\\.[0-9]+)([eE][-+]?[0-9]+)?")
	var word := RegEx.create_from_string("^[A-Za-z_][A-Za-z0-9_]*")
	var i := 0
	while i < expr.length():
		var rest := expr.substr(i)
		var c := expr[i]
		if c == " " or c == "\t" or c == "\n":
			i += 1
			continue
		var m := number.search(rest)
		if m != null:
			tokens.append({"kind": "num", "text": m.get_string()})
			i += m.get_string().length()
			continue
		m = word.search(rest)
		if m != null:
			tokens.append({"kind": "id", "text": m.get_string()})
			i += m.get_string().length()
			continue
		var two := rest.substr(0, 2)
		if two in ["==", "!=", "<=", ">=", "&&", "||"]:
			tokens.append({"kind": "op", "text": two})
			i += 2
			continue
		if c in ["+", "-", "*", "/", "%", "<", ">", "!", "(", ")", ","]:
			tokens.append({"kind": "op", "text": c})
			i += 1
			continue
		return ["!ERRKhông dùng được ký tự '%s'." % c]
	return tokens


# Recursive-descent validator. Grammar (loosest binding first):
#   or  := and (("or" | "||") and)*
#   and := not (("and" | "&&") not)*
#   not := ("not" | "!") not | cmp
#   cmp := sum (COMPARISON sum)?
#   sum := term (("+" | "-") term)*
#   term := unary (("*" | "/" | "%") unary)*
#   unary := ("-" | "+") unary | primary
#   primary := number | true | false | variable | function "(" args ")" | "(" or ")"
class Parser:
	var tokens: Array
	var vars: Array
	var pos := 0
	var error := ""

	func _init(p_tokens: Array, p_vars: Array) -> void:
		tokens = p_tokens
		vars = p_vars

	func parse_expression() -> void:
		_or()

	func _peek() -> String:
		return tokens[pos]["text"] if pos < tokens.size() else ""

	func _fail(message: String) -> void:
		if error == "":
			error = message

	func _or() -> void:
		_and()
		while error == "" and _peek() in ["or", "||"]:
			pos += 1
			_and()

	func _and() -> void:
		_not()
		while error == "" and _peek() in ["and", "&&"]:
			pos += 1
			_not()

	func _not() -> void:
		if _peek() in ["not", "!"]:
			pos += 1
			_not()
		else:
			_cmp()

	func _cmp() -> void:
		_sum()
		if error == "" and _peek() in COMPARISONS:
			pos += 1
			_sum()

	func _sum() -> void:
		_term()
		while error == "" and _peek() in ["+", "-"]:
			pos += 1
			_term()

	func _term() -> void:
		_unary()
		while error == "" and _peek() in ["*", "/", "%"]:
			pos += 1
			_unary()

	func _unary() -> void:
		if _peek() in ["-", "+"]:
			pos += 1
			_unary()
		else:
			_primary()

	func _primary() -> void:
		if pos >= tokens.size():
			_fail("Công thức bị cụt ở cuối.")
			return
		var token: Dictionary = tokens[pos]
		var text: String = token["text"]
		pos += 1
		if token["kind"] == "num" or text in LITERALS:
			return
		if text == "(":
			_or()
			if _peek() != ")":
				_fail("Thiếu dấu ')'.")
			else:
				pos += 1
			return
		if token["kind"] == "id":
			if text in ["if", "else"]:
				_fail("Không hỗ trợ 'if/else'. Dùng int(điều kiện), ví dụ: 1 + int(x >= 0.5)")
			elif text in ALLOWED_FUNCTIONS:
				if _peek() != "(":
					_fail("Hàm '%s' cần dấu '(' ngay sau." % text)
					return
				pos += 1
				if _peek() != ")":
					_or()
					while error == "" and _peek() == ",":
						pos += 1
						_or()
				if _peek() != ")":
					_fail("Thiếu dấu ')' của hàm '%s'." % text)
				else:
					pos += 1
			elif text in vars:
				if _peek() == "(":
					_fail("'%s' là biến, không gọi như hàm được." % text)
			else:
				_fail("Không dùng được '%s'. Biến có sẵn: %s" % [text, ", ".join(vars)])
			return
		_fail("Không mong đợi '%s' ở đây." % text)
