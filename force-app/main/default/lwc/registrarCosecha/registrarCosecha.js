import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import { CloseActionScreenEvent } from 'lightning/actions';
import crearCosecha from '@salesforce/apex/RegistrarCosechaController.crearCosecha';

export default class RegistrarCosecha extends LightningElement {
    @api recordId; // Lote__c Id
    
    isLoading = false;
    peso = '';
    fecha = new Date().toISOString().substring(0, 10);
    notas = '';

    handlePesoChange(event) {
        this.peso = event.target.value;
    }

    handleFechaChange(event) {
        this.fecha = event.target.value;
    }

    handleNotasChange(event) {
        this.notas = event.target.value;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleGuardar() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (!isInputsCorrect) {
            return;
        }

        this.isLoading = true;

        crearCosecha({
            loteId: this.recordId,
            peso: parseFloat(this.peso),
            fecha: this.fecha,
            notas: this.notas
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Éxito',
                    message: 'Cosecha registrada correctamente',
                    variant: 'success'
                })
            );
            
            // Disparar evento para recargar la caché de LDS y refrescar otros componentes
            this.dispatchEvent(new RefreshEvent());
            
            // Cerrar el modal
            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error => {
            let message = 'Error desconocido';
            if (error && error.body && error.body.message) {
                message = error.body.message;
            }
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: message,
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
    }
}
