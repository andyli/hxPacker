package packer;

using Lambda;

class Words {
	public var index(default, null):Hash<Int>;
	public var array(default, null):Array<WordsItem>;
	public var length(default, null):Int;
	
	public function new(?words:Iterable<WordsItem>):Void {
		length = 0;
		index = new Hash<Int>();
		array = [];
		
		if (words != null) {
			for (word in words) {
				var w = new WordsItem(word.toString());
				w.count = word.count;
				add(w);
			}
		}
	}
	
	public function iterator() {
		return array.iterator();
	}
	
	public function add(word:WordsItem):WordsItem {
		var w = word.toString();
		if (!index.exists(w)) {
			index.set(w, length);
			array.push(word);
			word.index = length;
			++length;
		} else {
			word = array[index.get(w)];
		}
	    
	    word.count++;
		return word;
	}
	
	public function sort(?sorter:WordsItem->WordsItem->Int) {
		array.sort(sorter == null ? function(word1,word2){
			// sort by frequency
			var dc = word2.count - word1.count;
			return dc != 0 ? dc : word1.index - word2.index;
		} : sorter);
		
		var i = 0;
		for (w in array) {
			index.set(w.toString(), i++);
		}
	}
	
	public function slice(pos:Int, ?end:Null<Int>):Words {
		return new Words(array.slice(pos, end));
	}
}