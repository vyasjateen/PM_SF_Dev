public with sharing class DeploymentCenterController {
    private Connection__c sourceConnection;
    private Connection__c targetConnection;
    private Map<Id,Connection__c> targetConnections;
    private List<DataSet__c> selectedDataSets;
    
    //Variable added by Jatin Vyas
    private Connection__c localConnection;
        
    public List<DataSetWrapper> dataSetWrappers { get; set; }
    public List<DataSetWrapper> filteredDataSetWrappers { get; set; }
    public List<SelectOption> targetConnectionOptions { get; set; }
    
     //Variable added by Jatin Vyas
    public String selectedSourceConnectionId {get; set; }
    
  
    public String selectedTargetConnectionId { get; set; }
    public String alertMessage { get; set; }
    public String dataSetSearchTerm { get; set; }
    public String countResult { get; set; }
    public String countResultIndex { get; set; }
    
    public Boolean isDeployStep { get; set; }
    public Boolean isDeployDisabled { get; set; }
    public Boolean isAlertShown { get; set; }
    public Boolean isNoConnectionError { get; set; }
    public Boolean isShowHidden { get; set; }

   //pagination Variables
    public Integer startNumber{get;set;}
    public Integer endNumber{get;set;}
    public Integer pageNumber;
    public Integer totalRecord{get;set;}
    public Integer pageSize{get;set;}
    public List<List<DataSetWrapper>> listOfListDataSetWrapper{get; set;}
    public String sortExpression {get; set;}
    public String sortDirection {get; set;}
    public DeploymentCenterController() {
        try {
            //sourceConnection = AccessValidationUtilities.queryConnectionsAsUser('where Source_Connection__c = true AND Active__c = true LIMIT 1').get(0);
        } catch (Exception e) {
            alertMessage = 'An active connection to the current source org must be defined before deployment.';
            isAlertShown = true;
            isDeployStep = false;
            isNoConnectionError = true;
            return;
        }
        
        targetConnections = new Map<Id,Connection__c>( AccessValidationUtilities.queryConnectionsAsUser('where Active__c = true') );
        
        if( targetConnections.values().size() == 0 ) {
            alertMessage = 'At least one active connection to a target org must be defined before deployment.';
            isAlertshown = true;
            isDeployStep = false;
            isNoConnectionError = true;
            return;
        }
        
        targetConnectionOptions = new List<SelectOption>();
        for( Connection__c targetConnection : targetConnections.values() ) {
            targetConnectionOptions.add( new SelectOption( targetConnection.Id, targetConnection.Name ) );
        }
        
        Map<String,Schema.DescribeSObjectResult> objectDescribes = DeploymentUtils.getObjectDescribes();

        List<DataSet__c> dataSets = AccessValidationUtilities.queryDataSetsAsUser('where Active__c = true order by Name asc');
            
        dataSetWrappers = new List<DataSetWrapper>();
        
        Integer index = 0;
        for( DataSet__c dataSet : dataSets ) {
            Schema.DescribeSObjectResult objectDescribe = objectDescribes.get( dataSet.ObjectName__c );
            
            DataSetWrapper dataSetWrapper = new DataSetWrapper();
            dataSetWrapper.dataSet = dataSet;
            dataSetWrapper.objectLabel = objectDescribe == null ? dataSet.ObjectName__c : objectDescribe.getLabel();
            dataSetWrapper.objectNamespace = objectDescribe == null ? '' : DeploymentUtils.getNamespace(objectDescribe);
            dataSetWrapper.isSelected = false;
            dataSetWrapper.index = index++;
            
            dataSetWrappers.add(dataSetWrapper);
        }
        
        isShowHidden = false;
        isNoConnectionError = false;
        isAlertShown = false;
        isDeployStep = true;
        isDeployDisabled = true;
        listOfListDataSetWrapper = new List<List<DataSetWrapper>>();
        filterDataSets();
    	//Added by Jatin Vyas
        pageNumber = 0;
        startNumber = 1;
        pageSize =10;
        endNumber = pageSize;
        totalRecord = filteredDataSetWrappers.size();
        if(filteredDataSetWrappers.size() < pageSize) {
            
            endNumber = filteredDataSetWrappers.size();
        }
        if(filteredDataSetWrappers.size() == 0)
            startNumber = 0;
        
        inIt();
   }
    /**
     *  @Description    :   Method to use intial page data
     *  
     *  @Args           :   void
     *
     *  @Return         :   Void
     **/
    public void inIt() {
        
        //Integer variable for counter
        Integer temp = 0;
        Integer tempPros = 0;
        listOfListDataSetWrapper = new List<List<DataSetWrapper>>();
        //Blank list add to list of list
        listOfListDataSetWrapper.add(new List<DataSetWrapper>());
        
        totalRecord = filteredDataSetWrappers.size();
        if(filteredDataSetWrappers.size() < pageSize) {
            
            endNumber = filteredDataSetWrappers.size();
        }
        if(filteredDataSetWrappers.size() == 0)
            startNumber = 0;
            
        //Check for List size
        if(filteredDataSetWrappers.size() > 0){
            
            //Loop through wrapper list
            for(DataSetWrapper  wrapper : filteredDataSetWrappers) {
                
                //Check for variable is equal to page size
                if(temp == pageSize) {
                    
                    //Add blank list to list of list
                    listOfListDataSetWrapper.add(new List<DataSetWrapper>());
                    temp = 0;
                }   
                //add wrapper data extract from list to list of list
                listOfListDataSetWrapper[listOfListDataSetWrapper.size()-1].add(wrapper);
                
                //Counter increament
                temp++;
            }
        }
    }
    
    //List of Wrapper to bind on page for pagination
    public List<DataSetWrapper> tempListOfWrapper {
        get {
            return listOfListDataSetWrapper[pageNumber];
        }
        set;
    }
    
    
     /**
     *  @Description    :   Method to used to move to first page data
     *  
     *  @Args           :   void
     *
     *  @Return         :   Void
     **/
    public void first() {
        pageNumber = 0;
        startNumber = 1 ;
        endNumber = tempListOfWrapper.size();
    }
    
    /**
     *  @Description    :   Method to used to move to previous page data
     *  
     *  @Args           :   void
     *
     *  @Return         :   Void
     **/
    public void previous() {
        pageNumber -= 1;
        startNumber = pageSize*((pageNumber+1) - 1)+1 ;
        endNumber = (startNumber + tempListOfWrapper.size()) - 1;
    }
    
    
    /**
     *  @Description    :   Method to used to move to next page data
     *  
     *  @Args           :   void
     *
     *  @Return         :   Void
     **/
    public void next() {
     
        pageNumber += 1;
        startNumber = pageSize*((pageNumber+1) - 1)+1;
        endNumber = (startNumber + tempListOfWrapper.size()) - 1;
    }
    
    /**
     *  @Description    :   Method to used to move to last page data
     *  
     *  @Args           :   void
     *
     *  @Return         :   Void
     **/
    public void last() {
      
        pageNumber = listOfListDataSetWrapper.size()-1;
        startNumber = pageSize*((pageNumber+1) - 1)+1   ;
        endNumber = filteredDataSetWrappers.size();
        }
        
    //Method to disable first button of  customer 
    public Boolean getFirstButtonDisabled() {
        return (pageNumber == 0);
    }
    
    //Method to disable previous button of customer
    public Boolean getPreviousButtonDisabled() {
        return (pageNumber == 0);
    }
    
    //Method to disable Next button of customer
    public Boolean getNextButtonDisabled() {
        return (pageNumber == listOfListDataSetWrapper.size()-1);
    }
    
    //Method to disable last button of customer
    public Boolean getLastButtonDisabled() {
        return (pageNumber == listOfListDataSetWrapper.size()-1);
    }
    
    public void onUpdateQueryFilter() {
        dataSetWrappers.get( Integer.valueOf(countResultIndex) ).rootRecordsCount = Integer.valueOf(countResult);
    }
    
    public void onErrorQueryFilter() {
        Integer index = Integer.valueOf(countResultIndex);
        dataSetWrappers.get(index).queryError = countResult;
    }
    
    public void onSearchDataSets() {
        filterDataSets();
        inIt();
        System.debug('filteredDataSetWrappers'+filteredDataSetWrappers);
    }
    
    public void onSelectShowHidden() {
        filterDataSets();
    }
    
    public void filterDataSets() {
        filteredDataSetWrappers = new List<DataSetWrapper>();
            System.debug('dataSetSearchTerm*****'+dataSetSearchTerm);
        for( DataSetWrapper dataSetWrapper : dataSetWrappers ) {
            Boolean isSearchMatch;
            if( String.isNotBlank(dataSetSearchTerm) ) {
            	System.debug('String.isNotBlank(dataSetSearchTerm)'+String.isNotBlank(dataSetSearchTerm));
                if( dataSetWrapper.dataSet.Name.contains(dataSetSearchTerm) ||
                    dataSetWrapper.dataSet.ObjectName__c.contains(dataSetSearchTerm) ||
                    ( dataSetWrapper.objectLabel != null && dataSetWrapper.objectLabel.contains(dataSetSearchTerm) ) ||
                    ( dataSetWrapper.objectNamespace != null && dataSetWrapper.objectNamespace.contains(dataSetSearchTerm) ) ) {
                    	System.debug('Enter In to If condition');
                    isSearchMatch = true;
                } else {
                	System.debug('Enter In toelse condition');
                    isSearchMatch = false;
                }
            } else {
            	System.debug('Else'+String.isNotBlank(dataSetSearchTerm));
                isSearchMatch = true;
            }
            
            if( ( isShowHidden || dataSetWrapper.dataSet.Root__c ) && isSearchMatch ) {
                filteredDataSetWrappers.add(dataSetWrapper);
                System.debug('filteredDataSetWrappers'+filteredDataSetWrappers);
            }
        }
    }
    
    public void onDismissAlert() {
        if( isNoConnectionError ) {
            return;
        }
        isAlertShown = false;
    }
    
    public void onSelect() {
        selectedDataSets = new List<DataSet__c>();
        
        for( DataSetWrapper dataSetWrapper : dataSetWrappers ) {
            if( dataSetWrapper.isSelected ) {
                selectedDataSets.add( dataSetWrapper.dataSet );
            }
        }
        
        if( selectedDataSets.size() == 0 ) {
            isDeployDisabled = true;
        } else {
            isDeployDisabled = false;
        }
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
	            
	        	//Added By Jatin Vyas -
	            
	            if(selectedTargetConnectionId == selectedSourceConnectionId) {
	                throw new CustomException('Source and Destination should not be same');
	            }
	            
	            
	            /*
	            Progress Bar
	            */
	            
				Integer totalRecordSet = selectedDataSets.size();
				Map<Id,Relationship__c> mapChildDataSetRelationship = new Map<Id,Relationship__c>();
				for(Relationship__c rel : [Select id, Name,ChildDataSet__c,ParentDataSet__c from Relationship__c  where ParentDataSet__c IN : selectedDataSets]){
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
				
				System.debug('DataSet'+totalRecordSet);
				
				/*
				*/
	            //Connection instance with selected source connection
	            Connection__c sourceConnection = targetConnections.get(selectedSourceConnectionId);
	            
	            //Connection instance for local connection
	            Connection__c localConnection = AccessValidationUtilities.queryConnectionsAsUser('where Local_Connection__c = true AND Active__c = true LIMIT 1').get(0);
	            
	    
	            Connection__c targetConnection = targetConnections.get(Id.valueOf(targetConnectionId));
	            
	        	Id deploymentResultId = DeploymentUtils.insertDeploymentResult(selectedSourceConnectionId, targetConnection.Id,totalRecordSet);
	            
	            //Id deploymentResultId = DeploymentUtils.insertDeploymentResult(sourceConnection.Id, targetConnection.Id);
	            
	            JSONGenerator generator = JSON.createGenerator(false);
	            DeploymentUtils.generateDeploymentParameter(selectedDataSets, localConnection, sourceConnection, targetConnection, deploymentResultId, generator);
	            
	            String jsonstring = generator.getAsString();
	            
	            DeploymentUtils.launchDeployment(jsonstring, deploymentResultId);
	            deploymentResults += String.valueOf(deploymentResultId) +',';
	            //pageRef = new PageReference('/' + deploymentResultId);
	            //pageRef.setRedirect(true);
         	}
         	deploymentResults = deploymentResults.removeEnd(',');
         	pageRef = new PageReference('/apex/MultipleTargets?deploymentResId=' + deploymentResults);
	        pageRef.setRedirect(true);
        } catch(Exception e) {
            alertMessage = e.getMessage();
            isAlertshown = true;
        }
        
        isDeployStep = false;
        
        return pageRef;
    }
    
    public class DataSetWrapper {
        public DataSet__c dataSet { get; set; }
        public String objectLabel { get; set; }
        public String objectNamespace { get; set; }         
        public Integer rootRecordsCount { get; set; }       
        public String queryError { get; set; }
        public Boolean isSelected { get; set; }
        public Boolean isDisabled { get; set; }
        public Integer index { get; set; }
    }
}