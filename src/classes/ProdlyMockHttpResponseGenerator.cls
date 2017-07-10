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
/**
 *  Description     :	using for create fake responce of web service
 *
 *  Created By      :   ROhit
 *
 *  Created Date    :   03-16-2017
 *
 *  Version         :   V_1.0
 *
 *  Code Coverage	:	
**/

@isTest
global class ProdlyMockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
   
    
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
     	String UserID = '1234';
        String userEmail = 'standarduser1@testorg.com';
        String deploymentResultId = '1234';
     	HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/x-www-form-urlencoded');
        if(request.getBody().contains('Started')){
        	String params = 'userId='+EncodingUtil.urlEncode(UserID, 'UTF-8')+'&userEmail='+EncodingUtil.urlEncode(userEmail, 'UTF-8')+'&deploymentResultId='+EncodingUtil.urlEncode(deploymentResultId, 'UTF-8')+'&action='+ProdlyConstants.STARTED ;
            res.setBody('Started');
        }else if(request.getBody().contains('Paused')){
	        String params = 'userId='+EncodingUtil.urlEncode(UserID, 'UTF-8')+'&userEmail='+EncodingUtil.urlEncode(userEmail, 'UTF-8')+'&deploymentResultId='+EncodingUtil.urlEncode(deploymentResultId, 'UTF-8')+'&action='+ProdlyConstants.PAUSED ;
            res.setBody('Paused');
        }else if(request.getBody().contains('Stopped')){
            String params = 'userId='+EncodingUtil.urlEncode(UserID, 'UTF-8')+'&userEmail='+EncodingUtil.urlEncode(userEmail, 'UTF-8')+'&deploymentResultId='+EncodingUtil.urlEncode(deploymentResultId, 'UTF-8')+'&action='+ProdlyConstants.STOPPED ;
            res.setBody('Stopped');
    	}            
        res.setStatusCode(200);
        return res;
    }
}