import { LightningElement, track} from 'lwc';
import { publish,subscribe,unsubscribe,createMessageContext,releaseMessageContext } from 'lightning/messageService';
import LOGGER from "@salesforce/messageChannel/metaDataLogger__c";

export default class MetaDataLogComponent extends LightningElement {

    subscription = null;
    context = createMessageContext();

    @track validationlog = [];

    connectedCallback() {
        
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(this.context, LOGGER, (message) => {
            this.displayMessage(message);
        });
    }

    displayMessage(message) {
        this.validationlog.unshift(message);
    }

}