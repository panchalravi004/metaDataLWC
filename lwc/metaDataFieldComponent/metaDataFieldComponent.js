import { LightningElement, wire, track } from 'lwc';
import { publish, subscribe, unsubscribe, createMessageContext, releaseMessageContext } from 'lightning/messageService';
import LOGGER from "@salesforce/messageChannel/metaDataLogger__c";
import createFields from '@salesforce/apex/MetaDataController.createFields';
import getSessionId from '@salesforce/apex/MetaDataController.getSessionId';

export default class MetaDataFieldComponent extends LightningElement {

    file;
    configData;
    isSpinner = false;
    context = createMessageContext();

    @track fieldRules = {
        "Text": ["API", "LABEL", "TYPE", "LENGTH"],
        "Email": ["API", "LABEL", "TYPE"],
        "Number": ["API", "LABEL", "TYPE", "PRECISION", "SCALE"],
        "Currency": ["API", "LABEL", "TYPE", "PRECISION", "SCALE"],
        "Percent": ["API", "LABEL", "TYPE", "PRECISION", "SCALE"],
        "Lookup": ["API", "LABEL", "TYPE", "RELATION_LABEL", "RELATION_NAME", "REFERENCE_TO"],
        "MasterDetail": ["API", "LABEL", "TYPE", "RELATION_LABEL", "RELATION_NAME", "REFERENCE_TO", "WRITE_REQUIRES"],
        "Date": ["API", "LABEL", "TYPE"],
        "Phone": ["API", "LABEL", "TYPE"],
        "Picklist": ["API", "LABEL", "TYPE", "VALUES"]
    };
    


    // get user session id 
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
    handleCreateFields() {
        if (this.validateJsonFile()) {
            this.isSpinner = true;

            createFields({ 'configs': JSON.stringify(this.configData['Fields']), 'sessionId': this.sessionId.data, 'objectApi' : this.configData['OBJECT_API'] })
                .then((result) => {
                    console.log('Result : ', JSON.stringify(result));
                    this.isSpinner = false;
                })
                .catch((error) => {
                    console.log('Error : ', error);
                    this.isSpinner = false;
                })
        }
    }

    // @description validate the json file before inserting
    validateJsonFile() {

        var isValidate = true;

        if('OBJECT_API' in this.configData){
            
            if('Fields' in this.configData){

                if(this.configData['Fields']){

                    this.configData['Fields'].forEach((field, index) => {

                        var temp = Object.keys(field);
                        if ('TYPE' in field) {

                            var rules = this.fieldRules[field['TYPE']];
                            rules.forEach(fieldRule => {
                                if (!temp.includes(fieldRule)) {
                                    isValidate = false;
                                    publish(this.context, LOGGER, {
                                        Position: index + 1,
                                        Level: 'Field',
                                        Key: fieldRule,
                                        Message: 'Required Key Missing '
                                    });

                                }
                            });
                        } else {
                            isValidate = false;
                            // type missing
                            publish(this.context, LOGGER, {
                                Position: index + 1,
                                Level: 'Field',
                                Key: "TYPE",
                                Message: `Required Key Missing `
                            });
                        }

                    });
                }

            }else{
                isValidate = false;
                publish(this.context, LOGGER, {
                    Position: 0,
                    Level: 'Field',
                    Key: 'Fields',
                    Message: 'Required Key Missing '
                });
            }
        }else{
            isValidate = false;
            publish(this.context, LOGGER, {
                Position: 0,
                Level: 'Object',
                Key: 'OBJECT_API',
                Message: 'Required Key Missing '
            });
        }

        return isValidate;
    }
}