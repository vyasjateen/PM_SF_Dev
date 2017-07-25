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
private class TrackDataMigrationStatusExtTest {
/** 
* Description       :   Unit test method for Login TrackDataMigrationStatusExt referencing on the TrackDataMigrationStatus vf page.
*
* Created By        :   Romesh Kumar (Simplyforce Technology)
*                
* Created Date      :   22/01/2017   
*
* Revision Log      :   V1.0
*
* Test Converage    :   100%
**/
    
    //Test Method
    static testMethod void testTrackMigration() {
        
        //Insert Deployment_Result__c
        Deployment_Result__c pDR =  new Deployment_Result__c(Status__c='Finished', Result__c = 'Success');
        insert pDR;
        
        Deployment_Data_Set_Result__c dDSR = new Deployment_Data_Set_Result__c(Result__c = 'Success', Status__c = 'Finished', Deployment_Result__c = pDR.Id);
        insert dDSR;
        
        Test.startTest();
        Deployment_Data_Set_Result__c dDSResult = [Select Id,Result__c,Status__c,Deployment_Result__c from Deployment_Data_Set_Result__c];
        
        
        
        //Refering to TrackDataMigrationStatus VF page
        Pagereference pref = Page.TrackDataMigrationStatus;
        
        //Put the Deploymeent Record id to current page parameter
        pref.getParameters().put('id',pDR.id);
        Test.setCurrentPage(pref);
        
        //Initiallize standard coontroller
        ApexPages.StandardController con = new ApexPages.StandardController(pDR);
        
        //Initiallize the extention
        TrackDataMigrationStatusExt ext = new TrackDataMigrationStatusExt(con);
        
        DataSetDetail dSD = new DataSetDetail(dDSResult,false);
        
        ext.dataSetDetails.add(dSD);
        //assert
        System.assertEquals(0, ext.deployDataSetResults.size());
        
        List<Child_Deployment_Data_Set_Result__c> childDeployment = new List<Child_Deployment_Data_Set_Result__c>();
        childDeployment.add(new Child_Deployment_Data_Set_Result__c( Deployment_Data_Set_Result__c = dDSR.Id, Deployment_Result_Id__c = pDR.Id, Result__c ='Success', Status__c = 'Finished'));
        childDeployment.add(new Child_Deployment_Data_Set_Result__c( Deployment_Data_Set_Result__c = dDSR.Id, Deployment_Result_Id__c = pDR.Id, Result__c ='Success', Status__c = 'Finished'));
        
        insert childDeployment;
        
        //calling the conntrollers method
        ext.getDeploymentInfo();
        
        //assert
        System.assertEquals(1, ext.deployDataSetResults.size());
        
        ext.setCollapse();
        
        ext.collapseDataSet = true;
        ext.setCollapse();
        
        Apexpages.currentPage().getParameters().put('indexParam','0');
        ext.setIndex();
        
        Test.stopTest();
    }
    
    
    static testMethod void testTrackMigration1() {
        //Insert Deployment_Result__c
        Deployment_Result__c pDR =  new Deployment_Result__c(Status__c='Finished', Result__c = 'Success');
        insert pDR;
        
        Deployment_Data_Set_Result__c dDSR = new Deployment_Data_Set_Result__c(Result__c = 'Success', Status__c = 'Finished', Deployment_Result__c = pDR.Id);
        insert dDSR;
        
        Test.startTest();
        Deployment_Data_Set_Result__c dDSResult = [Select Id,Result__c,Status__c,Deployment_Result__c from Deployment_Data_Set_Result__c];
        
        
        
        //Refering to TrackDataMigrationStatus VF page
        Pagereference pref = Page.TrackDataMigrationStatus;
        
        //Put the Deploymeent Record id to current page parameter
        pref.getParameters().put('id',pDR.id);
        Test.setCurrentPage(pref);
        
        //Initiallize standard coontroller
        ApexPages.StandardController con = new ApexPages.StandardController(pDR);
        
        //Initiallize the extention
        TrackDataMigrationStatusExt ext = new TrackDataMigrationStatusExt(con);
        
        DataSetDetail dSD = new DataSetDetail(dDSResult,true);
        
        ext.dataSetDetails.add(dSD);
        //assert
        System.assertEquals(0, ext.deployDataSetResults.size());
        
        List<Child_Deployment_Data_Set_Result__c> childDeployment = new List<Child_Deployment_Data_Set_Result__c>();
        childDeployment.add(new Child_Deployment_Data_Set_Result__c( Deployment_Data_Set_Result__c = dDSR.Id, Deployment_Result_Id__c = pDR.Id, Result__c ='Success', Status__c = 'Finished'));
        childDeployment.add(new Child_Deployment_Data_Set_Result__c( Deployment_Data_Set_Result__c = dDSR.Id, Deployment_Result_Id__c = pDR.Id, Result__c ='Success', Status__c = 'Finished'));
        
        insert childDeployment;
        
        //calling the conntrollers method
        ext.getDeploymentInfo();
        
        //assert
        System.assertEquals(1, ext.deployDataSetResults.size());
        
        ext.setCollapse();
        
        ext.collapseDataSet = true;
        ext.setCollapse();
        
        Apexpages.currentPage().getParameters().put('indexParam','0');
        ext.setIndex();
        
        Test.stopTest();
    }
 
}