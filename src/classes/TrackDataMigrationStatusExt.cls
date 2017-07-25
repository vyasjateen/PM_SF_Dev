/**
 * Description  :   Custom controller to implement functionality to show progress bar for the deployment progress in target org. This controller reference is on TrackDataMigrationStatus Page
 *                  
 * CreatedBy    :   Romesh Kumar
 *
 * Created Date :   01/07/2017
 *
 * Version      :   V_1.0 Created
 *
 * UpdatedBy    :   
         
 **/
public with sharing class TrackDataMigrationStatusExt {
    
    //String to hold the Deployment_Result__c id 
    public String deployResultId{get; set;}
    
    public String deployResultName{get; set;}
    
    //List to hold the Deployment results
    private List<Deployment_Result__c> deploymentResults;
    
    //List to hold the Deployment Batch results.
    public List<Deployment_Data_Set_Result__c> deployDataSetResults {get; set;}
    
    //Integer to hold the number of the data set completed
    public Integer completedDatSetCount {get; set;}
    
    //Integer too hold the Total number of data set to be completed
    public Integer totalDataSetCount {get; set;}
    
    //Flag to check Data Set table is Collapse or Expand on Page
    public Boolean collapseDataSet {get; set;}
    
    //List of Data Set wrapper
    public List<DataSetDetail> dataSetDetails {get; set;}
    
    //Constructor
    public TrackDataMigrationStatusExt(ApexPages.StandardController stdController){
        
        //Initialize
        deployResultId = ''; 
        deployResultName = '';
        totalDataSetCount = 0;
        completedDatSetCount = 0;
        deployDataSetResults = new List<Deployment_Data_Set_Result__c>();
        collapseDataSet = false;
        dataSetDetails = new List<DataSetDetail>();
        
        //Getting id from the page 
        deployResultId = ApexPages.currentPage().getParameters().get('id');
        deploymentResults = new List<Deployment_Result__c>();
        
        //Query over the Data set 
        deploymentResults = [SELECT Id, Name, Error__c,Total_DataSet__c FROM Deployment_Result__c WHERE Id =: deployResultId LIMIT 1];
    }
    
    /**
    *
    *
    *
    **/
    public void setCollapse(){
        
        if(collapseDataSet)
            collapseDataSet = false;
        else
            collapseDataSet = true;
    }
    
    /**
     * @description :   Method to set the display flag that determine the component shoud render or not
     *
     * @args        :   
     *
     * @return      :   void
     *
     * @UpdatedBy   :
     *
     * @Version     :   V_1.0 Created
     **/  
    public void setIndex(){
        
        //Fetching environment id from page which is going to be delete.
         string indexNumber = Apexpages.currentPage().getParameters().get('indexParam');
         
         System.debug('indexNumber:--'+indexNumber);
         if(dataSetDetails[Integer.valueOf(indexNumber)].display){
            dataSetDetails[Integer.valueOf(indexNumber)].display = false;
         }
            
         else{
            if(dataSetDetails[Integer.valueOf(indexNumber)].dataSetDetail.Status__c == 'Finished')
                dataSetDetails[Integer.valueOf(indexNumber)].display = true;
         }
         
        
    }
    /**
     * @description :   Method to get the Deployment result data on the page
     *
     * @args        :   
     *
     * @return      :   void
     *
     * @UpdatedBy   :
     *
     * @Version     :   V_1.0 Created
     **/  
    public void getDeploymentInfo(){
        
        //Map to hold the Data set Id with the Desply flag (determine, whether the related component should display or not)
        Map<String, Boolean> mapChkDisplayWithDataSetId = new Map<String, Boolean>();
        
        if(dataSetDetails.size() > 0){
            
            for(DataSetDetail dSD : dataSetDetails){
                
                //Check if DataSetDetail.display is true than add it to map
                if(dSD.display)
                    mapChkDisplayWithDataSetId.put(dSD.dataSetDetail.Id, dSD.display);
            }
        }
        
        //Reinitiallize the Data Set details
        dataSetDetails = new List<DataSetDetail>();
        
        try{
            //Reinitiallize
            totalDataSetCount = 0;
            completedDatSetCount = 0;
            totalDataSetCount = Integer.valueOf((deploymentResults[0].Total_DataSet__c));    
            //Check if the Deployment result list is filled
            if(deploymentResults.size() > 0){
                
                //Name of the Deployment result
                deployResultName = deploymentResults[0].Name;  
                
                //List to hold the Deployment_Data_Set_Result__c  
              /*  deployDataSetResults = [SELECT Id, Data_Set__c, Data_Set__r.Name, Name, Error__c, Result__c, Status__c,
                                                                                (SELECT Data_Set__c, Data_Set__r.Name, Name, Deployment_Data_Set_Result__c, Job_ID__c, Result__c,
                                                                                Result_ID__c, Id FROM Deployment_Batch_Results__r)
                                                                                FROM Deployment_Data_Set_Result__c 
                                                                                WHERE Deployment_Result__c =: deployResultId];*/
                                                                                
                deployDataSetResults = [SELECT Id, Data_Set__c, Data_Set__r.Name, Name, Error__c, Result__c, Status__c,
                                                                                (SELECT Data_Set__c, Data_Set__r.Name, Name, Deployment_Data_Set_Result__c, Job_ID__c, Result__c,
                                                                                Result_ID__c, Id FROM Deployment_Batch_Results__r),(Select Id, Data_Set__c,Deployment_Data_Set_Result__c,Deployment_Result_Id__c,
                                                                                Parent_Data_Set_Id__c,Result__c,Status__c from Child_Deployment_Data_Set_Results__r)
                                                                                FROM Deployment_Data_Set_Result__c 
                                                                                WHERE Deployment_Result__c =: deployResultId];
                
                //Looping overthrough the result
                for(Deployment_Data_Set_Result__c pDSR : deployDataSetResults){
                    
                    //Instantiate the wrapper
                    if(mapChkDisplayWithDataSetId.containsKey(pDSR.Id)){
                        DataSetDetail dSD = new DataSetDetail(pDSR, true);
                        dataSetDetails.add(dSD);
                    }
                    else{
                        DataSetDetail dSD = new DataSetDetail(pDSR, false);
                        dataSetDetails.add(dSD);
                    }
                    //check if the Status__c is finished
                    if(pDSR.Status__c.equalsIgnoreCase('Finished'))
                        completedDatSetCount++;
                    System.debug('completedDatSetCount'+completedDatSetCount);
                    
                    //Changes mad by - Priyanka Khandelwal 
                    //Progress bar
                    if(pDSR.Child_Deployment_Data_Set_Results__r.size() > 0) {
                        for(Child_Deployment_Data_Set_Result__c cDDSR : pDSR.Child_Deployment_Data_Set_Results__r) {
                            System.debug('completedDatSetCountChild'+cDDSR.Status__c.equalsIgnoreCase('Finished'));
                            
                            if(cDDSR.Status__c.equalsIgnoreCase('Finished')) {
                                completedDatSetCount++;
                                System.debug('completedDatSetCountChild Countter'+completedDatSetCount);
                            }
                        //  totalDataSetCount++;
                        }
                    }
                   // totalDataSetCount++;
                }
            }
            
        }catch(Exception e){
            Apexpages.addMessage(new ApexPages.Message(ApexPages.severity.Error, e.getMessage()));
        }
    }
}