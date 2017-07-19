public with sharing class DataSetEditorController {
        
        public static final String STANDARD_UPSERT_TYPE = 'Standard Upsert';
        public static final String NEXT_PAGE_OPTION_VALUE = 'NEXT_PAGE';
        public static final String NEXT_PAGE_OPTION_LABEL = '-- Next --'; 
        public Integer OBJECT_PAGE_OFFSET;
        
        @TestVisible
        private Map<String,DataSetWrapper> dataSetWrappersByObjectName;
        private Map<Id,DataSetWrapper> dataSetWrappersById;
        private Map<Id,DataSet__c> deleteDataSets;
        private Map<Id,Relationship__c> deleteRelationships;
        
        private String lastRootObjectName;
        
        public List<ObjectNode> objectNodes { get; set; }   
        public List<SelectOption> objectOptions { get; set; }
           
        public ObjectNode objectNode { get; set; }
        public DataSet__c rootDataSet { get; set; }
        
        public FieldWrapper selectedFieldWrapper { get; set; }
        
        public String clickedChecboxFieldName { get; set; }
        public String objectSearchTerm { get; set; }
        public String objectNamespaceSearchTerm { get; set; }
        public String navToSectionName { get; set; }
        public String navToNodeIndex { get; set; }
        public String fieldSelected { get; set; }
        public String parentSelected { get; set; }
        public String childSelected { get; set; }
        public String alertMessage { get; set; }
        public String countResult { get; set; }
        
        public Integer objectSelectorPage { get; set; }
            
        public Boolean isObjectStep { get; set; }
        public Boolean isFieldsStep { get; set; }
        public Boolean isParentStep { get; set; }
        public Boolean isChildStep { get; set; }
        public Boolean isSelectAllFields { get; set; }
        public Boolean isSuccessAlertShown { get; set; }
        public Boolean isFailureAlertShown { get; set; }
        public Boolean isDeleteCompleted { get; set; }
        Id datasetRecordId;
        
        
        //MD-74 Start
        private Connection__c originConnection;
        private Map<Id,Connection__c> originConnections;
        public List<SelectOption> originConnectionOptions { get; set; }
        public String selectedOriginConnectionId { get; set; }  
        public Map<String, String> mapOriginSchemaByNameAndLabel;
        public Map<String, Object> mapOriginDescribedSObject;
        private Boolean onLoadEditRequest;
        
        //MD-74 END
        
        public DataSetEditorController(ApexPages.standardController stdController) {
            
            try {
                //objectOptions = new List<SelectOption>();
            	objectSelectorPage = 0;
                Decimal offset = CustomSettingsUtilities.getInstance().getCustomSettings().Object_Selector_Page_Size__c;
                OBJECT_PAGE_OFFSET = offset == null ? 900 : Math.abs( Integer.valueOf( CustomSettingsUtilities.getInstance().getCustomSettings().Object_Selector_Page_Size__c ) );
                
                //MD-74 Start
                originConnections = new Map<Id,Connection__c>( AccessValidationUtilities.queryConnectionsAsUser('where  Active__c = true order by Local_Connection__c DESC') );
                
                originConnectionOptions = new List<SelectOption>();
                for( Connection__c originConnection : originConnections.values() ) {
                    originConnectionOptions.add(new SelectOption(originConnection.Id, originConnection.Name));
                }
                //MD-74 End
                
                mapOriginDescribedSObject = new Map<String, Object>();
                datasetRecordId = stdController.getId();
                initDataSet( datasetRecordId );
       			
       			//Set the defualt connection
                originConnection = originConnections.get(Id.valueOf(originConnectionOptions.get(0).getValue()));
               
                if(objectNode.dataSetWrapper.dataSet.Origin_Connection__c != null)
                    originConnection = originConnections.get(objectNode.dataSetWrapper.dataSet.Origin_Connection__c);
                    
                if(stdController.getId() != null) {
                	
                	onLoadEditRequest = true;
                    setObjectSchema();
                    
                    objectSelect();
                    
                    isSelectAllFields = checkForLabel();
                    onLoadEditRequest = false;
                } else {
                    
                    initObjectSelectors();
                    isSelectAllFields = checkForLabel();
                }
               
                initStep();
            } catch(Exception e) {
                isFailureAlertShown = true;
                alertMessage = 'Error loading data set: ' + e.getMessage() + ' ' + e.getStackTraceString();
            }
        }   
        
        //MD-74
        public void setObjectSchema() {
            
            objectOptions = new List<SelectOption>();
            originConnection = new Connection__c();
            originConnection = originConnections.get(objectNode.dataSetWrapper.dataSet.Origin_Connection__c);
            //objectNode.dataSetWrapper.dataSet.ObjectName__c = null;
            mapOriginSchemaByNameAndLabel = new Map<String, String>();
            if(onLoadEditRequest == false) {
	            clearDataSets();
	            
        	}            
            initDataSet( datasetRecordId );
            //Check for origin Connection
            if(!originConnection.Local_Connection__c) {
                
                List<Object> sObjects = new List<Object>();
       
                //Create Remote Site Setting
                RemoteSiteController.createRemoteSiteSettings((originConnection.Name).remove(' '), originConnection.Instance_URL__c,'RemoteSiteSetting for Origin Org');
       
                //describe sobject
                sObjects = ProdlyHttpRequest.doCalloutOrigin(originConnection);
                
                //Select option list
                objectOptions.add(new SelectOption('', '--None--' ));
                
                for(Object sObjectInstance : sObjects) {
                    
                    Map<String, Object> sObjectAttributes = (Map<String, Object>)sObjectInstance;
                    mapOriginSchemaByNameAndLabel.put(String.valueOf(sObjectAttributes.get('name')).toLowerCase(), String.valueOf(sObjectAttributes.get('label')));
                    objectOptions.add( new SelectOption(String.valueOf(sObjectAttributes.get('name')).toLowerCase(), String.valueOf(sObjectAttributes.get('label')) ) );
                }
                
                objectOptions = DeploymentUtils.sortByLabel(objectOptions);
                
            	initObjectSelectors();
               
            } else {
                
                initObjectSelectors();
            }
        }
        
        public Boolean checkForLabel() {
            
            Boolean isLabelCheck = true;
            //Changes made by - PRIYANKA khandelwal - JIRA 165
            
            for( FieldWrapper fieldWrapper : objectNode.filteredFieldWrappers ) {
               // fieldWrapper.isSelected = true;
               if(!fieldWrapper.isSelected) {
                    isLabelCheck = false;
                    return isLabelCheck;
               }
              
            }
            return isLabelCheck;
        } 
     
        private void initStep() {
            isObjectStep = true;
            isFieldsStep = false;
            isParentStep = false;
            isChildStep = false;
        }
        
        private void initObjectSelectors() {
            objectOptions = new List<SelectOption>();
            if( objectNode.dataSetWrapper == null ) {
                return;
            }
            
            Map<String,Schema.DescribeSObjectResult> objectDescribes;
            Boolean isFound = false;
            
            while( !isFound ) {
                
                if(originConnection.Local_Connection__c) {
                    
                    objectDescribes = DeploymentUtils.getVisibleObjectDescribes(objectSelectorPage * OBJECT_PAGE_OFFSET, OBJECT_PAGE_OFFSET);
                    
                    if( objectNode.dataSetWrapper.dataSet.Id == null || objectNode.dataSetWrapper.dataSet.ObjectName__c == NEXT_PAGE_OPTION_VALUE ) { break; }
                    
                    for( String objectName : objectDescribes.keySet() ) {
                        if( objectNode.dataSetWrapper.dataSet.ObjectName__c.toLowerCase() == objectName.toLowerCase() ) {
                            isFound = true;
                            break;
                        }
                    }
                    if( isFound ) { break; }
                    
                    objectSelectorPage++;
                } else {
                    
                    //If Origin is not a local org
                    List<Object> sObjects = ProdlyHttpRequest.doCalloutOrigin(originConnection);
                    if( objectNode.dataSetWrapper.dataSet.Id == null 
                        || objectNode.dataSetWrapper.dataSet.ObjectName__c == null 
                        || objectNode.dataSetWrapper.dataSet.ObjectName__c == NEXT_PAGE_OPTION_VALUE ) { 
                        
                        break; 
                    }
                     
                    for(Object sObjectInstance : sObjects) {
                        
                        Map<String, Object> sObjectAttributes = (Map<String, Object>)sObjectInstance;
                        
                        if( objectNode.dataSetWrapper.dataSet.ObjectName__c.equalsIgnoreCase(String.valueOf(sObjectAttributes.get('name')))) {
                            
                            isFound = true;
                            break;
                        }
                    }
                    if( isFound ) { 
                        
                        break; 
                    }
                    
                    objectSelectorPage++;
                }
            }  
            
           if(originConnection.Local_Connection__c) {
                for( String objectName : objectDescribes.keySet() ) {
                    Schema.DescribeSObjectResult objectDescribe = objectDescribes.get(objectName);
                    
                    //System.debug('DRUDMAN: Adding object option: name: ' + objectName + ' , label: ' + objectDescribe.getLabel());
                    objectOptions.add( new SelectOption(objectName, objectDescribe.getLabel() ) );
                }
                objectOptions = DeploymentUtils.sortByLabel(objectOptions);
            }
            
            if( objectNode.dataSetWrapper.dataSet.ObjectName__c == null ||
                objectNode.dataSetWrapper.dataSet.ObjectName__c == NEXT_PAGE_OPTION_VALUE ) {
                objectNode.dataSetWrapper.dataSet.ObjectName__c = objectOptions.get(0).getValue();
                addRequiredParentDataSets(objectNode.dataSetWrapper.dataSet.ObjectName__c, objectNode.dataSetWrapper, null, 0);
            }
            
            if( objectOptions.size() == OBJECT_PAGE_OFFSET ) {
                objectOptions.add( new SelectOption( NEXT_PAGE_OPTION_VALUE, NEXT_PAGE_OPTION_LABEL ) );
            }
            
            if(originConnection.Local_Connection__c) {
	            for( ObjectNode curObjectNode : objectNodes ) {
	                objectNode = curObjectNode;
	                
	                if( DeploymentUtils.getObjectDescribes().get( curObjectNode.dataSetWrapper.dataSet.ObjectName__c ) == null ) {
	                    dataSetWrappersByObjectName.remove( curObjectNode.dataSetWrapper.dataSet.ObjectName__c.toLowerCase() );
	                    curObjectNode.dataSetWrapper.dataSet.ObjectName__c = objectOptions.get(0).getValue();
	                    dataSetWrappersByObjectName.put( curObjectNode.dataSetWrapper.dataSet.ObjectName__c.toLowerCase(), curObjectNode.dataSetWrapper );
	                    
	                    clearDataSets();
	                }
	                
	                objectSelect();
	            }
            }
            else {
            	objectSelect();
            }
        }
        
        private void initDataSet(Id dataSetId) {
            objectNodes = new List<ObjectNode>();
            dataSetWrappersByObjectName = new Map<String,DataSetWrapper>();
            dataSetWrappersById = new Map<Id,DataSetWrapper>();
            deleteDataSets = new Map<Id,DataSet__c>();
            deleteRelationships = new Map<Id,Relationship__c>();
            
            List<DataSetWrapper> dataSetWrappersPaths = new List<DataSetWrapper>();
        	
            if( dataSetId == null) {
                DataSetWrapper dataSetWrapper = initNewDataSet();
            
                objectNode = new ObjectNode();
                objectNode.dataSetWrapper = dataSetWrapper;
                objectNode.index = 0;
                
                objectNodes.add(objectNode);
            } else {
                List<DataSet__c> dataSets = DeploymentUtils.queryAllDataSetsAll();
                
                Map<Id,DataSet__c> dataSetsById = new Map<Id,DataSet__c>();
                for( DataSet__c dataSet : dataSets ) {
                    dataSetsById.put( dataSet.Id, dataSet );
                }
                
                initEditDataSet(dataSetId, new Map<Id,RelationshipWrapper>(), dataSetsById, dataSetWrappersPaths);
                
                Integer counter = 0;
                for( Integer index = dataSetWrappersPaths.size() - 1; index >= 0; index-- ) {
                    ObjectNode curObjectNode = new ObjectNode();
                    curObjectNode.dataSetWrapper = dataSetWrappersPaths.get(index);
                    curObjectNode.index = counter++;
                    
                    objectNodes.add(curObjectNode);
                    
                    if( curObjectNode.dataSetWrapper.dataSet.Id == dataSetId ) {
                        objectNode = curObjectNode;
                    }   
                }
                
            }
        }
        
        private DataSetWrapper initEditDataSet(Id dataSetId, 
            Map<Id,RelationshipWrapper> relationshipWrappersByRelationshipId,
            Map<Id,DataSet__c> dataSetsById,
            List<DataSetWrapper> dataSetWrappersPaths) {
            if( dataSetWrappersById.get(dataSetId) != null ) {
                return dataSetWrappersById.get(dataSetId);
            }
            
            //DataSet__c dataSet = DeploymentUtils.queryDataSetAll(dataSetId);
            DataSet__c dataSet = dataSetsById.get(dataSetId);
            
            List<Relationship__c> childRelationships = new List<Relationship__c>();
            for( Relationship__c relationship : dataSet.ChildRelationships__r ) {
                childRelationships.add(relationship);
            }
            
            List<Relationship__c> parentRelationships = new List<Relationship__c>();
            for( Relationship__c relationship : dataSet.ParentRelationships__r ) {
                parentRelationships.add(relationship);
            }
            
            DataSetWrapper dataSetWrapper = new DataSetWrapper();
            dataSetWrapper.dataSet = dataSet;
            
            dataSetWrapper.isUpsert = false;
            for( Data_Set_Field__c dataSetField : DeploymentUtils.queryDataSetFields(dataSetId) ) {
            //for( Data_Set_Field__c dataSetField : dataSet.Data_Set_Fields__r ) {
            dataSetWrapper.dataSetFields.add(dataSetField);
    		dataSetWrapper.dataSetFieldsByName.put( dataSetField.Name.toLowerCase(), dataSetField );
    
                if( dataSetField.External_ID__c ) {
                    dataSetWrapper.isUpsert = true;
                }
            }
            
            if( dataSetWrapper.isUpsert &&
                String.isBlank( dataSetWrapper.dataset.Custom_Upsert_Record_Handling__c ) ) {
                dataSetWrapper.dataset.Custom_Upsert_Record_Handling__c = DataSetEditorController.STANDARD_UPSERT_TYPE;
            } else if( !dataSetWrapper.isUpsert &&
                String.isNotBlank( dataSetWrapper.dataSet.Custom_Upsert_Record_Handling__c ) ) {
                dataSetWrapper.isUpsert = true;
            }
            
            dataSetWrappersById.put(dataSetId, dataSetWrapper);
            dataSetWrappersByObjectName.put(dataSet.ObjectName__c.toLowerCase(), dataSetWrapper);       
                    
            if( dataSet.Root__c ) {
                rootDataSet = dataSet;
                dataSetWrappersPaths.add(dataSetWrapper);
            } else if( rootDataSet == null ) {
                dataSetWrappersPaths.add(dataSetWrapper);
            }
            
            for( Relationship__c relationship : childRelationships ) {
            //for( Relationship__c relationship : DeploymentUtils.queryDataSetChildRelationship(dataSetId) ) {
                RelationshipWrapper relationshipWrapper = relationshipWrappersByRelationshipId.get( relationship.Id );
                
                if( relationshipWrapper == null ) {
                    relationshipWrapper = new RelationshipWrapper();
                    relationshipWrapper.relationship = relationship;
                    
                    relationshipWrappersByRelationshipId.put( relationship.Id, relationshipWrapper );
                }
                
                relationshipWrapper.parentDataSetWrapper = dataSetWrapper;
                
                
                relationshipWrapper.childDataSetWrapper = initEditDataSet( relationship.ChildDataSet__r.Id, relationshipWrappersByRelationshipId, dataSetsById, dataSetWrappersPaths );
                
                dataSetWrapper.childRelationshipWrappers.add(relationshipWrapper);
            }     
                    
            for( Relationship__c relationship : parentRelationships ) {
            //for( Relationship__c relationship : DeploymentUtils.queryDataSetParentRelationship(dataSetId) ) {
                RelationshipWrapper relationshipWrapper = relationshipWrappersByRelationshipId.get( relationship.Id );
                
                if( relationshipWrapper == null ) {
                    relationshipWrapper = new RelationshipWrapper();
                    relationshipWrapper.relationship = relationship;
                    
                    relationshipWrappersByRelationshipId.put( relationship.Id, relationshipWrapper );
                }
                
                relationshipWrapper.childDataSetWrapper = dataSetWrapper;
                
                relationshipWrapper.parentDataSetWrapper = initEditDataSet( relationship.ParentDataSet__r.Id, relationshipWrappersByRelationshipId, dataSetsById, dataSetWrappersPaths );
                
                dataSetWrapper.parentRelationshipWrappers.add(relationshipWrapper);
            }
            
            if( rootDataSet == null ) {
                dataSetWrappersPaths.remove( dataSetWrappersPaths.size() - 1 );
            }
            System.assert(false,dataSetWrapper);
            return dataSetWrapper;
        }
        
        private DataSetWrapper initNewDataSet() {
            DataSet__c dataSet = new DataSet__c();
            dataSet.Root__c = true;
            dataSet.Active__c = true;
            dataSet.Replicate_Owner__c = false;
            dataSet.Replicate_Record_Type__c = false;
            dataSet.All_Fields__c = true;
            
            DataSetWrapper dataSetWrapper = new DataSetWrapper();
            dataSetWrapper.dataSet = dataSet;
            
            rootDataSet = dataSet;
            
            return dataSetWrapper;
        }
        
        public void toggleOverrideSettings() {
            if( objectNode.dataSetWrapper.dataSet.Override_Root_Settings__c ) {
                objectNode.dataSetWrapper.dataSet.Ignore_Namespace__c = null;
                objectNode.dataSetWrapper.dataSet.Ignore_Namespace_Name__c = null;
                objectNode.dataSetWrapper.dataSet.Create_Missing__c = null;
                objectNode.dataSetWrapper.dataSet.Sync_Picklist_Values__c = null;
            } else {
                objectNode.dataSetWrapper.dataSet.Ignore_Namespace__c = rootDataSet.Ignore_Namespace__c;
                objectNode.dataSetWrapper.dataSet.Ignore_Namespace_Name__c = rootDataSet.Ignore_Namespace_Name__c;  
                objectNode.dataSetWrapper.dataSet.Create_Missing__c = rootDataSet.Create_Missing__c;
                objectNode.dataSetWrapper.dataSet.Sync_Picklist_Values__c = rootDataSet.Sync_Picklist_Values__c;
            }
        }
        
        public void onClickFieldSettings() {
            for( FieldWrapper fieldWrapper : objectNode.fieldWrappers ) {
                if( fieldWrapper.name != fieldSelected ) {
                    continue;
                }
                
                selectedFieldWrapper = fieldWrapper;
                    
                break;
            }
        }
        
        public void onUpdateQueryFilter() {
            objectNode.dataSetWrapper.setRecordsToDeploy( Integer.valueOf(countResult) );
            isFailureAlertShown = false;
        }
        
        public void onErrorQueryFilter() {
            objectNode.dataSetWrapper.recordsToDeployLabel = 'Query filter is invalid: ' + countResult;
            isSuccessAlertShown = false;
            isFailureAlertShown = true;
            alertMessage = 'Query filter is invalid: ' + countResult;
        }
        
        /*public void onUpdateQueryFilter() {
            try {
                Schema.DescribeSObjectResult objectDescribe = DeploymentUtils.getObjectDescribes().get( rootDataSet.ObjectName__c );
                objectNode.dataSetWrapper.setRecordsToDeploy( AccessValidationUtilities.queryCountAsUser(objectDescribe, rootDataSet.Query_Filter__c) );
                isFailureAlertShown = false;
            } catch(Exception e) {
                objectNode.dataSetWrapper.recordsToDeployLabel = 'Query filter is invalid: ' + e.getMessage();
                isFailureAlertShown = true;
                alertMessage = 'Query filter is invalid: ' + e.getMessage();
            }
        }*/
        
        public void onSelectFieldExternalId() {
            for( FieldWrapper fieldWrapper : objectNode.fieldWrappers ) {
                if( fieldWrapper.name != fieldSelected ) {
                    continue;
                }
                
                fieldWrapper.isSelected = true;
                    
                if( !fieldWrapper.isLookup ) {
                    break;
                }
                
                for( ParentWrapper parentWrapper : objectNode.parentWrappers ) {
                    if( parentWrapper.name == fieldWrapper.name ) {
                        parentWrapper.isSelected = true;
                        parentSelect(parentWrapper, objectNode.dataSetWrapper);
                        break;
                    }   
                }
                    
                break;
            }
            
            isFailureAlertShown = false;
            alertMessage = null;
        }
    
        public void onSetAuditFieldsClick() {
            String selectedObjectName = objectNode.dataSetWrapper.dataSet.ObjectName__c.toLowerCase();
    
            if( !DeploymentUtils.isAllowedSystemFieldObject(selectedObjectName) ) {
                return;
            }
    
            objectNode.fieldWrappers = new List<FieldWrapper>();
            objectNode.filteredFieldWrappers = new List<FieldWrapper>();
            objectNode.parentWrappers = new List<ParentWrapper>();
            if(originConnection.Local_Connection__c) {
                Map<String,Schema.DescribeSObjectResult> objectDescribes = DeploymentUtils.getObjectDescribes();
                Schema.DescribeSObjectResult objectDescribe = objectDescribes.get(selectedObjectName);
                Map<String,Schema.DescribeFieldResult> fieldDescribes = DeploymentUtils.getFieldDescribes(objectDescribe);
        
                setObjectFields(objectNode.dataSetWrapper, fieldDescribes, selectedObjectName);
            }
            else {
                
                Map<String, Object> mapSobjectField = ProdlyHttpRequest.describeOriginSObject(originConnection, selectedObjectName);
                setOriginObjectFields(objectNode.dataSetWrapper, mapSobjectField, selectedObjectName);
            }
    
            setFilteredObjectFields();
        }  
        
        public void onUpsertClick() {
            objectNode.dataSetWrapper.isUpsert = String.isNotBlank( objectNode.dataSetWrapper.dataset.Custom_Upsert_Record_Handling__c );
            
            onSearchFields();
        }  
            
        public void onSearchChildren() {
            String caseInsensSearchTerm = objectSearchTerm.toLowerCase();
            String caseInsensNamespaceSearchTerm = objectNamespaceSearchTerm == null ? null : objectNamespaceSearchTerm.toLowerCase();
            
            objectNode.filteredChildWrappers = new List<ChildWrapper>();
            for( ChildWrapper childWrapper : objectNode.childWrappers ) {
                String labelCaseInsens = childWrapper.label.toLowerCase();
                String nameCaseInsens = childWrapper.name.toLowerCase();
                String relFieldNameCaseInsen = childWrapper.relationshipFieldName.toLowerCase();
                String relNameCaseInsen = childWrapper.relationshipName == null ? '' : childWrapper.relationshipName.toLowerCase();
                String namespaceCaseInsens = childWrapper.namespace == null ? '' : childWrapper.namespace.toLowerCase();
                
                Boolean isNamespaceMatch = String.isNotBlank( childWrapper.namespace );
                
                Boolean isSearchMatch = String.isBlank(caseInsensSearchTerm) ||
                    labelCaseInsens.contains(caseInsensSearchTerm) ||
                    nameCaseInsens.contains(caseInsensSearchTerm) ||
                    relFieldNameCaseInsen.contains(caseInsensSearchTerm) ||
                    relNameCaseInsen.contains(caseInsensSearchTerm);
                    
                Boolean isNamespaceSearchMatch = String.isBlank(caseInsensNamespaceSearchTerm) || 
                    namespaceCaseInsens.contains(caseInsensNamespaceSearchTerm);
                
                if( objectNode.dataSetWrapper.isSearchOnlyManagedChild &&
                    isNamespaceMatch &&
                    isNamespaceSearchMatch &&
                    isSearchMatch ) {
                    objectNode.filteredChildWrappers.add(childWrapper);
                } else if( !objectNode.dataSetWrapper.isSearchOnlyManagedChild &&
                    isSearchMatch ) {
                    objectNode.filteredChildWrappers.add(childWrapper);
                }
            }
        }
        
        public void onSearchFields() {
            String caseInsensSearchTerm = objectSearchTerm == null ? '' : objectSearchTerm.toLowerCase();
            
            objectNode.filteredFieldWrappers = new List<FieldWrapper>();
            for( FieldWrapper fieldWrapper : objectNode.fieldWrappers ) {
                String labelCaseInsens = fieldWrapper.label.toLowerCase();
                String nameCaseInsens = fieldWrapper.name.toLowerCase();
    
                if( ( labelCaseInsens.contains(caseInsensSearchTerm) ||
                    nameCaseInsens.contains(caseInsensSearchTerm) ) &&
                    ( !fieldWrapper.isLookup || objectNode.dataSetWrapper.isUpsert ) ) {
                    objectNode.filteredFieldWrappers.add(fieldWrapper);
                }
            }   
        }
        
        public void onAllFieldsSet() {
            
            //Changes made by - PRIYANKA khandelwal - JIRA 165
            for( FieldWrapper fieldWrapper : objectNode.fieldWrappers ) {
               // fieldWrapper.isSelected = true;
               fieldWrapper.isSelected = objectNode.dataSetWrapper.dataSet.All_Fields__c;
            }
            //isSelectAllFields = true;
            isSelectAllFields = objectNode.dataSetWrapper.dataSet.All_Fields__c;
            isFailureAlertShown = false;
            alertMessage = null;
        }
        
        public void onSelectField() {
            isSelectAllFields = false;
            
            isFailureAlertShown = false;
            alertMessage = null;
        }
        
        public void onSelectAllFieldsToggleCheckbox() {
            //isSelectAllFields = !isSelectAllFields;
        
            for( FieldWrapper fieldWrapper : objectNode.fieldWrappers ) {
                fieldWrapper.isSelected = fieldWrapper.isSystemField ? true : isSelectAllFields;
                
                if( !fieldWrapper.isSelected ) {
                    fieldWrapper.isSelectedExternalId = false;
                    fieldWrapper.isCreateMissing = false;
                    fieldWrapper.isSyncPicklistValues = false;
                    fieldWrapper.isSetEmpty = false;
                    fieldWrapper.isScrambleValue = false;
                    fieldWrapper.isFixedValue = false;
                    fieldWrapper.fixedValueInput = null;
                }
            }
            
            isFailureAlertShown = false;
            alertMessage = null;
        }
        
        public void onSelectAllFieldsToggle() {
            isSelectAllFields = !isSelectAllFields;
            onSelectAllFieldsToggleCheckbox();
            
            isFailureAlertShown = false;
            alertMessage = null;
        }
        
        public void onDismissAlert() {
            isFailureAlertShown = false;
            isSuccessAlertShown = false;
        }
        
        public void onDeploy() {
            onSave();
            isSuccessAlertShown = false;
        }
        
        public void onDelete() {
            try {
                List<DataSet__c> dataSets = new List<DataSet__c>();
                for(DataSetWrapper dataSetWrapper : dataSetWrappersByObjectName.values() ) {
                    if( dataSetWrapper.dataSet.Id == null ) {
                        continue;
                    }
                    dataSets.add( dataSetWrapper.dataSet );
                }
                
                List<Relationship__c> relationships = new List<Relationship__c>();
                List<Data_Set_Field__c> dataSetFields = new List<Data_Set_Field__c>();
                List<Data_Set_Field__c> deleteDataSetFields = new List<Data_Set_Field__c>();
                
                for( DataSetWrapper dataSetWrapper : dataSetWrappersByObjectName.values() ) {
                    for( RelationshipWrapper relationshipWrapper : dataSetWrapper.childRelationshipWrappers ) {
                        Relationship__c relationship = relationshipWrapper.relationship;
                        if( relationship.Id == null ) {
                            continue;
                        }
                        Relationship__c saveRelationship = new Relationship__c(Id = relationship.Id);
                    
                        relationships.add(saveRelationship);
                    }
                    
                    for( Data_Set_Field__c dataSetField : dataSetWrapper.dataSetFields ) {
                        if( dataSetField.Id == null ) {
                            continue;
                        }
                        
                        dataSetFields.add(dataSetField);
                    }
                    
                    for( Data_Set_Field__c dataSetField : dataSetWrapper.deletedDataSetFields.values() ) {
                        if( dataSetField.Id == null ) {
                            continue;
                        }
                        
                        deleteDataSetFields.add(dataSetField);
                    }
                }
                
                AccessValidationUtilities.deleteAsUser(relationships);
                AccessValidationUtilities.deleteAsUser(deleteRelationships.values());
                
                AccessValidationUtilities.deleteAsUser(dataSetFields);
                AccessValidationUtilities.deleteAsUser(deleteDataSetFields);
                
                AccessValidationUtilities.deleteAsUser(dataSets);   
                AccessValidationUtilities.deleteAsUser(deleteDataSets.values());
            } catch(Exception e) {
                isFailureAlertShown = true;
                alertMessage = 'Error deleting data set: ' + e.getMessage() + '\r\n';
                alertMessage += e.getStackTraceString();
                return;
            }
            
            isFailureAlertShown = false;
            isSuccessAlertShown = true;
            alertMessage = 'Data set has been succesfully deleted.';
            isDeleteCompleted = true;
        }
        
        public PageReference onClone() {
            onSave();
            
            Map<Id,DataSet__c> clonedDataSets = cloneDataSets();
            cloneDataSetFields(clonedDataSets);
            cloneRelationships(clonedDataSets);
            
            DataSet__c clonedRootDataSet;
            for( DataSet__c clonedDataSet : clonedDataSets.values() ) {
                if( clonedDataSet.Root__c ) {
                    clonedRootDataSet = clonedDataSet;
                    break;
                }
            }
            
            PageReference pageRef = new PageReference( '/' + clonedRootDataSet.Id );
            
            return pageRef;
        }
        
        private void cloneRelationships(Map<Id,DataSet__c> clonedDataSets) {
            List<Relationship__c> clonedRelationships = new List<Relationship__c>();
            
            for(DataSetWrapper dataSetWrapper : dataSetWrappersByObjectName.values() ) {
                for( RelationshipWrapper relationshipWrapper : dataSetWrapper.childRelationshipWrappers ) {
                    Relationship__c clonedRelationship = relationshipWrapper.relationship.clone(false, true);
    
                    clonedRelationship.ParentDataSet__c = clonedDataSets.get( relationshipWrapper.relationship.ParentDataSet__r.Id ).Id;
                    
                    if( relationshipWrapper.relationship.ChildDataSet__r == null ) {
                        continue;
                    }
                    
                    clonedRelationship.ChildDataSet__c = clonedDataSets.get( relationshipWrapper.relationship.ChildDataSet__r.Id ).Id;
                
                    clonedRelationships.add(clonedRelationship);
                }
            }
            
            insert clonedRelationships;
        }
        
        private void cloneDataSetFields(Map<Id,DataSet__c> clonedDataSets) {
            List<Data_Set_Field__c> clonedDataSetFields = new List<Data_Set_Field__c>();
            
            for(DataSetWrapper dataSetWrapper : dataSetWrappersByObjectName.values() ) {
                List<Data_Set_Field__c> clonedCurDataSetFields = new List<Data_Set_Field__c>();
                
                for( Data_Set_Field__c dataSetField : dataSetWrapper.dataSetFields ) {
                    Data_Set_Field__c clonedDataSetField = dataSetField.clone(false, true);
                    
                    clonedDataSetField.Data_Set__c = clonedDataSets.get( dataSetWrapper.dataSet.Id ).Id;
                    
                    clonedCurDataSetFields.add(clonedDataSetField);
                }
                
                clonedDataSetFields.addAll( clonedCurDataSetFields );
            }
            
            insert clonedDataSetFields;
        }
        
        private Map<Id,DataSet__c> cloneDataSets() {
            Map<Id,DataSet__c> clonedDataSets = new Map<Id,DataSet__c>();
                
            for(DataSetWrapper dataSetWrapper : dataSetWrappersByObjectName.values() ) {
                DataSet__c clonedDataSet = dataSetWrapper.dataSet.clone(false, true);
                
                clonedDataSets.put( dataSetWrapper.dataSet.Id, clonedDataSet );
            }
            
            insert clonedDataSets.values();
            
            return clonedDataSets;
        }
        
        /*public Boolean isEditorDirty() {
            if( String.isBlank( rootDataSet.Id ) ||
                deleteRelationships.size() > 0 ||
                deleteDataSets.size() > 0 ) {
                return true;
            }
            
            for(DataSetWrapper dataSetWrapper : dataSetWrappersByObjectName.values() ) {
                if( String.isBlank( dataSetWrapper.dataSet.Id ) ||
                    dataSetWrapper.dataSet.ObjectName__c !=  ) {
                    
                }
            }
            
            return false
        }*/
            
        public void onSave() {
            /*if( !isEditorDirty() ) {
                return;
            }*/
            
            isFailureAlertShown = false;
            isSuccessAlertShown = false;
            alertMessage = null;
            try {
            if(!isValid()) {
                    /*onErrorQueryFilter(); */
                    isSuccessAlertShown = false;
                    isFailureAlertShown = true;
                    alertMessage = 'Query filter is invalid';
                    return;
                } 
                onStore();
                
                List<DataSet__c> dataSets = new List<DataSet__c>();
                
                for(DataSetWrapper dataSetWrapper : dataSetWrappersByObjectName.values() ) {
                    dataSetWrapper.dataSet.ObjectName__c = dataSetWrapper.dataSet.ObjectName__c.toLowerCase();
                    
                    dataSets.add( dataSetWrapper.dataSet );
                }
                
                AccessValidationUtilities.upsertDataSetsAsUser(dataSets);
                
                List<Data_Set_Field__c> dataSetFields = new List<Data_Set_Field__c>();
                List<Data_Set_Field__c> deletedDataSetFields = new List<Data_Set_Field__c>();
                
                for(DataSetWrapper dataSetWrapper : dataSetWrappersByObjectName.values() ) {
                    for( Data_Set_Field__c dataSetField : dataSetWrapper.dataSetFields ) {
                        if( dataSetField.Data_Set__c == null ) {
                            dataSetField.Data_Set__c = dataSetWrapper.dataSet.Id;
                        }
                    }
                    
                    dataSetFields.addAll( dataSetWrapper.dataSetFields );
                    deletedDataSetFields.addAll( dataSetWrapper.deletedDataSetFields.values() );
                    
                    dataSetWrapper.deletedDataSetFields = new Map<Id,Data_Set_Field__c>();
                }
                
                AccessValidationUtilities.upsertDataSetFieldsAsUser(dataSetFields);
                
                List<Relationship__c> saveRelationships = new List<Relationship__c>();
                List<Relationship__c> relationships = new List<Relationship__c>();
                for(DataSetWrapper dataSetWrapper : dataSetWrappersByObjectName.values() ) {
                    for( RelationshipWrapper relationshipWrapper : dataSetWrapper.childRelationshipWrappers ) {
                        Relationship__c relationship = relationshipWrapper.relationship;
                        Relationship__c saveRelationship = new Relationship__c(Id = relationship.Id, 
                            Name = relationship.Name, 
                            ParentDataSet__c = relationship.ParentDataSet__r.Id,
                            ChildDataSet__c = relationship.ChildDataSet__r.Id);
                    
                        saveRelationships.add(saveRelationship);
                        relationships.add(relationship);
                    }
                }
                
                AccessValidationUtilities.upsertRelationshipsAsUser(saveRelationships);
                
                for( Integer i = 0; i < saveRelationships.size(); i++ ) {
                    relationships.get(i).Id = saveRelationships.get(i).Id;
                }
                AccessValidationUtilities.deleteAsUser(deleteRelationships.values());
                AccessValidationUtilities.deleteAsUser(deletedDataSetFields);
                AccessValidationUtilities.deleteAsUser(deleteDataSets.values());
            } catch(Exception e) {
                isFailureAlertShown = true;
                alertMessage = 'Error saving data set: ' + e.getMessage() + '\r\n';
                System.debug('Error saving data set: ' + e.getMessage() + ' ' + e.getStackTraceString());
                return;
            }
            
            deleteDataSets = new Map<Id,DataSet__c>();
            deleteRelationships = new Map<Id,Relationship__c>();
           
            isSuccessAlertShown = true;
            
            alertMessage = 'Data set has been succesfully saved.';
           
        }
        
        public void onPrevious() {
            if( isFieldsStep ) {
                isObjectStep = true;
                isFieldsStep = false;
            } else if( isParentStep ) {
                isFieldsStep = true;
                isParentStep = false;
            } else if( isChildStep ) {
                isParentStep = true;
                isChildStep = false;
            }
        }
            
        public void onNext() {
            if( isObjectStep ) {
                isObjectStep = false;
                isFieldsStep = true;
            } else if( isFieldsStep ) {
                isFieldsStep = false;
                isParentStep = true;
            } else if( isParentStep ) {
                isParentStep = false;
                isChildStep = true;
            }
        }
        
        public void onNavToNode() {
            try {
                onStore();
            } catch(Exception e) {
                isFailureAlertShown = true;
                alertMessage = 'Error: ' + e.getMessage() + '\r\n';
                return;
            }
            
            Integer index = Integer.valueOf(navToNodeIndex);
            
            List<ObjectNode> tmpObjectNodes = objectNodes;
            objectNodes = new List<ObjectNode>();
            
            Integer i;
            for( i = 0; i <= index; i++ ) {
                objectNodes.add( tmpObjectNodes.get(i) );
            }
            
            objectNode = objectNodes.get(i-1);
            
            objectSelectorPage = 0;
    
            //initObjectSelectors();
            
            isObjectStep = true;
            isFieldsStep = false;
            isParentStep = false;
            isChildStep = false;  
            //isSelectAllFields = false;
            isSelectAllFields = checkForLabel();
        }
        
        public void onNavToSection() { 
            //onUpdateQueryFilter();
                   
            isObjectStep = false;
            isFieldsStep = false;
            isParentStep = false;
            isChildStep = false;
                
            if( navToSectionName == 'object' ) {        
                isObjectStep = true;
            } else if( navToSectionName == 'fields' ) {
                isFieldsStep = true;
            } else if( navToSectionName == 'parent' ) {
                isParentStep = true;
            } else if( navToSectionName == 'child' ) {
                isChildStep = true;
            }
        }
             
        private RelationshipWrapper getSelectedParentRelationshipWrapper(String fieldName) {
            for( RelationshipWrapper relationshipWrapper : objectNode.dataSetWrapper.parentRelationshipWrappers ) {
                if( relationshipWrapper.relationship.Name == fieldName ) {
                    return relationshipWrapper;
                }
            }
            return null;
        }
            
        private ParentWrapper getSelectedParentWrapper() {
            for( ParentWrapper parentWrapper : objectNode.parentWrappers ) {
                if( parentWrapper.name == parentSelected ) {
                    return parentWrapper;
                }
            }
            return null;
        }
                 
        private RelationshipWrapper getSelectedChildRelationshipWrapper(String fieldName, String objectName) {
            for( RelationshipWrapper relationshipWrapper : objectNode.dataSetWrapper.childRelationshipWrappers ) {
                if( relationshipWrapper.relationship.Name == fieldName &&
                    objectName == relationshipWrapper.childDataSetWrapper.dataSet.ObjectName__c ) {
                    return relationshipWrapper;
                }
            }
            return null;
        }
            
        private ChildWrapper getSelectedChildWrapper() {
            for( ChildWrapper childWrapper : objectNode.childWrappers ) {
                if( childWrapper.relationshipName == childSelected ) {
                    return childWrapper;
                }
            }
            return null;
        }
            
        public void onParentClick() {
            ParentWrapper selectedParentWrapper = getSelectedParentWrapper();
            if( selectedParentWrapper == null ) {
                return;
            } if( selectedParentWrapper.isSelected ) {
                parentSelect(selectedParentWrapper, objectNode.dataSetWrapper);
            } else {
                parentDeselect(selectedParentWrapper);
            }
        }
        
        private void parentDeselect(ParentWrapper selectedParentWrapper) {
            Boolean isSelfRef = false;
            
            RelationshipWrapper selectedRelationshipWrapper;
            for( RelationshipWrapper relationshipWrapper : objectNode.dataSetWrapper.parentRelationshipWrappers ) {         
                Relationship__c relationship = relationshipWrapper.relationship;
                if( relationship.Name == selectedParentWrapper.name ) {
                    selectedRelationshipWrapper = relationshipWrapper;
                    if( relationship.ParentDataSet__r.ObjectName__c != null &&
                        objectNode.dataSetWrapper.dataSet.ObjectName__c != null ) {
                        isSelfRef = relationship.ParentDataSet__r.ObjectName__c.toLowerCase() == objectNode.dataSetWrapper.dataSet.ObjectName__c.toLowerCase();
                    }
                    break;
                }
            }
            
            objectNode.dataSetWrapper.parentRelationshipWrappers.remove(selectedRelationshipWrapper);
            selectedRelationshipWrapper.parentDataSetWrapper.childRelationshipWrappers.remove(selectedRelationshipWrapper);
            
            if( selectedRelationshipWrapper.relationship.Id != null ) {
                deleteRelationships.put( selectedRelationshipWrapper.relationship.Id, selectedRelationshipWrapper.relationship );
            }
            
            if( selectedRelationshipWrapper.parentDataSetWrapper.parentRelationshipWrappers.size() == 0 &&
                selectedRelationshipWrapper.parentDataSetWrapper.childRelationshipWrappers.size() == 0 &&
                !isSelfRef ) {
                dataSetWrappersByObjectName.remove( selectedRelationshipWrapper.parentDataSetWrapper.dataSet.ObjectName__c );
                
                if( selectedRelationshipWrapper.parentDataSetWrapper.dataSet.Id != null ) {
                    deleteDataSets.put( selectedRelationshipWrapper.parentDataSetWrapper.dataSet.Id, selectedRelationshipWrapper.parentDataSetWrapper.dataSet );
                }
            }
        }
        
        private void parentSelect(ParentWrapper selectedParentWrapper, DataSetWrapper dataSetWrapper) {
            parentSelect(selectedParentWrapper, dataSetWrapper, 0);
        }
        
        private void parentSelect(ParentWrapper selectedParentWrapper, DataSetWrapper dataSetWrapper, Integer depth) {
            if( depth++ > 1 ) {
                return;
            }
            
            String parentObjectName = selectedParentWrapper.parentName.toLowerCase();
            DataSetWrapper parentDataSetWrapper = dataSetWrappersByObjectName.get(parentObjectName);
            
            if( parentDataSetWrapper == null ) {
                DataSet__c parentDataSet = new DataSet__c();
                parentDataSet.Active__c = true;
                parentDataSet.Replicate_Owner__c = false;
                parentDataSet.Replicate_Record_Type__c = false;
                parentDataSet.ObjectName__c = parentObjectName;
                parentDataSet.Name = selectedParentWrapper.parentLabel + ' Data Set';
                parentDataSet.Ignore_Namespace__c = rootDataSet.Ignore_Namespace__c;
                parentDataSet.Ignore_Namespace_Name__c = rootDataSet.Ignore_Namespace_Name__c;
                parentDataSet.All_Fields__c = true;
                parentDataSet.Origin_Connection__c = rootDataSet.Origin_Connection__c;
                
                parentDataSetWrapper = new DataSetWrapper();
                parentDataSetWrapper.dataSet = parentDataSet;
                
                dataSetWrappersByObjectName.put(parentObjectName, parentDataSetWrapper);
            
                addRequiredParentDataSets(parentObjectName, parentDataSetWrapper, null, depth);
            }
            
            RelationshipWrapper relationshipWrapper = getSelectedParentRelationshipWrapper( selectedParentWrapper.name );
                    
            if( relationshipWrapper == null ) {
                Relationship__c relationship = new Relationship__c();
                relationship.Name = selectedParentWrapper.name;
                relationship.ChildDataSet__r = dataSetWrapper.dataSet;
                relationship.ParentDataSet__r = parentDataSetWrapper.dataSet;
                
                relationshipWrapper = new RelationshipWrapper();
                relationshipWrapper.relationship = relationship;
                relationshipWrapper.parentDataSetWrapper = parentDataSetWrapper;
                relationshipWrapper.childDataSetWrapper = objectNode.dataSetWrapper;
                
                dataSetWrapper.parentRelationshipWrappers.add(relationshipWrapper);
                parentDataSetWrapper.childRelationshipWrappers.add(relationshipWrapper);
            }
        }
        
        public void onParentConfigure() {
            try {
                onStore();   
            } catch(Exception e) {
                isFailureAlertShown = true;
                alertMessage = 'Error: ' + e.getMessage() + '\r\n';
                return;
            }
            
            ParentWrapper selectedParentWrapper = getSelectedParentWrapper();
            
            String parentObjectName = selectedParentWrapper.parentName.toLowerCase();
            DataSetWrapper parentDataSetWrapper = dataSetWrappersByObjectName.get(parentObjectName);
            
            navToObjectNode(parentDataSetWrapper, parentObjectName, selectedParentWrapper.parentLabel);
        }
        
        private void navToObjectNode(DataSetWrapper dataSetWrapper, String objectName, String objectLabel) {
            ObjectNode navObjectNode;
            
            Integer counter = 1;
            Integer size = objectNodes.size();
            for( ObjectNode curObjectNode : objectNodes ) {
                if( curObjectNode.dataSetWrapper.dataSet.ObjectName__c == objectName ) {
                    navObjectNode = curObjectNode;
                    break;
                }
                
                counter++;
            }
            
            if( navObjectNode == null ) {
                navObjectNode = new ObjectNode();
                
                navObjectNode.dataSetWrapper = dataSetWrapper;
                navObjectNode.label = objectLabel;
                navObjectNode.index = objectNodes.size();
                    
                objectNodes.add(navObjectNode);
            } else {
                for( Integer index = counter; counter < size; counter++ ) {
                    objectNodes.remove(index);
                }
            }
            
            objectNode = navObjectNode;
            
            objectSelectorPage = 0;
            
            //initObjectSelectors();
            
            objectSelect();
    
            onSetAuditFieldsClick();
            
            isObjectStep = true;
            isParentStep = false;
            isChildStep = false;   
            //isSelectAllFields = false;
            isSelectAllFields = checkForLabel();
        }
        
        public void onChildClick() {
            ChildWrapper selectedChildWrapper = getSelectedChildWrapper();
            if( selectedChildWrapper == null ) {
                return;
            } if( selectedChildWrapper.isSelected ) {
                childSelect(selectedChildWrapper);
            } else {
                childDeselect(selectedChildWrapper);
            }
        }
        
        private void childDeselect(ChildWrapper selectedChildWrapper) {
            Boolean isSelfRef = false;
            
            RelationshipWrapper selectedRelationshipWrapper;
            for( RelationshipWrapper relationshipWrapper : objectNode.dataSetWrapper.childRelationshipWrappers ) {          
                Relationship__c relationship = relationshipWrapper.relationship;
                
                if( relationship.Name == selectedChildWrapper.relationshipFieldName &&
                    relationship.ChildDataSet__r.ObjectName__c.toLowerCase() == selectedChildWrapper.name.toLowerCase() ) {
                    selectedRelationshipWrapper = relationshipWrapper;
                    isSelfRef = relationship.ChildDataSet__r.ObjectName__c.toLowerCase() == objectNode.dataSetWrapper.dataSet.ObjectName__c.toLowerCase();
                    break;
                }
            }
            
            objectNode.dataSetWrapper.childRelationshipWrappers.remove(selectedRelationshipWrapper);
            selectedRelationshipWrapper.childDataSetWrapper.parentRelationshipWrappers.remove(selectedRelationshipWrapper);
            
            if( selectedRelationshipWrapper.relationship.Id != null ) {
                deleteRelationships.put( selectedRelationshipWrapper.relationship.Id, selectedRelationshipWrapper.relationship );
            }
            
            if( selectedRelationshipWrapper.childDataSetWrapper.parentRelationshipWrappers.size() == 0 &&
                selectedRelationshipWrapper.childDataSetWrapper.childRelationshipWrappers.size() == 0 &&
                !isSelfRef ) {
                dataSetWrappersByObjectName.remove( selectedRelationshipWrapper.childDataSetWrapper.dataSet.ObjectName__c );
                
                if( selectedRelationshipWrapper.childDataSetWrapper.dataSet.Id != null ) {
                    deleteDataSets.put( selectedRelationshipWrapper.childDataSetWrapper.dataSet.Id, selectedRelationshipWrapper.childDataSetWrapper.dataSet );
                }
            }
        }
        
        private void childSelect(ChildWrapper selectedChildWrapper) {
            String childObjectName = selectedChildWrapper.name.toLowerCase();
            DataSetWrapper childDataSetWrapper = dataSetWrappersByObjectName.get(childObjectName);
            
            if( childDataSetWrapper == null ) {
                DataSet__c childDataSet = new DataSet__c();
                childDataSet.Active__c = true;
                childDataSet.Replicate_Owner__c = false;
                childDataSet.Replicate_Record_Type__c = false;
                childDataSet.ObjectName__c = childObjectName;
                childDataSet.Name = selectedChildWrapper.label + ' Data Set';
                childDataSet.Ignore_Namespace__c = rootDataSet.Ignore_Namespace__c;
                childDataSet.Ignore_Namespace_Name__c = rootDataSet.Ignore_Namespace_Name__c;
                childDataSet.All_Fields__c = true;
                childDataSet.Origin_Connection__c = rootDataSet.Origin_Connection__c;
                        
                childDataSetWrapper = new DataSetWrapper();
                childDataSetWrapper.dataSet = childDataSet;
                
                dataSetWrappersByObjectName.put(childObjectName, childDataSetWrapper);
            
                addRequiredParentDataSets(childObjectName, childDataSetWrapper, selectedChildWrapper.relationshipFieldName, 0);
            }
            
            RelationshipWrapper relationshipWrapper = getSelectedChildRelationshipWrapper( selectedChildWrapper.relationshipFieldName, childObjectName );
            
            if( relationshipWrapper == null ) {
                Relationship__c relationship = new Relationship__c();
                relationship.Name = selectedChildWrapper.relationshipFieldName;
                relationship.ChildDataSet__r = childDataSetWrapper.dataSet;
                relationship.ParentDataSet__r = objectNode.dataSetWrapper.dataSet;
                
                relationshipWrapper = new RelationshipWrapper();
                relationshipWrapper.relationship = relationship;
                relationshipWrapper.parentDataSetWrapper = objectNode.dataSetWrapper;
                relationshipWrapper.childDataSetWrapper = childDataSetWrapper;
                
                objectNode.dataSetWrapper.childRelationshipWrappers.add(relationshipWrapper);
                childDataSetWrapper.parentRelationshipWrappers.add(relationshipWrapper);
            }
        }    
        
        public void onChildConfigure() {
            try {
                onStore();   
            } catch(Exception e) {
                isFailureAlertShown = true;
                alertMessage = 'Error: ' + e.getMessage() + '\r\n';
                return;
            }
            
            ChildWrapper selectedChildWrapper = getSelectedChildWrapper();
            
            String childObjectName = selectedChildWrapper.name.toLowerCase();
            DataSetWrapper childDataSetWrapper = dataSetWrappersByObjectName.get(childObjectName);
            
            navToObjectNode(childDataSetWrapper, childObjectName, selectedChildWrapper.label);
        }
        
        private void addRequiredParentDataSets(String objectName, DataSetWrapper childDataSetWrapper, String childRelationshipFieldName, Integer depth) {
            //if local connection
            if(originConnection.Local_Connection__c) {
                Map<String,Schema.DescribeSObjectResult> objectDescribes = DeploymentUtils.getObjectDescribes();
                Schema.DescribeSObjectResult objectDescribe = objectDescribes.get(objectName);
                
                if( DeploymentUtils.isObjectVisible(objectDescribe) ) {
                    return;
                }
                
                Map<String,Schema.DescribeFieldResult> fieldDescribes = DeploymentUtils.getFieldDescribes(objectDescribe);
                
                for(String fieldName : fieldDescribes.keySet() ) {
                    if( fieldName == childRelationshipFieldName ) {
                        continue;
                    }
                    
                    Schema.DescribeFieldResult fieldDescribe = fieldDescribes.get(fieldName);
                    
                    Boolean isLookupField = fieldDescribe.getReferenceTo() != null && fieldDescribe.getReferenceTo().size() > 0;
                    Boolean isPolyMorphicLookup = fieldDescribe.isNamePointing();
                    Boolean isSystemField = DeploymentUtils.systemFieldNames.contains( fieldDescribe.getName() );
                    
                    if( !isLookupField ||
                        !fieldDescribe.isAccessible() ||
                        isPolyMorphicLookup ||
                        isSystemField ||
                        fieldDescribe.isNillable() || 
                        ( !fieldDescribe.isUpdateable() && !fieldDescribe.isCreateable() && fieldName != 'IsStandard' ) ||
                        fieldDescribe.isDeprecatedAndHidden() ) {
                        continue;
                    }
                    
                    Schema.sObjectType parentObjectType = fieldDescribe.getReferenceTo().get(0);
                    Schema.DescribeSObjectResult parentObjectDescribe = DeploymentUtils.getObjectDescribeByObjectType(parentObjectType);                
                    
                    ParentWrapper parentWrapper = new ParentWrapper();
                    parentWrapper.isSelected = true;
                    parentWrapper.name = fieldDescribe.getName();
                    parentWrapper.parentLabel = parentObjectDescribe.getLabel();
                    parentWrapper.parentName = parentObjectDescribe.getName();
                    
                    parentSelect(parentWrapper, childDataSetWrapper, depth);
                }
            }
            else {
                Map<String,Object> mapOriginDescribedSObject1 = ProdlyHttpRequest.describeOriginSObject(originConnection, objectName);
                /*if( DeploymentUtils.isObjectVisible(objectDescribe) ) {
                    return;
                }*/
                
                //Get the list of fields to be processed
                List<Object> fieldsAttributesList = (List<object>)mapOriginDescribedSObject1.get('fields');
            
                    
                for(Object fds: fieldsAttributesList ) {
                    Map<String, Object> mapFieldAttributes = (Map<String, Object>)fds;
                
                    if( String.valueOf(mapFieldAttributes.get('name')) == childRelationshipFieldName ) {
                        continue;
                    }
                    Boolean isLookupField = ((List<Object>)(mapFieldAttributes.get('referenceTo')) != null && ((List<Object>)mapFieldAttributes.get('referenceTo')).size() > 0);
                    Boolean isPolyMorphicLookup = Boolean.valueOf(mapFieldAttributes.get('namePointing'));
                    Boolean isSystemField = DeploymentUtils.systemFieldNames.contains(String.valueOf(mapFieldAttributes.get('name')));
                
                    if( !isLookupField ||
                        isPolyMorphicLookup ||
                        isSystemField ||
                        Boolean.valueOf(mapFieldAttributes.get('nillable')) || 
                        ( !Boolean.valueOf(mapFieldAttributes.get('updateable')) && !Boolean.valueOf(mapFieldAttributes.get('createable')) && String.valueOf(mapFieldAttributes.get('name')) != 'IsStandard' ) ||
                        Boolean.valueOf(mapFieldAttributes.get('deprecatedAndHidden')) ) {
                        continue;
                    }
                
                    //Schema.sObjectType parentObjectType = fieldDescribe.getReferenceTo().get(0);
                    //Schema.DescribeSObjectResult parentObjectDescribe = DeploymentUtils.getObjectDescribeByObjectType(parentObjectType);                
                    List<Object> objectsReference = (List<Object>)mapFieldAttributes.get('referenceTo');
                    List<String> referenceObjectName = new List<String>();
                    
                    for(Object obj :objectsReference){
                        referenceObjectName.add(String.valueOf(obj));
                    }
                        
                    /*Map<String,Object> mapObjectParent = ProdlyHttpRequest.describeOriginSObject(originConnection,referenceObjectName[0]);
                    */
                    ParentWrapper parentWrapper = new ParentWrapper();
                    parentWrapper.isSelected = true;
                    parentWrapper.name = String.valueOf(mapFieldAttributes.get('name'));
                    if(mapOriginSchemaByNameAndLabel.containsKey(String.valueOf(referenceObjectName[0]).toLowerCase()))
                    	parentWrapper.parentLabel = mapOriginSchemaByNameAndLabel.get(String.valueOf(referenceObjectName[0]).toLowerCase());
                    parentWrapper.parentName = String.valueOf(referenceObjectName[0]);
                    
                    parentSelect(parentWrapper, childDataSetWrapper, depth);
                    
                }
            }
        }   
        
        
        private void onStore() {
            objectSearchTerm = null;
            
            List<Data_Set_Field__c> dataSetFields = new List<Data_Set_Field__c>();
        Map<String,Data_Set_Field__c> dataSetFieldsByName = new Map<String,Data_Set_Field__c>();
            
            Set<Id> selectedDataSetFieldIds = new Set<Id>();
            
            Boolean isHasExternalId = false;
            for( FieldWrapper fieldWrapper : objectNode.fieldWrappers ) {
                if( !fieldWrapper.isSelected ||
                    ( fieldWrapper.isLookup && !fieldWrapper.isSelectedExternalId ) ||
                    ( objectNode.dataSetWrapper.dataSet.All_Fields__c && 
                        !fieldWrapper.isSelectedExternalId && 
                        !fieldWrapper.isCreateMissing && 
                        !fieldWrapper.isSyncPicklistValues && 
                        !fieldWrapper.isSetEmpty &&
                        !fieldWrapper.isScrambleValue &&
                        !fieldWrapper.isFixedValue ) ) {
                    continue;
                }
                
                Data_Set_Field__c dataSetField = getDataSetFieldObject(objectNode.dataSetWrapper, fieldWrapper.name);
                
                if( dataSetField == null ) {
                    dataSetField = new Data_Set_Field__c();
                } else if( dataSetField.Id != null ) {
                    selectedDataSetFieldIds.add( dataSetField.Id );
                }
                
                dataSetField.Name = fieldWrapper.name;
                dataSetField.External_ID__c = objectNode.dataSetWrapper.isUpsert ? fieldWrapper.isSelectedExternalId : false;
                dataSetField.Create_Missing__c = fieldWrapper.isCreateMissing;
                dataSetField.Sync_Picklist_Values__c = fieldWrapper.isSyncPicklistValues;
                dataSetField.Set_Empty__c = fieldWrapper.isSetEmpty;
                dataSetField.Scramble_Value__c = fieldWrapper.isScrambleValue;
                dataSetField.Fixed_Value__c = fieldWrapper.isFixedValue;
                dataSetField.Fixed_Value_Input__c = fieldWrapper.fixedValueInput;
                    
                dataSetFields.add(dataSetField);
            dataSetFieldsByName.put( dataSetField.Name.toLowerCase(), dataSetField );
                
                if( fieldWrapper.isSelectedExternalId ) {
                    isHasExternalId = true;
                }
            }
            
            for( Data_Set_Field__c dataSetField : objectNode.dataSetWrapper.dataSetFields ) {
                if( dataSetField.Id != null &&
                    !selectedDataSetFieldIds.contains( dataSetField.Id ) ) {
                    objectNode.dataSetWrapper.deletedDataSetFields.put(dataSetField.Id, dataSetField);
                }
            }
            
            objectNode.dataSetWrapper.dataSetFields = dataSetFields;
            objectNode.dataSetWrapper.dataSetFieldsByName = dataSetFieldsByName;
            
            if( objectNode.dataSetWrapper.isUpsert &&
                !isHasExternalId ) {
                throw new DeploymentUtils.DeploymentException('Please select an external ID field for an upsert data set.');
            } /*else if( objectNode.dataSetWrapper.dataSet.Set_Audit_Fields__c && 
                objectNode.dataSetWrapper.dataSet.Custom_Upsert_Record_Handling__c == DataSetEditorController.STANDARD_UPSERT_TYPE ) {
                throw new DeploymentUtils.DeploymentException('Standard upsert with set audit fields is not supported.');
            }*/
            
            /*if( objectNode.dataSetWrapper.isUpsert &&
                String.isBlank( objectNode.dataSetWrapper.dataSet.Custom_Upsert_Record_Handling__c ) ) {
                throw new DeploymentUtils.DeploymentException('Please select a custom upsert record handling option for the data set.');
            }*/
            
            for( DataSetWrapper dataSetWrapper : dataSetWrappersByObjectName.values() ) {
                if( dataSetWrapper.dataSet.Override_Root_Settings__c ||
                    dataSetWrapper.dataSet.Root__c ) {
                    continue;
                }
                
                dataSetWrapper.dataSet.Ignore_Namespace__c = objectNode.dataSetWrapper.dataSet.Ignore_Namespace__c;
                dataSetWrapper.dataSet.Ignore_Namespace_Name__c = objectNode.dataSetWrapper.dataSet.Ignore_Namespace_Name__c;
                dataSetWrapper.dataSet.Create_Missing__c = objectNode.dataSetWrapper.dataSet.Create_Missing__c;
                dataSetWrapper.dataSet.Sync_Picklist_Values__c = objectNode.dataSetWrapper.dataSet.Sync_Picklist_Values__c;
            }
        }
        
        private void clearDataSets() {
            for( DataSetWrapper dataSetWrapper : dataSetWrappersByObjectName.values() ) {
                if( dataSetWrapper == null ||
                    dataSetWrapper.dataSet.Root__c ) {
                    continue;
                }
                
                dataSetWrappersByObjectName.remove(dataSetWrapper.dataSet.ObjectName__c);
                
                if( dataSetWrapper.dataSet.Id != null ) {
                    deleteDataSets.put( dataSetWrapper.dataSet.Id, dataSetWrapper.dataSet );
                }
                
                for( RelationshipWrapper relationshipWrapper : dataSetWrapper.parentRelationshipWrappers ) {
                    if( relationshipWrapper.relationship.Id != null ) {
                        deleteRelationships.put( relationshipWrapper.relationship.Id, relationshipWrapper.relationship );
                    }
                }
                
                for( RelationshipWrapper relationshipWrapper : dataSetWrapper.childRelationshipWrappers ) {
                    if( relationshipWrapper.relationship.Id != null ) {
                        deleteRelationships.put( relationshipWrapper.relationship.Id, relationshipWrapper.relationship );
                    }
                }
                
                for( Data_Set_Field__c dataSetField : dataSetWrapper.dataSetFields ) {
                    if( dataSetField.Id != null ) {
                        objectNode.dataSetWrapper.deletedDataSetFields.put( dataSetField.Id, dataSetField );
                    }
                }
                        
                dataSetWrapper.parentRelationshipWrappers = new Set<RelationshipWrapper>();
                dataSetWrapper.childRelationshipWrappers = new Set<RelationshipWrapper>();
            }
            
            dataSetWrappersByObjectName = new Map<String,DataSetWrapper>();
            
            objectNode.dataSetWrapper.dataSetFields = new List<Data_Set_Field__c>();
            objectNode.dataSetWrapper.dataSetFieldsByName = new Map<String,Data_Set_Field__c>();
            objectNode.dataSetWrapper.dataSet.Query_Filter__c = null;
            objectNode.dataSetWrapper.parentRelationshipWrappers = new Set<RelationshipWrapper>();
            objectNode.dataSetWrapper.childRelationshipWrappers = new Set<RelationshipWrapper>();
        }
        
        public void onObjectSelect() {
            if(onLoadEditRequest == false)
	        	clearDataSets();
            if(originConnection.Local_Connection__c) {
                if( objectNode.dataSetWrapper.dataSet.ObjectName__c == NEXT_PAGE_OPTION_VALUE ) {
                    objectSelectorPage++;
                    initObjectSelectors();
                }
            }
            objectSelect();
        }
        
        public void objectSelect() {
            DataSetWrapper dataSetWrapper = objectNode.dataSetWrapper;
            if( dataSetWrapper.dataSet == null || dataSetWrapper.dataSet.ObjectName__c == null || dataSetWrapper.dataSet.ObjectName__c == '') {
                objectNode.fieldWrappers = new List<FieldWrapper>();
                objectNode.filteredFieldWrappers = new List<FieldWrapper>();
                objectNode.parentWrappers = new List<ParentWrapper>();
                objectNode.childWrappers = new List<ChildWrapper>();
                objectNode.filteredChildWrappers = new List<ChildWrapper>();
                return;
            }
            
            String selectedObjectName = dataSetWrapper.dataSet.ObjectName__c.toLowerCase();
    
            //TO DO: Handle case where non root node references root node, but then root node changes object type.
            
            dataSetWrappersByObjectName.put(selectedObjectName, dataSetWrapper);
           
            if( objectNode.index == 0 &&
                lastRootObjectName != null &&
                originConnection.Local_Connection__c) { //For root data set, object name can change, so remove it from the previous name
                dataSetWrappersByObjectName.remove(lastRootObjectName);
            } else if( objectNode.index == 0 ) {
                lastRootObjectName = selectedObjectName;
            }
            
            if(originConnection.Local_Connection__c)
                objectNode.label = DeploymentUtils.getObjectDescribes().get(selectedObjectName).getLabel();
            else 
                objectNode.label = mapOriginSchemaByNameAndLabel.get(selectedObjectName);
                
            objectNode.fieldWrappers = new List<FieldWrapper>();
            objectNode.filteredFieldWrappers = new List<FieldWrapper>();
            objectNode.parentWrappers = new List<ParentWrapper>();
            objectNode.childWrappers = new List<ChildWrapper>();
            objectNode.filteredChildWrappers = new List<ChildWrapper>();
            
            dataSetWrapper.isOwnerField = false;
            if(originConnection.Local_Connection__c) {
                
                Map<String,Schema.DescribeSObjectResult> objectDescribes = DeploymentUtils.getObjectDescribes();
                Schema.DescribeSObjectResult objectDescribe = objectDescribes.get(selectedObjectName);
                Map<String,Schema.DescribeFieldResult> fieldDescribes = DeploymentUtils.getFieldDescribes(objectDescribe);
            
                setObjectFields(dataSetWrapper, fieldDescribes, selectedObjectName);
                
                for( Schema.ChildRelationship childRelationship : objectDescribe.childRelationships ) {
                    Schema.DescribeSObjectResult childObjectDescribe = DeploymentUtils.getObjectDescribeByObjectName( childRelationship.getChildSObject().getDescribe().getName() );
                    
                    if( !DeploymentUtils.isObjectVisible(childObjectDescribe) /*||
                        DeploymentUtils.isObjectBinaryRequired(childObjectDescribe)*/ ) {
                        continue;
                    }
                    
                    Schema.DescribeFieldResult childFieldResult = DeploymentUtils.getFieldDescribeByFieldType(childRelationship.getField(), childObjectDescribe);
                    
                    if( childFieldResult == null||
                        !childFieldResult.isAccessible() ||
                        ( !childFieldResult.isUpdateable() && !childFieldResult.isCreateable() ) ||
                        childFieldResult.isDeprecatedAndHidden() ) {
                        continue;
                    }
                    
                    ChildWrapper childWrapper = new ChildWrapper();
                    
                    childWrapper.name = childObjectDescribe.getName();
                    childWrapper.label = childObjectDescribe.getLabel();
                    childWrapper.relationshipFieldName = childFieldResult.getName();
                    childWrapper.relationshipName = childRelationship.getRelationshipName() == null ? childObjectDescribe.getName() + childFieldResult.getName() : childRelationship.getRelationshipName();
                    childWrapper.namespace = DeploymentUtils.getNamespace(childFieldResult);
                    childWrapper.isSelected = isChildSelected(dataSetWrapper, childWrapper);
                    
                    objectNode.childWrappers.add(childWrapper);    
                }
        
                setFilteredObjectFields();
                
                objectNode.parentWrappers = (List<ParentWrapper>)DeploymentUtils.sortByLabel(objectNode.parentWrappers, ParentWrapper.class);
                objectNode.childWrappers = (List<ChildWrapper>)DeploymentUtils.sortByLabel(objectNode.childWrappers, ChildWrapper.class);
                objectNode.filteredChildWrappers = objectNode.childWrappers;
            } else {
                
                if(String.isNotBlank(selectedObjectName)) {
                    
                    //Describe Object
                    mapOriginDescribedSObject = ProdlyHttpRequest.describeOriginSObject(originConnection, selectedObjectName);
                    
                    if(mapOriginDescribedSObject == null)
                        return;
                        
                    setOriginObjectFields(dataSetWrapper, mapOriginDescribedSObject, selectedObjectName);
                    setFilteredObjectFields();
                    
                    //Get the list of fields to be processed
                    List<Object> fieldsAttributesList = (List<object>)mapOriginDescribedSObject.get('childRelationships');
                        
                    for(Object fds: fieldsAttributesList ) {
                
                        //Convert the each object in Field Map
                        Map<String, Object> mapFieldAttributes = (Map<String, Object>)fds;
                        
                        ChildWrapper childWrapper = new ChildWrapper();
                        
                        childWrapper.name = String.valueOf(mapFieldAttributes.get('childSObject'));
                        childWrapper.label = String.valueOf(mapFieldAttributes.get('childSObject'));
                        if(mapOriginSchemaByNameAndLabel.containsKey(childWrapper.name.toLowerCase()))
                            childWrapper.label = mapOriginSchemaByNameAndLabel.get(childWrapper.name.toLowerCase());
                        childWrapper.relationshipFieldName = String.valueOf(mapFieldAttributes.get('field'));
                        childWrapper.relationshipName = String.valueOf(mapFieldAttributes.get('relationshipName'));
                        childWrapper.namespace = DeploymentUtils.getNamespace(String.valueOf(mapFieldAttributes.get('childSObject')));
                        childWrapper.isSelected = isChildSelected(dataSetWrapper, childWrapper);
                        
                        objectNode.childWrappers.add(childWrapper);    
                    }
            
                    objectNode.parentWrappers = (List<ParentWrapper>)DeploymentUtils.sortByLabel(objectNode.parentWrappers, ParentWrapper.class);
                    objectNode.childWrappers = (List<ChildWrapper>)DeploymentUtils.sortByLabel(objectNode.childWrappers, ChildWrapper.class);
                    
                    objectNode.filteredChildWrappers = objectNode.childWrappers;
                } 
            }
            //Trial fix for view state memory error
            /*for( ObjectNode curObjectNode : objectNodes ) {
                if( objectNode != curObjectNode ) {
                    curObjectNode.fieldWrappers = null;   
                    curObjectNode.filteredFieldWrappers = null;
                    curObjectNode.parentWrappers = null;
                    curObjectNode.childWrappers = null;
                    curObjectNode.filteredChildWrappers = null;
                }
            }*/
            //END trial fix
        }
    
        private void setFilteredObjectFields() {
            objectNode.fieldWrappers = (List<FieldWrapper>)DeploymentUtils.sortByLabel(objectNode.fieldWrappers, FieldWrapper.class);
            
            objectNode.filteredFieldWrappers = new List<FieldWrapper>();
            for( FieldWrapper fieldWrapper : objectNode.fieldWrappers ) {
                    System.debug('falseRetrhfkerhf'+fieldWrapper.isLookup+'(())'+objectNode.dataSetWrapper.isUpsert+'))'+fieldWrapper.isSystemField+'**'+fieldWrapper.Name);
                if( !fieldWrapper.isLookup || objectNode.dataSetWrapper.isUpsert || fieldWrapper.isSystemField ) {
                    System.debug('falseRetrhfkerhf'+objectNode.filteredFieldWrappers.size());
                    objectNode.filteredFieldWrappers.add(fieldWrapper);
                }
            }
            
        }
    
        private void setObjectFields(DataSetWrapper dataSetWrapper, 
            Map<String,Schema.DescribeFieldResult> fieldDescribes,
            String selectedObjectName) {
            for(String fieldName : fieldDescribes.keySet() ) {
                Schema.DescribeFieldResult fieldDescribe = fieldDescribes.get(fieldName);
                
                if( fieldDescribe.getName() == DeploymentUtils.OWNER_FIELD_NAME ) {
                    dataSetWrapper.isOwnerField = true;
                }
                
                Boolean isLookupField = fieldDescribe.getReferenceTo() != null && fieldDescribe.getReferenceTo().size() > 0;
                Boolean isPolyMorphicLookup = fieldDescribe.isNamePointing();
                Boolean isSystemField = DeploymentUtils.systemFieldNames.contains( fieldDescribe.getName() );
                Boolean isLeadSystemField = selectedObjectName == 'lead' && 
                    DeploymentUtils.systemLeadFieldNames.contains( fieldDescribe.getName() );
                Boolean isAllowedSystemField = DeploymentUtils.isAllowedSystemField(fieldDescribe, selectedObjectName, rootDataSet.Set_Audit_Fields__c);
    
                if( !fieldDescribe.isAccessible() ||
                    //isPolyMorphicLookup ||
                    ( ( isSystemField || isLeadSystemField ) && !isAllowedSystemField ) || 
                    //( !fieldDescribe.isUpdateable() && !fieldDescribe.isCreateable() && fieldName != 'IsStandard' ) ||
                    fieldDescribe.isAutoNumber() ||
                    //fieldDescribe.isCalculated() ||
                    fieldDescribe.isDeprecatedAndHidden() ||
                    DeploymentUtils.isFieldBinary(fieldDescribe) ||
            DeploymentUtils.isFieldAddress(fieldDescribe) ||
                    DeploymentUtils.isFieldRecordType(fieldDescribe) ) {
                    continue;
                }
                
                if( !isPolyMorphicLookup ) {
                    
                    Data_Set_Field__c dataSetField = getDataSetFieldObject(dataSetWrapper, fieldDescribe.getName());
                    
                    FieldWrapper fieldWrapper = new FieldWrapper();
    
                    fieldWrapper.name = fieldDescribe.getName();
                    fieldWrapper.localName = DeploymentUtils.getLocalName( fieldDescribe.getName() );
                    fieldWrapper.namespace = DeploymentUtils.getNamespace(fieldDescribe);
                    fieldWrapper.label = fieldDescribe.getLabel();
                    fieldWrapper.ftype = DeploymentUtils.fieldTypeMapping.get( String.valueOf( fieldDescribe.getType() ) );
                    fieldWrapper.isScrambleSupportedType = isFieldScrambleSupportedType(fieldWrapper);
                    fieldWrapper.isUpdateable = fieldDescribe.isUpdateable();
                    fieldWrapper.isSelected = isFieldSelected(dataSetField, dataSetWrapper.dataSet);
                    fieldWrapper.isSelectedExternalId = isFieldSelectedExternalId(dataSetField);
                    fieldWrapper.isCreateMissing = isFieldSelectedCreateMissing(dataSetField);
                    fieldWrapper.isSetEmpty = isFieldSelectedSetEmpty(dataSetField);
                    fieldWrapper.isScrambleValue = isFieldSelectedScrambleValue(dataSetField);
                    fieldWrapper.isFixedValue = isFieldSelectedFixedValue(dataSetField);
                    fieldWrapper.fixedValueInput = getFieldSelectedFixedValueInput(dataSetField);
                    fieldWrapper.isSyncPicklistValues = isFieldSelectedSyncPicklistValues(dataSetField);
                    fieldWrapper.isLookup = isLookupField;
                    fieldWrapper.isCustom = fieldDescribe.isCustom();
                    fieldWrapper.isSystemField = isSystemField || isLeadSystemField;
                    
                    objectNode.fieldWrappers.add(fieldWrapper);
                }
                
                if( isLookupField ) {
                    for( Schema.sObjectType parentObjectType : fieldDescribe.getReferenceTo() ) {
                        //Schema.sObjectType parentObjectType = fieldDescribe.getReferenceTo().get(0);
                        Schema.DescribeSObjectResult parentObjectDescribe = DeploymentUtils.getObjectDescribeByObjectType(parentObjectType);
                        
                        if( parentObjectDescribe == null ||
                            !DeploymentUtils.isObjectVisible(parentObjectDescribe) /*|| 
                            DeploymentUtils.isObjectBinaryRequired(parentObjectDescribe)*/ ) {
                            continue;
                        }
                    }
                    
                    ParentWrapper parentWrapper = new ParentWrapper();
                    parentWrapper.name = fieldDescribe.getName();
                    parentWrapper.label = fieldDescribe.getLabel();
                    parentWrapper.isSelected = isParentSelected(dataSetWrapper, fieldDescribe.getName());
                    parentWrapper.isDisabled = isParentDisabled(dataSetWrapper, fieldDescribe.getName());
                    parentWrapper.isPolymorphic = isPolyMorphicLookup;
            
                    if( isPolyMorphicLookup ) {
                        parentWrapper.parentLabel = 'Polymorphic';
                        parentWrapper.parentName = 'Polymorphic';
                    } else {
                        Schema.sObjectType parentObjectType = fieldDescribe.getReferenceTo().get(0);
                        Schema.DescribeSObjectResult parentObjectDescribe = DeploymentUtils.getObjectDescribeByObjectType(parentObjectType);
                        
                        parentWrapper.parentLabel = parentObjectDescribe.getLabel();
                        parentWrapper.parentName = parentObjectDescribe.getName();
                    }
                    
                    objectNode.parentWrappers.add(parentWrapper);
                }
            }
        }
    
        //MD-74
        private void setOriginObjectFields(DataSetWrapper dataSetWrapper, 
            Map<String,Object> mapObjectFields,
            String selectedObjectName) {
            
            if(mapObjectFields == null) {
                return;
            }
            
            //Get the list of fields to be processed
            List<Object> fieldsAttributesList = (List<Object>)mapObjectFields.get('fields');
            
            for(Object fds: fieldsAttributesList) {
                
                //Convert the each object in Field Map
                Map<String, Object> mapFieldAttributes = (Map<String, Object>)fds;
                if(mapFieldAttributes.get('name') == DeploymentUtils.OWNER_FIELD_NAME ) {
                   dataSetWrapper.isOwnerField = true;
                }
                
                Boolean isLookupField = ((List<Object>)(mapFieldAttributes.get('referenceTo')) != null && ((List<Object>)mapFieldAttributes.get('referenceTo')).size() > 0) ;
                // Boolean isPolyMorphicLookup = Boolean.valueOf(mapFieldAttributes.get('namePointing'));
                Boolean isSystemField = DeploymentUtils.systemFieldNames.contains(String.valueOf(mapFieldAttributes.get('name')));
                Boolean isLeadSystemField = selectedObjectName == 'lead' && 
                DeploymentUtils.systemLeadFieldNames.contains(String.valueOf(mapFieldAttributes.get('name')));
                Boolean isAllowedSystemField = DeploymentUtils.isAllowedSystemField(String.valueOf(mapFieldAttributes.get('name')), selectedObjectName, rootDataSet.Set_Audit_Fields__c);
                
               if( ( ( isSystemField || isLeadSystemField ) && !isAllowedSystemField ) || 
                    Boolean.valueOf(mapFieldAttributes.get('autoNumber')) ||
                    Boolean.valueOf(mapFieldAttributes.get('deprecatedAndHidden')) ||
                    DeploymentUtils.isFieldBinary(String.valueOf(mapFieldAttributes.get('type'))) ||
                    DeploymentUtils.isFieldAddress(String.valueOf(mapFieldAttributes.get('type'))) ||
                    DeploymentUtils.isFieldRecordType(String.valueOf(mapFieldAttributes.get('name'))) ) {
                    continue;
                }
                
                Boolean isPolyMorphicLookup = false;
                if( !isPolyMorphicLookup ) {
                    
                    Data_Set_Field__c dataSetField = getDataSetFieldObject(dataSetWrapper, String.valueOf(mapFieldAttributes.get('name')));
                    
                    FieldWrapper fieldWrapper = new FieldWrapper();
    
                    fieldWrapper.name = String.valueOf(mapFieldAttributes.get('name'));
                    fieldWrapper.localName = DeploymentUtils.getLocalName( String.valueof(mapFieldAttributes.get('name')) );
                    fieldWrapper.namespace = DeploymentUtils.getNamespace(String.valueof(mapFieldAttributes.get('name')));
                    fieldWrapper.label = String.valueOf(mapFieldAttributes.get('label'));
                    fieldWrapper.ftype = DeploymentUtils.fieldTypeMapping.get(String.valueOf( mapFieldAttributes.get('type')) );
                    fieldWrapper.isScrambleSupportedType = isFieldScrambleSupportedType(fieldWrapper);
                    fieldWrapper.isUpdateable = Boolean.valueOf(mapFieldAttributes.get('updateable'));
                    fieldWrapper.isSelected = isFieldSelected(dataSetField, dataSetWrapper.dataSet);
                    fieldWrapper.isSelectedExternalId = isFieldSelectedExternalId(dataSetField);
                    fieldWrapper.isCreateMissing = isFieldSelectedCreateMissing(dataSetField);
                    fieldWrapper.isSetEmpty = isFieldSelectedSetEmpty(dataSetField);
                    fieldWrapper.isScrambleValue = isFieldSelectedScrambleValue(dataSetField);
                    fieldWrapper.isFixedValue = isFieldSelectedFixedValue(dataSetField);
                    fieldWrapper.fixedValueInput = getFieldSelectedFixedValueInput(dataSetField);
                    fieldWrapper.isSyncPicklistValues = isFieldSelectedSyncPicklistValues(dataSetField);
                    fieldWrapper.isLookup = isLookupField;
                    fieldWrapper.isCustom =  Boolean.valueOf(mapFieldAttributes.get('custom'));
                    fieldWrapper.isSystemField = isSystemField || isLeadSystemField;
                    
                    objectNode.fieldWrappers.add(fieldWrapper);
                    
                }
                
                 if( isLookupField ) {
                   
                    ParentWrapper parentWrapper = new ParentWrapper();
                    parentWrapper.name = String.valueOf(mapFieldAttributes.get('name'));
                    parentWrapper.label = String.valueOf(mapFieldAttributes.get('label'));
                    parentWrapper.isSelected = isParentSelected(dataSetWrapper, String.valueOf(mapFieldAttributes.get('name')));
                    parentWrapper.isDisabled = isParentDisabled(dataSetWrapper, String.valueOf(mapFieldAttributes.get('name')));
                    parentWrapper.isPolymorphic = isPolyMorphicLookup;
            
                    if( isPolyMorphicLookup ) {
                        parentWrapper.parentLabel = 'Polymorphic';
                        parentWrapper.parentName = 'Polymorphic';
                    } else {
                       
                        List<Object> objs = (List<Object>)mapFieldAttributes.get('referenceTo');
                        List<String> lsstr = new List<String>();
                        
                        for(Object a:objs){
                            lsstr.add(String.valueOf(a));
                        }
                        if(mapOriginSchemaByNameAndLabel.containsKey(String.valueOf(objs[0]).toLowerCase()))
                        	parentWrapper.parentLabel = mapOriginSchemaByNameAndLabel.get(String.valueOf(objs[0]).toLowerCase());
                        parentWrapper.parentName = String.valueOf(objs[0]);
                    }
                    
                    objectNode.parentWrappers.add(parentWrapper);
                }
            }
        }
        //MD-74   
        
        private Data_Set_Field__c getDataSetFieldObject(DataSetWrapper dataSetWrapper, String fieldName) {
           /* for( Data_Set_Field__c dataSetField : dataSetWrapper.dataSetFields ) {
                if( dataSetField.Name.toLowerCase() == fieldName.toLowerCase() ) {
                    return dataSetField;
                }
            }
            return null;*/
        return dataSetWrapper.dataSetFieldsByName.get( fieldName.toLowerCase() );
        }
    
        private Boolean isFieldScrambleSupportedType(FieldWrapper fieldWrapper) {
            return fieldWrapper.ftype == 'Boolean' ||
                fieldWrapper.ftype == 'Currency' ||
                fieldWrapper.ftype == 'Date' ||
                fieldWrapper.ftype == 'Date/Time' ||
                fieldWrapper.ftype == 'Double' ||
                fieldWrapper.ftype == 'Email' ||
                fieldWrapper.ftype == 'EncryptedString' ||
                fieldWrapper.ftype == 'Integer' ||
                fieldWrapper.ftype == 'Percent' ||
                fieldWrapper.ftype == 'Phone' ||
                fieldWrapper.ftype == 'String' ||
                fieldWrapper.ftype == 'Text Area' ||
                fieldWrapper.ftype == 'Time' ||
                fieldWrapper.ftype == 'URL';
        }
            
        private Boolean isFieldSelected(Data_Set_Field__c dataSetField, DataSet__c dataSet) {
            return dataSet.All_Fields__c || dataSetField != null;
        }
        
        private Boolean isFieldSelectedExternalId(Data_Set_Field__c dataSetField) {
            return dataSetField != null && dataSetField.External_ID__c;
        }
        
        private Boolean isFieldSelectedCreateMissing(Data_Set_Field__c dataSetField) {
            return dataSetField != null && dataSetField.Create_Missing__c;
        }
        
        private Boolean isFieldSelectedSyncPicklistValues(Data_Set_Field__c dataSetField) {
            return dataSetField != null && dataSetField.Sync_Picklist_Values__c;
        }
        
        private Boolean isFieldSelectedSetEmpty(Data_Set_Field__c dataSetField) {
            return dataSetField != null && dataSetField.Set_Empty__c;
        }
        
        private Boolean isFieldSelectedScrambleValue(Data_Set_Field__c dataSetField) {
            return dataSetField != null && dataSetField.Scramble_Value__c;
        }
        
        private Boolean isFieldSelectedFixedValue(Data_Set_Field__c dataSetField) {
            return dataSetField != null && dataSetField.Fixed_Value__c;
        }
        
        private String getFieldSelectedFixedValueInput(Data_Set_Field__c dataSetField) {
            return dataSetField != null ? dataSetField.Fixed_Value_Input__c : null;
        }
        
        private Boolean isChildSelected(DataSetWrapper dataSetWrapper, ChildWrapper childWrapper) {
            for( RelationshipWrapper relationshipWrapper : dataSetWrapper.childRelationshipWrappers ) {
                if( relationshipWrapper.relationship.Name == childWrapper.relationshipFieldName &&
                    relationshipWrapper.relationship.ChildDataSet__r.ObjectName__c.toLowerCase() == childWrapper.name.toLowerCase() ) {
                    return true;
                }
            }
            
            return false;
        }
        
        private Boolean isParentDisabled(DataSetWrapper dataSetWrapper, String fieldName) {
            return dataSetWrapper.dataSet.ObjectName__c.toLowerCase() == 'eventrelation' &&
                fieldName.toLowerCase() == 'relationid';
        }
        
        private Boolean isParentSelected(DataSetWrapper dataSetWrapper, String fieldName) {
            if( dataSetWrapper.dataSet.ObjectName__c.toLowerCase() == 'eventrelation' &&
                fieldName.toLowerCase() == 'relationid' ) {
                return true;
            }
            
            for( RelationshipWrapper relationshipWrapper : dataSetWrapper.parentRelationshipWrappers ) {
                if( relationshipWrapper.relationship.Name == fieldName ) {
                    return true;
                }
            }
              
            return false;
        }
        
        public class RelationshipWrapper {
            public Relationship__c relationship;
            public DataSetWrapper parentDataSetWrapper;
            public DataSetWrapper childDataSetWrapper;
        }
        
        public class DataSetWrapper {
            public DataSet__c dataSet { get; set; }
            public Boolean isUpsert { get; set; }
            public Boolean isOwnerField { get; set; }
            public Boolean isSearchOnlyManagedChild { get; set; }
            public String recordsToDeployLabel { get; set; }
            public Integer recordsToDeploy;
            public Set<RelationshipWrapper> parentRelationshipWrappers { get; set; }
            public Set<RelationshipWrapper> childRelationshipWrappers { get; set; }
            public List<Data_Set_Field__c> dataSetFields { get; set; }
            public Map<String,Data_Set_Field__c> dataSetFieldsByName { get; set; }
            public Map<Id,Data_Set_Field__c> deletedDataSetFields { get; set; }
            
            public DataSetWrapper() {
                isOwnerField = false;
                isUpsert = false;
                isSearchOnlyManagedChild = false;
                
                parentRelationshipWrappers = new Set<RelationshipWrapper>();
                childRelationshipWrappers = new Set<RelationshipWrapper>();
                dataSetFields = new List<Data_Set_Field__c>();
            dataSetFieldsByName = new Map<String,Data_Set_Field__c>();
                deletedDataSetFields = new Map<Id,Data_Set_Field__c>();
            }
            
            public void setRecordsToDeploy(Integer recordsToDeploy) {
                this.recordsToDeploy = recordsToDeploy;
                recordsToDeployLabel = 'There are ' + recordsToDeploy + ' estimated records to deploy.';
            }
        }
        
        public class ObjectNode {
            public DataSetWrapper dataSetWrapper { get; set; }
            public String label { get; set; }
            public Integer index { get; set; }
            
            public List<FieldWrapper> fieldWrappers { get; set; }
            public List<FieldWrapper> filteredFieldWrappers { get; set; }
            public List<ParentWrapper> parentWrappers { get; set; }
            public List<ChildWrapper> childWrappers { get; set; }
            public List<ChildWrapper> filteredChildWrappers { get; set; }
        }
        
        public boolean isValid() {
            String queryQualifiers = objectNode.dataSetWrapper.dataSet.Query_Filter__c;
            if(originConnection.Local_Connection__c) {
                if(queryQualifiers != null && queryQualifiers.trim() != '')
                {
                    String strQuery = 'Select count() from ' + objectNode.dataSetWrapper.dataSet.ObjectName__c  + ' where ' + queryQualifiers;
                    try{
                        integer  recCount = Database.countQuery(strQuery);
                        return true;
                    }
                    catch(exception e){
                      
                    }
                    return false;
                }
            }
            return true;
        }   
    }