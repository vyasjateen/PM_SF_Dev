/**
 *	Description			:	this class is using for make http post/get request to hit web service end point.
 *
 *	Created By			:	
 *
 *	Created Date		:	03/10/2017
 *
 *	Version				:	V_1.0
 *
 *	Revision Log		:	V_1.0 - Created
 							V1_1 Modiified by Romesh
 							
 *
 *	Access Modifiers	:	
**/

public class ProdlyHttpService{


	/**
	 * This is a generic method to call all get type web service and get data from end point
	 * @author Rohit Ramawat <rohit.ramawat@simplyforce.com>
	 * @param String url end point url
	 * @return HttpResponse after http get request responce return by end point
	 * @version V_1.0
	 * @since 03/10/2017
	 * @todo Need to create test classes for it
	 */
    /*public static HttpResponse makeGetCallout(String url) {
    	
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) {
            // Deserializes the JSON string into collections of primitive data types.
            //Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            // Cast the values in the 'animals' key as a list
            //List<Object> animals = (List<Object>) results.get('animals');
            System.debug('Received the following ');
            //for (Object animal: animals) {
            //   System.debug(animal);
            //}
        }
        return response;
    }*/
	/**
	 * This is a generic method to make post type web service request.
	 * @author Rohit Ramawat <rohit.ramawat@simplyforce.com>
	 * @param String url End point url
	 * @param String jsonStringParms formatted json string which contains webservice required parameters
	 * @return HttpResponse after http get request responce return by end point
	 * @version V_1.0
	 * @since 03/10/2017
	 * @todo Need to create test classes for it
	 */
    public static HttpResponse makePostCallout(String url, String jsonStringParms) {
    	
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('POST');
    	
    	/*V1_1 Added by Romesh*/
    	request.setTimeout(120000);
        
        //request.setHeader('Content-Type', 'application/json;charset=UTF-8');
     	request.setHeader('Content-Type','application/x-www-form-urlencoded');  
        //jsonStringParms      request.setBody('{"name":"mighty moose"}');
        request.setBody(jsonStringParms);
        HttpResponse response = http.send(request);
        
       
        // Parse the JSON response
        if (response.getStatusCode() != 201) {
            System.debug('The status code returned was not expected: ' +
                response.getStatusCode() + ' ' + response.getStatus());
        } else {
            System.debug(response.getBody());
        }
        return response;
    }        

}