import { LightningElement, wire } from 'lwc';
import getLotesActivos from '@salesforce/apex/DashboardProduccionController.getLotesActivos';
import getKgCosechadosEsteMes from '@salesforce/apex/DashboardProduccionController.getKgCosechadosEsteMes';
import getEficienciaPromedio from '@salesforce/apex/DashboardProduccionController.getEficienciaPromedio';

export default class DashboardProduccion extends LightningElement {
    @wire(getLotesActivos) lotesActivos;
    @wire(getKgCosechadosEsteMes) kgCosechados;
    @wire(getEficienciaPromedio) eficienciaPromedio;
}
