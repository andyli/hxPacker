package packer;

class Encoder {
	public var parser(default, null):Parser;
	public var encoder(default, null):Int->String;
	
	var regGrpItem:RegGrpItem;
	
	public function new(?pattern:String, ?encoder:Int->String, ?ignore:Iterable<RegGrpItem>) {
		parser = new Parser(ignore);
		if (pattern != null) parser.add(new RegGrpItem(pattern, function(a) return ""));
		regGrpItem = parser.list.last();
		this.encoder = encoder;
	}
	
	public function search(script:String):Words {
		var words = new Words();
		regGrpItem.replacement = function(a) {
			return words.add(new WordsItem(a[0])).toString();
		}
		parser.exec(script);
		return words;
	}
	
	public function encode(script:String):String {
		var words = search(script);
		words.sort();
		var index = 0;
		for (word in words) {
			word.encoded = encoder(index++);
		}
		regGrpItem.replacement = function(a) {
			return words.array[words.index.get(a[0])].encoded;
		}
		return parser.exec(script);
	}
}