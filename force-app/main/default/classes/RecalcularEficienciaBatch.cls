public class RecalcularEficienciaBatch implements Database.Batchable<SObject>, Database.Stateful {

    @TestVisible private Integer totalProcesados = 0;
    @TestVisible private Integer totalErrores    = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Lote__c
            WHERE Estado__c != 'Archivado'
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            LoteService.calcularEficiencia(new Map<Id, SObject>(scope).keySet());
            totalProcesados += scope.size();
        } catch (Exception e) {
            totalErrores += scope.size();
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Logging to Log_Proceso__c implemented in HU-06
    }
}
