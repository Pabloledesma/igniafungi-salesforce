import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import COSECHA_ACTUALIZADA_CHANNEL from '@salesforce/messageChannel/CosechaActualizadaChannel__c';
import ESTADO_FIELD           from '@salesforce/schema/Lote__c.Estado__c';
import EFICIENCIA_FIELD       from '@salesforce/schema/Lote__c.Eficiencia_Biologica__c';
import TOTAL_COSECHADO_FIELD  from '@salesforce/schema/Lote__c.Total_Cosechado_Kg__c';
import CANTIDAD_COSECHAS_FIELD from '@salesforce/schema/Lote__c.Cantidad_Cosechas__c';
import FECHA_INOCULACION_FIELD from '@salesforce/schema/Lote__c.Fecha_Inoculacion__c';

const FIELDS = [
    ESTADO_FIELD,
    EFICIENCIA_FIELD,
    TOTAL_COSECHADO_FIELD,
    CANTIDAD_COSECHAS_FIELD,
    FECHA_INOCULACION_FIELD
];

const ESTADO_CSS = {
    'En Inoculación':  'estado-badge estado-inoculacion',
    'En Colonización': 'estado-badge estado-colonizacion',
    'En Producción':   'estado-badge estado-produccion',
    'Finalizado':      'estado-badge estado-finalizado',
    'Archivado':       'estado-badge estado-archivado'
};

const MS_PER_DAY = 1000 * 60 * 60 * 24;

export default class LoteCard extends LightningElement {
    @api recordId;

    @wire(MessageContext) messageContext;
    _subscription;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    lote;

    connectedCallback() {
        this._subscription = subscribe(
            this.messageContext,
            COSECHA_ACTUALIZADA_CHANNEL,
            ({ loteId }) => {
                if (loteId === this.recordId) {
                    getRecordNotifyChange([{ recordId: this.recordId }]);
                }
            }
        );
    }

    disconnectedCallback() {
        unsubscribe(this._subscription);
        this._subscription = null;
    }

    get isLoading() {
        return !this.lote.data && !this.lote.error;
    }

    get hasError() {
        return !!this.lote.error;
    }

    get estado() {
        return getFieldValue(this.lote.data, ESTADO_FIELD) || '—';
    }

    get estadoClass() {
        return ESTADO_CSS[this.estado] || 'estado-badge estado-archivado';
    }

    get eficienciaBiologica() {
        return getFieldValue(this.lote.data, EFICIENCIA_FIELD) ?? 0;
    }

    // lightning-progress-bar requires value in [0, 100]
    get eficienciaClamped() {
        return Math.min(this.eficienciaBiologica, 100);
    }

    get totalCosechadoKg() {
        return getFieldValue(this.lote.data, TOTAL_COSECHADO_FIELD) ?? 0;
    }

    get cantidadCosechas() {
        return getFieldValue(this.lote.data, CANTIDAD_COSECHAS_FIELD) ?? 0;
    }

    get diasDesdeInoculacion() {
        const fecha = getFieldValue(this.lote.data, FECHA_INOCULACION_FIELD);
        if (!fecha) return '—';
        return Math.floor((Date.now() - new Date(fecha).getTime()) / MS_PER_DAY);
    }
}
