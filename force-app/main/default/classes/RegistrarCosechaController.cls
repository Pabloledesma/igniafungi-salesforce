public with sharing class RegistrarCosechaController {
    
    @AuraEnabled
    public static void crearCosecha(Id loteId, Decimal peso, Date fecha, String notas) {
        try {
            Cosecha__c nuevaCosecha = new Cosecha__c();
            nuevaCosecha.Lote__c = loteId;
            nuevaCosecha.Peso_Kg__c = peso;
            nuevaCosecha.Fecha_cosecha__c = fecha;
            nuevaCosecha.Notas__c = notas;
            
            insert nuevaCosecha;
        } catch (Exception e) {
            throw new AuraHandledException('Error al registrar la cosecha: ' + e.getMessage());
        }
    }
}
