package packer;

class WordsItem {
	var word:String;
	public var index:Int;
	public var count:Int;
	public var encoded:String;
	
	public function new(word:String):Void {
		this.word = word;
		count = 0;
		index = 0;
		encoded = "";
	}
	
	public function toString():String {
		return word;
	}
}