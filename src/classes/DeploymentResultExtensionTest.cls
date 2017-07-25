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
@isTest(seeAllData=false)
private class deploymentResultExtensionTest{

    static testmethod void constructorTest() {
        // set up some test data to work with
        // select user profile
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        
        // create instance of user
        User u = new User(Alias = 'standt', Email='standarduser1@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName=Math.random() + '@testorg.com');
        
        // create user    
        insert u;
        
        // create instance of connection 
        Connection__c connection = new Connection__c(Name = 'Test 1' ,
                                        //CurrencyIsoCode='',
                                        Access_Token__c='1234',
                                        Refresh_Token__c='1234',
                                        Active__c=true,
                                        Expires_On__c=null,
                                        Local_Connection__c = true,
                                        OrganizationId__c=UserInfo.getOrganizationId(),
                                        Org_Type__c='Production',
                                        //Source_Connection__c=null,
                                        User_Email__c =u.Email,
                                        User_Full_Name__c=u.Name,
                                        User_Id__c=u.Id,
                                        Username__c=u.UserName);
            
        insert connection;
        
        DataSet__c dataSetRoot = new DataSet__c(Name = 'ContactDataSet', ObjectName__c = 'contact',Root__c = true, Active__c = true, Origin_Connection__c = connection.Id);
        insert dataSetRoot;
        
        // get connection list
        List<Connection__c> con = [Select Id,Name From Connection__c limit 1];
        // create list variable of Deployment_Result__c
        List<Deployment_Result__c> deploymentResult =  New List<Deployment_Result__c>();
        
        // create records in Deployment_Result__c with deployment result status=STARTED
        deploymentResult.add(New Deployment_Result__c(
            //Name = 'Test Deployment',
            //CurrencyIsoCode='',
            Result__c=null,
            Target_Connection__c=con[0].Id,   
            Source_Connection__c=con[0].Id,
            Status__c=ProdlyConstants.STARTED                     
        ));
        // create records in Deployment_Result__c with deployment result status=STOPPED
        deploymentResult.add(New Deployment_Result__c(
            Result__c=null,
            Target_Connection__c=con[0].Id,   
            Source_Connection__c=con[0].Id,
            Status__c=ProdlyConstants.STOPPED                     
        ));
        // create records in Deployment_Result__c with deployment result status=PAUSED
        deploymentResult.add(New Deployment_Result__c(
            Result__c=null,
            Target_Connection__c=con[0].Id,   
            Source_Connection__c=con[0].Id,
            Status__c=ProdlyConstants.PAUSED                      
        ));
        // create records in Deployment_Result__c with deployment result status=FINISHED
        deploymentResult.add(New Deployment_Result__c(
            Result__c=null,
            Target_Connection__c=con[0].Id,   
            Source_Connection__c=con[0].Id,
            Status__c=ProdlyConstants.FINISHED                        
        ));
        // create records in Deployment_Result__c with deployment result status=FINISHED
        deploymentResult.add(New Deployment_Result__c(
            Result__c=null,
            Target_Connection__c=con[0].Id,   
            Source_Connection__c=con[0].Id,
            Status__c= ''                       
        ));
        try{
            insert deploymentResult;  
        }catch(exception e){
            system.debug(e);
        }   
        
      	Deployment_Data_Set_Result__c dDSR = new Deployment_Data_Set_Result__c(Data_Set__c = dataSetRoot.Id, Deployment_Result__c = deploymentResult[0].Id, Status__c = 'Started');
        insert dDSR;                        
    
        
        Test.startTest();
        
        // Mockup class - generate test date responce 
        Test.setMock(HttpCalloutMock.class, new ProdlyMockHttpResponseGenerator());
        //Test.setCurrentPage(Page.deploymentResults);
        // set page url parameter
        System.currentPageReference().getParameters().put('id', deploymentResult[0].Id);
        // pass deployment result value in a constructor. 
        deploymentResultExtension controller = new deploymentResultExtension(new ApexPages.StandardController(deploymentResult[0]));
        // start deployment service
        controller.startServiceCall();
        
        // pause deployment service
        controller.pauseService();
        
        // resume deployment service
        controller.resumeService();
        // stop deployment service
        controller.stopService(); 
        
        
        // value assignment in a variables 
        String UserID = u.Id;
        String userEmail = u.Email;
        String deploymentResultId = deploymentResult[0].Id;
        //-----------------------------------------
        // Frst test request for start deployment service 
        Http h = new Http();        
        HttpRequest req1 = new HttpRequest();
        // set end point for http callout
        req1.setEndpoint(ProdlyConstants.WEB_SERVICE_URL+'/action');
        // Set web service Type 
        req1.setMethod('POST');
        // parameters for web service        
        String params = 'userId='+EncodingUtil.urlEncode(UserID, 'UTF-8')+'&userEmail='+EncodingUtil.urlEncode(userEmail, 'UTF-8')+'&deploymentResultId='+EncodingUtil.urlEncode(deploymentResultId, 'UTF-8')+'&action='+ProdlyConstants.STARTED ;
        req1.setBody(params);
        HttpResponse res1 = h.send(req1);
        System.assertEquals(ProdlyConstants.STARTED, res1.getBody());

        // Second test request for pause deployment service        
        HttpRequest req2 = new HttpRequest();
        // set end point for http callout
        req2.setEndpoint(ProdlyConstants.WEB_SERVICE_URL+'/action');
        // Set web service Type 
        req2.setMethod('POST');
        // parameters for web service        
        String params2 = 'userId='+EncodingUtil.urlEncode(UserID, 'UTF-8')+'&userEmail='+EncodingUtil.urlEncode(userEmail, 'UTF-8')+'&deploymentResultId='+EncodingUtil.urlEncode(deploymentResultId, 'UTF-8')+'&action='+ProdlyConstants.PAUSED ;
        req2.setBody(params2);
        HttpResponse res2 = h.send(req2);
        //System.assertEquals(ProdlyConstants.PAUSED, res2.getBody());

        // Third test request for stopped deployment service          
        HttpRequest req3 = new HttpRequest();
        // set end point for http callout
        req3.setEndpoint(ProdlyConstants.WEB_SERVICE_URL+'/action');
        // Set web service Type 
        req3.setMethod('POST');
        // parameters for web service        
        String params3 = 'userId='+EncodingUtil.urlEncode(UserID, 'UTF-8')+'&userEmail='+EncodingUtil.urlEncode(userEmail, 'UTF-8')+'&deploymentResultId='+EncodingUtil.urlEncode(deploymentResultId, 'UTF-8')+'&action='+ProdlyConstants.STOPPED ;
        req3.setBody(params3);
        HttpResponse res3 = h.send(req3);
        //System.assertEquals(ProdlyConstants.STOPPED, res3.getBody());   
        
        // set page url parameter
        System.currentPageReference().getParameters().put('id', deploymentResult[1].Id);
        
        // pass deployment result value in a constructor. 
        deploymentResultExtension controller1 = new deploymentResultExtension(new ApexPages.StandardController(deploymentResult[1]));
        
        // resume deployment service
        controller1.resumeService();
        
        // pause deployment service
        controller1.pauseService();
        
        // resume deployment service
        controller1.stopService();
        
        // set page url parameter
        System.currentPageReference().getParameters().put('id', deploymentResult[2].Id);
        
        // pass deployment result value in a constructor. 
        deploymentResultExtension controller2 = new deploymentResultExtension(new ApexPages.StandardController(deploymentResult[2]));
        
        // resume deployment service
        controller2.resumeService();
        
        // pause deployment service
        controller2.pauseService();
        
        // resume deployment service
        controller2.stopService();
        // resume deployment service
        controller2.stopService();
        
        // set page url parameter
        System.currentPageReference().getParameters().put('id', deploymentResult[3].Id);
        
        // pass deployment result value in a constructor. 
        deploymentResultExtension controller3= new deploymentResultExtension(new ApexPages.StandardController(deploymentResult[3]));    
        // resume deployment service
        controller3.resumeService();
        
        // pause deployment service
        controller3.pauseService();
        
        // resume deployment service
        controller3.stopService();
        
        controller3.disablePollerFunction();
        
        //Update the status iof deployment result to stopped
        deploymentResultExtension.updateDRStatus(deploymentResult[2].Id, ProdlyConstants.STOPPED);
        
        //Update the status iof deployment result to stopped
        deploymentResultExtension.updateDRStatus(deploymentResult[2].Id, ProdlyConstants.STARTED);
                       
        Test.stopTest();
        
    }
    
    
}