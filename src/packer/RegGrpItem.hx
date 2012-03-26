package packer;

class RegGrpItem {
	public function new(expression:String, ?replace:Replace):Void {
	    this.length = RegGrp.count(expression);
	    this.replacement = replace == null ? RegGrp.IGNORE : replace;
	    this.expression = expression;
	}
	
	var expression:String;
	
	public var length(default, null):Int;
	public var replacement(default, null):Replace;
	
	public function toString():String {
		return expression;
	}
}