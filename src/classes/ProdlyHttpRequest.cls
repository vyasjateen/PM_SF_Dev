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
    
    
    
    public static void doCalloutOrigin() {
    	HttpRequest request = new HttpRequest();
		request.setEndpoint('https://ap5.salesforce.com/services/data/v22.0/sobjects/');
		request.setMethod('GET');
		request.setHeader('Authorization', '00D7F000000rkwd!AQgAQF1P.yhULd3zeOar_PwJ7btzubwEUOVqzqchEu.pdWcn9QC0e_xPfMOqoFxu9_QrwMYx.rEHRbHlksedYhepUyxYa1.F');
		String body = (new Http()).send(request).getBody();
		system.debug('******body  **********'+body);
		//JSONParser jsonParse = JSONParser.parse(body);
		
		//system.debug(jsonParse.sobjects);
    }
    
}