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
private class DeploymentCenterControllerTest {
	 @testSetup static void setup() {
   	
        Connection__c sourceConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy',Org_Type__c='Production', Local_Connection__c = false, Active__c = true, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert sourceConnection;
        
        Connection__c targetConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Org_Type__c='Production', Local_Connection__c = false, Active__c = true, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert targetConnection;   
        
        Connection__c localConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy',Org_Type__c='Production', Local_Connection__c = true, Active__c = true, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert localConnection;
        
        DataSet__c dataSetParent = new DataSet__c(Name = 'Test', ObjectName__c = 'account', Root__c = false, Active__c = true, Origin_Connection__c = localConnection.Id);
        insert dataSetParent;
        
        DataSet__c dataSetRoot = new DataSet__c(Name = 'ContactDataSet', ObjectName__c = 'contact',Root__c = true, Active__c = true, Origin_Connection__c = localConnection.Id);
        insert dataSetRoot;
        
        DataSet__c dataSetRoot1 = new DataSet__c(Name = 'ContactDataSet', ObjectName__c = 'Test',Root__c = true, Active__c = true, Origin_Connection__c = localConnection.Id);
        insert dataSetRoot1;
        
        DataSet__c dataSetRoot2 = new DataSet__c(Name = 'ContactDataSet', ObjectName__c = 'Test',Root__c = true, Active__c = true, Origin_Connection__c = targetConnection.Id);
        insert dataSetRoot2;
        
        DataSet__c dataSetChild = new DataSet__c(Name = 'OpportunityDataSet', ObjectName__c = 'opportunity',Root__c = false, Active__c = true, Origin_Connection__c = localConnection.Id);
        insert dataSetChild;
        
        Relationship__c relParent = new Relationship__c(Name = 'TestRel', ChildDataSet__c = dataSetRoot.Id, ParentDataSet__c = dataSetParent.Id);
        insert relParent;
        
        Relationship__c relChild = new Relationship__c(Name = 'TestRel', ChildDataSet__c = dataSetChild.Id, ParentDataSet__c = dataSetRoot.Id);
        insert relChild;
                
        Data_Set_Field__c dataSetField = new Data_Set_Field__c(Name = 'Name', Data_Set__c = dataSetRoot.Id);
        insert dataSetField;
           
       Deployment_Result__c result = new Deployment_Result__c();
        insert result;
       	
    }
    
    static testMethod void testDeploymentCenterNoTarget() {
       
       	Test.startTest();
       	
       	List<Connection__c> connections = [Select id, Active__c from Connection__c];
       	for(Connection__c con : connections) {
       		con.Active__c = false;
       	}
       	update connections;
       	
        PageReference pageRef = Page.DeploymentCenter;
        
        Test.setCurrentPageReference(pageRef);
       	
        DeploymentCenterController controller = new DeploymentCenterController();
        
        System.assertEquals(true, (controller.alertMessage).contains('Error loading data set: '+Label.ERROR_NO_ACTIVE_CONNECTION));
        System.assertEquals(true, controller.isAlertshown);
        System.assertEquals(false, controller.isDeployStep);
        System.assertEquals(true, controller.isNoConnectionError);
     
        Test.stopTest();
    }
    
    static testMethod void testDeploymentCenterTargetConnection() {
       
       	Test.startTest();
       	
        PageReference pageRef = Page.DeploymentCenter;
        
        Test.setCurrentPageReference(pageRef);
       	
        DeploymentCenterController controller = new DeploymentCenterController();
        controller.pageSize = 1;
        System.assertEquals(3, controller.targetConnectionOptions.size());
        System.assertEquals(true, controller.isDeployStep);
        System.assertEquals(false, controller.isAlertShown);
        System.assertEquals(true, controller.isDeployDisabled);
        
        Test.stopTest();
    }
 	
 		
 	static testMethod void testDeploymentCenter() {
       
       	Test.startTest();
       	
       	Deployment_Result__c dsR = [Select Id from Deployment_Result__c LIMIT 1];
    	PageReference pageRef = Page.DeploymentCenter;
        
        Test.setCurrentPageReference(pageRef);
        
        DeploymentCenterController controller = new DeploymentCenterController();
        controller.pageSize = 1;
        
        controller.inIt();
        System.assertEquals(3, controller.targetConnectionOptions.size());
        System.assertEquals(true, controller.isDeployStep);
        System.assertEquals(false, controller.isAlertShown);
        System.assertEquals(true, controller.isDeployDisabled);
        System.assertEquals(1,(controller.tempListOfWrapper).size());
        
        controller.next();
        controller.last();
        controller.getNextButtonDisabled();
        controller.getLastButtonDisabled();
        controller.first();
        controller.getFirstButtonDisabled();
        controller.getPreviousButtonDisabled();
        controller.last();
        controller.previous();
        
       
        //controller.onErrorQueryFilter();
        //controller.onSearchDataSets();
        //controller.onSelectShowHidden();
        controller.onDismissAlert();
        controller.onSelect();      
        System.assertEquals(true, controller.isDeployDisabled);
        
        controller.dataSetWrappers.get(0).isSelected = true;
        controller.onSelect();
        System.assertEquals(false, controller.isDeployDisabled);   
        
        String responseBody = '{ "recordId" : "' + dsR.Id + '" ';
        
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody(responseBody);
        PageReference pageRefReturn = DeploymentUtils.processResponse(res);
        System.assertNotEquals(null, pageRefReturn);
        
        res.setStatusCode(505);
        pageRefReturn = DeploymentUtils.processResponse(res);
        System.assertNotEquals(null, pageRefReturn); 
        
        //controller.selectedTargetConnectionId = targetConnection.Id;
        ///controller.doDeploy();
        Test.stopTest();
 	}        
}