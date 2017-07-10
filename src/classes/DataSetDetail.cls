//Wrapper of Data Set
    public class DataSetDetail{
    	//
    	public Deployment_Data_Set_Result__c dataSetDetail {get; set;}
    	
    	public Boolean display {get; set;}
    	
    	public DataSetDetail(Deployment_Data_Set_Result__c dataSetDetail, Boolean display){
    		
    		this.dataSetDetail = dataSetDetail;
    		this.display = display;
    	}
    	
    }