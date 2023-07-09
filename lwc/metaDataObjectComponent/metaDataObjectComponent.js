import { LightningElement, wire, track } from 'lwc';
import { publish,subscribe,unsubscribe,createMessageContext,releaseMessageContext } from 'lightning/messageService';
import LOGGER from "@salesforce/messageChannel/metaDataLogger__c";
import createObjects from '@salesforce/apex/MetaDataController.createObjects';
import getSessionId from '@salesforce/apex/MetaDataController.getSessionId';

export default class MetaDataObjectComponent extends LightningElement {

    file;
    configData;
    isWithField = false;
    isSpinner = false;

    // @track validationlog = [];

    @track objectRules = ["OBJECT_API","OBJECT_LABEL","OBJECT_PURAL","FIELD_TYPE","FIELD_LABEL","DEPLOY_STATUS","SHARING_MODEL"];

    @track fieldRules = {
        "Text": ["API", "LABEL", "TYPE", "LENGTH"],
        "Email": ["API", "LABEL", "TYPE"],
        "Number": ["API", "LABEL", "TYPE", "PRECISION", "SCALE"],
        "Currency": ["API", "LABEL", "TYPE", "PRECISION", "SCALE"],
        "Percent": ["API", "LABEL", "TYPE", "PRECISION", "SCALE"],
        "Lookup": ["API", "LABEL", "TYPE", "RELATION_LABEL", "RELATION_NAME","REFERENCE_TO"],
        "MasterDetail": ["API", "LABEL", "TYPE", "RELATION_LABEL", "RELATION_NAME","REFERENCE_TO","WRITE_REQUIRES"],
        "Date": ["API", "LABEL", "TYPE"],
        "Phone": ["API", "LABEL", "TYPE"],
        "Picklist": ["API", "LABEL", "TYPE","VALUES"]
    };

    // Get LMS context
    context = createMessageContext();

    // ---Remaining Fields---
    // Picklist
    // Formula

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

    // - call create object method to create object and fields form json 
    // - pass the configuration data and session id
    handleCreateObject() {
        this.isSpinner = true;
        if(this.validateJsonFile()){
            createObjects({ 'configs': JSON.stringify(this.configData), 'sessionId': this.sessionId.data,'withFields':this.isWithField })
            .then((result) => {
                console.log('Result : ', JSON.stringify(result));
                this.isSpinner = false;
            })
            .catch((error) => {
                console.log('Error : ', error);
                this.isSpinner = false;
            })
        }else{
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

        this.configData.forEach((obj,index) => {
            
            var temp = Object.keys(obj);

            this.objectRules.forEach(objRule => {
                if(!temp.includes(objRule)){
                    isValidate = false;
                    publish(this.context, LOGGER, {
                        Position:index+1,
                        Level:'Object',
                        Key:objRule,
                        Message:'Required Key Missing'
                    });
                }
            });

            if(this.isWithField){

                if('Fields' in obj){
                    if(obj['Fields']){

                        obj['Fields'].forEach((field,f) => {
                            
                            var temp2 = Object.keys(field);

                            if('TYPE' in field){
                                var rules = this.fieldRules[field['TYPE']];
                                rules.forEach(fieldRule => {
                                    if(!temp2.includes(fieldRule)){
                                        isValidate = false;
                                        publish(this.context, LOGGER, {
                                            Position:'O'+(index+1)+'-F'+(f+1),
                                            Level:'Field',
                                            Key:fieldRule,
                                            Message:'Required Key Missing '
                                        });

                                    }
                                });
                            }else{
                                isValidate = false;
                                // type missing
                                publish(this.context, LOGGER, {
                                    Position:(index+1)+'-'+(f+1),
                                    Level:'Field',
                                    Key:"TYPE",
                                    Message:`Required Key Missing `
                                });
                            }

                        });

                    }

                }else{
                    isValidate = false;
                    publish(this.context, LOGGER, {
                        Position:index+1,
                        Level:'Object',
                        Key:"Fields",
                        Message:'Required Key Missing'
                    });
                }

            }

        });

        // console.log('LOG : ',JSON.stringify(this.validationlog));

        return isValidate;
    }
}