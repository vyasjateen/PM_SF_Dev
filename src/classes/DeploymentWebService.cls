@RestResource(urlMapping='/dataset/deploy/*')
global with sharing class DeploymentWebService {
	public final static String TARGET_CONNECTION_ID_PARAMETER = 'targetConnectionId';
	
	@HttpGet
	global static DeploymentResult doGet() {
		String rootDataSetId;
		
		try {
			Integer startIndex = RestContext.request.requestURI.lastIndexOf('/') + 1;
			Integer endIndex = RestContext.request.requestURI.length();
			
			rootDataSetId = RestContext.request.requestURI.substring(startIndex, endIndex);
		} catch(Exception e) {
			//Ignore
		}
		
		String targetConnectionId;
		
		try {
			targetConnectionId = String.escapeSingleQuotes( RestContext.request.params.get( DeploymentWebService.TARGET_CONNECTION_ID_PARAMETER ) );
		} catch(Exception e) {
			//Ignore
		}
        
        DeploymentResult result = new DeploymentResult();
        
        if( targetConnectionId == null ) {
        	result.error = 'No target connection ID has been specified.';
        
        	return result;
        }
        
        try {
        	result.resultId = DeploymentService.deploy(rootDataSetId, targetConnectionId);
        } catch(Exception e) {
        	result.error = e.getMessage();
        }
        
        return result;
	}
	
	global class DeploymentResult {
		global String resultId;
		global String error;
	}
}