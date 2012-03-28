package packer;

class Privates extends Encoder {
	static var IGNORE = [
		new RegGrpItem("CONDITIONAL", RegGrp.IGNORE),
		new RegGrpItem("(OPERATOR)(REGEXP)", RegGrp.IGNORE)
	];
	static var PATTERN = "\\b_[\\da-zA-Z$][\\w$]*\\b";
	
	public function new():Void {
		super(PATTERN, function(index){
			return "_" + Packer.encode62(index);
		}, IGNORE);
	}
	
	override public function search(script:String):Words {
		var words = super.search(script);
		
		if (words.index.exists("_private")) {
			var _private = words.array[words.index.get("_private")];
			_private.count = 99999;
		}
		
		return words;
	}
}