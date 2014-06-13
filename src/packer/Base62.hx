package packer;

using Lambda;

class Base62 extends Encoder {	
	public function new():Void {
		super();
	}
	
	override public function encode(script:String):String {
		var words = search(script);
		
		words.sort();
		
		var encoded = new Map<String,Int>();
		for (i in 0...words.length) {
			encoded.set(Packer.encode62(i), i);
		}
		
		function replacement(r:EReg) {
			return words.array[words.index.get(r.matched(0))].replacement;
		}
		
		var index = 0;
		for (word in words) {
			if (encoded.exists(word.toString())) {
				word.index = encoded.get(word.toString());
				word.word = "";
			} else {
				while(words.index.exists(Packer.encode62(index))) ++index;
				word.index = index++;
				if (word.count == 1) {
					word.word = "";
				}
			}
			word.replacement = Packer.encode62(word.index);
			if (word.replacement.length == word.toString().length) {
				word.word = "";
			}
		}
		
		// sort by encoding
	    words.sort(function(word1:WordsItem, word2:WordsItem) {
	      return word1.index - word2.index;
	    });
	    
	    // trim unencoded words
	    words = words.slice(0, getKeyWords(words).split("|").length);
	    
	    script = getPattern(words).map(script, replacement);
	    
	    /* build the packed script */
	    
	    var p = escape(script);
	    var a = "[]";
	    var c = getCount(words);
	    var k = getKeyWords(words);
	    var e = getEncoder(words);
	    var d = getDecoder(words);
	
	    // the whole thing
	    return 'eval(function(p,a,c,k,e,r){e=$e;if(\'0\'.replace(0,e)==0){while(c--)r[e(c)]=k[c];k=[function(e){return r[e]||e}];e=function(){return\'$d\'};c=1};while(c--)if(k[c])p=p.replace(new RegExp(\'\\\\b\'+e(c)+\'\\\\b\',\'g\'),k[c]);return p}(\'$p\',$a,$c,\'$k\'.split(\'|\'),0,{}))';
	}
	
	override public function search(script:String):Words {
		var words = new Words();
		~/\b[\da-zA-Z]\b|\w{2,}/g.map(script, function(r) {
			words.add(new WordsItem(r.matched(0)));
			return "";
		});
		return words;
	}
	
	public function escape(script:String):String {
		return ~/[\r\n]+/g.replace(~/([\\'])/g.replace(script, "\\$1"), "\\n");
	}
	
	public function getCount(words:Words):Int {
		return cast Math.max(words.length, 1);
	}
	
	public function getDecoder(words:Words):String {
		// returns a pattern used for fast decoding of the packed script
		var trim = new RegGrp([
			new RegGrpItem("(\\d)(\\|\\d)+\\|(\\d)", function(a) return a[1]+"-"+a[3]),
			new RegGrpItem("([a-z])(\\|[a-z])+\\|([a-z])", function(a) return a[1]+"-"+a[3]),
			new RegGrpItem("([A-Z])(\\|[A-Z])+\\|([A-Z])", function(a) return a[1]+"-"+a[3]),
			new RegGrpItem("\\|", function(a) return ""),
		]);
		var pattern = trim.exec(words.map(function(word) 
			return word.toString() != "" && word.replacement != null ? word.replacement : ""
		).array().slice(0, 62).join("|"));
		
		if (pattern == "") return "^$";
		
		pattern = "[" + pattern + "]";
		
		var size = words.length;
		if (size > 62) {
			pattern = "(" + pattern + "|";
			var c = Packer.encode62(size).charAt(0);
			if (c > "9") {
				pattern += "[\\\\d";
				if (c >= "a") {
					pattern += "a";
					if (c >= "z") {
						pattern += "-z";
						if (c >= "A") {
							pattern += "A";
							if (c > "A") pattern += "-" + c;
						}
					} else if (c == "b") {
						pattern += "-" + c;
					}
				}
				pattern += "]";
			} else if (c == "9") {
				pattern += "\\\\d";
			} else if (c == "2") {
				pattern += "[12]";
			} else if (c == "1") {
				pattern += "1";
			} else {
				pattern += "[1-" + c + "]";
			}
			
			pattern += "\\\\w)";
		}
		return pattern;
	}
	
	public function getEncoder(words:Words):String {
		var size = words.length;
		return size > 10 ? size > 36 ? ENCODE62 : ENCODE36 : ENCODE10;
	}
	
	public function getKeyWords(words:Words):String {
		return ~/\|+$/.replace(words.map(function(w) return w.toString()).join("|"), "");
	}
	
	public function getPatternString(words:Words):String {
		var w = words.map(function(w) return w.toString()).join("|");
		w = ~/\|{2,}/g.replace(w, "|");
		w = ~/^\|+|\|+$/g.replace(w, "");
		
		return "\\b(" + (w == "" ? "\\x0" : w) + ")\\b";
	}
	
	public function getPattern(words:Words):EReg {
		return new EReg(getPatternString(words), "g");
	}
	
	static var ENCODE10 = "String";
	static var ENCODE36 = "function(c){return c.toString(36)}";
	static var ENCODE62 = "function(c){return(c<62?'':e(parseInt(c/62)))+((c=c%62)>35?String.fromCharCode(c+29):c.toString(36))}";
}