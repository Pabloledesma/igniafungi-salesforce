import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import COSECHA_ACTUALIZADA_CHANNEL from '@salesforce/messageChannel/CosechaActualizadaChannel__c';
import getCosechas from '@salesforce/apex/CosechaTimelineController.getCosechas';
import { NavigationMixin } from 'lightning/navigation';

export default class CosechaTimeline extends NavigationMixin(LightningElement) {
    @api recordId;
    @track timelineData = [];
    @track error;

    @wire(MessageContext) messageContext;
    _subscription;
    _wiredCosechasResult;

    @wire(getCosechas, { loteId: '$recordId' })
    wiredCosechas(result) {
        this._wiredCosechasResult = result;
        const { error, data } = result;
        if (data) {
            this.timelineData = data.map(item => {
                let dtStr = item.cosecha.Fecha_cosecha__c;
                let formattedDt = dtStr;
                if (dtStr) {
                    const [year, month, day] = dtStr.split('-');
                    formattedDt = `${day}/${month}/${year}`;
                }
                return {
                    ...item,
                    formattedDate: formattedDt,
                    url: `/${item.cosecha.Id}`
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Unknown error';
            this.timelineData = [];
        }
    }

    connectedCallback() {
        this._subscription = subscribe(
            this.messageContext,
            COSECHA_ACTUALIZADA_CHANNEL,
            ({ loteId }) => {
                if (loteId === this.recordId) {
                    refreshApex(this._wiredCosechasResult);
                }
            }
        );
    }

    disconnectedCallback() {
        unsubscribe(this._subscription);
        this._subscription = null;
    }

    get hasCosechas() {
        return this.timelineData && this.timelineData.length > 0;
    }

    handleRecordClick(event) {
        event.preventDefault();
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }
}
