public with sharing class ParentWrapper implements ComponentWrapperIntf {
	public String name { get; set; }
	public String label { get; set; }
	public String parentName { get; set; }
	public String parentLabel { get; set; }
	public Boolean isSelected { get; set; }
	public Boolean isDisabled { get; set; }
	public Boolean isPolymorphic { get; set; }
	
	public String getLabel() {
		return label;
	}
}