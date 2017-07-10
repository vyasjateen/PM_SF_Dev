public with sharing class DeploymentController {
    private Connection__c sourceConnection;
    private Connection__c targetConnection;
    private Map<Id,Connection__c> targetConnections;
    //Local Org Connection hold - added by Jatin Vyas - 06-06-2017
    private Connection__c localConnnection;
  
    public DataSet__c rootDataSet  { get; set; }
    
    public List<SelectOption> targetConnectionOptions { get; set; }
    public String selectedTargetConnectionId { get; set; }  
    //Variable added by Jatin Vyas - 06/05/2017
    public String selectedSourceConnectionId {get; set;}	
    public String alertMessage { get; set; }
    public String countResult { get; set; }
    
    public Boolean isAlertShown { get; set; }
    public Boolean isNoConnectionError { get; set; }
    public Boolean isSubmittedStep { get; set; }
    public Boolean isDeployStep { get; set; }
    
    public Integer rootRecordsCount { get; set; }   
    public String rootObjectLabel { get; set; }
    
    public DeploymentController(ApexPages.standardController stdController) {
        Id dataSetId = stdController.getId();
        rootDataSet = DeploymentUtils.queryDataSet(dataSetId, new Map<Id,DataSet__c>());
        
        if( rootDataSet == null ) {
            alertMessage = 'An active root data set defined for deployment.';
            isSubmittedStep = false;
            isAlertShown = true;
            isDeployStep = false;
            isNoConnectionError = false;
            return;
        }
        
        try {
            //sourceConnection = AccessValidationUtilities.queryConnectionsAsUser('where Local_Connection__c = true AND Active__c = true LIMIT 1').get(0);
            localConnnection =  AccessValidationUtilities.queryConnectionsAsUser('where Local_Connection__c = true AND Active__c = true LIMIT 1').get(0);
        } catch (Exception e) {
            alertMessage = 'An active connection to the current source org must be defined before deployment.';
            isSubmittedStep = false;
            isAlertShown = true;
            isDeployStep = false;
            isNoConnectionError = true;
            return;
        }
        
        targetConnections = new Map<Id,Connection__c>( AccessValidationUtilities.queryConnectionsAsUser('where  Active__c = true') );
        
        if( targetConnections.values().size() == 0 ) {
            alertMessage = 'At least one active connection to a target org must be defined before deployment.';
            isSubmittedStep = false;
            isAlertShown = true;
            isDeployStep = false;
            isNoConnectionError = true;
            return;
        }
        
        targetConnectionOptions = new List<SelectOption>();
        for( Connection__c targetConnection : targetConnections.values() ) {
            targetConnectionOptions.add( new SelectOption( targetConnection.Id, targetConnection.Name ) );
        }
        
        Schema.DescribeSObjectResult objectDescribe = DeploymentUtils.getObjectDescribes().get(rootDataSet.ObjectName__c);
        
        rootObjectLabel = objectDescribe.getLabel();
        
        /*try {
            rootRecordsCount = AccessValidationUtilities.queryCountAsUser(objectDescribe, rootDataSet.Query_Filter__c);
        } catch(Exception e) {
            alertMessage = 'Invalid data set query filter: ' + e.getMessage();
            isSubmittedStep = false;
            isAlertShown = true;
            isDeployStep = false;
            return;
        }*/
        
        //isSubmittedStep = false;
        //isDeployStep = true;
        isNoConnectionError = false;
    }
    
    
    
    public PageReference doDeploy() {
        PageReference pageRef;
        
        try {
        	
	 		//Added By Jatin Vyas - 06/07/2017  
	 		//Added by 07/04/2017 - MD-241 
         	List<String> connectionId = ((selectedTargetConnectionId.remove('[')).remove(']')).split(',');
         	String deploymentResults = '';
         	for(String st: connectionId) {
         		String targetConnectionId = st.trim();
	            
	            if(targetConnectionId == selectedSourceConnectionId) {
	                throw new CustomException('Source and Destination should not be same');
	            }
	            
	            /*
	            Progress Bar changes
	            */
	            Integer totalRecordSet = 1;
				Map<Id,Relationship__c> mapChildDataSetRelationship = new Map<Id,Relationship__c>();
				for(Relationship__c rel : [Select id, Name,ChildDataSet__c,ParentDataSet__c from Relationship__c  where ParentDataSet__c =: rootDataSet.Id]){
				    mapChildDataSetRelationship.put(rel.ChildDataSet__c, rel);
				}
				totalRecordSet += mapChildDataSetRelationship.size();
				Map<Id,Relationship__c> mapChildDataSetRelationship1 = new Map<Id,Relationship__c>();
				for(Relationship__c rel : [Select id, Name,ChildDataSet__c,ParentDataSet__c from Relationship__c  where ParentDataSet__c IN : mapChildDataSetRelationship.KeySet()]){
				    mapChildDataSetRelationship1.put(rel.ChildDataSet__c, rel);
				}
				totalRecordSet += mapChildDataSetRelationship1.size();
				Map<Id,Relationship__c> mapChildDataSetRelationship2 = new Map<Id,Relationship__c>();
				for(Relationship__c rel : [Select id, Name,ChildDataSet__c,ParentDataSet__c from Relationship__c  where ParentDataSet__c IN : mapChildDataSetRelationship1.KeySet()]){
				    mapChildDataSetRelationship2.put(rel.ChildDataSet__c, rel);
				}
				totalRecordSet += mapChildDataSetRelationship2.size();
				
	            //Connection instance with selected source connection
	            Connection__c sourceConnection = targetConnections.get(selectedSourceConnectionId);
	            
	            //Connection instance for local connection
	            Connection__c localConnection = AccessValidationUtilities.queryConnectionsAsUser('where Local_Connection__c = true AND Active__c = true LIMIT 1').get(0);
	            
	            Connection__c targetConnection = targetConnections.get(Id.valueOf(targetConnectionId));
		    //Changed By Jatin Vyas - 06/05/2017
	            Id deploymentResultId = DeploymentUtils.insertDeploymentResult(selectedSourceConnectionId, targetConnection.Id,totalRecordSet);
	            
	            
	            //Id deploymentResultId = DeploymentUtils.insertDeploymentResult(sourceConnection.Id, targetConnection.Id);
	            
	            JSONGenerator generator = JSON.createGenerator(false);
	            DeploymentUtils.generateDeploymentParameter(new List<DataSet__c>{rootDataSet}, localConnection, sourceConnection, targetConnection, deploymentResultId, generator);
	            
	            String jsonstring = generator.getAsString();
	            
	            DeploymentUtils.launchDeployment(jsonstring, deploymentResultId);
	            deploymentResults += String.valueOf(deploymentResultId) +',';
	            
         	}
         	deploymentResults = deploymentResults.removeEnd(',');
         	pageRef = new PageReference('/apex/MultipleTargets?deploymentResId=' + deploymentResults);
	        pageRef.setRedirect(true);
	           
        } catch(Exception e) {
            alertMessage = e.getMessage();
            System.debug(alertMessage+'***'+e.getLineNumber());
            isAlertShown = true;
            return null;
        }
        
        isDeployStep = false;
        
        return pageRef;
    }  
    
    /*Changes made by MD-269 Jira ticket
    	Changed by Jatin Vyas 
    */
    public void onDismissAlert() {
        if( isNoConnectionError ) {
            return;
        }
        isAlertShown = false;
    }
    
    public void onUpdateQueryFilter() {
        rootRecordsCount = Integer.valueOf(countResult);
    }
    
    public void onErrorQueryFilter() {
        alertMessage = 'Invalid data set query filter: ' + countResult;
        isSubmittedStep = false;
        isAlertShown = true;
        isDeployStep = false;
    }
}