public class JSONParser {
	
	public String encoding;
	public Integer maxBatchSize;
	public List<Sobjects> sobjects;
	
	public class Sobjects {
		public Boolean activateable;
		public Boolean createable;
		public Boolean custom;
		public Boolean customSetting;
		public Boolean deletable;
		public Boolean deprecatedAndHidden;
		public Boolean feedEnabled;
		public Object keyPrefix;
		public String label;
		public String labelPlural;
		public Boolean layoutable;
		public Boolean mergeable;
		public String name;
		public Boolean queryable;
		public Boolean replicateable;
		public Boolean retrieveable;
		public Boolean searchable;
		public Boolean triggerable;
		public Boolean undeletable;
		public Boolean updateable;
	}
	
	public static JSONParser parse(String json) {
		return (JSONParser) System.JSON.deserialize(json, JSONParser.class);
	}
}