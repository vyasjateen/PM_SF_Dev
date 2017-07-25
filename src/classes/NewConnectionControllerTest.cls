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
private class NewConnectionControllerTest {

    static testMethod void connectionController() {
    	PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        NewConnectionController controller = new NewConnectionController(null);
        
        System.assertEquals(true, controller.isSourceConnection);
        
        PageReference oauthPage = controller.doConnect();
        
        System.assertNotEquals(null, oauthPage);
        
    }
    
    static testMethod void testNewConnectionControllerTarget() {
    	
        Connection__c connection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Local_Connection__c = true);
        insert connection;
        
        PageReference pageRef = Page.NewConnectionEditor;
        pageRef.getParameters().put('Id',connection.Id);
        Test.setCurrentPageReference(pageRef);
       
        NewConnectionController controller = new NewConnectionController(new ApexPages.StandardController(connection));
        
        System.assertNotEquals(null, controller.orgTypeOptions);
        
        PageReference oauthPage = controller.doConnect();
        
        System.assertNotEquals(null, oauthPage);
        
        controller.onDismissAlert();
    }
    
}