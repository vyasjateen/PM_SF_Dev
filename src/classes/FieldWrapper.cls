public with sharing class FieldWrapper implements ComponentWrapperIntf {
	public String name { get; set; }
	public String localName { get; set; }
	public String namespace { get; set; }
	public String label { get; set; }
	public String ftype { get; set; }
    public String fixedValueInput { get; set; }

	public Boolean isCustom { get; set; }
	public Boolean isLookup { get; set; }
	public Boolean isUpdateable { get; set; }
    public Boolean isSelectedExternalId { get; set; }
	public Boolean isSelected { get; set; }
	public Boolean isCreateMissing { get; set; }
    public Boolean isSyncPicklistValues { get; set; }
    public Boolean isSetEmpty { get; set; }
    public Boolean isScrambleValue { get; set; }
    public Boolean isFixedValue { get; set; }
    public Boolean isSystemField { get; set; }
    public Boolean isScrambleSupportedType { get; set; }
	
	public String getLabel() {
		return label;
	}
}