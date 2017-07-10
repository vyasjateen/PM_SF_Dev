public with sharing class ChildWrapper implements ComponentWrapperIntf {
	public String name { get; set; }
	public String label { get; set; }
	public String relationshipFieldName { get; set; }
	public String relationshipName { get; set; }
	public String namespace { get; set; }
	public Boolean isSelected { get; set; }
	
	public String getLabel() {
		return label;
	}
}