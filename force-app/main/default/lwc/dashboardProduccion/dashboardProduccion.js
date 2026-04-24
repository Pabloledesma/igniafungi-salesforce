import { LightningElement, wire, track } from 'lwc';
import getLotesActivos from '@salesforce/apex/DashboardProduccionController.getLotesActivos';
import getLotesActivosList from '@salesforce/apex/DashboardProduccionController.getLotesActivosList';
import getKgCosechadosEsteMes from '@salesforce/apex/DashboardProduccionController.getKgCosechadosEsteMes';
import getEficienciaPromedio from '@salesforce/apex/DashboardProduccionController.getEficienciaPromedio';

export default class DashboardProduccion extends LightningElement {
    @wire(getLotesActivos) lotesActivos;
    @wire(getKgCosechadosEsteMes) kgCosechados;
    @wire(getEficienciaPromedio) eficienciaPromedio;
    @wire(getLotesActivosList) lotesActivosList;

    @track selectedLoteId;

    get hasLotes() {
        return this.lotesActivosList.data && this.lotesActivosList.data.length > 0;
    }

    handleLoteSelected(event) {
        this.selectedLoteId = event.detail.loteId;
    }
}
