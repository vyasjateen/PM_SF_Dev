/**
 *  Description         :   this class is using for make http post/get request to upload data one org to another org. 
 *
 *  Created By          :   
 *
 *  Created Date        :   03/10/2017
 *
 *  Version             :   V_1.0
 *
 *  Revision Log        :   V_1.0 - Created
                            V_2.0 - Modified by :   Romesh Kumar    
                                    Remove the hardcoded URL fetching from ProdlyConstants and put all those in Custom Metadata and fetching Endpint from there
 **/

public class ProdlyHttpRequest {
    
    /**
     * This method id using for start deployment service, which is using for deploy data one org to other org 
     * @author Rohit Ramawat <rohit.ramawat@simplyforce.com>
     * @param String deploymentResultId unique key for start deployment process
     * @return String after http post request service will return resonse in string format
     * @version V_1.0
     * @since 03/10/2017
     * @todo Need to create test classes for it
     */
    public static string startDeploymentServiceCall(String deploymentResultId) {
        
        //String to hold the Endpoint URl
        String serviceUrl = getEndPoint();
        
        //Check if serviceUrl is not blank. 
        if(String.isNotBlank(serviceUrl)){
            
            //Creating Endpoint URL by Appending additional parameters
            serviceUrl += '/action'; 
            
            String UserID = UserInfo.getUserId();
            String UserEmail = UserInfo.getUserEmail();
            //String params = '{"userId":"'+UserID+'","userEmail":"'+UserEmail+'","deploymentResultId":"'+deploymentResultId+'","action":"Started"}' ;
            String params = 'userId='+EncodingUtil.urlEncode(UserID, 'UTF-8')+'&userEmail='+EncodingUtil.urlEncode(userEmail, 'UTF-8')+'&deploymentResultId='+EncodingUtil.urlEncode(deploymentResultId, 'UTF-8')+'&action='+ProdlyConstants.STARTED ;
            
            HttpResponse response= ProdlyHttpService.makePostCallout(serviceUrl,params);
            Integer statusCode = response.getStatusCode();
            String statusName = response.getStatus();
            
            String res='';
            String errorMsg;
            String infoMsg; 
            if(response!=null && statusCode==200){
                res = response.getBody();
                if(res=='' || res==null){
                    errorMsg = Label.INVALID_RESPONSE;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, errorMsg));
                }
            }else{
                errorMsg = 'Request failed. Please contact administrator. <br/> Error Code: <b>' + statusCode + '</b><br/> Error Message: <b>' + statusName + '</b>';
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, errorMsg));
            }
            if(res!=null)
                res=res.trim();
            return res;
        } else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.ENDPOINT_MISSING));
            return '';
        }
    }


    /**
     * This method id using for start deployment service, which is using for deploy data one org to other org 
     * @author Rohit Ramawat <rohit.ramawat@simplyforce.com>
     * @param String deploymentResultId unique key for stop deployment process
     * @return String after http post request service will return resonse in string format
     * @version V_1.0
     * @since 03/10/2017
     * @todo Need to create test classes for it
     */
    public static string stopDeploymentServiceCall(String deploymentResultId) {
        
        //String to hold the Endpoint URl
        String serviceUrl = getEndPoint();
        System.debug('ENdPoint--------------'+serviceUrl);
        //Check if serviceUrl is not blank. 
        if(String.isNotBlank(serviceUrl)){
            
            //Creating Endpoint URL by Appending additional parameters
            serviceUrl += '/action'; 
                    
            //String serviceUrl=ProdlyConstants.WEB_SERVICE_URL+'/action';        
            String UserID = UserInfo.getUserId();
            String UserEmail = UserInfo.getUserEmail();
            //String params = '{"userId":"'+UserID+'","userEmail":"'+UserEmail+'","deploymentResultId":"'+deploymentResultId+'","action":"Started"}' ;
            //String params = 'userId='+UserID+'&userEmail='+UserEmail+'&deploymentResultId='+deploymentResultId+'&action=Stopped' ;
            String params = 'userId='+EncodingUtil.urlEncode(UserID, 'UTF-8')+'&userEmail='+EncodingUtil.urlEncode(userEmail, 'UTF-8')+'&deploymentResultId='+EncodingUtil.urlEncode(deploymentResultId, 'UTF-8')+'&action='+ProdlyConstants.STOPPED ;
    
            HttpResponse response= ProdlyHttpService.makePostCallout(serviceUrl,params);
            Integer statusCode = response.getStatusCode();
            String statusName = response.getStatus();
            
            String res='';
            String errorMsg;
            String infoMsg;
    
            if(response!=null && statusCode==200){
                res = response.getBody();
                if(res=='' || res==null){
                    errorMsg = Label.INVALID_RESPONSE;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, errorMsg));
                }
                
            }else{
                errorMsg = 'Request failed. Please contact administrator. <br/> Error Code: <b>' + statusCode + '</b><br/> Error Message: <b>' + statusName + '</b>';
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, errorMsg));
            }
            if(res!=null)
                res=res.trim();
            return res;
        
        } else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.ENDPOINT_MISSING));
            return '';
        }
    }


    /**
     * This method id using for start deployment service, which is using for deploy data one org to other org 
     * @author Rohit Ramawat <rohit.ramawat@simplyforce.com>
     * @param String deploymentResultId unique key for pause deployment process
     * @return String after http post request service will return resonse in string format
     * @version V_1.0
     * @since 03/10/2017
     * @todo Need to create test classes for it
     */
    public static string pauseDeploymentServiceCall(String deploymentResultId) {
        
        //String to hold the Endpoint URl
        String serviceUrl = getEndPoint();
        
        //Check if serviceUrl is not blank. 
        if(String.isNotBlank(serviceUrl)){
            
            //Creating Endpoint URL by Appending additional parameters
            serviceUrl += '/action'; 
            
            String UserID = UserInfo.getUserId();
            String UserEmail = UserInfo.getUserEmail();
            //String params = '{"userId":"'+UserID+'","userEmail":"'+UserEmail+'","deploymentResultId":"'+deploymentResultId+'","action":"Started"}' ;
            //String params = 'userId='+UserID+'&userEmail='+UserEmail+'&deploymentResultId='+deploymentResultId+'&action=Paused' ;
            String params = 'userId='+EncodingUtil.urlEncode(UserID, 'UTF-8')+'&userEmail='+EncodingUtil.urlEncode(userEmail, 'UTF-8')+'&deploymentResultId='+EncodingUtil.urlEncode(deploymentResultId, 'UTF-8')+'&action='+ProdlyConstants.PAUSED ;
            HttpResponse response= ProdlyHttpService.makePostCallout(serviceUrl,params);
            Integer statusCode = response.getStatusCode();
            String statusName = response.getStatus();
            
            String res='';
            String errorMsg;
            String infoMsg;
            if(response!=null && statusCode==200){
                
                res = response.getBody();
                
                if(res=='' || res==null){
                    errorMsg = Label.INVALID_RESPONSE;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, errorMsg));
                }
            }else{
                errorMsg = 'Request failed. Please contact administrator. <br/> Error Code: <b>' + statusCode + '</b><br/> Error Message: <b>' + statusName + '</b>';
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, errorMsg));
            }
            if(res!=null)
                res=res.trim();
            return res;
        }
        else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.ENDPOINT_MISSING));
            return '';
        }
       
    }

    /**
     * This method id using for start deployment service, which is using for deploy data one org to other org 
     * @author Rohit Ramawat <rohit.ramawat@simplyforce.com>
     * @param String deploymentResultId unique key for resume deployment process
     * @return String after http post request service will return resonse in string format
     * @version V_1.0
     * @since 03/10/2017
     * @todo Need to create test classes for it
     */
    public static string resumeDeploymentServiceCall(String deploymentResultId) {
        
        //String to hold the Endpoint URl
        String serviceUrl = getEndPoint();
        
        //Check if serviceUrl is not blank. 
        if(String.isNotBlank(serviceUrl)) {
            
            //Creating Endpoint URL by Appending additional parameters
            serviceUrl += '/action';        
            
            String UserID = UserInfo.getUserId();
            String UserEmail = UserInfo.getUserEmail();
            //String params = '{"userId":"'+UserID+'","userEmail":"'+UserEmail+'","deploymentResultId":"'+deploymentResultId+'","action":"Started"}' ;
            //String params = 'userId='+UserID+'&userEmail='+UserEmail+'&deploymentResultId='+deploymentResultId+'&action=Started' ;
            String params = 'userId='+EncodingUtil.urlEncode(UserID, 'UTF-8')+'&userEmail='+EncodingUtil.urlEncode(userEmail, 'UTF-8')+'&deploymentResultId='+EncodingUtil.urlEncode(deploymentResultId, 'UTF-8')+'&action='+ProdlyConstants.STARTED ;
            
            HttpResponse response= ProdlyHttpService.makePostCallout(serviceUrl,params);
            Integer statusCode = response.getStatusCode();
            String statusName = response.getStatus();
            
            String res='';
            String errorMsg;
            String infoMsg;
            if(response!=null && statusCode==200){
                res = response.getBody();
                if(res=='' || res==null){
                    errorMsg = Label.INVALID_RESPONSE;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, errorMsg));
                }
            }else{
                errorMsg = 'Request failed. Please contact administrator. <br/> Error Code: <b>' + statusCode + '</b><br/> Error Message: <b>' + statusName + '</b>';
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, errorMsg));
            }
            if(res!=null)
                res=res.trim();
            return res;
        } else {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.ENDPOINT_MISSING));
            return '';
        }
    }
    
    /**
     * @description :   Method to get the endpoint URI according to the Moovers (custom setting) Instance type (Custom Field) value.
     *
     * @args        :   
     *
     * @return      :   void
     *
     * @createdBy   :   Romesh Kumar
     *
     * @Version     :   V_2.0 Created
     **/  
    private static String getEndPoint() {
        
        //Variabe to hold the endpoint URI
        String endPointURI = '';
        
        //Check id Instance type of Moover (Cusotm Setting) is not null.
        if(ReplicateIt_Settings__c.getOrgDefaults().Instance_Type__c != null ){
            
            //Qeury to fetch the endpoint 
            List<Prodly_Moover_Credetial_Details__mdt> pMCredDteails = [SELECT DeveloperName, Endpoint__c FROM Prodly_Moover_Credetial_Details__mdt WHERE DeveloperName LIKE : ReplicateIt_Settings__c.getOrgDefaults().Instance_Type__c + '%' LIMIT 1];
            
            //Check if pMCredDteails filled, then set the endpoint URI
            if( pMCredDteails.size() > 0) 
                endPointURI = pMCredDteails[0].Endpoint__c;
        
        } else {
            
            //Set endpoint of Production
            endPointURI = [SELECT DeveloperName, Endpoint__c FROM Prodly_Moover_Credetial_Details__mdt WHERE DeveloperName LIKE : 'Prod%' LIMIT 1].Endpoint__c;
        }
        
        return endPointURI;
    }
    
    
    public static String getAccessToken(String requestType, String clientId, String clientScrete, String refreshToken) {
    	
    	if(String.isNotBlank(clientId) && String.isNotBlank(requestType) && String.isNotBlank(clientScrete) &&  String.isNotBlank(refreshToken)) {
    		Http http = new Http();
	        HttpRequest request = new HttpRequest();
	        String baseUrl = requestType == 'Production' ? 'https://login.salesforce.com' : 'https://test.salesforce.com';
	        
	        request.setMethod('GET');
	        request.setEndpoint(baseUrl+'/services/oauth2/token');
	        
	        String queryString = 'grant_type=refresh_token&client_id='+clientId+'&client_secret='+clientScrete+'&refresh_token='+refreshToken+'&format=json';       
	        request.setBody(queryString);
	        HttpResponse res = http.send(request);
	        String body = (res.getBody());
		        
	        if(res.getStatusCode() == 200 && (body != null || body != '') && body.contains('access_token')) { 
		        String accessT = (body.split('"access_token":"')[1]).split('",')[0];
		        return accessT;
	        }
    	}
    	return null;    
    }
    public static List<Object> doCalloutOrigin(Connection__c con) {
        
        String clientId = CustomSettingsUtilities.getInstance().getClientId();
        String consumerKey = CustomSettingsUtilities.getInstance().getClientSecret();
        if(String.isNotBlank(clientId) && String.isNotBlank(consumerKey)) {
	        String accessToken = getAccessToken(con.Org_Type__c,clientId,consumerKey, con.Refresh_Token__c);
	        
	        if(String.isNotBlank(accessToken)) {
	        	Http http = new Http();
		        HttpRequest request = new HttpRequest();
		        request.setEndpoint(con.Instance_URL__c+'/services/data/v22.0/sobjects/');
		        request.setMethod('GET');
		        request.setHeader('Authorization','Bearer '+accessToken);
		        HttpResponse res = http.send(request);
		        String body = (res.getBody());
		        
		        if(res.getStatusCode() == 200 && (body != null || body != '')) { 
			        Map<String, Object> mapOfResult = (Map<String, Object>)JSON.deserializeUntyped(body);
			        List<Object> lstOfObjects = (List<Object>)mapOfResult.get('sobjects');
			        return lstOfObjects;
		        }
	        }
        }
        return null;
    }
    
    public static Map<String,Object> describeOriginSObject(Connection__c con, String objName) {
        
        String clientId = CustomSettingsUtilities.getInstance().getClientId();
        String consumerKey = CustomSettingsUtilities.getInstance().getClientSecret();
        if(String.isNotBlank(clientId) && String.isNotBlank(consumerKey)) {
        	String accessToken = getAccessToken(con.Org_Type__c,clientId,consumerKey, con.Refresh_Token__c);
        	
        	if(String.isNotBlank(accessToken)) {
		        Http http = new Http();
		        HttpRequest request = new HttpRequest();
		        request.setEndpoint(con.Instance_URL__c+'/services/data/v22.0/sobjects/'+objName+'/describe');
		        request.setMethod('GET');
		        request.setHeader('Authorization','Bearer '+accessToken);
		        HttpResponse res = http.send(request);
		        
		        String body = (res.getBody());
		        
		        if(res.getStatusCode() == 200 && (body != null || body != '')) { 
		            Map<String, Object> mapOfResult = (Map<String, Object>)JSON.deserializeUntyped(body);
		            return mapOfResult;
		        }
		        else {
		            return new Map<String,Object>();
		        }
        	}
        }
        return null;
    }
    
}