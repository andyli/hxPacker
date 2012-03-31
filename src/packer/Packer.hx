package packer;

class Packer {
	public var minifier(default, null):Minifier;
	public var shrinker(default, null):Shrinker;
	public var privates(default, null):Privates;
	public var base62(default, null):Base62;
	
	public function new():Void {
		minifier = new Minifier();
		shrinker = new Shrinker();
		privates = new Privates();
		base62 = new Base62();
	}
	
	public function pack(script:String, base62:Bool, shrink:Bool, privates:Bool) {
		script = this.minifier.minify(script);
		if (shrink) script = this.shrinker.shrink(script);
  		if (privates) script = this.privates.encode(script);
  		if (base62) script = this.base62.encode(script);
  		return script;
	}
	
	static public var version = "3.1";
	
	static public var data = new Parser([
		new RegGrpItem("STRING1", RegGrp.IGNORE),
		new RegGrpItem('STRING2', RegGrp.IGNORE),
		new RegGrpItem("CONDITIONAL", RegGrp.IGNORE), // conditional comments
		new RegGrpItem("(OPERATOR)\\s*(REGEXP)", function(a) return a[1] + a[2])
	]);
	
	static public function encode52(c):String {
		// Base52 encoding (a-Z)
		function encode(c:Int):String {
			var _c = c % 52;
			return	(c < 52 ? '' : encode(Std.int(c/52))) +
        			(_c > 25 ? String.fromCharCode(_c + 39) : String.fromCharCode(_c + 97));
		}
		
		var encoded = encode(c);
		if (~/^(do|if|in)$/.match(encoded)) encoded = encoded.substr(1) + 0;
		return encoded;
	}
	
	static public function encode62(c:Int) {
		var _c = c % 62;
		return	(c < 62 ? '' : encode62(Std.int(c/62))) + 
				(_c > 35 ? String.fromCharCode(_c + 29) : toRadix(_c, 36));
	}
	
	static public function toRadix(N:Float, radix:Int):String {
		var HexN = "", Q:Float = Math.floor(Math.abs(N)), R;
		while (true) {
			R = Q % radix;
			
			HexN = "0123456789abcdefghijklmnopqrstuvwxyz".charAt(Std.int(R)) + HexN;
			Q = (Q - R) / radix;
			if (Q == 0) break;
		}
		return ((N < 0) ? "-" + HexN : HexN);
	}
}