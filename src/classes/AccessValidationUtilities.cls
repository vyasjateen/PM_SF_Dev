public with sharing class AccessValidationUtilities {
    public class AccessValidationException extends Exception {}
    
    public static void deleteAsUser(List<SObject> sobjects) {
        Schema.DescribeSObjectResult objectDescribe = sobjects.getSObjectType().getDescribe();
        if( objectDescribe.isDeletable() == false ) {
            throw new AccessValidationException('Permission denied. Unable to delete record in object: ' + objectDescribe.getName());
        }

        delete sobjects;
    }
    
    public static SObject[] upsertRelationshipsAsUser(List<Relationship__c> relationships) {
        Map<String,Schema.DescribeFieldResult> fieldResults = DeploymentUtils.getFieldDescribes( Schema.sObjectType.Relationship__c );
        return AccessValidationUtilities.upsertAsUser(relationships, fieldResults);
    }
    
    public static SObject[] upsertDataSetFieldsAsUser(List<Data_Set_Field__c> dataSetFields) {
        Map<String,Schema.DescribeFieldResult> fieldResults = DeploymentUtils.getFieldDescribes( Schema.sObjectType.Data_Set_Field__c );
        return AccessValidationUtilities.upsertAsUser(dataSetFields, fieldResults);
    }
        
    public static SObject[] upsertDataSetsAsUser(List<DataSet__c> dataSets) {
        Map<String,Schema.DescribeFieldResult> fieldResults = DeploymentUtils.getFieldDescribes( Schema.sObjectType.DataSet__c );
        return AccessValidationUtilities.upsertAsUser(dataSets, fieldResults);
    }
    
    public static SObject[] upsertAsUser(List<SObject> sobjects, Map<String,Schema.DescribeFieldResult> fieldResults) {
        Schema.DescribeSObjectResult objectDescribe = sobjects.getSObjectType().getDescribe();
        if( !objectDescribe.isUpdateable() || !objectDescribe.isCreateable() ) {
            throw new AccessValidationException('Permission denied. Unable to upsert record in object: ' + objectDescribe.getName());
        }
        
        for( Schema.DescribeFieldResult fieldResult : fieldResults.values() ) {
            if( fieldResult.isCustom() && ( !fieldResult.isUpdateable() || !fieldResult.isCreateable() ) 
                && ( !( objectDescribe.getName() == 'Relationship__c' && fieldResult.getName() == 'ParentDataSet__c' ) )
                && ( !( objectDescribe.getName() == 'Data_Set_Field__c' && fieldResult.getName() == 'Data_Set__c' ) ) ) {
                throw new AccessValidationException('Permission denied. Unable to upsert record in object: ' + objectDescribe.getName() + ' and field: ' + fieldResult.getName());
            }
        }
            
        upsert sobjects;
            
        return sobjects;
    }
    
    public static List<Data_Set_Field__c> queryDataSetFieldsAsUser(String queryQualifiers, String additionalQuery) {
        Schema.DescribeSObjectResult objectDescribe = Schema.sObjectType.Data_Set_Field__c;
        Map<String,Schema.DescribeFieldResult> fieldResults = DeploymentUtils.getFieldDescribes(objectDescribe);
        return (List<Data_Set_Field__c>)AccessValidationUtilities.queryAsUser(objectDescribe, fieldResults, queryQualifiers, additionalQuery);
    }
    
    public static DataSet__c queryDataSetAsUser(String queryQualifiers, String additionalQuery) {
        return (DataSet__c)queryDataSetsAsUser(queryQualifiers, additionalQuery).get(0);
    }
  
    public static List<DataSet__c> queryDataSetsAsUser(String queryQualifiers, String additionalQuery) {
        Schema.DescribeSObjectResult objectDescribe = Schema.sObjectType.DataSet__c;
        Map<String,Schema.DescribeFieldResult> fieldResults = DeploymentUtils.getFieldDescribes(objectDescribe);
        SObject[] objectResults = AccessValidationUtilities.queryAsUser(objectDescribe, fieldResults, queryQualifiers, additionalQuery);
        if( objectResults == null || objectResults.size() == 0 ) {
            return null;
        }
        return objectResults;
    }
    
    public static List<DataSet__c> queryDataSetsAsUser(String queryQualifiers) {
        Schema.DescribeSObjectResult objectDescribe = Schema.sObjectType.DataSet__c;
        Map<String,Schema.DescribeFieldResult> fieldResults = DeploymentUtils.getFieldDescribes(objectDescribe);
        return AccessValidationUtilities.queryAsUser(objectDescribe, fieldResults, queryQualifiers);
    }
    
    public static List<Connection__c> queryConnectionsAsUser(String queryQualifiers) {
        Schema.DescribeSObjectResult objectDescribe = Schema.sObjectType.Connection__c;
        Map<String,Schema.DescribeFieldResult> fieldResults = DeploymentUtils.getFieldDescribes(objectDescribe);
        return AccessValidationUtilities.queryAsUser(objectDescribe, fieldResults, queryQualifiers);
    }
    
    public static SObject[] queryAsUser(Schema.DescribeSObjectResult objectDescribe, Map<String,Schema.DescribeFieldResult> fieldResults, String queryQualifiers) {
        return queryAsUser(objectDescribe, fieldResults, queryQualifiers, null);
    }
    
    public static SObject[] queryAsUser(Schema.DescribeSObjectResult objectDescribe, Map<String,Schema.DescribeFieldResult> fieldResults, String queryQualifiers, String additionalQuery) {
        validateObjectFieldsAccessible(objectDescribe, fieldResults);
        
        String sobjectsQuery = 'SELECT ';
        
        for( Schema.DescribeFieldResult fieldResult : fieldResults.values() ) {
            sobjectsQuery += fieldResult.getName() + ','; 
        }
        
        if( additionalQuery != null ) {
            sobjectsQuery += ( ' ' + additionalQuery );
        } else {
            sobjectsQuery = sobjectsQuery.substring(0, sobjectsQuery.length() - 1);
        }
        
        sobjectsQuery += ' from ' + objectDescribe.getName() + ' ' + queryQualifiers;
        
        System.debug('sobjectsQuery****************'+sobjectsQuery);
        return Database.query(sobjectsQuery);
        
    }
    
        
    public static Integer queryCountAsUser(Schema.DescribeSObjectResult objectDescribe, String queryQualifiers) {
        validateObjectAccessible(objectDescribe);
        
        String sobjectsQuery = 'SELECT count() from ' + objectDescribe.getName() + ( String.isBlank( queryQualifiers ) ? ' limit 50000' : ' WHERE ' + queryQualifiers + ' limit 50000' );
        
        return Database.countQuery(sobjectsQuery);
    }
    
    public static void validateObjectFieldsAccessible(Schema.DescribeSObjectResult objectDescribe) {
        Map<String,Schema.DescribeFieldResult> fieldResults = DeploymentUtils.getFieldDescribes(objectDescribe);
        validateObjectFieldsAccessible(objectDescribe, fieldResults);
    }
    
    public static void validateObjectAccessible(Schema.DescribeSObjectResult objectDescribe) {
        if( !objectDescribe.isAccessible() ) {
            throw new AccessValidationException('Permission denied. Unable to query record in object: ' + objectDescribe.getName());
        }
    }
    
    public static void validateObjectFieldsAccessible(Schema.DescribeSObjectResult objectDescribe, Map<String,Schema.DescribeFieldResult> fieldResults) {
        if( !objectDescribe.isAccessible() ) {
            throw new AccessValidationException('Permission denied. Unable to query record in object: ' + objectDescribe.getName());
        }
        
        for( Schema.DescribeFieldResult fieldResult : fieldResults.values() ) {
            if( !fieldResult.isAccessible() ) {
                throw new AccessValidationException('Permission denied. Unable to query record in object: ' + objectDescribe.getName() + ' and field: ' + fieldResult.getName());
            }
        }
    }
    
    public static String getDataSetRelationshipsSubquery() {
        Schema.DescribeSObjectResult objectDescribe = Schema.sObjectType.DataSet__c;
        Map<String,Schema.DescribeFieldResult> fieldResults = DeploymentUtils.getFieldDescribes(objectDescribe);
            
        String query = '(SELECT Id, Name, ChildDataSet__c, ParentDataSet__c from ChildRelationships__r where ChildDataSet__r.Active__c = true' + ')';
        query += ( ', (SELECT Id, Name, ParentDataSet__c, ChildDataSet__c from ParentRelationships__r where ParentDataSet__r.Active__c = true' + ')' );
        
        return query;
    }
    
    public static String getDataSetFieldsSubqueryEditor() {
       Schema.DescribeSObjectResult dataSetFieldObjectDescribe = Schema.sObjectType.Data_Set_Field__c;
        Map<String,Schema.DescribeFieldResult> dataSetFieldFieldResults = DeploymentUtils.getFieldDescribes(dataSetFieldObjectDescribe);
        
        String sobjectsQuery = '(SELECT ';
        
        for( Schema.DescribeFieldResult fieldResult : dataSetFieldFieldResults.values() ) {
            sobjectsQuery += fieldResult.getName() + ','; 
        }
        
        sobjectsQuery = sobjectsQuery.substring(0, sobjectsQuery.length() - 1);
        
        sobjectsQuery += ' from Data_Set_Fields__r)';
            
        return sobjectsQuery;
    }
    
    public static String getDataSetRelationshipsSubqueryEditor() {
        Schema.DescribeSObjectResult objectDescribe = Schema.sObjectType.DataSet__c;
        Map<String,Schema.DescribeFieldResult> fieldResults = DeploymentUtils.getFieldDescribes(objectDescribe);
        
        String childDataSetFieldsQuery = '', parentDataSetFieldsQuery = '';
        
        childDataSetFieldsQuery += ( 'ChildDataSet__r.Id, ChildDataSet__r.ObjectName__c' );
        parentDataSetFieldsQuery += ( 'ParentDataSet__r.Id, ParentDataSet__r.ObjectName__c' );
        
        Schema.DescribeSObjectResult dataSetFieldObjectDescribe = Schema.sObjectType.Data_Set_Field__c;
        Map<String,Schema.DescribeFieldResult> dataSetFieldFieldResults = DeploymentUtils.getFieldDescribes(dataSetFieldObjectDescribe);
            
        String query = '(SELECT Name, ChildDataSet__c, ParentDataSet__c, ' + childDataSetFieldsQuery + ', ' + parentDataSetFieldsQuery + ' from ChildRelationships__r' + ')';
        query += ( ', (SELECT Name, ParentDataSet__c, ChildDataSet__c, ' + parentDataSetFieldsQuery + ', ' + childDataSetFieldsQuery + ' from ParentRelationships__r' + ')' );
        
        return query;
    }
}