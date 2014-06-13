package packer;

using Lambda;

class Minifier {
	public function new():Void {}
	
	public function minify(script:String):String {
		// packing with no additional options
	    script += "\n";
	    script = ~/\\\r?\n/g.replace(script, "");
	    script = Minifier.comments.exec(script);
	    script = Minifier.clean.exec(script);
	    script = Minifier.whitespace.exec(script);
	    
	    // concat untill cannot concat more
	    var concated = Minifier.concat.exec(script);
	    while (concated != script) {
	    	script = concated;
	    	concated = Minifier.concat.exec(script);
	    }
	    
	    return script;
	}
	
	static var clean = Packer.data.union(new Parser([
		new RegGrpItem("\\(\\s*([^;)]*)\\s*;\\s*([^;)]*)\\s*;\\s*([^;)]*)\\)", function(a) return "("+a[1]+";"+a[2]+";"+a[3]+")"), // for (;;) loops
		new RegGrpItem("throw[^};]+[};]", RegGrp.IGNORE), // a safari 1.3 bug
		new RegGrpItem(";+\\s*([};])", function(a) return a[1])
	]));
	
	static var concat = new Parser([
		new RegGrpItem("(STRING1)\\+(STRING1)", function(a) return a[1].substr(0,a[1].length-1) + a[3].substr(1)),
		new RegGrpItem("(STRING2)\\+(STRING2)", function(a) return a[1].substr(0,a[1].length-1) + a[3].substr(1))
	]).merge(Packer.data);
	
	static function comment2Replace(a:Array<String>):String {
		var comment = a[1], regexp = a[3] == null ? "" : a[3];
    	if (~/^\/\*@/.match(comment) && ~/@\*\/$/.match(comment)) {
        	comment = Minifier.conditionalComments.exec(comment);
    	} else {
        	comment = "";
    	}
    	return comment + " " + regexp;
    }
	
	static var comments = {
		var c = Packer.data.union(new Parser([
			new RegGrpItem(";;;[^\\n]*\\n", function(a) return ""),
			new RegGrpItem("(COMMENT1)\\n\\s*(REGEXP)?", function(a) return "\n" + (a[3] != null? a[3] : "")),
			new RegGrpItem("(COMMENT2)\\s*(REGEXP)?", comment2Replace)
		]));
		c.list.remove(Packer.data.array()[2]);
		c;
	}
	
	static var conditionalComments = Packer.data.union(new Parser([
		new RegGrpItem(";;;[^\\n]*\\n", function(a) return ""),
		new RegGrpItem("(COMMENT1)\\n\\s*(REGEXP)?", function(a) return "\n"+a[3]),
		new RegGrpItem("(COMMENT2)\\s*(REGEXP)?", function(a) return ' '+a[3])
	]));
	
	static var whitespace = {
		var w = Packer.data.union(new Parser([
			new RegGrpItem("\\/\\/@[^\\n]*\\n", RegGrp.IGNORE),
			new RegGrpItem("@\\s+\\b", function(a) return "@ "), // protect conditional comments
			new RegGrpItem("\\b\\s+@", function(a) return " @"),
			new RegGrpItem("(\\d)\\s+(\\.\\s*[a-z\\$_\\[(])", function(a) return a[1] + " " + a[2]), // http://dean.edwards.name/weblog/2007/04/packer3/#comment84066
			new RegGrpItem("([+-])\\s+([+-])", function(a) return a[1] + " " + a[2]), // c = a++ +b;
			#if !(neko || cpp || php)
			new RegGrpItem("(\\w)\\s+([\\u0080-\\uffff])", function(a) return a[1] + " " + a[2]), // http://code.google.com/p/base2/issues/detail?id=78
			#end
			new RegGrpItem("\\b\\s+\\$\\s+\\b", function(a) return " $ "), // var $ in
			new RegGrpItem("\\$\\s+\\b", function(a) return "$ "), // object$ in
			new RegGrpItem("\\b\\s+\\$", function(a) return " $"), // return $object
			new RegGrpItem("\\b\\s+\\b", function(a) return " "),
			new RegGrpItem("\\s+", function(a) return "")
		]));
		w.list.remove(Packer.data.array()[2]);
		w;
	}
	
}