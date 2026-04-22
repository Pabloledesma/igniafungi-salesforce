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
        insert new Log_Proceso__c(
            Name                    = 'RecalcularEficienciaBatch ' + DateTime.now().format('yyyy-MM-dd HH:mm'),
            Tipo_Proceso__c         = 'RecalcularEficienciaBatch',
            Fecha_Ejecucion__c      = DateTime.now(),
            Registros_Procesados__c = totalProcesados,
            Registros_con_Error__c  = totalErrores,
            Estado__c               = totalErrores == 0 ? 'Exitoso' : 'Con Errores',
            Job_Id__c               = bc != null ? String.valueOf(bc.getJobId()) : null
        );
    }
}
