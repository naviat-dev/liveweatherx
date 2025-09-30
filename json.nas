var MAX_DEPTH = 50;

var parse = func(s) {
	if (utf8.size(s) < 1) die("JSON parse error: string is empty"); 

	var depth = 0;

	# These variables are updated by the next() funtion
	var parsing = 1;
	var i = 0;
	var linenum = 1;
	var colnum = 1;
	var c = utf8.strc(s, i);

	var next = func(assert=1) {
		i += 1;
		if (i >= utf8.size(s)) {
			if (assert) die("JSON: unexpected end of input");
			c = nil;
			parsing = 0;
			return;
		}
		c = utf8.strc(s, i);

		colnum += 1;
		if (c == `\n`) {
			linenum += 1;
			colnum = 1;
		}
		#printpos();
	}

	var skipws = func() {
		while (parsing) {
			if (!string.isxspace(c)) return;
			next(0);
		}
	}

	# DEBUG

	var printpos = func(tag = "") {
		print("[" ~ tag ~ "]  Line: " ~ linenum ~ "  Col: " ~ colnum ~ "  Position: " ~ i ~ "  Character: " ~ debug.string(utf8.chstr(c)));
	}

	# Parsing functions.

	var parse_object = func {
		var object = {};
		if (c != `{`) die("JSON: An internal error occured while trying to read object");
		next();
		skipws();
		if (c != `}`) while (1) {
			skipws();
			var key = parse_string();
			skipws();

			if (c == `:`) next();
			else die("JSON parse error on line " ~ linenum ~ ". Unexpected character \"" ~ utf8.chstr(c) ~"\". Missing colon after member key?");

			object[key] = parse_element();

			if (c == `,`) next()
			elsif (c == `}`) break;
			else die("JSON parse error on line " ~ linenum ~ ". Unexpected character \"" ~ utf8.chstr(c) ~"\". Missing comma or closing bracket after object member?");
		}
		next(0);
		return object;
	}

	var parse_array = func {
		var array = [];
		if (c != `[`) die("JSON: An internal error occured while trying to parse array");
		next();
		skipws();

		if (c != `]`) while (1) {
			append(array, parse_element());

			if (c == `,`) next();
			elsif (c == `]`) break;
			else die("JSON parse error on line " ~ linenum ~ ". Unexpected character \"" ~ utf8.chstr(c) ~"\". Missing comma or closing bracket after array element?");
		}

		next(0);
		return array;
	}

	var parse_string = func { # TODO: unicode escapes
		var ESCAPES = {
			`"`: `"`,
			`n`: `\n`,
			`\\`: `\\`,
			`/`: `/`,
			`b`: 8,
			`f`: 12,
			`n`: `\n`,
			`r`: `\r`,
			`t`: `\t`
		};

		var string = "";
		if (c != `"`) die("JSON: An internal error occured while trying to parse string");
		next();

		for (; c != `"`; next()) {
			if (c == `\\`) {
				next();
				print("escaping: " ~ utf8.chstr(c));
				if (contains(ESCAPES, c)) string = string ~ utf8.chstr(ESCAPES[c]);
				else die("JSON parse error on line " ~ linenum ~ " (invalid string escape)");
			} else {
				string = string ~ utf8.chstr(c); # Optimize this?
			}
		}
		next(0);
		return string;
	}

	var parse_number = func { # Maybe make this more strict?
		var numstr = "";
		while (parsing) {
			if (string.isdigit(c) or c == `.` or c == `-` or c == `+` or c == `e` or c == `E`) numstr = numstr ~ utf8.chstr(c);
			else break;
			next(0);
		}
		var n = num(numstr);
		if (num != nil) return n;
		else die("JSON parse error on line " ~ linenum ~ ". Could not parse number.");
	}

	var parse_constant = func(test, result) {
		for (var ti = 0; parsing and ti < size(test); ti += 1) {
			tc = utf8.strc(test, ti);
			if (c != tc) die("JSON parse error on line " ~ linenum ~ ". Did you mean \"" ~ test ~ "\"?");
			next(0);
		}
		return result;
	}

	var parse_element = func {
		depth += 1;
		if (depth > MAX_DEPTH) die("JSON error: too deep");

		skipws();

		var value = nil;
		if    (c == `{`) value = parse_object();
		elsif (c == `[`) value = parse_array();
		elsif (c == `"`) value = parse_string();
		elsif (string.isdigit(c) or c == `-`) value = parse_number();
		elsif (c ==  `t`) value = parse_constant("true", 1);
		elsif (c == `f`) value = parse_constant("false", 0);
		elsif (c == `n`) value = parse_constant("null", nil);
		else die("JSON parse error on line " ~ linenum ~ ". Unknown element");

		skipws();
		depth -= 1;
		return value;
	}

	var val = parse_element();
	if (parsing) die("JSON parse error on line " ~ linenum ~ ". Excepted end of input but got more data");
	return val;
}

var test = func(path) {
	var output = nil;
	debug.benchmark("JSON TEST", func {
		output = parse(io.readfile(path));
	});
	debug.dump(output);
}
