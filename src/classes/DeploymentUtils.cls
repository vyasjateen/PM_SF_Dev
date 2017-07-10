public with sharing class DeploymentUtils {
    private static Map<String,Schema.SObjectType> globalSchema;
    private static Map<String,Schema.DescribeSObjectResult> objectDescribes;
    private static Map<String,Map<String,Schema.DescribeFieldResult>> fieldDescribes;
    
    public static final String OWNER_FIELD_NAME = 'OwnerId';
    public static final String RECORD_TYPE_FIELD_NAME = 'RecordTypeId';
    
    public static Set<String> systemFieldNames = new Set<String>{'Id', 'CreatedDate', 'IsDeleted', 'LastActivityDate', 
        'LastModifiedDate', 'LastReferencedDate', 'LastViewedDate', 'SystemModstamp',
        'CreatedById', 'OwnerId', 'LastModifiedById'};

    public static Set<String> systemLeadFieldNames = new Set<String>{'ConvertedDate', 'ConvertedAccountId', 
        'ConvertedContactId', 'ConvertedOpportunityId'};

    public static Set<String> systemAuditFieldNames = new Set<String>{'CreatedDate', 'LastModifiedDate', 
        'CreatedById', 'LastModifiedById'};

    public static Set<String> systemLeadAuditFieldNames = new Set<String>{'ConvertedDate', 'ConvertedAccountId', 
        'ConvertedContactId', 'ConvertedOpportunityId'};

    public static Set<String> auditFieldObjects = new Set<String>{'account', 'campaignmember', 'contact',
        'case', 'casecomment', 'contract', 'feedcomment', 'feeditem', 'idea', 'ideacomment', 'lead', 'opportunity',
        'vote', 'task', 'event', 'attachment'};
  
    public static Map<String,String> fieldTypeMapping = new Map<String,String> {
        String.valueOf( Schema.DisplayType.anytype ) => 'Any Type',
        String.valueOf( Schema.DisplayType.base64 ) => 'Base64',
        String.valueOf( Schema.DisplayType.Boolean ) => 'Boolean',
        String.valueOf( Schema.DisplayType.Combobox ) => 'Combobox',
        String.valueOf( Schema.DisplayType.Currency ) => 'Currency',
        String.valueOf( Schema.DisplayType.DataCategoryGroupReference ) => 'Data Category Group Reference',
        String.valueOf( Schema.DisplayType.Date ) => 'Date',
        String.valueOf( Schema.DisplayType.DateTime ) => 'Date/Time',
        String.valueOf( Schema.DisplayType.Double ) => 'Double',
        String.valueOf( Schema.DisplayType.Email ) => 'Email',
        String.valueOf( Schema.DisplayType.EncryptedString ) => 'EncryptedString',
        String.valueOf( Schema.DisplayType.ID ) => 'ID',
        String.valueOf( Schema.DisplayType.Integer ) => 'Integer',
        String.valueOf( Schema.DisplayType.MultiPicklist ) => 'Picklist (Multi-Select)',
        String.valueOf( Schema.DisplayType.Percent ) => 'Percent',
        String.valueOf( Schema.DisplayType.Phone ) => 'Phone',
        String.valueOf( Schema.DisplayType.Picklist ) => 'Picklist',
        String.valueOf( Schema.DisplayType.Reference ) => 'Reference',
        String.valueOf( Schema.DisplayType.String ) => 'String',
        String.valueOf( Schema.DisplayType.TextArea ) => 'Text Area',
        String.valueOf( Schema.DisplayType.Time ) => 'Time',
        String.valueOf( Schema.DisplayType.URL ) => 'URL'
    };
    
    public final static String URL = CustomSettingsUtilities.getInstance().getBaseUrl() + '/deploy';
        
    public static Boolean isFieldRecordType(Schema.DescribeFieldResult fieldDescribe) {
        return fieldDescribe.getName() == RECORD_TYPE_FIELD_NAME;
    }   
        
    public static Boolean isFieldBinary(Schema.DescribeFieldResult fieldDescribe) {
        return String.valueOf( fieldDescribe.getType() ).equals(String.valueOf( Schema.DisplayType.base64 ) );
    }  
        
    /*public static Boolean isFieldGeolocation(Schema.DescribeFieldResult fieldDescribe) {
        return String.valueOf( fieldDescribe.getType() ).equals(String.valueOf( Schema.DisplayType. ) );
    } */
        
    public static Boolean isFieldAddress(Schema.DescribeFieldResult fieldDescribe) {
        return String.valueOf( fieldDescribe.getType() ).equals(String.valueOf( Schema.DisplayType.Address ) );
    }
    
    public static Boolean isObjectBinaryRequired(Schema.DescribeSObjectResult objectDescribe) {
        Map<String,Schema.DescribeFieldResult> objectFieldDescribes = DeploymentUtils.getFieldDescribes(objectDescribe);
        
        for( Schema.DescribeFieldResult fieldDescribe : objectFieldDescribes.values() ) {
            if( String.valueOf( fieldDescribe.getType() ).equals(String.valueOf( Schema.DisplayType.base64 ) ) &&
                !fieldDescribe.isNillable() ) {
                return true;
            }
        }
        
        return false;
    }
    
    public static Boolean isObjectVisible(Schema.DescribeSObjectResult objectDescribe) {
        if( !objectDescribe.isAccessible() ||
            ( !objectDescribe.isCreateable() && !objectDescribe.isUpdateable() ) ||
            objectDescribe.isDeprecatedAndHidden() ||
            !objectDescribe.isQueryable() ) {
            return false;
        }
        return true;
    }

    public static Boolean isAllowedSystemField(Schema.DescribeFieldResult fieldDescribe, 
        String selectedObjectName, 
        Boolean isAllowAuditFields) {
        if( !isAllowAuditFields|| !isAllowedSystemFieldObject(selectedObjectName) ) {
            return false;
        }

        if( selectedObjectName == 'lead' ) {
            return DeploymentUtils.systemAuditFieldNames.contains( fieldDescribe.getName() ) 
                || DeploymentUtils.systemLeadAuditFieldNames.contains( fieldDescribe.getName() );
        } else {
            return DeploymentUtils.systemAuditFieldNames.contains( fieldDescribe.getName() ) ;
        }
    }

    public static Boolean isAllowedSystemFieldObject(String objectName) {
        return DeploymentUtils.auditFieldObjects.contains( objectName ) ||
            objectName.endsWith('__c');
    }

    public static List<Schema.DescribeFieldResult> getAllDeployableFields(String objectName, Boolean isAllowAuditFields) {
        objectDescribes = DeploymentUtils.getObjectDescribes();
        Schema.DescribeSObjectResult objectDescribe = objectDescribes.get(objectName);
        Map<String,Schema.DescribeFieldResult> objectFieldDescribes = DeploymentUtils.getFieldDescribes(objectDescribe);

        String lowerObjectName = objectName.toLowerCase();
        
        List<Schema.DescribeFieldResult> deployableFields = new List<Schema.DescribeFieldResult>();
        for(String fieldName : objectFieldDescribes.keySet() ) {
            Schema.DescribeFieldResult fieldDescribe = objectFieldDescribes.get(fieldName);
  
            Boolean isLookupField = fieldDescribe.getReferenceTo() != null && fieldDescribe.getReferenceTo().size() > 0;
            Boolean isPolyMorphicLookup = fieldDescribe.isNamePointing();
            Boolean isSystemField = DeploymentUtils.systemFieldNames.contains( fieldDescribe.getName() );
            Boolean isLeadSystemField = lowerObjectName == 'lead' && 
                DeploymentUtils.systemLeadFieldNames.contains( fieldDescribe.getName() );
            Boolean isAllowedSystemField = DeploymentUtils.isAllowedSystemField(fieldDescribe, lowerObjectName, isAllowAuditFields);

            if( !fieldDescribe.isAccessible() || 
                //( !fieldDescribe.isUpdateable() && !fieldDescribe.isCreateable() && fieldName != 'IsStandard' ) || 
                isPolyMorphicLookup ||
                ( ( isSystemField || isLeadSystemField ) && !isAllowedSystemField ) ||
                fieldDescribe.isAutoNumber() ||
                //fieldDescribe.isCalculated() ||
                fieldDescribe.isDeprecatedAndHidden() ) {
                continue;
            }
            
            deployableFields.add(fieldDescribe);
        }
        
        return deployableFields;
    }
    
    public static Map<String,Schema.DescribeSObjectResult> getVisibleObjectDescribes(Integer startIndex, Integer offset) {
        globalSchema = getGlobalDescribe();
        Map<String,Schema.DescribeSObjectResult> pagedObjectDescribes = new Map<String,Schema.DescribeSObjectResult>();
        
        List<String> keyList = new List<String>();
        keyList.addAll( globalSchema.keySet() );
        keyList.sort();
        
        Integer counter = 0;        
        for( String objectName : keyList ) {
            Schema.DescribeSObjectResult objectDescribe = globalSchema.get(objectName).getDescribe();
            
            if( !DeploymentUtils.isObjectVisible(objectDescribe) ) {
                continue;
            }
            
            if( counter < startIndex ) {
                counter++;
                continue;
            } else if( counter >= ( startIndex + offset ) ) {
                break;
            }
            
            counter++;
            
            pagedObjectDescribes.put(objectName, objectDescribe);
        }
        
        return pagedObjectDescribes;
    }
    
    public static Map<String,Schema.DescribeSObjectResult> getObjectDescribes() {
        if( objectDescribes != null ) {
            return objectDescribes;
        }
        
        globalSchema = getGlobalDescribe();
        objectDescribes = new Map<String,Schema.DescribeSObjectResult>();
                
        for( String objectName : globalSchema.keySet() ) {
            Schema.DescribeSObjectResult objectDescribe = globalSchema.get(objectName).getDescribe();
            objectDescribes.put(objectName, objectDescribe);
        }
        
        return objectDescribes;
    }
    
    public static Map<String,Schema.DescribeFieldResult> getFieldDescribes(Schema.DescribeSObjectResult objectDescribe) {
        globalSchema = getGlobalDescribe();
        fieldDescribes = getFieldDescribes();
        
        Map<String,Schema.DescribeFieldResult> objectFieldDescribes = fieldDescribes.get( objectDescribe.getName() );
        if( objectFieldDescribes != null ) {
            return objectFieldDescribes;
        }
        
        Map<String,Schema.SObjectField> objectFields = objectDescribe.fields.getMap();
        
        objectFieldDescribes = new Map<String,Schema.DescribeFieldResult>();
        for( String fieldName : objectFields.keySet() ) {
            Schema.SObjectField objectField = objectFields.get(fieldName);
            Schema.DescribeFieldResult fieldDescribe = objectField.getDescribe();
            objectFieldDescribes.put(fieldName, fieldDescribe);
        }
        
        fieldDescribes.put( objectDescribe.getName(), objectFieldDescribes );
        
        return objectFieldDescribes;
    }
    
    public static Schema.DescribeFieldResult getFieldDescribeByFieldType(Schema.SObjectField fieldType, Schema.DescribeSObjectResult objectDescribe) {
        Map<String,Schema.DescribeFieldResult> objectFieldDescribes = getFieldDescribes( objectDescribe);
        Map<String,Schema.SObjectField> objectFields = objectDescribe.fields.getMap();
        
        for( String fieldName : objectFields.keySet() ) {
            Schema.SObjectField curFieldType = objectFields.get(fieldName);
            if( curFieldType == fieldType ) {
                return objectFieldDescribes.get(fieldName);
            }
        }
        return null;
    }
    
    public static Schema.DescribeSObjectResult getObjectDescribeByObjectName(String objectName) {
        if( objectName == null ) { return null; }
        
        globalSchema = getGlobalDescribe();
        objectDescribes = getObjectDescribes();
        
        return objectDescribes.get( objectName.toLowerCase() );
    }
    
    public static Schema.DescribeSObjectResult getObjectDescribeByObjectType(Schema.SObjectType objectType) {
        return objectType.getDescribe();
        
        /*globalSchema = getGlobalDescribe();
        objectDescribes = getObjectDescribes();
        
        for( String objectName : globalSchema.keySet() ) {
            Schema.SObjectType curObjectType = globalSchema.get(objectName);
            if( curObjectType == objectType ) {
                return objectDescribes.get(objectName);
            }
        }
        return null;*/
    }
    
    public static Map<String,Map<String,Schema.DescribeFieldResult>> getFieldDescribes() {
        if( fieldDescribes == null ) {
            fieldDescribes = new Map<String,Map<String,Schema.DescribeFieldResult>>();
        }
        
        return fieldDescribes;
    }
    
    public static Map<String,Schema.SObjectType> getGlobalDescribe() {
        if( globalSchema != null ) {
            return globalSchema;
        }
        
        globalSchema = Schema.getGlobalDescribe();
        
        return globalSchema;
    }
    
    public static String getLocalName(String name) {
        if( !name.endsWith('__c') ) { //Standard field
            return name;
        }
        
        Integer firstIndex = name.indexOf( '__' );
        Integer lastIndex = name.lastIndexOf( '__' );
        if( firstIndex == lastIndex ) { //Custom field, but no namespace
            return name;
        }
        
        String namespace = name.substring( name.indexOf( '__' ) + 2, name.length() );
        return namespace;
    }
    
    public static String getNamespace(Schema.DescribeFieldResult fieldResult) {
        return getNamespace(fieldResult.getName());
    }
    
    public static String getNamespace(Schema.DescribeSObjectResult objectDescribe) {
        return getNamespace(objectDescribe.getName());
    }
    
    public static String getNamespace(String name) {
        if( !name.endsWith('__c') ) { //Standard field
            return null;
        }
        
        Integer firstIndex = name.indexOf( '__' );
        Integer lastIndex = name.lastIndexOf( '__' );
        if( firstIndex == lastIndex ) { //Custom field, but no namespace
            return null;
        }
        
        String namespace = name.substring( 0, name.indexOf( '__' ) );
        return namespace;
    }
    
    public static List<ComponentWrapperIntf> sortByLabel(List<ComponentWrapperIntf> componentWrappers, System.Type sType) {
        List<String> labels = new List<String>();
        Map<String,ComponentWrapperIntf> labelsMap = new Map<String,ComponentWrapperIntf>();
        Set<String> labelsSets = new Set<String>();
        Map<String,List<ComponentWrapperIntf>> dupLabels = new Map<String,List<ComponentWrapperIntf>>();
        
        for( ComponentWrapperIntf componentWrapper : componentWrappers ) {
            if( labelsSets.contains( componentWrapper.getLabel() ) ) {
                List<ComponentWrapperIntf> curDupLabels = dupLabels.get( componentWrapper.getLabel() );
                if( curDupLabels == null ) {
                    curDupLabels = new List<ComponentWrapperIntf>();
                    dupLabels.put( componentWrapper.getLabel(), curDupLabels );
                }
                curDupLabels.add(componentWrapper);
                continue;
            }
            labelsSets.add( componentWrapper.getLabel() );
            labelsMap.put( componentWrapper.getLabel(), componentWrapper );
            labels.add( componentWrapper.getLabel() );
        }
        
        labels.sort();
        
        List<ComponentWrapperIntf> tmpComponentWrappers = componentWrappers;
        
        if( sType.equals( FieldWrapper.class ) ) {
            componentWrappers = new List<FieldWrapper>();   
        } else if( sType.equals( ParentWrapper.class ) ) {
            componentWrappers = new List<ParentWrapper>();  
        } else if( sType.equals( ChildWrapper.class ) ) {
            componentWrappers = new List<ChildWrapper>();   
        }
        
        for( String label : labels ) {
            ComponentWrapperIntf componentWrapper = labelsMap.get(label);
            componentWrappers.add(componentWrapper);
            List<ComponentWrapperIntf> curDupLabels = dupLabels.get(label);
            if( curDupLabels != null ) {
                componentWrappers.addAll(curDupLabels);
            }
        }
        
        return componentWrappers;
    }
    
    public static List<SelectOption> sortByLabel(List<SelectOption> selectOptions) {
        List<String> labels = new List<String>();
        Map<String,SelectOption> labelsMap = new Map<String,SelectOption>();
        Map<String,List<SelectOption>> dupLabels = new Map<String,List<SelectOption>>();
        
        for( SelectOption selectOption : selectOptions ) {
            if( labelsMap.keySet().contains( selectOption.getLabel() ) ) {
                List<SelectOption> curDupLabels = dupLabels.get( selectOption.getLabel() );
                if( curDupLabels == null ) {
                    curDupLabels = new List<SelectOption>();
                    dupLabels.put( selectOption.getLabel(), curDupLabels );
                }
                curDupLabels.add(selectOption);
                continue;
            }
            labelsMap.put( selectOption.getLabel(), selectOption );
            labels.add( selectOption.getLabel() );
        }
        
        labels.sort();
        
        List<SelectOption> tmpSelectOptions = selectOptions;
        selectOptions = new List<SelectOption>();
        
        for( String label : labels ) {
            selectOptions.add( labelsMap.get(label) );
            List<SelectOption> curDupLabels = dupLabels.get(label);
            if( curDupLabels != null ) {
                selectOptions.addAll(curDupLabels);
            }
        }
        
        return selectOptions;
    }
        
    public static void generateDeploymentParameter(List<DataSet__c> dataSets, Connection__c localConnection,
        Connection__c sourceConnection, 
        Connection__c targetConnection,
        Id deploymentResultId,
        JSONGenerator generator) {

        DataSet__c rootDataSet = new DataSet__c();

        for( DataSet__c dataSet : dataSets ) {
            if( dataSet.Root__c ) {
                rootDataSet = dataSet;
                break;
            }
        }

        Map<Id,DataSet__c> cachedDataSets = new Map<Id,DataSet__c>();
            
        generator.writeStartObject();
        
        generator.writeStringField('deploymentResultId', deploymentResultId);
        generator.writeBooleanField('noRecordResults', CustomSettingsUtilities.getInstance().getCustomSettings().No_Record_Results__c);
        generator.writeStringField('submitterId', UserInfo.getUserId());
        generator.writeStringField('submitterEmail', [SELECT Email from User where Id = :UserInfo.getUserId()].Email);
        generator.writeStringField('submitterOrgId', UserInfo.getOrganizationId());
       	//Jira 284
       	generator.writeStringField('packageNameSpace', 'null');
       	generator.writeStringField('isNewRequest', 'true');
        generator.writeFieldName('deploymentDataSets');
        generator.writeStartArray();
        
        for( DataSet__c dataSet : dataSets ) {
            generator.writeStartObject();
            generator.writeFieldName('dataSets');
            generator.writeStartArray();    
            processDataSet(dataSet.Id, generator, new Set<String>(), cachedDataSets, rootDataSet);
            generator.writeEndArray();
            generator.writeEndObject();
        }
        
        generator.writeEndArray();
        
        generator.writeFieldName('sourceOrgConnection');        
        processConnection(sourceConnection, generator);
        
        generator.writeFieldName('targetOrgConnection');        
        processConnection(targetConnection, generator);
        
		generator.writeFieldName('localOrgConnection');
        processConnection(localConnection, generator);
	
        generator.writeEndObject();
    }
    
    /*This method will be delete
    */
    /*public static void generateDeploymentParameter(List<DataSet__c> dataSets,
        Connection__c sourceConnection, 
        Connection__c targetConnection,
        Id deploymentResultId,
        JSONGenerator generator) {

        DataSet__c rootDataSet = new DataSet__c();

        for( DataSet__c dataSet : dataSets ) {
            if( dataSet.Root__c ) {
                rootDataSet = dataSet;
                break;
            }
        }

        Map<Id,DataSet__c> cachedDataSets = new Map<Id,DataSet__c>();
            
        generator.writeStartObject();
        
        generator.writeStringField('deploymentResultId', deploymentResultId);
        generator.writeBooleanField('noRecordResults', CustomSettingsUtilities.getInstance().getCustomSettings().No_Record_Results__c);
        generator.writeStringField('submitterId', UserInfo.getUserId());
        generator.writeStringField('submitterEmail', [SELECT Email from User where Id = :UserInfo.getUserId()].Email);
        generator.writeStringField('submitterOrgId', UserInfo.getOrganizationId());
       
        generator.writeFieldName('deploymentDataSets');
        generator.writeStartArray();
        
        for( DataSet__c dataSet : dataSets ) {
            generator.writeStartObject();
            generator.writeFieldName('dataSets');
            generator.writeStartArray();    
            processDataSet(dataSet.Id, generator, new Set<String>(), cachedDataSets, rootDataSet);
            generator.writeEndArray();
            generator.writeEndObject();
        }
        
        generator.writeEndArray();
        
        generator.writeFieldName('sourceOrgConnection');        
        processConnection(sourceConnection, generator);
        
        generator.writeFieldName('targetOrgConnection');        
        processConnection(targetConnection, generator);
       
        generator.writeEndObject();
    }*/
    
    private static void processConnection(Connection__c connection, JSONGenerator generator) {
        generator.writeStartObject();
        generator.writeStringField('recordId', connection.Id);
        generator.writeStringField('refreshToken', connection.Refresh_Token__c);
        generator.writeStringField('orgType', connection.Org_Type__c);
        generator.writeStringField('orgId', connection.OrganizationId__c);
        generator.writeStringField('userId', connection.User_Id__c);
        generator.writeEndObject();
    }
    
    private static void processDataSet(Id dataSetId, 
    JSONGenerator generator,
    Set<String> coveredDataSets, 
    Map<Id,DataSet__c> cachedDataSets,
    DataSet__c rootDataSet) {
        if( coveredDataSets.contains( dataSetId ) ) {
            return;
        }
        
        coveredDataSets.add( dataSetId );
        
        DataSet__c dataSet = queryDataSet( dataSetId, cachedDataSets );

        String lowerObjectName = dataSet.ObjectName__c.toLowerCase();
        
        generator.writeStartObject();
        generator.writeStringField('id', dataSet.Id);
        generator.writeStringField('name', dataSet.Name);
        generator.writeStringField('sobjectName', dataSet.ObjectName__c);
        generator.writeBooleanField('replicateOwner', dataSet.Replicate_Owner__c);
        generator.writeBooleanField('replicateRecordType', dataSet.Replicate_Record_Type__c);
        generator.writeBooleanField('createMissing', dataSet.Create_Missing__c);
        generator.writeBooleanField('syncPicklistValues', dataSet.Sync_Picklist_Values__c);
        generator.writeBooleanField('setAuditFields', dataSet.Set_Audit_Fields__c);
        generator.writeBooleanField('ignoreNamespace', dataSet.Ignore_Namespace__c);
        generator.writeBooleanField('ignoreRelationshipConstraints', dataSet.Ignore_Relationship_Constraints__c);
        
        if( String.isNotBlank( dataSet.Ignore_Namespace_Name__c ) ) {
            generator.writeStringField('ignoreNamespaceName', dataSet.Ignore_Namespace_Name__c);
        }
        
        if( String.isNotBlank( dataSet.Custom_Upsert_Record_Handling__c ) ) {
            generator.writeStringField('customUpsertRecordHandling', dataSet.Custom_Upsert_Record_Handling__c);
        }
        
        if( String.isNotBlank( dataSet.Query_Filter__c ) ) {
            generator.writeStringField('queryFilter', dataSet.Query_Filter__c);
        }
        
        //If all fields option, get latest schema, compare with currently stored fields, throw out deleted fields, add new fields
        //List<Data_Set_Field__c> savedDataSetFields = DeploymentUtils.queryDataSetFields( dataSet.Id );
        
        List<Data_Set_Field__c> dataSetFields;

        if( dataSet.All_Fields__c ) {
            dataSetFields = new List<Data_Set_Field__c>();
            
            List<Schema.DescribeFieldResult> deployableDieldDescribes = DeploymentUtils.getAllDeployableFields( dataSet.ObjectName__c, rootDataSet.Set_Audit_Fields__c );
            for( Schema.DescribeFieldResult fieldDescribe : deployableDieldDescribes ) {
                Boolean isLookupField = fieldDescribe.getReferenceTo() != null && fieldDescribe.getReferenceTo().size() > 0;
                Boolean isAllowedSystemField = DeploymentUtils.isAllowedSystemField(fieldDescribe, lowerObjectName, rootDataSet.Set_Audit_Fields__c);

                Data_Set_Field__c dataSetField = getDataSetField(dataSet, fieldDescribe.getName());
                if( dataSetField == null &&
                    ( ( !fieldDescribe.isUpdateable() && !fieldDescribe.isCreateable() && !isAllowedSystemField ) && fieldDescribe.getName() != 'IsStandard' && !fieldDescribe.isCalculated() ) ) {
                    continue;
                } else if( dataSetField == null &&
                     ( isLookupField && !isAllowedSystemField ) ) {
                    continue;
                } else if( dataSetField == null ) {
                    dataSetField = new Data_Set_Field__c(Name = fieldDescribe.getName(), External_ID__c = false);
                }
                dataSetFields.add(dataSetField);
            }
            
        } else {
            //if( dataSet.Data_Set_Fields__r.size() >= 250 ) {
                dataSetFields = DeploymentUtils.queryDataSetFields( dataSet.Id );
            /*} else {
                dataSetFields = dataSet.Data_Set_Fields__r;
            }*/
        }
        
        /*if( dataSetFields.size() == 0 ) {
            throw new DeploymentException('Please select at least one field for deployment or enable the all fields option for the data set: ' + dataSet.Name);
        }*/
        
        generator.writeFieldName('dataSetFields');
        generator.writeStartArray();
        for( Data_Set_Field__c dataSetField : dataSetFields ) {
            generator.writeStartObject();
            generator.writeObjectField('name', dataSetField.Name);
            generator.writeBooleanField('externalId', dataSetField.External_ID__c);
            generator.writeBooleanField('createMissing', dataSetField.Create_Missing__c);
            generator.writeBooleanField('syncPicklistValues', dataSetField.Sync_Picklist_Values__c);
            generator.writeBooleanField('setEmpty', dataSetField.Set_Empty__c);
            generator.writeBooleanField('scrambleValue', dataSetField.Scramble_Value__c);
            generator.writeBooleanField('fixedValue', dataSetField.Fixed_Value__c);
            if( dataSetField.Fixed_Value_Input__c != null ) {
                generator.writeStringField('fixedValueInput', dataSetField.Fixed_Value_Input__c);
            }
            generator.writeEndObject();
        }
        generator.writeEndArray();
        
        generator.writeFieldName('childDataSetRelationships');
        generator.writeStartArray();
        for( Relationship__c childRelationship : dataSet.ChildRelationships__r ) {
            generator.writeStartObject();
            generator.writeObjectField('id', childRelationship.ChildDataSet__c);
            generator.writeObjectField('name', childRelationship.Name);
            generator.writeObjectField('relationshipId', childRelationship.Id);
            generator.writeEndObject();
        }
        generator.writeEndArray();
        
        generator.writeFieldName('parentDataSetRelationships');
        generator.writeStartArray();
        for( Relationship__c parentRelationship : dataSet.ParentRelationships__r ) {
            generator.writeStartObject();
            generator.writeObjectField('id', parentRelationship.ParentDataSet__c);
            generator.writeObjectField('name', parentRelationship.Name);
            generator.writeObjectField('relationshipId', parentRelationship.Id);
            generator.writeEndObject();
        }
        generator.writeEndArray();
        
        generator.writeEndObject();
        
        for( Relationship__c childRelationship : dataSet.ChildRelationships__r ) {
            processDataSet(childRelationship.ChildDataSet__c, generator, coveredDataSets, cachedDataSets, rootDataSet);
        }
        
        for( Relationship__c parentRelationship : dataSet.ParentRelationships__r ) {
            processDataSet(parentRelationship.ParentDataSet__c, generator, coveredDataSets, cachedDataSets, rootDataSet);
        }
    }
    
    //public static Data_Set_Field__c getDataSetField(List<Data_Set_Field__c> dataSetFields, String fieldName) {
    public static Data_Set_Field__c getDataSetField(DataSet__c dataSet, String fieldName) {
        for( Data_Set_Field__c dataSetField :  dataSet.Data_Set_Fields__r ) {
            if( dataSetField.Name == fieldName ) {
                return dataSetField;
            }
        }
        return null;
    }
    
    public static DataSet__c queryDataSet(Id dataSetId, Map<Id,DataSet__c> cachedDataSets) {
        if( cachedDataSets.get(dataSetId) != null ) {
            return cachedDataSets.get(dataSetId);
        }
        
        AccessValidationUtilities.validateObjectFieldsAccessible( Schema.sObjectType.Relationship__c );
        String additionalQuery = AccessValidationUtilities.getDataSetRelationshipsSubquery() + ', ' + AccessValidationUtilities.getDataSetFieldsSubqueryEditor();
        DataSet__c rootDataSet = AccessValidationUtilities.queryDataSetAsUser('where Id = \'' + dataSetId + '\' AND Active__c = true', additionalQuery);
        
        cachedDataSets.put(dataSetId, rootDataSet);
        
        return rootDataSet;
    }
     
    public static List<DataSet__c> queryAllDataSetsAll() {
        AccessValidationUtilities.validateObjectFieldsAccessible( Schema.sObjectType.Relationship__c );
        String additionalQuery = AccessValidationUtilities.getDataSetRelationshipsSubqueryEditor() + ', ' + AccessValidationUtilities.getDataSetFieldsSubqueryEditor();
        return AccessValidationUtilities.queryDataSetsAsUser('', additionalQuery);
    }
    
    public static DataSet__c queryDataSetAll(Id dataSetId) {
        AccessValidationUtilities.validateObjectFieldsAccessible( Schema.sObjectType.Relationship__c );
        String additionalQuery = AccessValidationUtilities.getDataSetRelationshipsSubqueryEditor() + ', ' + AccessValidationUtilities.getDataSetFieldsSubqueryEditor();
        DataSet__c rootDataSet = AccessValidationUtilities.queryDataSetAsUser('where Id = \'' + dataSetId + '\'', additionalQuery);
        
        return rootDataSet;
    }
    
    public static List<Data_Set_Field__c> queryDataSetFields(Id dataSetId) {
        AccessValidationUtilities.validateObjectFieldsAccessible( Schema.sObjectType.Data_Set_Field__c );   

        List<Data_Set_Field__c> dataSetFields = AccessValidationUtilities.queryDataSetFieldsAsUser('where Data_Set__c = \'' + dataSetId + '\'', null);
        
        return dataSetFields;
    }
    
    public static Deployment_Result__c parseDeploymentResult(String response) {
        System.JSONParser parser = JSON.createParser(response);
        
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME &&
                parser.getCurrentName() == 'recordId') {
                parser.nextToken();
                Deployment_Result__c result = new Deployment_Result__c(Id = parser.getIdValue());
                return result;
            }
        }
        
        return null;
    }
    
    public static PageReference processResponse(HttpResponse res) {
        Deployment_Result__c result = DeploymentUtils.parseDeploymentResult(res.getBody());
        
        PageReference pageRef = new PageReference('/' + result.Id);
        pageRef.setRedirect(true);
        
        return pageRef;
    }
    
    public static Id insertDeploymentResult(Id sourceConnectionId, Id targetConnectionId,Integer totalDataSet) {
        Deployment_Result__c deploymentResult = new Deployment_Result__c(Source_Connection__c = sourceConnectionId,
            Target_Connection__c = targetConnectionId,Total_DataSet__c = totalDataSet,
            Status__c = 'Started');
        
        insert deploymentResult;
        
        return deploymentResult.Id;
    }
    
    private static Boolean trackDeployment(String jsonstring) {
        try {
            ReplicateIt_Settings__c customSettings = CustomSettingsUtilities.getInstance().getCustomSettings();
            
            if( !customSettings.Debug_Deployment__c || String.isBlank( customSettings.Debug_Deployment_Email__c ) ) {
                return false;
            }
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            mail.setToAddresses( customSettings.Debug_Deployment_Email__c.split(',') );
            mail.setUseSignature(false);
            mail.setReplyTo('no-reply@prodly.co');
            mail.setSubject('Moover Deployment Debug Tracking');
            mail.setPlainTextBody(jsonstring);
            mail.setHtmlBody(jsonstring);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail}, true);
        } catch(Exception e) {
            System.debug('Error sending deployment debug tracking: ' + e.getMessage() + ' : ' + e.getStackTraceString());
        }
        
        return true;
    }
        
    @future( callout = true )
    public static void launchDeployment(String jsonstring, Id deploymentResultId) {
        Boolean isTrackDeployment = trackDeployment(jsonstring);
        if( isTrackDeployment ) {
            return;
        }
        
        Deployment_Result__c deploymentResult = new Deployment_Result__c(Id = deploymentResultId);
        
        try {
        	
        	System.debug('jsonstring(((((((((((((())))))))))))))'+jsonstring);
            Http http = new Http();
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint( DeploymentUtils.URL );
            req.setMethod('POST');
            req.setBody(jsonstring);
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);
            
            HttpResponse res = http.send(req);
            
            System.debug(logginglevel.INFO, 'Sending json: ' + jsonstring);        
            
            if( res.getStatusCode() == 200 ) {
                return;
            }
            
            String alertMessage = 'Error submitting deployment set, error code: ' + res.getStatusCode() + 
                ' : error message: ' + res.getBody();
                
            deploymentResult.Error__c = alertMessage;
        } catch(Exception e) {
            deploymentResult.Error__c = e.getMessage();
        }
            
        deploymentResult.Result__c = 'Failure';
        deploymentResult.Status__c = 'Finished';
        
        update deploymentResult;
    }
    
    public class DeploymentException extends Exception {}
}