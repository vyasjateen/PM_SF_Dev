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
    static testMethod void testNewConnectionControllerSource() {
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
        
        Test.setCurrentPageReference(pageRef);
        
        NewConnectionController controller = new NewConnectionController(null);
        
        System.assertEquals(false, controller.isSourceConnection);
        
        PageReference oauthPage = controller.doConnect();
        
        System.assertNotEquals(null, oauthPage);
    }
    
    static testMethod void testDeployDataSet() {
        DataSet__c dataSet = new DataSet__c(ObjectName__c = 'account');
        insert dataSet;
        
        Data_Set_Field__c dataSetField = new Data_Set_Field__c(Name = 'Name', Data_Set__c = dataSet.Id);
        insert dataSetField;
        
        Connection__c sourceConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Local_Connection__c = true);
        insert sourceConnection;
        
        Connection__c targetConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Local_Connection__c = false);
        insert targetConnection;
        
        PageReference pageRef = Page.DeployDataSet;
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(dataSet);
        DeploymentController controller = new DeploymentController(sc);
        
        System.assertEquals(2, controller.targetConnectionOptions.size());
        System.assertEquals(null, controller.isDeployStep);
        System.assertEquals(null, controller.isAlertShown);
        System.assertEquals(null, controller.isSubmittedStep);
        
        controller.selectedTargetConnectionId = targetConnection.Id;
        
        controller.doDeploy();
    }
    
    static testMethod void testDeployNoSource() {
        DataSet__c dataSet = new DataSet__c(ObjectName__c = 'Account');
        insert dataSet;
        
        Data_Set_Field__c dataSetField = new Data_Set_Field__c(Name = 'Name', Data_Set__c = dataSet.Id);
        insert dataSetField;
        
        PageReference pageRef = Page.DeployDataSet;
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(dataSet);
        DeploymentController controller = new DeploymentController(sc);
        
        System.assertEquals(false, controller.isDeployStep);
        System.assertEquals(true, controller.isAlertShown);
        System.assertEquals(false, controller.isSubmittedStep);
    }
        
    static testMethod void testDeployNoTarget() {
        DataSet__c dataSet = new DataSet__c(ObjectName__c = 'Account');
        insert dataSet;
        
        Data_Set_Field__c dataSetField = new Data_Set_Field__c(Name = 'Name', Data_Set__c = dataSet.Id);
        insert dataSetField;
        
        Connection__c sourceConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Source_Connection__c = true);
        insert sourceConnection;
        
        PageReference pageRef = Page.DeployDataSet;
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(dataSet);
        DeploymentController controller = new DeploymentController(sc);
        
        System.assertEquals(false, controller.isDeployStep);
        System.assertEquals(true, controller.isAlertShown);
        System.assertEquals(false, controller.isSubmittedStep);
    }
        
    static testMethod void testParseDeploymentResult() {
        Deployment_Result__c result = new Deployment_Result__c();
        insert result;
        
        DataSet__c dataSet = new DataSet__c(ObjectName__c = 'Account');
        insert dataSet;
        
        Data_Set_Field__c dataSetField = new Data_Set_Field__c(Name = 'Name', Data_Set__c = dataSet.Id);
        insert dataSetField;
        
        PageReference pageRef = Page.DeployDataSet;
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(dataSet);
        DeploymentController controller = new DeploymentController(sc);
        
        String response = '{ "recordId" : "' + result.Id + '" ';
        
        result = DeploymentUtils.parseDeploymentResult(response);
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.Id);
    }
    
    static testMethod void testDeploymentCenterController() {
        Deployment_Result__c result = new Deployment_Result__c();
        insert result;
        
        DataSet__c dataSet = new DataSet__c(ObjectName__c = 'account');
        insert dataSet;
        
        Data_Set_Field__c dataSetField = new Data_Set_Field__c(Name = 'Name', Data_Set__c = dataSet.Id);
        insert dataSetField;
        
        Connection__c sourceConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Org_Type__c = 'Production', Source_Connection__c = true);
        insert sourceConnection;
        
        Connection__c targetConnection = new Connection__c(Access_Token__c = 'xxxx', Refresh_Token__c = 'yyyy', Org_Type__c = 'Production', Source_Connection__c = false);
        insert targetConnection;
        
        PageReference pageRef = Page.DeploymentCenter;
        
        Test.setCurrentPageReference(pageRef);
        
        DeploymentCenterController controller = new DeploymentCenterController();
        
        System.assertEquals(2, controller.targetConnectionOptions.size());
        System.assertEquals(true, controller.isDeployStep);
        System.assertEquals(false, controller.isAlertShown);
        System.assertEquals(true, controller.isDeployDisabled);
        
        controller.onSelect();      
        System.assertEquals(true, controller.isDeployDisabled);
        
        controller.dataSetWrappers.get(0).isSelected = true;
        controller.onSelect();
        System.assertEquals(false, controller.isDeployDisabled);
        
        String responseBody = '{ "recordId" : "' + result.Id + '" ';
        
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody(responseBody);
        PageReference pageRefReturn = DeploymentUtils.processResponse(res);
        System.assertNotEquals(null, pageRefReturn);
        
        res.setStatusCode(505);
        pageRefReturn = DeploymentUtils.processResponse(res);
        System.assertNotEquals(null, pageRefReturn); 
        
        controller.selectedTargetConnectionId = targetConnection.Id;
        controller.doDeploy();
    }
    
    static testMethod void testGetObjectDescribes() {
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
    
    static testMethod void testNewEditorController() {
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        System.assertNotEquals(null, controller.objectNode);
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper);
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper.dataSet);
    } 
    
    static testMethod void testNewEditorControllerObjectSelect() {
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
    }
    
    static testMethod void testNewEditorControllerFieldsSelect() {
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        System.assertEquals(false, controller.isSelectAllFields);

        FieldWrapper fieldWrapper = new FieldWrapper();
        fieldWrapper.isSystemField = false;
        
        controller.objectNode.fieldWrappers.add(fieldWrapper);
        
        controller.onSelectAllFieldsToggle();
        
        System.assertEquals(true, controller.isSelectAllFields);
        System.assertEquals(true, controller.objectNode.fieldWrappers.get(0).isSelected);
    }  
    
    static testMethod void testNewEditorControllerFieldsSearch() {
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
    }
        
    static testMethod void testNewEditorControllerNextPrevSections() {
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
    }
            
    static testMethod void testNewEditorControllerNavSections() {
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
    }
    
    static testMethod void testNewEditorControllerNavNode() {
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.objectNode.dataSetWrapper.dataSet = new DataSet__c();
        
        System.assertEquals(null, controller.navToNodeIndex);
        
        controller.onNext();
        
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
    }
        
    static testMethod void testNewEditorControllerParentSelect() {
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
        
        System.assertEquals(1, controller.objectNode.dataSetWrapper.parentRelationshipWrappers.size());
    }
        
    static testMethod void testNewEditorControllerParentDeselect() {
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
    }
        
    static testMethod void testNewEditorControllerParentConfigure() {
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
    }
        
    static testMethod void testNewEditorControllerChildSelect() {
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
        
        System.assertEquals(1, controller.objectNode.dataSetWrapper.childRelationshipWrappers.size());
    }
        
    static testMethod void testNewEditorControllerChildDeselect() {
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
    }
        
    static testMethod void testNewEditorControllerChildConfigure() {
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
    }
    
    static testMethod void testEditEditorController() {
        DataSet__c accountDataSet = new DataSet__c(ObjectName__c = 'account', Active__c = true, Root__c = true);
        insert accountDataSet;
        
        Data_Set_Field__c adataSetField = new Data_Set_Field__c(Name = 'Account Data Set', Data_Set__c = accountDataSet.Id);
        insert adataSetField;
        
        DataSet__c contactDataSet = new DataSet__c(ObjectName__c = 'contact', Active__c = true);
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
    
    static testMethod void testToggleOverrideSettings() {
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.objectNode.dataSetWrapper.dataSet.Override_Root_Settings__c = true;
        
        controller.toggleOverrideSettings();
        
        System.assertEquals(false, controller.objectNode.dataSetWrapper.dataSet.Ignore_Namespace__c);
        
        controller.objectNode.dataSetWrapper.dataSet.Override_Root_Settings__c = false;
        
        controller.toggleOverrideSettings();
        
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper.dataSet.Ignore_Namespace__c);
    }
    
    static testMethod void testOnClickFieldSettings() {
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.onClickFieldSettings();
        
        System.assertEquals(null, controller.selectedFieldWrapper);
    }
    
    static testMethod void testOnSearchChildren() {
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c(ObjectName__c = 'account'));
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        controller.objectSearchTerm = 'a';
        
        controller.onSearchChildren();
        
        System.assertNotEquals(0, controller.objectNode.filteredChildWrappers.size());
    }
    
    static testMethod void testOnSelectFieldExternalId() {
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        controller.objectSearchTerm = 'a';
        
        controller.onSelectFieldExternalId();
        
        System.assertEquals(false, controller.isFailureAlertShown);
    }
    
    static testMethod void testOnUpsertClick() {
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.onUpsertClick();
    }
           
    static testMethod void testOnUpdateQueryFilter() {
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
    }
    
    static testMethod void testOnAllFieldsSet() {
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.onAllFieldsSet();
        
        System.assertEquals(true, controller.isSelectAllFields);
    } 
     
    static testMethod void testOnSelectField() {
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(new DataSet__c());
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.onSelectField();
        
        System.assertEquals(false, controller.isSelectAllFields);
    }
           
    static testMethod void testEditorControllerDeploy() {
        DataSet__c dataSet = new DataSet__c(ObjectName__c = 'account', Root__c = true);
        insert dataSet;
        
        Data_Set_Field__c dataSetField = new Data_Set_Field__c(Name = 'Name', Data_Set__c = dataSet.Id);
        insert dataSetField;
        
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(dataSet);
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.objectNode.dataSetWrapper.dataSet.All_Fields__c = true;
        controller.onDeploy();
        
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper.dataSet.Id);
    }  
    
    static testMethod void testEditorControllerClone() {
        DataSet__c accountDataSet = new DataSet__c(ObjectName__c = 'account', Active__c = true, Root__c = true);
        insert accountDataSet;
        
        Data_Set_Field__c adataSetField = new Data_Set_Field__c(Name = 'Account Data Set', Data_Set__c = accountDataSet.Id);
        insert adataSetField;
        
        DataSet__c contactDataSet = new DataSet__c(ObjectName__c = 'contact', Active__c = true);
        insert contactDataSet;
        
        Data_Set_Field__c cdataSetField = new Data_Set_Field__c(Name = 'Contact Data Set', Data_Set__c = contactDataSet.Id);
        insert cdataSetField;
        
        Relationship__c relationship = new Relationship__c(Name = 'AccountId', ChildDataSet__c = contactDataSet.Id, ParentDataSet__c = accountDataSet.Id);
        insert relationship;
        
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController(accountDataSet);
        
        DataSetEditorController controller = new DataSetEditorController(sc);
        
        controller.onSave();
        
        pageRef = controller.onClone();
        
        System.assertNotEquals(null, pageRef);
    }
        
            
    static testMethod void testNewEditorControllerSave() {
        PageReference pageRef = Page.NewConnectionEditor;
        
        Test.setCurrentPageReference(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.standardController( new DataSet__c(Root__c = true) );
        
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
        
        for( DataSetEditorController.DataSetWrapper dataSetWrapper : controller.dataSetWrappersByObjectName.values() ) {
            dataSetWrapper.dataSet.All_Fields__c = true;
        }
        
        for( FieldWrapper fieldWrapper : controller.objectNode.fieldWrappers ) {
            fieldWrapper.isSelected = true;
        }
        
        controller.onSave();
        
        System.assertEquals('Data set has been succesfully saved.', controller.alertMessage);
        System.assertEquals(false, controller.isFailureAlertShown);
        System.assertEquals(true, controller.isSuccessAlertShown);
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper.dataSet.Id);
        System.assertNotEquals(null, controller.objectNode.dataSetWrapper.parentRelationshipWrappers.iterator().next().parentDataSetWrapper.dataSet.Id);
        
        Relationship__c relationship = [SELECT Id from Relationship__c where ChildDataSet__c = :controller.objectNode.dataSetWrapper.dataSet.Id];
        System.assertNotEquals(null, relationship);
    }
    
                
    static testMethod void testNewEditorControllerDelete() {
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
    }
                
    static testMethod void testCustomSettingsGetClientSecret() {
        CustomSettingsUtilities instance = CustomSettingsUtilities.getInstance();
        
        instance.customSettings.Instance_Type__c = 'staging';
        instance.getClientSecret();
        
        instance.customSettings.Instance_Type__c = 'demo';
        instance.getClientSecret();
        
        instance.customSettings.Instance_Type__c = 'demo';
        instance.getClientSecret();
        
        instance.customSettings.Instance_Type__c = null;
        instance.getClientSecret();
    }
}