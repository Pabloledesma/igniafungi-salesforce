import { LightningElement, api, wire, track } from 'lwc';
import getCosechas from '@salesforce/apex/CosechaTimelineController.getCosechas';
import { NavigationMixin } from 'lightning/navigation';

export default class CosechaTimeline extends NavigationMixin(LightningElement) {
    @api recordId;
    @track timelineData = [];
    @track error;

    @wire(getCosechas, { loteId: '$recordId' })
    wiredCosechas({ error, data }) {
        if (data) {
            this.timelineData = data.map(item => {
                // Determine the correct date handling considering timezone issues in Salesforce dates.
                // It's usually safer to use a date library or simple substring for yyyy-mm-dd format if passed.
                // SF Date comes as "YYYY-MM-DD". We can format it manually to avoid timezone shift.
                let dtStr = item.cosecha.Fecha_cosecha__c;
                let formattedDt = dtStr;
                if (dtStr) {
                    const [year, month, day] = dtStr.split('-');
                    formattedDt = `${day}/${month}/${year}`;
                }

                return {
                    ...item,
                    formattedDate: formattedDt,
                    url: `/${item.cosecha.Id}` // Placeholder for correct browser href behavior, navigation handles real
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'Unknown error';
            this.timelineData = [];
        }
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
