import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME_FIELD              from '@salesforce/schema/Lote__c.Name';
import CEPA_FIELD              from '@salesforce/schema/Lote__c.Cepa__c';
import ESTADO_FIELD            from '@salesforce/schema/Lote__c.Estado__c';
import EFICIENCIA_FIELD        from '@salesforce/schema/Lote__c.Eficiencia_Biologica__c';
import TOTAL_COSECHADO_FIELD   from '@salesforce/schema/Lote__c.Total_Cosechado_Kg__c';
import FECHA_INOCULACION_FIELD from '@salesforce/schema/Lote__c.Fecha_Inoculacion__c';

const FIELDS = [
    NAME_FIELD,
    CEPA_FIELD,
    ESTADO_FIELD,
    EFICIENCIA_FIELD,
    TOTAL_COSECHADO_FIELD,
    FECHA_INOCULACION_FIELD
];

const ESTADO_CSS = {
    'En Inoculación':  'estado-pill estado-inoculacion',
    'En Colonización': 'estado-pill estado-colonizacion',
    'En Producción':   'estado-pill estado-produccion',
    'Finalizado':      'estado-pill estado-finalizado',
    'Archivado':       'estado-pill estado-archivado'
};

const MS_PER_DAY = 1000 * 60 * 60 * 24;

export default class LoteDetalle extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    lote;

    get isLoading() {
        return !this.lote?.data && !this.lote?.error;
    }

    get nombre() {
        return getFieldValue(this.lote.data, NAME_FIELD) || '—';
    }

    get cepa() {
        return getFieldValue(this.lote.data, CEPA_FIELD) || '—';
    }

    get estado() {
        return getFieldValue(this.lote.data, ESTADO_FIELD) || '—';
    }

    get estadoClass() {
        return ESTADO_CSS[this.estado] || 'estado-pill estado-archivado';
    }

    get eficiencia() {
        return getFieldValue(this.lote.data, EFICIENCIA_FIELD) ?? 0;
    }

    get eficienciaClamped() {
        return Math.min(this.eficiencia, 100);
    }

    get totalCosechado() {
        return getFieldValue(this.lote.data, TOTAL_COSECHADO_FIELD) ?? 0;
    }

    get diasActivo() {
        const fecha = getFieldValue(this.lote.data, FECHA_INOCULACION_FIELD);
        if (!fecha) return '—';
        return Math.floor((Date.now() - new Date(fecha).getTime()) / MS_PER_DAY);
    }

    handleCerrar() {
        this.dispatchEvent(new CustomEvent('cerrar'));
    }
}
