public class MetaDataController {

    // @description : This is rules for different types and different fields
    public static List<String> ruleLength = new List<String>{'Text'};
    public static List<String> rulePrecision = new List<String>{'Number','Currency','Percent'};
    public static List<String> ruleRequired = new List<String>{'Text','Number','Email','Currency','Percent','Phone','Date'};
    public static List<String> ruleUnique = new List<String>{'Text','Number','Email'};
    public static List<String> ruleExternal = new List<String>{'Text','Number','Email'};
    public static List<String> ruleRelation = new List<String>{'Lookup','MasterDetail'};
    public static List<String> ruleFormula = new List<String>{'Text','Number','Currency','Percent','Date'};
    
    
    // @description : Create object with fields
    @AuraEnabled(cacheable=false)
    public static List<MetadataService.UpsertResult> createObjects(String configs, String sessionId, Boolean withFields) {
        
        List<Map<String, Object>> configList = convertJsonToList(configs);
        
        System.debug('createObjects ===> CONFIG '+configList);

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
                    List<Map<String, Object>> fieldList = convertJsonToList(JSON.serialize(con.get('Fields')));

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
    public static List<MetadataService.UpsertResult> createFields(String configs, String sessionId){
        
        List<Map<String, Object>> configList = convertJsonToList(configs);

        // Create service for current user session
        MetadataService.MetadataPort service = createService(sessionId);

        List<MetadataService.Metadata> newFieldList = new List<MetadataService.Metadata>();
        for (Map<String, Object> con : configList) {

            List<Map<String, Object>> fieldList = convertJsonToList(JSON.serialize(con.get('Fields')));

            newFieldList.addAll(createCustomFields(fieldList, String.valueOf(con.get('OBJECT_API'))));
            // add to page layout
            //newFieldList.add(addFieldsToLayout(service,fieldList,con.get('OBJECT_API')));
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

            // This will create formula field with define type
            if (ruleFormula.contains(String.valueOf(field.get('TYPE')))) {
                if(field.containsKey('FORMULA')){
                    customField.formula = String.valueOf(field.get('FORMULA'));
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

    // @description : Add Fields in multiple section of multiple layouts of multiple objects
    @AuraEnabled(cacheable=true)
    public static List<MetadataService.UpsertResult> upsertLayouts(String configs, String sessionId){

        List<Map<String, Object>> configList = convertJsonToList(configs);

        System.debug('upsertLayouts ===> CONFIG '+configList);

        // Create service for current user session
        MetadataService.MetadataPort service = createService(sessionId);

        List<MetadataService.Metadata> updatedLayoutList = new List<MetadataService.Metadata>();

        for (Map<String, Object> obj : configList) {
            
            // Get Layouts list from object
            List<Map<String, Object>> layoutList = convertJsonToList(JSON.serialize(obj.get('LAYOUTS')));

            // Get Layout
            for (Map<String, Object> objLayout : layoutList) {

                MetadataService.Layout layout = new MetadataService.Layout();
                
                if(!Boolean.valueOf(objLayout.get('ISNEW'))){
                    layout = (MetadataService.Layout) service.readMetadata('Layout',new String[] { String.valueOf(obj.get('OBJECT_API'))+'-'+String.valueOf(objLayout.get('NAME'))+' Layout' }).getRecords()[0];
                    System.debug('======== Old Layout ========');
                }else{
                    System.debug('======== New Layout ========');
                    layout.fullName = String.valueOf(obj.get('OBJECT_API'))+'-'+String.valueOf(objLayout.get('NAME'))+' Layout';
                }

                // Get Sections list from Layout
                List<Map<String, Object>> sectionList = convertJsonToList(JSON.serialize(objLayout.get('SECTIONS')));

                // sections not available then initialize this
                if(layout.layoutSections==null){
                    System.debug('======== New Section With Required Field ========');
                    layout.layoutSections = new List<MetadataService.LayoutSection>();
                }

                for (Map<String, Object> layoutSection : sectionList) {

                    MetadataService.LayoutSection section = null;

                    // Get Sections list from Layout
                    List<Map<String, Object>> fieldList = convertJsonToList(JSON.serialize(layoutSection.get('FIELDS')));
                    
                    if(!Boolean.valueOf(objLayout.get('ISNEW')) && !Boolean.valueOf(layoutSection.get('ISNEW'))){

                        for (MetadataService.LayoutSection existingSection : layout.layoutSections) {
                            if (existingSection.label.equals(String.valueOf(layoutSection.get('NAME')))) {
                                System.debug('======== Old Section Match ========');
                                section = (MetadataService.LayoutSection) existingSection;
                                break;
                            }
                        }

                        if(section != null){
                            MetadataService.LayoutColumn existingColumn = section.layoutColumns[0];
                
                            for (Map<String, Object> field : fieldList) {
                                System.debug('======== Field Updated ========');
                                MetadataService.LayoutItem item = new MetadataService.LayoutItem();
                                item.behavior = String.valueOf(field.get('BEHAVIOR'));
                                item.field = String.valueOf(field.get('API'));
                                existingColumn.layoutItems.add(item);
                            }
                        }

                    }else{
                        System.debug('======== New Section User Define ========');
                        section = new MetadataService.LayoutSection();
                        if(section != null){
                            section.editHeading = Boolean.valueOf(layoutSection.get('EDITHEADING'));
                            section.label = String.valueOf(layoutSection.get('NAME'));
                            section.style = String.valueOf(layoutSection.get('STYLE'));

                            section.layoutColumns = new List<MetadataService.LayoutColumn>();
                            MetadataService.LayoutColumn layoutColumn = new MetadataService.LayoutColumn();

                            layoutColumn.layoutItems = new List<MetadataService.LayoutItem>();

                            for (Map<String, Object> field : fieldList) {
                                System.debug('======== New Field User Define ========');
                                MetadataService.LayoutItem item = new MetadataService.LayoutItem();
                                item.behavior = String.valueOf(field.get('BEHAVIOR'));
                                item.field = String.valueOf(field.get('API'));
                                layoutColumn.layoutItems.add(item);
                            }
                            section.layoutColumns.add(layoutColumn);
                            layout.layoutSections.add(section);
                        }
                        
                    }

                }

                System.debug('======== New Layout Added ========');

                updatedLayoutList.add(layout);

            }

        }

        return createMetadataBatches(service, updatedLayoutList);

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

    // @description : creating batch and then insert    
    // (MAX BATCH = 10) - For single operation
    public static List<MetadataService.UpsertResult> createMetadataBatches(MetadataService.MetadataPort service, List<MetadataService.Metadata> newObjectList) {
        Integer batchSize = 10; // Specify the desired batch size
        List<MetadataService.UpsertResult> results = new List<MetadataService.UpsertResult>();

        for (Integer i = 0; i < newObjectList.size(); i += batchSize) {
            List<MetadataService.Metadata> batch = new List<MetadataService.Metadata>();
            for (Integer j = i; j < Math.min(i + batchSize, newObjectList.size()); j++) {
                batch.add(newObjectList[j]);
            }
            
            try {
                MetadataService.UpsertResult[] upsertResults = service.upsertMetadata(batch);
                results.addAll(upsertResults);
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

    public static List<Map<String, Object>> convertJsonToList(String jsonString){
        
        List<Object> tempList = (List<Object>) JSON.deserializeUntyped(jsonString);
        List<Map<String, Object>> configList = new List<Map<String, Object>>();

        for (Object obj : tempList) {
            if (obj instanceof Map<String, Object>) {
                Map<String, Object> config = (Map<String, Object>) obj;
                configList.add(config);
            }
        }

        return configList;

    }

    public class MetadataServiceExamplesException extends Exception { }

}