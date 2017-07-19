global with sharing  class DeploymentService {
	global static Id deploy(Id rootDataSetId, Id targetConnectionId) {
		DataSet__c rootDataSet = DeploymentUtils.queryDataSet(rootDataSetId, new Map<Id,DataSet__c>());
		
		Connection__c targetConnection = AccessValidationUtilities.queryConnectionsAsUser('where Id = \'' + targetConnectionId + '\' LIMIT 1').get(0);
		Connection__c sourceConnection = AccessValidationUtilities.queryConnectionsAsUser('where Source_Connection__c = true AND Active__c = true LIMIT 1').get(0);
		Connection__c localConnection =  AccessValidationUtilities.queryConnectionsAsUser('where Local_Connection__c = true AND Active__c = true LIMIT 1').get(0);
		Id deploymentResultId = DeploymentUtils.insertDeploymentResult(sourceConnection.Id, targetConnection.Id, 1);
			
		JSONGenerator generator = JSON.createGenerator(false);
		DeploymentUtils.generateDeploymentParameter(new List<DataSet__c>{rootDataSet},localConnection, sourceConnection, targetConnection, deploymentResultId, generator);
			
		String jsonstring = generator.getAsString();
			
		DeploymentUtils.launchDeployment(jsonstring, deploymentResultId);
			
		return deploymentResultId;
	}
}