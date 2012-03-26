package packer;

class Packer {
	public var shrinker(default, null):Shrinker;
	public var privates(default, null):Privates;
	public var base62(default, null):Base62;
	
	public function new():Void {
		shrinker = new Shrinker();
		privates = new Privates();
		base62 = new Base62();
	}
	
	public function pack(script:String, base62:Base62, shrink:Shrinker, privates:Privates) {
		
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
			return (c < 52 ? '' : encode(Std.int(c / 52))) +
				((c = c % 52) > 25 ? String.fromCharCode(c + 39) : String.fromCharCode(c + 97));
		}
		
		var encoded = encode(c);
		if (~/^(do|if|in)$/.match(encoded)) encoded = encoded.substr(1) + 0;
		return encoded;
	}
}