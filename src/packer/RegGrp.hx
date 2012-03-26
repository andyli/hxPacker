package packer;

using Lambda;

class RegGrp {
    inline public static var IGNORE:Replace = function(a:Array<String>) return a[0];
    
    public var ignoreCase:Bool;
    public var list(default, null):List<RegGrpItem>;
    
	public function new(?values:Iterable<RegGrpItem> = null, ?ignoreCase:Bool = false):Void {
		list = new List<RegGrpItem>();
		
		if (values != null) 
			for (v in values) add(v);
		
		this.ignoreCase = ignoreCase;
	}
	
	public function test(string:String):Bool {
		// The slow way to do it. Hopefully, this isn't called too often. :-)
		return exec(string) != string;
	}
	
	public function exec(string:String, ?_override:Replace):String {
		if (list.empty()) return string;
		
		return new EReg(toString(), ignoreCase ? "i" : "")
			.customReplace(string, function(r:EReg):String {
				var offset = 1;
			    // Loop through the RegGrp items.
			    for (item in list) {
			    	var next = offset + item.length + 1;
			    	if (eregHasMatched(r, offset)) {
			    		var replacement = _override == null ? item.replacement : _override;
						return replacement(eregMatchedArray(r, offset, next));
			    	}
			    	
			    	offset = next;
			    }
			    return r.matched(0);
			});
	}
	
	public function toString():String {
		var offset = 1;
		return "(" + list.map(function(item:RegGrpItem) {
	      // Fix back references.
	      var expression = ~/\\(\d+)/.customReplace(item.toString(), function(r:EReg):String {
	        return "\\" + (offset + Std.parseInt(r.matched(1)));
	      });
	      offset += item.length + 1;
	      return expression;
	    }).join(")|(") + ")";
	}
	
	public function iterator() {
		return list.iterator();
	}
	
	public function add(item:RegGrpItem):Void {
		list.add(item);
	}
	
	public function merge(items:Iterable<RegGrpItem>):RegGrp {
		for (item in items) add(item);
		return this;
	}
	
	public function union(items:Iterable<RegGrpItem>):RegGrp {
		return new RegGrp(list).merge(items);
	}
	
	static function eregMatchedArray(ereg:EReg, from:Int, to:Int):Array<String> {
		var a = [];
		var m;
		for (i in from...to) {
			try {
				if((m = ereg.matched(i)) != null) {
					a.push(m);
				} else {
					a.push(null);
				}
			} catch (e:Dynamic) {
				a.push(null);
			}
		}
		
		return a;
	}
	
	static function eregHasMatched(ereg:EReg, n:Int):Bool {
		try {
			return ereg.matched(n) != null;
		} catch(e:Dynamic) {}
		return false;
	}
	
	// Count the number of sub-expressions in a RegExp/RegGrp.Item.
	static public function count(expression:String):Int {
		expression = ~/\\./g.replace(expression, "");
		expression = ~/\(\?[:=!]|\[[^\]]+\]/g.replace(expression, "");
		var n = 0;
		~/\(/.customReplace(expression, function(r:EReg):String {
			++n;
			return "";
		});
		return n;
	}
}