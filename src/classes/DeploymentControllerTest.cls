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
private class DeploymentControllerTest {

    
    static testMethod void deploymentTestLocalNotExists() {
    	
    	Test.startTest();
	 	Connection__c sourceConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Local_Connection__c = false, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert sourceConnection;
        
        Connection__c targetConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Local_Connection__c = false, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert targetConnection;
        
        DataSet__c dataSet = new DataSet__c(Name = 'Test', ObjectName__c = 'account',Origin_Connection__c = sourceConnection.Id, Active__c = true);
        insert dataSet;
        
        Data_Set_Field__c dataSetField = new Data_Set_Field__c(Name = 'Name', Data_Set__c = dataSet.Id);
        insert dataSetField;
        
       
        PageReference pageRef = Page.DeployDataSet;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(dataSet);
        DeploymentController controller = new DeploymentController(sc);
        controller.selectedTargetConnectionId = targetConnection.Id;
        controller.selectedSourceConnectionId = sourceConnection.Id;
        Test.stopTest();
        
    }
    static testMethod void deploymentTest() {
    	
    	Test.startTest();
	 	Connection__c sourceConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Local_Connection__c = true, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert sourceConnection;
        
        Connection__c targetConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Local_Connection__c = false, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert targetConnection;
        
        DataSet__c dataSet = new DataSet__c(Name = 'Test', ObjectName__c = 'account',Origin_Connection__c = sourceConnection.Id);
        insert dataSet;
        
        Data_Set_Field__c dataSetField = new Data_Set_Field__c(Name = 'Name', Data_Set__c = dataSet.Id);
        insert dataSetField;
        
       
        PageReference pageRef = Page.DeployDataSet;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(dataSet);
        DeploymentController controller = new DeploymentController(sc);
        controller.selectedTargetConnectionId = targetConnection.Id;
        controller.selectedSourceConnectionId = sourceConnection.Id;
        Test.stopTest();
        
    }
    
    static testMethod void deploymentTargetTest() {
    	
    	Test.startTest();
	 	Connection__c sourceConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Local_Connection__c = true, Active__c = false);
        insert sourceConnection;
        
        Connection__c targetConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Local_Connection__c = false, Active__c = false);
        insert targetConnection;
        
        DataSet__c dataSet = new DataSet__c(Name = 'Test', ObjectName__c = 'account',Origin_Connection__c = sourceConnection.Id);
        insert dataSet;
        
        Data_Set_Field__c dataSetField = new Data_Set_Field__c(Name = 'Name', Data_Set__c = dataSet.Id);
        insert dataSetField;
        
       
        PageReference pageRef = Page.DeployDataSet;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(dataSet);
        DeploymentController controller = new DeploymentController(sc);
        controller.selectedTargetConnectionId = targetConnection.Id;
        controller.selectedSourceConnectionId = sourceConnection.Id;
        Test.stopTest();
        
    }
    
    static testMethod void deploymentDoDeployTest() {
    	
    	Test.startTest();
	 	Connection__c sourceConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Local_Connection__c = true, Active__c = true);
        insert sourceConnection;
        
        Connection__c targetConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Local_Connection__c = false, Active__c = true);
        insert targetConnection;
        
        DataSet__c dataSetParent = new DataSet__c(Name = 'Test', ObjectName__c = 'account',Origin_Connection__c = sourceConnection.Id, Root__c = false);
        insert dataSetParent;
        
        DataSet__c dataSetRoot = new DataSet__c(Name = 'ContactDataSet', ObjectName__c = 'contact',Origin_Connection__c = sourceConnection.Id, Root__c = true);
        insert dataSetRoot;
        
        DataSet__c dataSetChild = new DataSet__c(Name = 'OpportunityDataSet', ObjectName__c = 'opportunity',Origin_Connection__c = sourceConnection.Id, Root__c = false);
        insert dataSetChild;
        
        Relationship__c relParent = new Relationship__c(Name = 'TestRel', ChildDataSet__c = dataSetRoot.Id, ParentDataSet__c = dataSetParent.Id);
        insert relParent;
        
        Relationship__c relChild = new Relationship__c(Name = 'TestRel', ChildDataSet__c = dataSetChild.Id, ParentDataSet__c = dataSetRoot.Id);
        insert relChild;
        
        
        Data_Set_Field__c dataSetField = new Data_Set_Field__c(Name = 'Name', Data_Set__c = dataSetRoot.Id);
        insert dataSetField;
        
       
        PageReference pageRef = Page.DeployDataSet;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(dataSetRoot);
        DeploymentController controller = new DeploymentController(sc);
        controller.selectedTargetConnectionId = targetConnection.Id;
        controller.selectedSourceConnectionId = sourceConnection.Id;
        
        controller.doDeploy();
        controller.countResult = String.valueOf(3);
        controller.onDismissAlert();
        controller.onUpdateQueryFilter();
        controller.onErrorQueryFilter();
        Test.stopTest();
        
    }
    
    static testMethod void deploymentDoDeployTestOrigin() {
    	
    	Test.startTest();
	 	Connection__c sourceConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy',Org_Type__c='Production', Local_Connection__c = true, Active__c = true, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert sourceConnection;
        
        Connection__c targetConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Org_Type__c='Production', Local_Connection__c = false, Active__c = true, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert targetConnection;
        
        DataSet__c dataSetParent = new DataSet__c(Name = 'Test', ObjectName__c = 'account',Origin_Connection__c = targetConnection.Id, Root__c = false);
        insert dataSetParent;
        
        DataSet__c dataSetRoot = new DataSet__c(Name = 'ContactDataSet', ObjectName__c = 'contact',Origin_Connection__c = targetConnection.Id, Root__c = true);
        insert dataSetRoot;
        
        DataSet__c dataSetChild = new DataSet__c(Name = 'OpportunityDataSet', ObjectName__c = 'opportunity',Origin_Connection__c = targetConnection.Id, Root__c = false);
        insert dataSetChild;
        
        Relationship__c relParent = new Relationship__c(Name = 'TestRel', ChildDataSet__c = dataSetRoot.Id, ParentDataSet__c = dataSetParent.Id);
        insert relParent;
        
        Relationship__c relChild = new Relationship__c(Name = 'TestRel', ChildDataSet__c = dataSetChild.Id, ParentDataSet__c = dataSetRoot.Id);
        insert relChild;
        
        
        Data_Set_Field__c dataSetField = new Data_Set_Field__c(Name = 'Name', Data_Set__c = dataSetRoot.Id);
        insert dataSetField;
        
       
        PageReference pageRef = Page.DeployDataSet;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(dataSetRoot);
        DeploymentController controller = new DeploymentController(sc);
        controller.selectedTargetConnectionId = targetConnection.Id;
        controller.selectedSourceConnectionId = sourceConnection.Id;
        
        controller.doDeploy();
        controller.countResult = String.valueOf(3);
        controller.onDismissAlert();
        controller.onUpdateQueryFilter();
        controller.onErrorQueryFilter();
        Test.stopTest();
        
    }
}