public with sharing class RemoteSiteController {
   
    public static void createRemoteSiteSettings(String nameRS, String urlRS, String des) { 
    	try {  
	        MetadataService.MetadataPort service = createService();
	        MetadataService.RemoteSiteSetting remoteSiteSettings = new MetadataService.RemoteSiteSetting();
	        remoteSiteSettings.fullName = ((nameRS.remove('_')).remove(' ')).remove('-');
	        remoteSiteSettings.url = urlRS;
	        remoteSiteSettings.description = des;
	        remoteSiteSettings.isActive=true;
	        remoteSiteSettings.disableProtocolSecurity=false;
	        MetadataService.AsyncResult[] results = service.create(new List<MetadataService.Metadata> { remoteSiteSettings });
	        MetadataService.AsyncResult[] checkResults = service.checkStatus(new List<string> {string.ValueOf(results[0].Id)});
	        system.debug('chk' + checkResults );
    	}
    	catch(Exception e) {
    		System.debug('RemoteSiteSetting'+e.getMessage());
    	}
    }

     public static MetadataService.MetadataPort createService() {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;
    }


}