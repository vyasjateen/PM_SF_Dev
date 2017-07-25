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
private class ControllerTests {
    public static Boolean isOrigin = false;
   @testSetup static void setup() {
   	
        Connection__c sourceConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy',Org_Type__c='Production', Local_Connection__c = false, Active__c = true, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert sourceConnection;
        
        Connection__c targetConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Org_Type__c='Production', Local_Connection__c = false, Active__c = true, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert targetConnection;   
        
        Connection__c localConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy',Org_Type__c='Production', Local_Connection__c = true, Active__c = true, OrganizationId__c='XXXX', User_Id__c='XXXX');
        insert localConnection;
        
        DataSet__c dataSetParent = new DataSet__c(Name = 'Test', ObjectName__c = 'account', Root__c = false);
        insert dataSetParent;
        
        DataSet__c dataSetRoot = new DataSet__c(Name = 'ContactDataSet', ObjectName__c = 'contact',Root__c = true);
        insert dataSetRoot;
        
        DataSet__c dataSetChild = new DataSet__c(Name = 'OpportunityDataSet', ObjectName__c = 'opportunity',Root__c = false);
        insert dataSetChild;
        
        Relationship__c relParent = new Relationship__c(Name = 'TestRel', ChildDataSet__c = dataSetRoot.Id, ParentDataSet__c = dataSetParent.Id);
        insert relParent;
        
        Relationship__c relChild = new Relationship__c(Name = 'TestRel', ChildDataSet__c = dataSetChild.Id, ParentDataSet__c = dataSetRoot.Id);
        insert relChild;
                
        Data_Set_Field__c dataSetField = new Data_Set_Field__c(Name = 'Name', Data_Set__c = dataSetRoot.Id);
        insert dataSetField;
           
    }
    
 	static testMethod void testNewEditorController() {
 		
 		Test.startTest();
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        System.assertNotEquals(null, controller.objectNode);
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper);
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper.dataSet);
        Test.stopTest();
    } 
    
    static testMethod void testNewEditorControllerOriginOrg() {
    	Test.startTest();
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        Connection__c con = AccessValidationUtilities.queryConnectionsAsUser('where  Local_Connection__c = false')[0];
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c(Root__c = true, Origin_Connection__c = con.Id));
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        System.assertNotEquals(null, controller.objectNode);
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper);
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper.dataSet);
        Test.stopTest();
    } 
    
    static testMethod void testNewEditorControllerExistingDataSet() {
    	
    	Test.startTest();
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        DataSet__c ds = [Select id, Origin_Connection__c, ObjectName__c from DataSet__c where Name = 'ContactDataSet'];
        Connection__c con = AccessValidationUtilities.queryConnectionsAsUser('where  Local_Connection__c = true')[0]; 
        ds.Origin_Connection__c = con.Id;
        update ds;
        
        ApexPages.StandardController sc = new ApexPages.standardController(ds);
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        controller.toggleOverrideSettings();
        System.assertNotEquals(null, controller.objectNode);
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper);
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper.dataSet);
        
        Test.stopTest();
    } 
    
    static testMethod void testNewEditorControllerNextPrevSections() {
    	
    	Test.startTest();
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        System.assertEquals(true, controller.isObjectStep);
        System.assertEquals(false, controller.isFieldsStep);
        System.assertEquals(false, controller.isParentStep);
        System.assertEquals(false, controller.isChildStep);
        
        controller.onNext();
        
        System.assertEquals(false, controller.isObjectStep);
        System.assertEquals(true, controller.isFieldsStep);
        System.assertEquals(false, controller.isParentStep);
        System.assertEquals(false, controller.isChildStep);
        
        controller.onNext();
        
        System.assertEquals(false, controller.isObjectStep);
        System.assertEquals(false, controller.isFieldsStep);
        System.assertEquals(true, controller.isParentStep);
        System.assertEquals(false, controller.isChildStep);
        
        controller.onNext();
        
        System.assertEquals(false, controller.isObjectStep);
        System.assertEquals(false, controller.isFieldsStep);
        System.assertEquals(false, controller.isParentStep);
        System.assertEquals(true, controller.isChildStep);
        
        controller.onPrevious();
        
        System.assertEquals(false, controller.isObjectStep);
        System.assertEquals(false, controller.isFieldsStep);
        System.assertEquals(true, controller.isParentStep);
        System.assertEquals(false, controller.isChildStep);
        
        controller.onPrevious();
        
        System.assertEquals(false, controller.isObjectStep);
        System.assertEquals(true, controller.isFieldsStep);
        System.assertEquals(false, controller.isParentStep);
        System.assertEquals(false, controller.isChildStep);
        
        controller.onPrevious();
        
        System.assertEquals(true, controller.isObjectStep);
        System.assertEquals(false, controller.isFieldsStep);
        System.assertEquals(false, controller.isParentStep);
        System.assertEquals(false, controller.isChildStep);
        
        Test.stopTest();
    }
    
  	static testMethod void testNewEditorControllerSave() {
  		
  		Test.startTest();
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        DataSet__c ds = [Select id, Origin_Connection__c, ObjectName__c from DataSet__c where Name = 'ContactDataSet'];
        Connection__c con = AccessValidationUtilities.queryConnectionsAsUser('where  Local_Connection__c = true')[0]; 
        ds.Origin_Connection__c = con.Id;
        update ds;
        
        ApexPages.StandardController sc = new ApexPages.standardController( ds );
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        controller.objectNode.dataSetWrapper.dataSet.ObjectName__c = 'contact';
        controller.onObjectSelect();
        
        controller.parentSelected = 'AccountId';
        for( ParentWrapper parentWrapper : controller.objectNode.parentWrappers ) {
            if( parentWrapper.name == controller.parentSelected ) {
                controller.objectNode.parentWrappers.get(0).isSelected = true;          
            }
        }
        
        controller.onParentClick();
        
        controller.childSelected = 'Opportunity';
        for( ChildWrapper childWrapper : controller.objectNode.childWrappers ) {
            if( childWrapper.name == controller.childSelected ) {
                controller.objectNode.childWrappers.get(0).isSelected = true;          
            }
        }
        
        controller.onChildClick();
        
        controller.isFailureAlertShown = false;
        controller.isSuccessAlertShown = false;
        
       	for( DataSetEditorController.DataSetWrapper dataSetWrapper : controller.dataSetWrappersByObjectName.values() ) {
            dataSetWrapper.dataSet.All_Fields__c = true;
        }
        
        for( FieldWrapper fieldWrapper : controller.objectNode.fieldWrappers ) {
            fieldWrapper.isSelected = true;
        }
       
        DataSet__c dsParent = [Select Id,ObjectName__c, Origin_Connection__c from DataSet__c where Name = 'Test'];
        /*Relationship__c relParent = new Relationship__c(Name = 'TestRel', ChildDataSet__c = ds.Id, ParentDataSet__c = dsParent.Id);
        insert relParent;*/
        
        controller.onSave();
        
        System.assertEquals('Data set has been succesfully saved.', controller.alertMessage);
        System.assertEquals(false, controller.isFailureAlertShown);
        System.assertEquals(true, controller.isSuccessAlertShown);
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper.dataSet.Id);
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper.parentRelationshipWrappers);
        
        Relationship__c relationship = [SELECT Id from Relationship__c where ChildDataSet__c = :controller.objectNode.dataSetWrapper.dataSet.Id];
        System.assertNotEquals(null, relationship);
        
        controller.onDeploy();
        
        Test.stopTest();
    }
    
   
    static testMethod void testNewEditorControllerSaveOrigin() {
    	
    	isOrigin = true;
    	
    	
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        DataSet__c ds = [Select id, Origin_Connection__c, ObjectName__c from DataSet__c where Name = 'ContactDataSet'];
        Connection__c con = AccessValidationUtilities.queryConnectionsAsUser('where  Local_Connection__c = false')[0]; 
        ds.Origin_Connection__c = con.Id;
        update ds;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ProdlyMockHttpResponseGenerator());
    	isOrigin = false;
    	
        ApexPages.StandardController sc = new ApexPages.standardController( ds );
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        controller.objectNode.dataSetWrapper.dataSet.ObjectName__c = 'contact';
        controller.objectNode.dataSetWrapper.dataSet.Query_Filter__c = 'where Name != null';
        controller.onObjectSelect();
        
        controller.parentSelected = 'AccountId';
        for( ParentWrapper parentWrapper : controller.objectNode.parentWrappers ) {
            if( parentWrapper.name == controller.parentSelected ) {
                controller.objectNode.parentWrappers.get(0).isSelected = true;          
            }
        }
        
        controller.onParentClick();
        
        controller.isFailureAlertShown = false;
        controller.isSuccessAlertShown = false;
        
       	for( DataSetEditorController.DataSetWrapper dataSetWrapper : controller.dataSetWrappersByObjectName.values() ) {
            dataSetWrapper.dataSet.All_Fields__c = true;
        }
        
        for( FieldWrapper fieldWrapper : controller.objectNode.fieldWrappers ) {
            fieldWrapper.isSelected = true;
        }
       
        DataSet__c dsParent = [Select Id,ObjectName__c, Origin_Connection__c from DataSet__c where Name = 'Test'];
        /*Relationship__c relParent = new Relationship__c(Name = 'TestRel', ChildDataSet__c = ds.Id, ParentDataSet__c = dsParent.Id);
        insert relParent;*/
        
        controller.onSave();
        Map<String,Object> mapObject = new Map<String,Object>();
      
        System.assertEquals(true, controller.isValid());
        System.assertEquals('Data set has been succesfully saved.', controller.alertMessage);
        System.assertEquals(false, controller.isFailureAlertShown);
        System.assertEquals(true, controller.isSuccessAlertShown);
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper.dataSet.Id);
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper.parentRelationshipWrappers);
        
        
        //Relationship__c relationship = [SELECT Id from Relationship__c where ChildDataSet__c = :controller.objectNode.dataSetWrapper.dataSet.Id];
        
        //System.assertNotEquals(null, relationship);
        
        Test.stopTest();
    }
    
     static testMethod void testNewEditorControllerDelete() {
     	
     	Test.startTest();
     	
     	PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        controller.objectNode.dataSetWrapper.dataSet.ObjectName__c = 'contact';
        controller.onObjectSelect();
        
        controller.parentSelected = 'AccountId';
        for( ParentWrapper parentWrapper : controller.objectNode.parentWrappers ) {
            if( parentWrapper.name == controller.parentSelected ) {
                controller.objectNode.parentWrappers.get(0).isSelected = true;          
            }
        }
        
        controller.onParentClick();        
        
        controller.isFailureAlertShown = false;
        controller.isSuccessAlertShown = false;
        
        controller.onSave();
        
        Id contactDataSetId = controller.objectNode.dataSetWrapper.dataSet.Id;
        Id accountDataSetId = controller.objectNode.dataSetWrapper.parentRelationshipWrappers.iterator().next().parentDataSetWrapper.dataSet.Id;
        Id relationshipId = controller.objectNode.dataSetWrapper.parentRelationshipWrappers.iterator().next().relationship.Id;
        
        controller.onDelete();
        
        System.assertEquals(false, controller.isFailureAlertShown);
        System.assertEquals(true, controller.isSuccessAlertShown);
        
        Boolean isRecordExists = false;
        try {
            DataSet__c contactDataSet = [SELECT Id from DataSet__c where Id = :contactDataSetId];
            isRecordExists = true;
        } catch(Exception e) {
        }
        
        System.assertEquals(false, isRecordExists);
        
        try {
            DataSet__c accountDataSet = [SELECT Id from DataSet__c where Id = :accountDataSetId];
            isRecordExists = true;
        } catch(Exception e) {
        }
        
        System.assertEquals(false, isRecordExists);
        
        try {
            Relationship__c relationship = [SELECT Id from Relationship__c where Id = :relationshipId];
            isRecordExists = true;
        } catch(Exception e) {
        }
        
        System.assertEquals(false, isRecordExists);
        
        Test.stopTest();
    }
    
    static testMethod void testNewEditorControllerParentDeselect() {
    	
    	Test.startTest(); 
    	
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        controller.objectNode.dataSetWrapper.dataSet.ObjectName__c = 'contact';
        controller.onObjectSelect();
        
        controller.parentSelected = 'AccountId';
        for( ParentWrapper parentWrapper : controller.objectNode.parentWrappers ) {
            if( parentWrapper.name == controller.parentSelected ) {
                controller.objectNode.parentWrappers.get(0).isSelected = true;          
            }
        }
        
        controller.onParentClick();
        
        for( ParentWrapper parentWrapper : controller.objectNode.parentWrappers ) {
            if( parentWrapper.name == controller.parentSelected ) {
                controller.objectNode.parentWrappers.get(0).isSelected = false;         
            }
        }
        
        controller.onParentClick();
        
        System.assertEquals(0, controller.objectNode.dataSetWrapper.parentRelationshipWrappers.size());
        Test.stopTest();
    }
         
 	static testMethod void testNewEditorControllerChildDeselect() {
 		
 		Test.startTest();
 		
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        controller.objectNode.dataSetWrapper.dataSet.ObjectName__c = 'account';
        controller.onObjectSelect();
        
        controller.childSelected = 'Contacts';
        for( ChildWrapper childWrapper : controller.objectNode.childWrappers ) {
            if( childWrapper.relationshipName == controller.childSelected ) {
                childWrapper.isSelected = true;
            }
        }
        
        controller.onChildClick();
        
        for( ChildWrapper childWrapper : controller.objectNode.childWrappers ) {
            if( childWrapper.relationshipName == controller.childSelected ) {
                childWrapper.isSelected = false;
            }
        }
        
        controller.onChildClick();
        
        System.assertEquals(0, controller.objectNode.dataSetWrapper.childRelationshipWrappers.size());
        Test.stopTest();
    }   
    
    static testMethod void testNewEditorControllerParentConfigure() {
    	
  		Test.startTest();
  		
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        controller.objectNode.dataSetWrapper.dataSet.ObjectName__c = 'contact';
        controller.onObjectSelect();
        
        System.assertEquals(null, controller.parentSelected);
        
        controller.parentSelected = 'AccountId';
        for( ParentWrapper parentWrapper : controller.objectNode.parentWrappers ) {
            if( parentWrapper.name == controller.parentSelected ) {
                controller.objectNode.parentWrappers.get(0).isSelected = true;          
            }
        }
        
        controller.onParentClick();
        controller.onParentConfigure();
        
        System.assertEquals(true, controller.isObjectStep);
        System.assertEquals('Account', controller.objectNode.label);
        
        Test.stopTest();
    }
    
    static testMethod void testNewEditorControllerChildConfigure() {
        
        Test.startTest();
        
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        controller.objectNode.dataSetWrapper.dataSet.ObjectName__c = 'account';
        controller.onObjectSelect();
        
        System.assertEquals(null, controller.childSelected);
        
        controller.childSelected = 'Contacts';
        for( ChildWrapper childWrapper : controller.objectNode.childWrappers ) {
            if( childWrapper.relationshipName == controller.childSelected ) {
                childWrapper.isSelected = true;
            }
        }
        
        controller.onChildClick();
        controller.onChildConfigure();
        
        System.assertEquals(true, controller.isObjectStep);
        System.assertEquals('Contact', controller.objectNode.label);
        
        Test.stopTest();
    }
    
    
    static testMethod void testEditorControllerClone() {
       
        Test.startTest();
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        DataSet__c ds = [Select id, Origin_Connection__c, ObjectName__c from DataSet__c where Name = 'ContactDataSet'];
        Connection__c con = AccessValidationUtilities.queryConnectionsAsUser('where  Local_Connection__c = true')[0]; 
        ds.Origin_Connection__c = con.Id;
        update ds;
        
        ApexPages.StandardController sc = new ApexPages.standardController( ds );
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.onSave();
        
        pageRef = controller.onClone();
        
		Test.stopTest();
    }
    
    static testMethod void testEditorControllerDeploy() {
        
        Test.startTest();
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        DataSet__c ds = [Select id, Origin_Connection__c, ObjectName__c from DataSet__c where Name = 'ContactDataSet'];
        Connection__c con = AccessValidationUtilities.queryConnectionsAsUser('where  Local_Connection__c = true')[0]; 
        ds.Origin_Connection__c = con.Id;
        update ds;
        
        ApexPages.StandardController sc = new ApexPages.standardController(ds);
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.objectNode.dataSetWrapper.dataSet.All_Fields__c = true;
        controller.onDeploy();
        
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper.dataSet.Id);
        
        Test.stopTest();
    }  
    
       static testMethod void testOnClickFieldSettings() {
       	
   			Test.startTest();
	        PageReference pageRef = Page.NewConnectionEditor;
	        
	        Test.setCurrentPageReference(pageRef);
	        
	        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
	        
	        DataSetEditorController controller = new DataSetEditorController(sc);
	        
	        controller.onClickFieldSettings();
	        
	        System.assertEquals(null, controller.selectedFieldWrapper);
	        
	        Test.stopTest();
    }
    
    static testMethod void testOnSearchChildren() {
    	
    	Test.startTest();
    	
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c(ObjectName__c = 'account'));
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        controller.objectSearchTerm = 'a';
        
        controller.onSearchChildren();
        
        System.assertNotEquals(0, controller.objectNode.filteredChildWrappers.size());
        
        Test.stopTest();
    }
    
    static testMethod void testOnSelectFieldExternalId() {
    	
    	Test.startTest();
    	
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        controller.objectSearchTerm = 'a';
        
        controller.onSelectFieldExternalId();
        
        System.assertEquals(false, controller.isFailureAlertShown);
        
        Test.stopTest();
    }
    
    static testMethod void testOnUpsertClick() {
    	
    	Test.startTest();
    	
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.onUpsertClick();
        
        Test.stopTest();
    }
           
    static testMethod void testOnUpdateQueryFilter() {
    	
    	Test.startTest();
    	
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        controller.countResult = '1';
        
        controller.onUpdateQueryFilter();
        
        System.assertEquals(false, controller.isFailureAlertShown);
        
        controller.countResult = 'some error';
        
        controller.onErrorQueryFilter();
        
        System.assertEquals(true, controller.isFailureAlertShown);
        
        Test.stopTest();
    }
    
    static testMethod void testOnAllFieldsSet() {
    	
    	Test.startTest();
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.onAllFieldsSet();
        
        System.assertEquals(true, controller.isSelectAllFields);
        
        Test.stopTest();
    } 
     
    static testMethod void testOnSelectField() {
    	
    	Test.startTest();
    	
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.onSelectField();
        
        System.assertEquals(false, controller.isSelectAllFields);
        
        Test.stopTest();
    }
	
	static testMethod void testNewEditorControllerObjectSelect() {
		
		Test.startTest();
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        controller.objectNode.dataSetWrapper.dataSet.ObjectName__c = 'account';
        controller.onObjectSelect();
        
        System.assertEquals('Account', controller.objectNode.label);
        System.assertNotEquals(null, controller.objectNode.fieldWrappers);
        System.assertNotEquals(null, controller.objectNode.parentWrappers);
        System.assertNotEquals(null, controller.objectNode.childWrappers);
        
        Test.stopTest();
    }
    
    static testMethod void testNewEditorControllerFieldsSelect() {
    	
    	Test.startTest();
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        System.assertEquals(true, controller.isSelectAllFields);

        FieldWrapper fieldWrapper = new FieldWrapper();
        fieldWrapper.isSystemField = false;
        
        controller.objectNode.fieldWrappers.add(fieldWrapper);
        
        controller.onSelectAllFieldsToggle();
        
        System.assertEquals(false, controller.isSelectAllFields);
        System.assertEquals(false, controller.objectNode.fieldWrappers.get(0).isSelected);
        
        Test.stopTest();
    }  
    
    static testMethod void testNewEditorControllerFieldsSearch() {
    	
    	Test.startTest();
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        System.assertEquals(null, controller.objectSearchTerm);
        
        controller.objectNode.dataSetWrapper.dataSet.ObjectName__c = 'account';
        controller.onObjectSelect();
        
        controller.objectSearchTerm = 'Name';
        
        controller.onSearchFields();
        
        System.assertNotEquals(0, controller.objectNode.filteredFieldWrappers.size());
        
        Test.stopTest();
    }
        
    
    static testMethod void testNewEditorControllerNavSections() {
    	
    	Test.startTest();
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        System.assertEquals(null, controller.navToSectionName);
        
        controller.navToSectionName = 'fields';     
        controller.onNavToSection();
        
        System.assertEquals(false, controller.isObjectStep);
        System.assertEquals(true, controller.isFieldsStep);
        System.assertEquals(false, controller.isParentStep);
        System.assertEquals(false, controller.isChildStep);
        
        controller.navToSectionName = 'parent';     
        controller.onNavToSection();
        
        System.assertEquals(false, controller.isObjectStep);
        System.assertEquals(false, controller.isFieldsStep);
        System.assertEquals(true, controller.isParentStep);
        System.assertEquals(false, controller.isChildStep);
        
        controller.navToSectionName = 'child';     
        controller.onNavToSection();
        
        System.assertEquals(false, controller.isObjectStep);
        System.assertEquals(false, controller.isFieldsStep);
        System.assertEquals(false, controller.isParentStep);
        System.assertEquals(true, controller.isChildStep);   
        
        controller.navToSectionName = 'object';     
        controller.onNavToSection();
        
        System.assertEquals(true, controller.isObjectStep);
        System.assertEquals(false, controller.isFieldsStep);
        System.assertEquals(false, controller.isParentStep);
        System.assertEquals(false, controller.isChildStep);
        
        test.stopTest();
    }
    
   /* static testMethod void testNewEditorControllerNavNode() {
    	
    	Test.startTest();
        PageReference pageRef = Page.NewConnectionEditor;    
        
        Test.setCurrentPageReference(pageRef);
        
        DataSet__c ds = [Select id, Origin_Connection__c, ObjectName__c from DataSet__c where Name = 'ContactDataSet'];
        Connection__c con = AccessValidationUtilities.queryConnectionsAsUser('where  Local_Connection__c = false')[0]; 
        ds.Origin_Connection__c = con.Id;
        update ds;
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.objectNode.dataSetWrapper.dataSet = new DataSet__c();
        
         controller.onNext();
         
        System.assertEquals(null, controller.navToNodeIndex);
        
       
        DataSetEditorController.ObjectNode nextNode = new DataSetEditorController.ObjectNode();
        nextNode.index = 1;
        nextNode.label = 'Case';
        
        controller.objectNodes.add(nextNode);
        
        controller.navToNodeIndex = '1';     
        controller.onNavToNode();
        
        System.assertEquals('Case', controller.objectNode.label);
        System.assertEquals(true, controller.isObjectStep);
        System.assertEquals(false, controller.isFieldsStep);
        System.assertEquals(false, controller.isParentStep);
        System.assertEquals(false, controller.isChildStep);
        
        Test.stopTest();
    }*/
    
    static testMethod void testEditorControllerDismissAlert() {
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.isFailureAlertShown = true;
        controller.isSuccessAlertShown = true;
        
        controller.onDismissAlert();
        
        System.assertEquals(false, controller.isFailureAlertShown);
        System.assertEquals(false, controller.isSuccessAlertShown);
    } 
    
    static testMethod void testEditEditorController() {
    	
    	Connection__c con = AccessValidationUtilities.queryConnectionsAsUser('where  Local_Connection__c = true')[0];
    	
    	
        DataSet__c accountDataSet = new DataSet__c(ObjectName__c = 'account', Active__c = true, Root__c = true, Origin_Connection__c = con.Id);
        insert accountDataSet;
        
        Data_Set_Field__c adataSetField = new Data_Set_Field__c(Name = 'Account Data Set', Data_Set__c = accountDataSet.Id);
        insert adataSetField;
        
        DataSet__c contactDataSet = new DataSet__c(ObjectName__c = 'contact', Active__c = true, Origin_Connection__c = con.Id);
        insert contactDataSet;
        
        Data_Set_Field__c cdataSetField = new Data_Set_Field__c(Name = 'Contact Data Set', Data_Set__c = contactDataSet.Id);
        insert cdataSetField;
        
        Relationship__c relationship = new Relationship__c(Name = 'AccountId', ChildDataSet__c = contactDataSet.Id, ParentDataSet__c = accountDataSet.Id);
        insert relationship;
        
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(accountDataSet);
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        System.assertEquals(2, controller.dataSetWrappersByObjectName.values().size());
        //System.assertEquals('Accepted Event Relation', controller.objectNode.label);
        System.assertEquals('Account', controller.objectNode.label);
        System.assertEquals(1, controller.objectNode.dataSetWrapper.childRelationshipWrappers.size());
    }
    
   /* static testMethod void testGetObjectDescribes() {
        Map<String,Schema.DescribeSObjectResult> objectDescribes = DeploymentUtils.getObjectDescribes();
        System.assertNotEquals(null, objectDescribes);
        
        Schema.DescribeSObjectResult objectDescribe = DeploymentUtils.getObjectDescribeByObjectType( objectDescribes.values().get(0).getSobjectType() );
        System.assertNotEquals(null, objectDescribes);
    }
    
    static testMethod void testSortByNameFieldWrappers() {
        FieldWrapper fieldWrapper1 = new FieldWrapper();
        fieldWrapper1.label = 'a';
        
        FieldWrapper fieldWrapper2 = new FieldWrapper();
        fieldWrapper2.label = 'b';
        
        List<ComponentWrapperIntf> fieldWrappers = new List<ComponentWrapperIntf>{fieldWrapper2, fieldWrapper1};
        
        fieldWrappers = DeploymentUtils.sortByLabel(fieldWrappers, FieldWrapper.class);
        
        System.assertEquals('a', ((FieldWrapper)fieldWrappers.get(0)).label);
        System.assertEquals('b', ((FieldWrapper)fieldWrappers.get(1)).label);
    }
    
    static testMethod void testSortByNameSelectOptions() {
        SelectOption selectOption = new SelectOption('a', 'a');
        SelectOption selectOption2 = new SelectOption('b', 'b');
        
        List<SelectOption> selectOptions = new List<SelectOption>{selectOption, selectOption2};
        
        selectOptions = DeploymentUtils.sortByLabel(selectOptions);
        
        System.assertEquals('a', selectOptions.get(0).getLabel());
        System.assertEquals('b', selectOptions.get(1).getLabel());
    }
   
    
        
    
    
    

    
    
    
   */
    
   
    
    
    
}