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
    
    //MD-74
    public Connection__c originConn;
    
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
        
        targetConnections = new Map<Id,Connection__c>( AccessValidationUtilities.queryConnectionsAsUser('where  Active__c = true Order By Name ASC NULLS Last') );
        
        //Get Origin Connection
        originConn = targetConnections.get(rootDataSet.Origin_Connection__c);
        
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
        
        //For Local Connction
        if(originConn.Local_Connection__c) {
            Schema.DescribeSObjectResult objectDescribe = DeploymentUtils.getObjectDescribes().get(rootDataSet.ObjectName__c);
            rootObjectLabel = objectDescribe.getLabel();
        }
        else {
            //describe sobject
            rootObjectLabel = apexpages.currentpage().getparameters().get('objName');
            
        }
            
        isNoConnectionError = false;
    }
    
    
    
    public PageReference doDeploy() {
        PageReference pageRef;
        
        try {
            
            //Added By Jatin Vyas - 06/07/2017  
            //Added by 07/04/2017 - MD-241 
            
            List<String> connectionIds = ((selectedTargetConnectionId.remove('[')).remove(']')).split(',');
            
            String deploymentResults = '';
            
            /*
            	Progress Bar changes
            */
            Integer totalRecordSet = 1;
            
            Map<Id,Relationship__c> mapParentDataSetRelationshipOneLevel = new Map<Id,Relationship__c>();
            for(Relationship__c rel : [Select id, Name,ChildDataSet__c,ParentDataSet__c from Relationship__c  where ChildDataSet__r.Active__c = true and ChildDataSet__c =: rootDataSet.Id]){
                if(rel.ParentDataSet__c != rel.ChildDataSet__c)
                	mapParentDataSetRelationshipOneLevel.put(rel.ParentDataSet__c, rel);
            }
            
            totalRecordSet += mapParentDataSetRelationshipOneLevel.size();
            
            Map<Id,Relationship__c> mapParentDataSetRelationshipTwoLevel = new Map<Id,Relationship__c>();
            for(Relationship__c rel : [Select id, Name,ChildDataSet__c,ParentDataSet__c from Relationship__c  where ChildDataSet__r.Active__c = true and ChildDataSet__c =: mapParentDataSetRelationshipOneLevel.keySet()]){
                if(rel.ParentDataSet__c != rel.ChildDataSet__c)
                mapParentDataSetRelationshipTwoLevel.put(rel.ParentDataSet__c, rel);
            }
            
            totalRecordSet += mapParentDataSetRelationshipTwoLevel.size();
            
            Map<Id,Relationship__c> mapChildDataSetRelationshipOneLevel = new Map<Id,Relationship__c>();
            for(Relationship__c rel : [Select id, Name,ChildDataSet__c,ParentDataSet__c from Relationship__c  where ParentDataSet__r.Active__c = true and ParentDataSet__c =: rootDataSet.Id]){
            	 if(rel.ParentDataSet__c != rel.ChildDataSet__c)
                mapChildDataSetRelationshipOneLevel.put(rel.ChildDataSet__c, rel);
            }
            totalRecordSet += mapChildDataSetRelationshipOneLevel.size();
            
            Map<Id,Relationship__c> mapChildDataSetRelationshipTwoLevel = new Map<Id,Relationship__c>();
            for(Relationship__c rel : [Select id, Name,ChildDataSet__c,ParentDataSet__c from Relationship__c  where ParentDataSet__r.Active__c = true and ParentDataSet__c IN : mapChildDataSetRelationshipOneLevel.KeySet()]){
                 if(rel.ParentDataSet__c != rel.ChildDataSet__c)
                mapChildDataSetRelationshipTwoLevel.put(rel.ChildDataSet__c, rel);
            }
            totalRecordSet += mapChildDataSetRelationshipTwoLevel.size();
            
            Map<Id,Relationship__c> mapChildDataSetRelationshipThreeLevel = new Map<Id,Relationship__c>();
            for(Relationship__c rel : [Select id, Name,ChildDataSet__c,ParentDataSet__c from Relationship__c  where ParentDataSet__r.Active__c = true and ParentDataSet__c IN : mapChildDataSetRelationshipTwoLevel.KeySet()]){
               	 if(rel.ParentDataSet__c != rel.ChildDataSet__c)
                mapChildDataSetRelationshipThreeLevel.put(rel.ChildDataSet__c, rel);
            }
            
            totalRecordSet += mapChildDataSetRelationshipThreeLevel.size();
            
            Connection__c sourceConnection = new Connection__c();
            if(selectedSourceConnectionId != null && targetConnections.containsKey(selectedSourceConnectionId))
            	sourceConnection = targetConnections.get(selectedSourceConnectionId);
            
            Connection__c localConnection = new Connection__c();
            List<Connection__c> lcs = AccessValidationUtilities.queryConnectionsAsUser('where Local_Connection__c = true AND Active__c = true LIMIT 1');
            if(lcs.size() > 0)
            	localConnection = lcs[0];
            	
            Connection__c originConnection = new Connection__c();
            if(rootDataSet.Origin_Connection__c != null && targetConnections.containsKey(rootDataSet.Origin_Connection__c))
            	originConnection = targetConnections.get(Id.valueOf(rootDataSet.Origin_Connection__c));
            
            Map<Id, Map<String, Map<String,Object>>> mapOriginDescribedSObjectsForMultipleDSs = new Map<Id, Map<String, Map<String,Object>>>();
            
            if(!originConn.Local_Connection__c) {
            
            	Map<String, Map<String,Object>> mapOriginDescribedSObjectDeploy = new Map<String, Map<String,Object>>();
            	Map<Id,DataSet__c> cachedDataSets = new Map<Id,DataSet__c>();
            	Set<String> coveredObjects = new Set<String>();
            	
            	mapOriginDescribedSObjectDeploy = DeploymentUtils.originChildParent(rootDataSet.Id, mapOriginDescribedSObjectDeploy, 
            																		originConnection, cachedDataSets, coveredObjects);
            	mapOriginDescribedSObjectsForMultipleDSs.put(rootDataSet.Id, mapOriginDescribedSObjectDeploy);
            }
        
            for(String cId : connectionIds) {
                
                String targetConnectionId = cId.trim();
                if(targetConnectionId == selectedSourceConnectionId) {
                    throw new ProdlyCustomException('Source and Destination should not be same');
                }
                
                Connection__c targetConnection = new Connection__c();
	            if(targetConnectionId != null && targetConnections.containsKey(targetConnectionId))
	            	targetConnection = targetConnections.get(Id.valueOf(targetConnectionId));
	            
                Id deploymentResultId = DeploymentUtils.insertDeploymentResult(selectedSourceConnectionId, targetConnection.Id,totalRecordSet);
                
                JSONGenerator generator = JSON.createGenerator(false);
              	
              	DeploymentUtils.generateDeploymentParameter(new List<DataSet__c>{rootDataSet}, localConnection, sourceConnection, targetConnection, deploymentResultId, generator, mapOriginDescribedSObjectsForMultipleDSs);
              		
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