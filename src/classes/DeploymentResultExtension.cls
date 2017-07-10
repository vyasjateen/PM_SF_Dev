/**
 *  Description         :   This class is using for enable/disable buttons on deploymentresult visual force page conditionally 
 *
 *  Created By          :   Rohit Ramawat
 *
 *  Created Date        :   03/09/2017
 *
 *  Version             :   V_1.0
 *
 *  Revision Log        :   V_1.0 - Created
   							V_2.0 - Modified :- Romesh Kumar
   									Description :- Modified all the condition when the button will show and hide. made all message correct and put all message in the Custom 
   									Label, So client can modify them accordign to their need.
   									
 *
 *  Access Modifiers    :   
**/

public class DeploymentResultExtension {

    //Variable to hold the status of button enable/disable.
    public boolean startService { get;set; }
   
    //Variable to hold the status of button enable/disable.
    public boolean pauseService { get;set; }
   
    //Variable to hold the status of button enable/disable.
    public boolean resumeService { get;set; }
    
    //Variable to hold the status of button enable/disable.
    public boolean stopService { get;set; }
    
    //Instance to hold the deployment result record.
    private final Deployment_Result__c DeploymentResult;
    
    //String to hold the request name if it is Start, Pause, Stop Or Resume.
    String requestedEvent;
    
    //Flag to check if action:Poller request is enable or not
    public Boolean pollerRequest {get; set;}
    
    /**
     * Constructor
     * The extension constructor initializes the private member
     * variable acct by using the getRecord method from the standard    
     * @author Rohit Ramawat <rohit.ramawat@simplyforce.com>
     * @version V_1.0
     * @params ApexPages.StandardController stdController
     * @since 03/19/2017
     */
    
    public DeploymentResultExtension (ApexPages.StandardController stdController) {

        Deployment_Result__c dResult= (Deployment_Result__c)stdController.getRecord();
        // On page load button will be enable/disable according to Status__c value for the perticular record
        // true : button will be disable on UI
        // false : button will be enable/clickabe on UI. 
        requestedEvent = '';
        
        //Query on the Deployment result to get Deployment Detail
    	this.DeploymentResult = [SELECT Id, Status__c, LastModifiedDate FROM Deployment_Result__c WHERE Id =: dResult.Id LIMIT 1];
            
        
        pollerRequest = false;
        
        if(DeploymentResult.Status__c != null && DeploymentResult.Status__c.equalsIgnoreCase(ProdlyConstants.FINISHED)) {
            
            startService = true;
            pauseService = true;
            resumeService = true;
            stopService = true;
        } else if(DeploymentResult.Status__c != null && DeploymentResult.Status__c.equalsIgnoreCase(ProdlyConstants.STARTED)) {
          
            startService = true;
            pauseService = false;
            resumeService = true;
            stopService = false;
        } else if(DeploymentResult.Status__c != null && DeploymentResult.Status__c.equalsIgnoreCase(ProdlyConstants.PAUSED)) {
	      
	    	if(DeploymentResult.LastModifiedDate >= Date.today().addDays(-7)) {
	            
	            startService = true;
	            pauseService = true;
	            resumeService = false;
	            stopService = false;
	        } else {
	        	
	        	startService = true;
	            pauseService = true;
	            resumeService = true;
	            stopService = true;
	            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.DEPLOYMENT_LOST_ALERT));
	        }
        } else {
            
            startService = true;
            pauseService = true;
            resumeService = true;
            stopService = true;
        }
    }
    
    /**
    */
    public PageReference startService() {
        return null;
    }
    
    /**
     * method is using for start deployment one org to other salesforce org using web service.
     * @author Rohit Ramawat <rohit.ramawat@simplyforce.com>
     * @version V_1.0
     * @since 03/19/2017
     */
    public void startServiceCall(){
        
        // Assign value of url parameter Id to deploymentResultId variable
        String deploymentResultId = ApexPages.currentPage().getParameters().get('id');
        
        // start record deployment from one org to other org using following service
        String response = ProdlyHttpRequest.startDeploymentServiceCall(deploymentResultId);
        
        // response equal to Started then disable following buttons  startService,resumeService and
        // enable following buttons pauseService,stopService
        if(response.equalsIgnoreCase(ProdlyConstants.STARTED)){
            
            //Set flag values
            startService = true;
            pauseService = false;
            resumeService = true;
            stopService = false;
            
            //String infoMsg = ProdlyConstants.DEPLOYMENT_SERVICE_SUCCESS_MESSAGE;
            //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.DEPLOYMENT_SUCCESS_MESSAGE));
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.INVALID_RESPONSE));
        }
    }
     
    /**
     * method is using for change deployment service status start to resume .
     * @author Rohit Ramawat <rohit.ramawat@simplyforce.com>
     * @version V_1.0
     * @since 03/19/2017
     */
     public void pauseService() {
        
        // Assign value of url parameter Id to deploymentResultId variable
        String deploymentResultId = ApexPages.currentPage().getParameters().get('id');
        
        //Check if the Deployment Result Id is not blank
        if(String.isNotBlank(deploymentResultId)){
           
           //Set requested Event is Pause
           requestedEvent = ProdlyConstants.PAUSED;
        
            //Query on the Deployment result to get Deployment Detail
            Deployment_Result__c deployResult = [SELECT Id, Status__c FROM Deployment_Result__c WHERE Id =: deploymentResultId LIMIT 1];
            
            //Check if deployResult Status is not equals to the Finished
            if(!deployResult.Status__c.equalsIgnoreCase(ProdlyConstants.FINISHED)) {
            
                //Check if deployResult Status is not equals to the Stopped
                if(!deployResult.Status__c.equalsIgnoreCase(ProdlyConstants.STOPPED)){
                    
                    //Check if deployResult Status is not equals to the Paused
                    if(!deployResult.Status__c.equalsIgnoreCase(ProdlyConstants.PAUSED)){
            			
            			// pause record deployment from one org to other org using following service
                        String response = ProdlyHttpRequest.pauseDeploymentServiceCall(deploymentResultId);
                        
                        // response equal to Paused then disable following buttons  startService,pauseService and
                        // enable following buttons resumeService,stopService
                        if(response.equalsIgnoreCase(ProdlyConstants.PAUSED)){
                            
                            //Set poller request flag to true
            				pollerRequest = true;
                            
                            //Set flag values
                            startService = true;
                            pauseService = true;
                            resumeService = false;
                            stopService = false;
                            
                            //Update the Status of deployment result to the Request in Progress 
                            //update new Deployment_Result__c(Id = deploymentResultId, Status__c = ProdlyConstants.REQUEST_IN_PROGRESS);
                            
                            //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.DEPLOYMENT_SUCCESS_MESSAGE));
                        }else{
                        	//Set poller request flag to false
    						pollerRequest = false;
                            
                            if(String.isNotBlank(response))
                            	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.INVALID_RESPONSE));
                        }
                    } else {
                        
                        //Set flag values
                        startService = true;
                        pauseService = true;
                        resumeService = false;
                        stopService = false;
                        
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.PAUSE_ALERT));
                    }
                }else {
                	//Set flags to true to disable the button
		            pauseService = true;
		            resumeService = true;
		            stopService = true;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.STOP_ALERT));
                }
                updateDDSRStatus(deploymentResultId,requestedEvent);
            } 
            else {
            	
            	//Set flags to true to disable the button
	            pauseService = true;
	            resumeService = true;
	            stopService = true;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.FINISH_ALERT));   
            }
         }
     }
    
    
    /**
     * method is using for change deployment service status pause to resume .
     * @author Rohit Ramawat <rohit.ramawat@simplyforce.com>
     * @version V_1.0
     * @since 03/19/2017
     */
     public void resumeService() {
        
        // Assign value of url parameter Id to deploymentResultId variable
        String deploymentResultId = ApexPages.currentPage().getParameters().get('id');  
        
        //Check if the Deployment Result Id is not blank
        if(String.isNotBlank(deploymentResultId)) {
         	
         	//Set requested Event is Pause
            requestedEvent = ProdlyConstants.STARTED;
         	
            //Query on the Deployment result to get the Deployemnt Result detail
            Deployment_Result__c deployResult = [SELECT Id, Status__c FROM Deployment_Result__c WHERE Id =: deploymentResultId LIMIT 1];
            
            //Check if Status is not equals to the Finished
            if(!deployResult.Status__c.equalsIgnoreCase(ProdlyConstants.FINISHED)) {
                
                //Check if Status is not equals to the Stopped
                if(!deployResult.Status__c.equalsIgnoreCase(ProdlyConstants.STOPPED)) {            
                
                    //Check if Status is not equals to the Started
                    if(!deployResult.Status__c.equalsIgnoreCase(ProdlyConstants.STARTED)) {
            			
            			// resume record deployment from one org to other org using following service
                        String response = ProdlyHttpRequest.resumeDeploymentServiceCall(deploymentResultId);
                        
                        // response equal to STARTED then disable following buttons  startService,resumeService and
                        // enable following buttons pauseService,stopService        
                        if(response.equalsIgnoreCase(ProdlyConstants.STARTED)) {
                            
                            //Set poller request flag to true
            				pollerRequest = true;
                            
                            //Set flag values
                            startService = true;
                            pauseService = false;
                            resumeService = true;
                            stopService = false;
                            
                            // update status according to web service responce
                            updateDRStatus(deploymentResultId,ProdlyConstants.STARTED);
                            
                        }
                        else{
                        	//Set poller request flag to false
    						pollerRequest = false;
    						
                            if(String.isNotBlank(response))
                            	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.INVALID_RESPONSE));
                        }
                    } else {
                        
                        //Set flag values
                        startService = true;
                        pauseService = false;
                        resumeService = true;
                        stopService = false;
                        
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.START_ALERT));
                    }
                } else {
                	
                	//Set flags to true to disable the button
		            pauseService = true;
		            resumeService = true;
		            stopService = true;
		            
		            //Show stop aalert on page.
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.STOP_ALERT));
                }
            } else{
            	//Set flags to true to disable the button
	            pauseService = true;
	            resumeService = true;
	            stopService = true;
	            
	            //Show finish alert on page
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.FINISH_ALERT));   
            }
        }
            
    }
    /**
     * method is using for change deployment service status pause/start/ to stop .
     * @author Rohit Ramawat <rohit.ramawat@simplyforce.com>
     * @version V_1.0Deployment_Result__c
     * @since 03/19/2017
     */
     public void stopService() {
        
        // Assign value of url parameter Id to deploymentResultId variable
        String deploymentResultId = ApexPages.currentPage().getParameters().get('id');
        
        //Check if the Deployment Result Id is not blank
        if(String.isNotBlank(deploymentResultId)) {
        	
        	//Set requested Event is Pause
            requestedEvent = ProdlyConstants.STOPPED;
        	
            //Query on the Deployment result to get the Deploument result detail
            Deployment_Result__c deployResult = [SELECT Id, Status__c  FROM Deployment_Result__c WHERE Id =: deploymentResultId LIMIT 1];
            	
        	//Check if Status is not equals to the Finished
            if(!deployResult.Status__c.equalsIgnoreCase(ProdlyConstants.FINISHED)) {
                
                //Check if Status is not equals to the Stopped
                if(deployResult != null && !deployResult.Status__c.equalsIgnoreCase(ProdlyConstants.STOPPED)) {              
                    
            		// stop record deployment from one org to other org using following service
                    String response = ProdlyHttpRequest.stopDeploymentServiceCall(deploymentResultId);
                    
                    // response equal to STOPPED then disable following buttons pauseService,resumeService,stopService and
                    // enable following buttons startService  
                    if(response.equalsIgnoreCase(ProdlyConstants.STOPPED)) {
                        
                        //Set poller request flag to true
    					pollerRequest = true;
                        
                        //Set flag values
                        startService = false;
                        pauseService = true;
                        resumeService = true;
                        stopService = true;
                               
                        //Check if the Status is not equals to the Paused 
                        if(!deployResult.Status__c.equalsIgnoreCase(ProdlyConstants.STOPPED)) {
                            
                            //Update the Deploymentn result status to Stopped
                            updateDRStatus(deploymentResultId,ProdlyConstants.STOPPED);
                            
                        }   
                       
                    } else {
                    	//Set poller request flag to false
    					pollerRequest = false;
                        
                        //Check if response is blank
                        if(String.isNotBlank(response))
                        	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.INVALID_RESPONSE));
                    }
                     updateDDSRStatus(deploymentResultId,requestedEvent);
                } else {
                    
                    //Set flag values
                    startService = false;
                    pauseService = true;
                    resumeService = true;
                    stopService = true;
                   
                    //Add msg to show on page
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.STOP_ALERT));
                }
            } else {
            	//Set flags to true to disable the button
	            pauseService = true;
	            resumeService = true;
	            stopService = true;
	            
	            //Show finish alert on the page.
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, Label.FINISH_ALERT));   
            }
        }
    }
    /**
     * @description :   Method to get the Deployment result status detail wheteher the status is updated or not
     *
     * @args        :   
     *
     * @return      :   void
     *
     * @createdBy   : 	Romesh Kumar
     *
     * @Version     :   V_1.0 Created
     **/  
     public void disablePollerFunction () {
     	
     	// Assign value of url parameter Id to deploymentResultId variable
        String deploymentResultId = ApexPages.currentPage().getParameters().get('id');
		
		//Check if deploymentResultId is not blank
		if(String.isNotBlank(deploymentResultId)) {
			//Query on the Deployment result to get the dployment result detail
	        Deployment_Result__c deployResult = [SELECT Id, Status__c FROM Deployment_Result__c WHERE Id =: deploymentResultId LIMIT 1];
	            
	     	//Check if deployResult is not null and status is changed according to the request.
	     	if(deployResult != null && (deployResult.Status__c.equalsIgnoreCase(requestedEvent) || deployResult.Status__c.equalsIgnoreCase(ProdlyConstants.FINISHED)))
	     		pollerRequest = false;
	   }
     }
    
    
    /**
     * method is using for update deployment result status according to web service responce.
     * @author Rohit Ramawat <rohit.ramawat@simplyforce.com>
     * @version V_1.0Deployment_Result__c
     * @since 03/22/2017
     * @param String deploymentResultId
     * @param String status
     */
    @future
    public static void updateDRStatus(String deploymentResultId, String status) {
        
        // if web service response equal to stopped and deploymentResultId not equalto null and having current status=Paused then
        // update deployment result status = Stopped 
        if(status.equalsIgnoreCase(ProdlyConstants.STOPPED)) {
            
            //Update the status   
            update new Deployment_Result__c(Id=deploymentResultId,Status__c=ProdlyConstants.STOPPED);
        } else if(status.equalsIgnoreCase(ProdlyConstants.STARTED)) {

            //Update the status   
            update new Deployment_Result__c(Id=deploymentResultId,Status__c=ProdlyConstants.STARTED);
        }
    }
    
    
    /**
     * method is using for update deployment data set result status according to web service responce.
     * @author Jatin Vyas
     * @version 
     * @since 
     * @param 
     * @param String status    
     */
  	@future
    public static void updateDDSRStatus(Id deploymentResultId, String requestedEvent) {
        System.debug('deploymentResultId'+deploymentResultId);
        
        // if web service response equal to stopped and deploymentResultId not equalto null and having current status=Paused then
        // update deployment result status = Stopped 
        if(deploymentResultId != null) {
        	
        	List<Deployment_Data_Set_Result__c> dDSR = [Select Id, Status__c,Deployment_Result__c FROM Deployment_Data_Set_Result__c where Deployment_Result__c =: deploymentResultId];
      
	        if(dDSR.size() > 0) {
	            List<Deployment_Data_Set_Result__c> updateDeployDataSetResult = new List<Deployment_Data_Set_Result__c>();
	            
	            for(Deployment_Data_Set_Result__c dDSResult : dDSR) {
	            	
	            	if(!dDSResult.Status__c.equalsIgnoreCase('Finished')) {
	            		if(requestedEvent == 'STOPPED')
	            			dDSResult.Status__c = 'Stopped';
            			else if(requestedEvent == 'PAUSED')
            				dDSResult.Status__c = 'Paused';
	            		updateDeployDataSetResult.add(dDSResult);
	            	}
	            }
	            
	            if(updateDeployDataSetResult.size() > 0)
	            	update updateDeployDataSetResult;
	        }
		}
           
    }
}