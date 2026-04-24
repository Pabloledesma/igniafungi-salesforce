import { LightningElement, api } from 'lwc';

const ESTADO_CSS = {
    'En Inoculación':  'estado-pill estado-inoculacion',
    'En Colonización': 'estado-pill estado-colonizacion',
    'En Producción':   'estado-pill estado-produccion',
    'Finalizado':      'estado-pill estado-finalizado',
    'Archivado':       'estado-pill estado-archivado'
};

export default class LoteRow extends LightningElement {
    @api lote;
    @api selectedLoteId;

    get isSelected() {
        return this.lote && this.selectedLoteId === this.lote.Id;
    }

    get rowClass() {
        return 'lote-row' + (this.isSelected ? ' lote-row--selected' : '');
    }

    get estadoClass() {
        return ESTADO_CSS[this.lote?.Estado__c] || 'estado-pill estado-archivado';
    }

    get eficiencia() {
        return this.lote?.Eficiencia_Biologica__c ?? 0;
    }

    handleClick() {
        this.dispatchEvent(new CustomEvent('loteselected', {
            detail: { loteId: this.lote.Id },
            bubbles: true
        }));
    }
}
