package classes.engine
{
	import com.adobe.utils.StringUtil;
	
	public class EngineLanguage
	{
		
		public var data:Object;
		public var indexed:Array;
		
		public var id:String;
		public var valid:Boolean = false;
		
		public function EngineLanguage(id:String)
		{
			this.id = id;
		}
		
		public function parseData(input:String):void
		{
			input = StringUtil.trim(input);
			// Create XML Tree
			try
			{
				var xmlMain:XML = new XML(input);
				var xmlChildren:XMLList = xmlMain.children();
			}
			catch (e:Error)
			{
				trace("3:[EngineLanguage] \"" + id + "\" - Malformed XML Language");
				return;
			}
			
			// Init Data Holders
			data = new Object();
			indexed = new Array();
			
			// Parse XML Tree
			for (var a:uint = 0; a < xmlChildren.length(); ++a)
			{
				// Check for Language Object, if not, create one.
				var lang:String = xmlChildren[a].attribute("id").toString();
				if (data[lang] == null)
				{
					data[lang] = new Object();
				}
				
				// Add Attributes to Object
				var langAttr:XMLList = xmlChildren[a].attributes();
				for (var b:uint = 0; b < langAttr.length(); b++)
				{
					data[lang]["_" + langAttr[b].name()] = langAttr[b].toString();
				}
				
				// Add Text to Object
				var langNodes:XMLList = xmlChildren[a].children();
				for (var c:uint = 0; c < langNodes.length(); c++)
				{
					data[lang][langNodes[c].attribute("id").toString()] = langNodes[c].children()[0].toString();
				}
				indexed[data[lang]["_index"]] = lang;
			}
			
			valid = true;
		}
		
		public function getString(id:String, lang:String = "us"):String
		{
			if (data[lang] && data[lang][id])
			{
				return data[lang][id];
			}
			
			return "";
		}
	}

}