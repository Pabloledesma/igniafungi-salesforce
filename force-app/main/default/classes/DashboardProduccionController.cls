public with sharing class DashboardProduccionController {
    
    @AuraEnabled(cacheable=true)
    public static Integer getLotesActivos() {
        return [SELECT Count() FROM Lote__c WHERE Estado__c NOT IN ('Archivado', 'Finalizado')];
    }
    
    @AuraEnabled(cacheable=true)
    public static Decimal getKgCosechadosEsteMes() {
        AggregateResult[] results = [SELECT SUM(Peso_Kg__c) total FROM Cosecha__c WHERE Fecha_cosecha__c = THIS_MONTH];
        Decimal total = (Decimal)results[0].get('total');
        return total != null ? total : 0;
    }
    
    @AuraEnabled(cacheable=true)
    public static Decimal getEficienciaPromedio() {
        AggregateResult[] results = [SELECT AVG(Eficiencia_Biologica__c) promedio FROM Lote__c WHERE Eficiencia_Biologica__c != null AND Eficiencia_Biologica__c > 0];
        Decimal promedio = (Decimal)results[0].get('promedio');
        return promedio != null ? promedio.setScale(2) : 0;
    }

    @AuraEnabled(cacheable=true)
    public static List<Lote__c> getLotesActivosList() {
        return [
            SELECT Id, Name, Cepa__c, Estado__c, Eficiencia_Biologica__c
            FROM   Lote__c
            WHERE  Estado__c NOT IN ('Archivado', 'Finalizado')
            ORDER BY CreatedDate DESC
        ];
    }
}
