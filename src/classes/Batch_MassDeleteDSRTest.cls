/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Batch_MassDeleteDSRTest {
	@testSetup static void setup() {
		
   		Connection__c sourceConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy',Org_Type__c='Production', Local_Connection__c = false, Active__c = true, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert sourceConnection;
        
        Connection__c targetConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Org_Type__c='Production', Local_Connection__c = false, Active__c = true, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert targetConnection;   
        
        DataSet__c dataSetRoot = new DataSet__c(Name = 'ContactDataSet', ObjectName__c = 'contact',Root__c = true, Active__c = true);
        insert dataSetRoot;
        
        Data_Set_Field__c dataSetField1 = new Data_Set_Field__c(Name = 'Name', Data_Set__c = dataSetRoot.Id);
        insert dataSetField1;
        
        Data_Set_Field__c dataSetField2 = new Data_Set_Field__c(Name = 'LastName', Data_Set__c = dataSetRoot.Id);
        insert dataSetField2;
       	
       	Data_Set_Field__c dataSetField3 = new Data_Set_Field__c(Name = 'FirstName', Data_Set__c = dataSetRoot.Id);
        insert dataSetField3;
           
       	Deployment_Result__c result = new Deployment_Result__c(Source_Connection__c = sourceConnection.Id, Target_Connection__c = targetConnection.Id);
        insert result;
        
        Deployment_Data_Set_Result__c dDSR = new Deployment_Data_Set_Result__c(Data_Set__c = dataSetRoot.Id, Deployment_Result__c = result.Id, Status__c = 'Finished');
        insert dDSR;
        
        Deployment_Batch_Result__c deployBatch = new Deployment_Batch_Result__c(Data_Set__c = dataSetRoot.Id, Deployment_Data_Set_Result__c = dDSR.Id, Job_ID__c = 'XXXX', Result__c = 'Success', Status__c='Finsihed');
        insert deployBatch;
        
        List<Deployment_Record_Result__c> dRecordResults = new List<Deployment_Record_Result__c>();
        dRecordResults.add(new Deployment_Record_Result__c(Data_Set__c = dataSetRoot.Id, Deployment_Batch_Result__c = deployBatch.Id, Deployment_Data_Set_Result__c = dDSR.Id, Record_ID__c ='XXXXX'));
        dRecordResults.add(new Deployment_Record_Result__c(Data_Set__c = dataSetRoot.Id, Deployment_Batch_Result__c = deployBatch.Id, Deployment_Data_Set_Result__c = dDSR.Id, Record_ID__c ='XXXXX'));
        dRecordResults.add(new Deployment_Record_Result__c(Data_Set__c = dataSetRoot.Id, Deployment_Batch_Result__c = deployBatch.Id, Deployment_Data_Set_Result__c = dDSR.Id, Record_ID__c ='XXXXX'));
        dRecordResults.add(new Deployment_Record_Result__c(Data_Set__c = dataSetRoot.Id, Deployment_Batch_Result__c = deployBatch.Id, Deployment_Data_Set_Result__c = dDSR.Id, Record_ID__c ='XXXXX'));
        
        insert dRecordResults;
       	
    }
    
    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        
        Test.startTest();
        
        List<Deployment_Result__c> deploymentResult = [Select Id from Deployment_Result__c];
        
        Set<Id> setIds = new Set<Id>();
        for(Deployment_Result__c ds : deploymentResult)
        	setIds.add(ds.Id);
        
        Batch_MassDeleteDSR.deleteRecordResult (setIds);
        
        Test.stopTest();
        
        List<Deployment_Record_Result__c> fetchDRR = [Select Id from Deployment_Record_Result__c];
        System.assertEquals(0, fetchDRR.size());
                
    	List<Deployment_Batch_Result__c> fetchDBR = [Select Id from Deployment_Batch_Result__c];
    	System.assertEquals(0, fetchDBR.size());
    	
    	List<Deployment_Data_Set_Result__c> fetchDDSR = [Select Id from Deployment_Data_Set_Result__c];
    	System.assertEquals(0, fetchDDSR.size());
    	
    	List<Deployment_Result__c> fetchDR = [Select Id from Deployment_Result__c];
    	System.assertEquals(0, fetchDR.size());
    }
}