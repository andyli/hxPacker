package packer;

class Parser extends RegGrp {
	public function new(?values:Iterable<RegGrpItem>, ?ignoreCase:Bool):Void {
		super(values, ignoreCase);
	}
	
	override public function add(item:RegGrpItem):Void {
		var expression = item.toString();
		expression = Parser.dictionary.exec(expression);
		super.add(new RegGrpItem(expression, item.replacement));
	}
	
	static public var dictionary = new RegGrp([
		new RegGrpItem("OPERATOR", function(a) return "return|typeof|[\\[(\\^=,{}:;&|!*?]"),
		new RegGrpItem("CONDITIONAL", function(a) return "\\/\\*@\\w*|\\w*@\\*\\/|\\/\\/@\\w*|@\\w+"),
		new RegGrpItem("COMMENT1", function(a) return "\\/\\/[^\\n]*"),
		new RegGrpItem("COMMENT2", function(a) return "\\/\\*[^*]*\\*+([^\\/][^*]*\\*+)*\\/"),
		new RegGrpItem("REGEXP", function(a) return "\\/(\\\\[\\/\\\\]|[^*\\/])(\\\\.|[^\\/\\n\\\\])*\\/[gim]*"),
		new RegGrpItem("STRING1", function(a) return "'(\\\\.|[^'\\\\])*'"),
		new RegGrpItem("STRING2", function(a) return '"(\\\\.|[^"\\\\])*"')
	]);
}