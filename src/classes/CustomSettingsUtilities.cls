public with sharing class CustomSettingsUtilities {
    private final static String BASE_URL_PROD = 'https://prodly-moover.herokuapp.com';
    private final static String CLIENT_ID_PROD = '3MVG9A2kN3Bn17ht6SOom7y5d9CZGF0Yy910Ha2RBFhTOy3kiOdEBGQ69Ylr69K6TDRr22.HH0N46vHjh9ZEk';
    private final static String CLIENT_SECRET_PROD = '4468045098672738970';
    
    private final static String BASE_URL_DEV = 'https://prodly-moover-dev.herokuapp.com';
    private final static String CLIENT_ID_DEV = '3MVG9A2kN3Bn17ht6SOom7y5d9Ns3XjYoPUt8q5m4oIo6MNG8bY14hTalAilwpWasMcaOIHUrz00fSy5pedfK';
    private final static String CLIENT_SECRET_DEV = '752336322481826581';
    
    private final static String BASE_URL_DEV_SF = 'https://prodly-moover-dev-sf.herokuapp.com';
    private final static String CLIENT_ID_DEV_SF = '3MVG9A2kN3Bn17ht6SOom7y5d9JRn.puQxB7mfT_vI8j28YFSdnZBE8JCrpCyPCEXz0CdSRV8VBLmSC0_1dcO';
    private final static String CLIENT_SECRET_DEV_SF = '6249655542659132671';
    
    private final static String BASE_URL_STAGE = 'https://prodly-moover-stage.herokuapp.com';
    private final static String CLIENT_ID_STAGE = '3MVG9A2kN3Bn17ht6SOom7y5d9HKHkhtaLJK_moAYUkCn1cvmvgrmuIGGhWNNr5aoQJKVD0SHo7Sav22SOMQz';
    private final static String CLIENT_SECRET_STAGE = '6126692024143885397';
    
    private final static String BASE_URL_DEMO = 'https://prodly-moover-demo.herokuapp.com';
    private final static String CLIENT_ID_DEMO = '3MVG9A2kN3Bn17ht6SOom7y5d9NAOYh73oXr9OXQjNRTGNWiQb_Fh5wa1e.DeX_7KaLNT_R4MRjecc0PnsJCH';
    private final static String CLIENT_SECRET_DEMO = '6474446938040783210';
    
    private static CustomSettingsUtilities instance;
    
    @TestVisible
    private ReplicateIt_Settings__c customSettings;
    
    private CustomSettingsUtilities() {
        initDeploymentSettings();
    }
        
    public static CustomSettingsUtilities getInstance() {
        if( instance == null ) {
            instance = new CustomSettingsUtilities();
        }
        
        return instance;
    }   
        
    public ReplicateIt_Settings__c getCustomSettings() {
        return customSettings;
    }
    
    public String getInstanceType() {
        return String.isNotBlank( customSettings.Instance_Type__c ) ? customSettings.Instance_Type__c.toLowerCase() : customSettings.Instance_Type__c;
    }
    
    public String getBaseUrl() {
        String instanceType = getInstanceType();
        if( instanceType == 'dev' ||
            instanceType == 'development' ) {
            return CustomSettingsUtilities.BASE_URL_DEV;
        } else if( instanceType == 'dev_sf' ||
            instanceType == 'development_sf' ) {
            return CustomSettingsUtilities.BASE_URL_DEV_SF;
        } else if( instanceType == 'stage' ||
            instanceType == 'staging' ) {
            return CustomSettingsUtilities.BASE_URL_STAGE;
        } else if( instanceType == 'demo' ) {
            return CustomSettingsUtilities.BASE_URL_DEMO;
        } else {
            return CustomSettingsUtilities.BASE_URL_PROD;
        }
    }
    
    public String getClientId() {
        String instanceType = getInstanceType();
        if( instanceType == 'dev' ||
            instanceType == 'development' ) {
            return CustomSettingsUtilities.CLIENT_ID_DEV;
        } else if( instanceType == 'dev_sf' ||
            instanceType == 'development_sf' ) {
            return CustomSettingsUtilities.CLIENT_ID_DEV_SF;
        } else if( instanceType == 'stage' ||
            instanceType == 'staging' ) {
            return CustomSettingsUtilities.CLIENT_ID_STAGE;
        } else if( instanceType == 'demo' ) {
            return CustomSettingsUtilities.CLIENT_ID_DEMO;
        } else {
            return CustomSettingsUtilities.CLIENT_ID_PROD;
        }
    }
    
    public String getClientSecret() {
        String instanceType = getInstanceType();
        if( instanceType == 'dev_sf' ||
            instanceType == 'development_sf' ) {
            return CustomSettingsUtilities.CLIENT_SECRET_DEV_SF;
        } else if( instanceType == 'stage' ||
            instanceType == 'staging' ) {
            return CustomSettingsUtilities.CLIENT_SECRET_STAGE;
        } else if( instanceType == 'demo' ) {
            return CustomSettingsUtilities.CLIENT_SECRET_DEMO;
        } else if(instanceType == 'dev' ||
            instanceType == 'development' ) {
        	return CustomSettingsUtilities.CLIENT_SECRET_DEV;
            }else {
            return CustomSettingsUtilities.CLIENT_SECRET_PROD;
        }
    }
    
    private void initDeploymentSettings() {
        customSettings = ReplicateIt_Settings__c.getInstance();
        
        if( customSettings != null && customSettings.Name != null  ) {
            return;
        }
        
        customSettings = new ReplicateIt_Settings__c();
        customSettings.Instance_Type__c = 'Production';
        customSettings.No_Record_Results__c = false;
        customSettings.Object_Selector_Page_Size__c = 900;
    customSettings.Debug_Deployment__c = false;
    }
}