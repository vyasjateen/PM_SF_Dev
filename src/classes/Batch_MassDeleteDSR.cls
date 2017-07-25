/**
 *  Description     :       Batch to Cleanup DataSetResult
 *
 *  Created By      :       
 *
 *  Created Date    :       07/23/2017
 *
 *  Revision Logs   :       V1.0 - Created
 **/

global with sharing class Batch_MassDeleteDSR implements Database.Batchable<sobject>, Database.Stateful {
    
    public Set<Id> dataSetResultIds;
    public static Set<Id> setDataSetResultId;
    //To hold Query String
    public String strQuery = '';
    public String nameSpaceName = '';
    public String currentObject;
   
    public static void deleteRecordResult(Set<Id> setDResultIds) {
        
        String strClassName = 'Batch_MassDeleteDSR';
        //strClassName = strClassName.substring(0,strClassName.indexOf(':'));
        
        String nameSpaceName = DeploymentUtils.getNameSpacePrefix(strClassName);
        
        setDataSetResultId = setDResultIds;
        Batch_MassDeleteDSR batch = new Batch_MassDeleteDSR();
        batch.dataSetResultIds = setDResultIds;
       
        
        if(nameSpaceName == 'null') 
            batch.nameSpaceName = '';
        else 
            batch.nameSpaceName = nameSpaceName;
        batch.strQuery = 'Select Id from '+batch.nameSpaceName+'Deployment_Record_Result__c where '+batch.nameSpaceName+'Deployment_Data_Set_Result__r.'+batch.nameSpaceName+'Deployment_Result__c in : dataSetResultIds';
        batch.currentObject ='Deployment_Record_Result__c';
        id batchstart = Database.executeBatch(batch,200);
        
    }
    
    //Start method of Batch
    global Database.QueryLocator start(Database.BatchableContext bc){
        
        //return query 
        return Database.getQueryLocator(strQuery);
    }
    
    //Execute method of batch
    global void execute(Database.batchableContext bc, List<Sobject> listData ) {      
        
        
        Database.DeleteResult[] deletedResult = Database.delete(listData, false);

    }
    
    //finish method of batch
    global void finish(Database.batchableContext bc){
        System.debug('setDataSetResultId' + setDataSetResultId );
         System.debug('setDataSetResultId' + dataSetResultIds );
        if(currentObject == 'Deployment_Record_Result__c') {
            //For Deployment_Batch_Result__c
            
            Batch_MassDeleteDSR batch = new Batch_MassDeleteDSR();
            batch.nameSpaceName = nameSpaceName;
            batch.strQuery = 'Select Id from '+batch.nameSpaceName+'Deployment_Batch_Result__c where '+batch.nameSpaceName+'Deployment_Data_Set_Result__r.'+batch.nameSpaceName+'Deployment_Result__c IN : dataSetResultIds';
            batch.dataSetResultIds= dataSetResultIds;
            batch.currentObject = 'Deployment_Batch_Result__c';
            DataBase.executeBatch(batch,200);
        }
        
        else if(currentObject == 'Deployment_Batch_Result__c') {
            //For Deployment_Data_Set_Result__c
            
            Batch_MassDeleteDSR batch = new Batch_MassDeleteDSR();
            batch.nameSpaceName = nameSpaceName;
            batch.strQuery = 'Select Id from '+batch.nameSpaceName+'Deployment_Data_Set_Result__c where '+batch.nameSpaceName+'Deployment_Result__c IN :dataSetResultIds';
            batch.dataSetResultIds= dataSetResultIds;
            batch.currentObject = 'Deployment_Data_Set_Result__c';
            DataBase.executeBatch(batch,200);
        }
        
        else if(currentObject == 'Deployment_Data_Set_Result__c') {
            
            Batch_MassDeleteDSR batch = new Batch_MassDeleteDSR();
            batch.nameSpaceName = nameSpaceName;
            batch.dataSetResultIds= dataSetResultIds;
            batch.strQuery = 'Select Id from '+batch.nameSpaceName+'Deployment_Result__c where Id IN : dataSetResultIds';
            batch.currentObject = '';
            DataBase.executeBatch(batch,200);
        }
        
        else {
            
        }
        
        
    }

    
}