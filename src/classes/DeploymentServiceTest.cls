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
private class DeploymentServiceTest {

    static testMethod void myUnitTest() {
    	
    	Test.startTest();
    	
       	Connection__c sourceConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy',Org_Type__c='Production', Local_Connection__c = false, Active__c = true, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert sourceConnection;
        
        Connection__c targetConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Org_Type__c='Production', Local_Connection__c = false, Active__c = true, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert targetConnection;   
        
        Connection__c localConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy',Org_Type__c='Production', Local_Connection__c = true, Active__c = true, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert localConnection;
        
        DataSet__c dataSetRoot = new DataSet__c(Name = 'ContactDataSet', ObjectName__c = 'contact',Root__c = true, Active__c = true, Origin_Connection__c = localConnection.Id);
        insert dataSetRoot;
        
        DeploymentService.deploy(dataSetRoot.Id, targetConnection.Id);
        
        List<Deployment_Result__c> deploymnetResult = [Select Id from Deployment_Result__c];
        System.assertEquals(1, deploymnetResult.size());
        
         Test.stopTest();
        
    }
}