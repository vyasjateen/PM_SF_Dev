public with sharing class NewConnectionController {
    private final static String BASE_REDIRECT_URL = CustomSettingsUtilities.getInstance().getBaseUrl() + '/oauth/callback';
    
    public List<SelectOption> orgTypeOptions { get; set; }
    
    public String connectionName { get; set; }
    public String selectedOrgType { get; set; }
    public String alertMessage { get; set; }
    
    public Boolean isSourceConnection { get; set; }
    public Boolean isAlertShown { get; set; }
    
    private Connection__c sourceConnection;
    
    public NewConnectionController(ApexPages.standardController stdController) {
        orgTypeOptions = new List<SelectOption>();
        orgTypeOptions.add( new SelectOption( 'Production', 'Production' ) );
        orgTypeOptions.add( new SelectOption( 'Sandbox', 'Sandbox' ) );
        
        isSourceConnection = false;
        
        try {
            sourceConnection = AccessValidationUtilities.queryConnectionsAsUser('where Local_Connection__c = true AND Active__c = true LIMIT 1').get(0);
        } catch (Exception e) {
            isSourceConnection = true;
            alertMessage = 'The first active connection you establish must be to the local org, otherwise subsequent steps will not function correctly. Click connect to proceed.';
            isAlertShown = true;
        }
    }
    
    public void onDismissAlert() {
        isAlertShown = false;
    }
    
    public PageReference doConnect() {
        if( connectionName == null ) {
            connectionName = '';
        }
        
        String clientId = CustomSettingsUtilities.getInstance().getClientId();
        Map<String,Schema.DescribeFieldResult> fieldResults = new Map<String,Schema.DescribeFieldResult>();
        fieldResults.put('IsSandbox', Schema.sObjectType.Organization.fields.IsSandbox);
        String sourceOrgType = Boolean.valueOf( AccessValidationUtilities.queryAsUser(Schema.sObjectType.Organization, fieldResults, 'limit 1').get(0).get('IsSandbox') ) ? 'Sandbox' : 'Production';
        String targetOrgType = selectedOrgType;
        
        String redirectUrl = NewConnectionController.BASE_REDIRECT_URL;  
        String clientIdEncoded = EncodingUtil.urlEncode(clientId, 'UTF-8');
        String redirectUrlEncoded = EncodingUtil.urlEncode(redirectUrl, 'UTF-8');
        String nameSpaceName = 'null';
        String promptEncoded = null, stateEncoded = null, loginHint = null;
        if( sourceConnection != null ) {
            promptEncoded = 'login%20consent';
            String state = sourceConnection.Refresh_Token__c;
            stateEncoded = EncodingUtil.urlEncode(connectionName + '|' + sourceOrgType + '|' + targetOrgType  + '|' + state +'| packageNameSpace ='+nameSpaceName , 'UTF-8');
            loginHint = '';
        } else {
            targetOrgType = sourceOrgType;
            stateEncoded = EncodingUtil.urlEncode(connectionName + '|' + sourceOrgType + '|' + targetOrgType + '| packageNameSpace ='+nameSpaceName, 'UTF-8');
            loginHint = '&login_hint=' + EncodingUtil.urlEncode(UserInfo.getUserName(), 'UTF-8');
        }
        
        String baseUrl = targetOrgType == 'Production' ? 'https://login.salesforce.com' : 'https://test.salesforce.com';
        String oauthUrl = baseUrl + '/services/oauth2/authorize?prompt=' + promptEncoded + 
            '&response_type=code&client_id=' + clientIdEncoded + 
            '&redirect_uri=' + redirectUrlEncoded + 
            loginHint + 
            ( stateEncoded == null ? '' : '&state=' + stateEncoded);
        
        System.debug('Debug Log*****************'+oauthUrl);
        PageReference pageRef = new PageReference(oauthUrl);
        pageRef.setRedirect(true);
            
        return pageRef;
    }
}