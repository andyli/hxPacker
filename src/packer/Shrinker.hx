package packer;

class Shrinker {
	static var PREFIX = "\x02";
	static var SHRUNK = "\\x02\\d+\\b";
	
	var _data:Array<String>;
	
	public function new():Void {
		
	}
	
	public function decodeData(script:String):String {
		// put strings and regular expressions back
		var data = _data; // encoded strings and regular expressions
		_data = null;
		return ~/\x01(\d+)\x01/g.map(script, function(r) {
			return data[Std.parseInt(r.matched(1))];
		});
	}
	
	public function encodeData(script:String):String {
		// encode strings and regular expressions
		var data = _data = []; // encoded strings and regular expressions
		return Packer.data.exec(script, function(a){
			var replacement = "\x01" + data.length + "\x01",
				match = a[0],
				regexp = a[2];
			if (regexp != null && regexp != "") {
				replacement = a[1] + replacement;
				match = regexp;
			}
			data.push(match);
			return replacement;
		});
	}
	
	public function shrink(script:String):String {
		script = encodeData(script);
		
		// identify blocks, particularly identify function blocks (which define scope)
		var BLOCK         = ~/((catch|do|if|while|with|function)\b[^~{};]*(\(\s*[^{};]*\s*\))\s*)?(\{[^{}]*\})/g;
		var BRACKETS      = ~/\{[^{}]*\}|\[[^\[\]]*\]|\([^\(\)]*\)|~[^~]+~/;
		var BRACKETS_g    = ~/\{[^{}]*\}|\[[^\[\]]*\]|\([^\(\)]*\)|~[^~]+~/g;
		var ENCODED_BLOCK = ~/~#?(\d+)~/g;
		var IDENTIFIER    = ~/[a-zA-Z_$][\w\$]*/g;
		var SCOPED        = ~/~#(\d+)~/g;
		var VAR_g         = ~/\bvar\b/g;
		var VARS          = ~/\bvar\s+[\w$]+[^;#]*|\bfunction\s+[\w$]+/g;
		var VAR_TIDY      = ~/\b(var|function)\b|\sin\s+[^;]+/g;
		var VAR_EQUAL     = ~/\s*=[^,;]*/g;
		
		var blocks = []; // store program blocks (anything between braces {})
		// decoder for program blocks
		function decodeBlocks(script:String, encoded:EReg) {
			while (encoded.match(script)) {
				script = encoded.map(script, function(r){
					return blocks[Std.parseInt(r.matched(1))];
				});
			}
			return script;
		}
		
		var total = 0;
		// encoder for program blocks
		function encodeBlocks(r:EReg):String {
			var	prefix = matchedOrNull(r, 1), 
				blockType = matchedOrNull(r, 2), 
				args = matchedOrNull(r, 3), 
				block = matchedOrNull(r, 4),
				replacement;
			if (prefix == null) prefix = "";
			if (blockType == "function") {
				// decode the function block (THIS IS THE IMPORTANT BIT)
				// We are retrieving all sub-blocks and will re-parse them in light
				// of newly shrunk variables
				block = args + decodeBlocks(block, SCOPED);
				prefix = BRACKETS.replace(prefix, "");
				// create the list of variable and argument names
				args = args.substr(1, args.length-2);
				
				var vars = null;
				if (args != "_no_shrink_") {
					vars = VAR_g.replace(eregAllMatched(VARS, block).join(";"), ";var");
					while (BRACKETS.match(vars)) {
						vars = BRACKETS_g.replace(vars, "");
					}
					vars = VAR_TIDY.replace(vars, "");
					vars = VAR_EQUAL.replace(vars, "");
				}
				block = decodeBlocks(block, ENCODED_BLOCK);
				
				// process each identifier
				if (args != "_no_shrink_") {
					var count = 0, shortId;
					var ids = eregAllMatched(IDENTIFIER, args + "," + vars);
					var processed = new Map<String,Bool>();
					for (id in ids) {
						if (!processed.exists(id)) {
							processed.set(id, true);
							id = ~/([\/()[\]{}|*+-.,^$?\\])/g.replace(id, "\\$1");
							// encode variable names
							while (new EReg(Shrinker.PREFIX + count + "\\b", "").match(block)) ++count;
							var reg = new EReg("([^\\w$.])" + id + "([^\\w$:])", "");
							var reg_g = new EReg("([^\\w$.])" + id + "([^\\w$:])", "g");
							while (reg.match(block)) {
								block = reg_g.replace(block, "$1" + Shrinker.PREFIX + count + "$2");
							}
							block = new EReg("([^{,\\w$.])" + id + ":", "g").replace(block, "$1" + Shrinker.PREFIX + count + ":");
							++count;
						}
					}
					total = cast Math.max(total, count);
				}
				replacement = prefix + "~" + blocks.length + "~";
				blocks.push(block);
			} else {
				replacement = "~#" + blocks.length + "~";
				blocks.push(prefix + block);
			}
			return replacement;
		}
		
		// encode blocks, as we encode we replace variable and argument names
		while (BLOCK.match(script)) {
			script = BLOCK.map(script, encodeBlocks);
		}
		
		// put the blocks back
		script = decodeBlocks(script, ENCODED_BLOCK);
		
		var shortId, count = 0;
		var shrunk = new Encoder(Shrinker.SHRUNK, function(i:Int):String {
			// find the next free short name
			do {
				shortId = Packer.encode52(count++);
			} while (new EReg("[^\\w$.]" + shortId + "[^\\w$:]", "").match(script));
			return shortId;
		});
		script = shrunk.encode(script);
		
		return decodeData(script);
	}
	
	static function matchedOrNull(r:EReg, n:Int):Null<String> {
		try {
			return r.matched(n);
		} catch(e:Dynamic) {
			return null;
		}
	}
	
	static function eregAllMatched(r:EReg, m:String):Array<String> {
		var a = [];
		r.map(m, function(r){
			a.push(r.matched(0));
			return "";
		});
		return a;
	}
}