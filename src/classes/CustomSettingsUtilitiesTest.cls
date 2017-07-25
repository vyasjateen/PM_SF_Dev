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
private class CustomSettingsUtilitiesTest {

    static testMethod void testClientSecret() {
        CustomSettingsUtilities instance = CustomSettingsUtilities.getInstance();
        
        instance.customSettings.Instance_Type__c = 'staging';
        instance.getClientSecret();
        
        instance.customSettings.Instance_Type__c = 'demo';
        instance.getClientSecret();
        
        instance.customSettings.Instance_Type__c = 'dev';
        instance.getClientSecret();
        
        instance.customSettings.Instance_Type__c = null;
        instance.getClientSecret();
        
        instance.customSettings.Instance_Type__c = 'dev_sf';
        instance.getClientSecret();
        System.assertNotEquals(null, instance.getClientSecret());
      
    }
    
    static testMethod void testClientId() {
        CustomSettingsUtilities instance = CustomSettingsUtilities.getInstance();
        
        instance.customSettings.Instance_Type__c = 'staging';
        instance.getClientId();
        
        instance.customSettings.Instance_Type__c = 'demo';
        instance.getClientId();
        
        instance.customSettings.Instance_Type__c = 'dev';
        instance.getClientId();
        
        instance.customSettings.Instance_Type__c = null;
        instance.getClientId();
        
        instance.customSettings.Instance_Type__c = 'dev_sf';
        instance.getClientId();
        System.assertNotEquals(null, instance.getClientId());
      
    }
    
    static testMethod void testBaseurl() {
        CustomSettingsUtilities instance = CustomSettingsUtilities.getInstance();
        
        instance.customSettings.Instance_Type__c = 'staging';
        instance.getBaseUrl();
        
        instance.customSettings.Instance_Type__c = 'demo';
        instance.getBaseUrl();
        
        instance.customSettings.Instance_Type__c = 'dev';
        instance.getBaseUrl();
        
        instance.customSettings.Instance_Type__c = null;
        instance.getBaseUrl();
        
        instance.customSettings.Instance_Type__c = 'dev_sf';
        instance.getBaseUrl();
       
        System.assertNotEquals(null, instance.getBaseUrl());
      
    }
}