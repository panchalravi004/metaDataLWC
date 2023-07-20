import { LightningElement, wire, track } from 'lwc';
import { publish, subscribe, unsubscribe, createMessageContext, releaseMessageContext } from 'lightning/messageService';
import LOGGER from "@salesforce/messageChannel/metaDataLogger__c";
import updateProfile from '@salesforce/apex/MetaDataController.updateProfile';
import getSessionId from '@salesforce/apex/MetaDataController.getSessionId';

export default class MetaDataPermissionComponent extends LightningElement {
    file;
    configData;
    isWithField = false;
    isSpinner = false;

    @track rules = {
        "Profile": ["NAME", "CUSTOM", "OBJECTS"],
        "Object": ["OBJECT_API","CREATE","DELETE","EDIT","READ","MODIFY_ALL","VIEW_ALL","FIELDS"],
        "Field": ["API","EDITABLE","READABLE"],
    };

    // Get LMS context
    context = createMessageContext();

    // Get User Session Id
    @wire(getSessionId) sessionId;

    handleFileChange(event) {
        
        this.file = event.target.files[0];
        console.log('SESSION : ', JSON.stringify(this.sessionId.data));

        if (this.file) {
            const reader = new FileReader();
            reader.onload = () => {
                const fileContent = reader.result;
                this.configData = JSON.parse(fileContent);
                // Use the jsonData as needed within the component
                console.log('JSON ', JSON.stringify(this.configData));

            };
            reader.readAsText(this.file);
        }
    }

    // - call update profile to give field and object permission
    // - pass the configuration data and session id
    handleUpdatePermission() {
        this.isSpinner = true;
        console.log('Json Validate');
        if(this.validateJsonFile()){
            console.log('Json Validate True Start');
            updateProfile({ 'configs': JSON.stringify(this.configData), 'sessionId': this.sessionId.data,'withFields':this.isWithField })
            .then((result) => {
                console.log('Result : ', JSON.stringify(result));
                this.isSpinner = false;
            })
            .catch((error) => {
                console.log('Error : ', error);
                this.isSpinner = false;
            })
            console.log('Json Validate True End');
        }else{
            console.log('Json Validate False');
            this.isSpinner = false;
        }
    }

    handleFieldCheckBox(){
        this.isWithField = !this.isWithField;
    }

    // @description validate the json file before inserting
    validateJsonFile(){

        

        // this.validationlog = [];
        var isValidate = true;

        this.configData.forEach((profile,index) => {
            
            var profileKeys = Object.keys(profile);

            this.rules['Profile'].forEach(profileRule => {
                if(!profileKeys.includes(profileRule)){
                    isValidate = false;
                    publish(this.context, LOGGER, {
                        Position:'P'+(index+1),
                        Level:'Profile',
                        Key:profileRule,
                        Message:'Required Key Missing'
                    });
                }
            });

            if(isValidate){

                profile['OBJECTS'].forEach((object,objIndex) => {
                    
                    var objKeys = Object.keys(object);

                    this.rules['Object'].forEach(objectRule => {
                        if(!objKeys.includes(objectRule)){
                            isValidate = false;
                            publish(this.context, LOGGER, {
                                Position:'P'+(index+1)+'O'+(objIndex+1),
                                Level:'Object',
                                Key:objectRule,
                                Message:'Required Key Missing'
                            });
                        }
                    });

                    if(this.isWithField){

                        if(isValidate){

                            object['FIELDS'].forEach((field,fieldIndex) => {
                                
                                var fieldKeys = Object.keys(field);

                                this.rules['Field'].forEach(fieldRule => {
                                    if(!fieldKeys.includes(fieldRule)){
                                        isValidate = false;
                                        publish(this.context, LOGGER, {
                                            Position:'P'+(index+1)+'O'+(objIndex+1)+'F'+(fieldIndex+1),
                                            Level:'Field',
                                            Key:fieldRule,
                                            Message:'Required Key Missing'
                                        });
                                    }
                                });

                            });

                        }

                    }

                });

            }

        });

        // console.log('LOG : ',JSON.stringify(this.validationlog));

        return isValidate;
    }
}