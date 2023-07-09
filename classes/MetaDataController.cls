public class MetaDataController {

    // @description : This is rules for different types and different fields
    public static List<String> ruleLength = new List<String>{'Text'};
    public static List<String> rulePrecision = new List<String>{'Number','Currency','Percent'};
    public static List<String> ruleRequired = new List<String>{'Text','Number','Email','Currency','Percent','Phone','Date'};
    public static List<String> ruleUnique = new List<String>{'Text','Number','Email'};
    public static List<String> ruleExternal = new List<String>{'Text','Number','Email'};
    public static List<String> ruleRelation = new List<String>{'Lookup','MasterDetail'};
    
    
    // @description : Create object with fields
    @AuraEnabled(cacheable=false)
    public static List<MetadataService.SaveResult> createObjects(String configs, String sessionId, Boolean withFields) {
        
        List<Object> tempList = (List<Object>) JSON.deserializeUntyped(configs);
        List<Map<String, Object>> configList = new List<Map<String, Object>>();

        for (Object obj : tempList) {
            if (obj instanceof Map<String, Object>) {
                Map<String, Object> config = (Map<String, Object>) obj;
                configList.add(config);
            }
        }
        System.debug('CONFIG '+configList);

        // Create service for current user session
        MetadataService.MetadataPort service = createService(sessionId);

        List<MetadataService.Metadata> newObjectList = new List<MetadataService.Metadata>();

        for (Map<String, Object> con : configList) {
            MetadataService.CustomObject customObject = new MetadataService.CustomObject();
            customObject.fullName = String.valueOf(con.get('OBJECT_API'));
            customObject.label = String.valueOf(con.get('OBJECT_LABEL'));
            customObject.pluralLabel = String.valueOf(con.get('OBJECT_PURAL'));
            customObject.nameField = new MetadataService.CustomField();
            customObject.nameField.type_x = String.valueOf(con.get('FIELD_TYPE'));
            customObject.nameField.label = String.valueOf(con.get('FIELD_LABEL'));
            customObject.deploymentStatus = String.valueOf(con.get('DEPLOY_STATUS'));
            customObject.sharingModel = String.valueOf(con.get('SHARING_MODEL'));
            newObjectList.add(customObject);

            // If fields also created with object
            if (withFields) {
                if (con.containsKey('Fields')) {
                    List<Map<String, Object>> fieldList = new List<Map<String, Object>>();
                    for (Object obj : (List<Object>) con.get('Fields')) {
                        if (obj instanceof Map<String, Object>) {
                            Map<String, Object> field = (Map<String, Object>) obj;
                            fieldList.add(field);
                        }
                    }
                    newObjectList.addAll(createCustomFields(fieldList, con.get('OBJECT_API')));
                    // add to page layout
                    // newObjectList.add(addFieldsToLayout(service,fieldList,con.get('OBJECT_API')));

                }
            }
        }

        return createMetadataBatches(service, newObjectList);
    }

    // @description : Create fields
    @AuraEnabled(cacheable=false)
    public static List<MetadataService.SaveResult> createFields(String configs, String sessionId){
        
        List<Object> tempList = (List<Object>) JSON.deserializeUntyped(configs);
        List<Map<String, Object>> configList = new List<Map<String, Object>>();

        for (Object obj : tempList) {
            if (obj instanceof Map<String, Object>) {
                Map<String, Object> field = (Map<String, Object>) obj;
                configList.add(field);
            }
        }

        // Create service for current user session
        MetadataService.MetadataPort service = createService(sessionId);

        List<MetadataService.Metadata> newFieldList = new List<MetadataService.Metadata>();
        for (Map<String, Object> obj : configList) {

            List<Object> tempList2 = (List<Object>) obj.get('Fields');
            List<Map<String, Object>> configList2 = new List<Map<String, Object>>();

            for (Object obj2 : tempList2) {
                if (obj2 instanceof Map<String, Object>) {
                    Map<String, Object> field = (Map<String, Object>) obj2;
                    configList2.add(field);
                }
            }

            newFieldList.addAll(createCustomFields(configList2, String.valueOf(obj.get('OBJECT_API'))));
        }

        return createMetadataBatches(service, newFieldList);

    }

    // @description : create custom field for specific object
    public static List<MetadataService.Metadata> createCustomFields(List<Map<String, Object>> fieldList, Object objectApi) {
        List<MetadataService.Metadata> customFields = new List<MetadataService.Metadata>();

        for (Map<String, Object> field : fieldList) {
            MetadataService.CustomField customField = new MetadataService.CustomField();
            customField.fullName = String.valueOf(objectApi) + '.' + String.valueOf(field.get('API'));
            customField.label = String.valueOf(field.get('LABEL'));
            customField.type_x = String.valueOf(field.get('TYPE'));

            if (ruleLength.contains(String.valueOf(field.get('TYPE')))) {
                customField.length = Integer.valueOf(field.get('LENGTH'));
            }
            if (rulePrecision.contains(String.valueOf(field.get('TYPE')))) {
                customField.precision = Integer.valueOf(field.get('PRECISION'));
                customField.scale = Integer.valueOf(field.get('SCALE'));
            }
            if (ruleRelation.contains(String.valueOf(field.get('TYPE')))) {
                customField.relationshipLabel = String.valueOf(field.get('RELATION_LABEL'));
                customField.relationshipName = String.valueOf(field.get('RELATION_NAME'));
                customField.referenceTo = String.valueOf(field.get('REFERENCE_TO'));

                if (String.valueOf(field.get('TYPE')) == 'MasterDetail') {
                    customField.writeRequiresMasterRead = Boolean.valueOf(field.get('WRITE_REQUIRES'));
                }
            }

            if (ruleRequired.contains(String.valueOf(field.get('TYPE')))) {
                customField.required = field.containsKey('REQUIRED') ? Boolean.valueOf(field.get('REQUIRED')) : false;
            }
            if (ruleUnique.contains(String.valueOf(field.get('TYPE')))) {
                customField.unique = field.containsKey('UNIQUE') ? Boolean.valueOf(field.get('UNIQUE')) : false;
            }
            if (ruleExternal.contains(String.valueOf(field.get('TYPE')))) {
                customField.externalId = field.containsKey('EXTERNAL') ? Boolean.valueOf(field.get('EXTERNAL')) : false;
            }

            customFields.add(customField);
        }

        return customFields;
    }

    // @description : creating batch and then insert    
    // (MAX BATCH = 10) - For single operation
    public static List<MetadataService.SaveResult> createMetadataBatches(MetadataService.MetadataPort service, List<MetadataService.Metadata> newObjectList) {
        Integer batchSize = 10; // Specify the desired batch size
        List<MetadataService.SaveResult> results = new List<MetadataService.SaveResult>();

        for (Integer i = 0; i < newObjectList.size(); i += batchSize) {
            List<MetadataService.Metadata> batch = new List<MetadataService.Metadata>();
            for (Integer j = i; j < Math.min(i + batchSize, newObjectList.size()); j++) {
                batch.add(newObjectList[j]);
            }
            
            try {
                MetadataService.SaveResult[] saveResults = service.createMetadata(batch);
                results.addAll(saveResults);
            } catch (Exception e) {
                // Handle the exception appropriately
                System.debug('An error occurred while creating metadata. Error message: ' + e.getMessage());
            }
        }

        return results;
    }
    
    public static MetadataService.MetadataPort createService(String sessionId){
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        // service.SessionHeader.sessionId = UserInfo.getSessionId();
        service.SessionHeader.sessionId = sessionId;
        return service;
    }
    
    // @description : Add all fields to page layouts
    public static MetadataService.Metadata addFieldsToLayout(MetadataService.MetadataPort service, List<Map<String, Object>> fieldList, Object objectApi ){

        String objName = String.valueOf(objectApi);
        String layoutName = String.valueOf(objectApi).replace('_', ' ').substringBefore('c').trim()+' Layout';

        MetadataService.Layout layout = (MetadataService.Layout) service.readMetadata('Layout',new String[] { objName+'-'+layoutName }).getRecords()[0];

        // Add Layout section, layout, item and field
        if(layout.layoutSections==null)
            layout.layoutSections = new List<MetadataService.LayoutSection>();

        // Find the existing section
        MetadataService.LayoutSection existingSection = null;
        for (MetadataService.LayoutSection section : layout.layoutSections) {
            if (section.label.equals('Information')) {
                existingSection = section;
                break;
            }
        }

        if(existingSection != null){
            MetadataService.LayoutColumn existingColumn = existingSection.layoutColumns[0];
            
            for (Map<String, Object> field : fieldList) {
                MetadataService.LayoutItem item = new MetadataService.LayoutItem();
                item.behavior = 'Readonly';
                item.field = String.valueOf(field.get('API'));
                existingColumn.layoutItems.add(item);
            }
        }

        return layout;

    }

    // @description : handle save result if any error accured
    public static void handleSaveResults(MetadataService.SaveResult saveResult){
        // Nothing to see?
        if(saveResult==null || saveResult.success)
            return;
        // Construct error message and throw an exception
        if(saveResult.errors!=null)
        {
            List<String> messages = new List<String>();
            messages.add(
                (saveResult.errors.size()==1 ? 'Error ' : 'Errors ') +
                    'occured processing component ' + saveResult.fullName + '.');
            for(MetadataService.Error error : saveResult.errors)
                messages.add(
                    error.message + ' (' + error.statusCode + ').' +
                    ( error.fields!=null && error.fields.size()>0 ?
                        ' Fields ' + String.join(error.fields, ',') + '.' : '' ) );
            if(messages.size()>0)
                throw new MetadataServiceExamplesException(String.join(messages, ' '));
        }
        if(!saveResult.success)
            throw new MetadataServiceExamplesException('Request failed with no specified error.');
    }

    // @description : Get current user session from Visual force page
    // VFPage Name  : GenerateSessionIdForLWC
    @AuraEnabled(cacheable=true)
    public static String getSessionId() {
        return Page.GenerateSessionIdForLWC.getContent().toString();
    }

    public class MetadataServiceExamplesException extends Exception { }

}
