public class ArchivarLotesViejos implements Database.Batchable<SObject>, Database.Stateful {

    private static final Integer DIAS_SIN_COSECHA = 180;

    @TestVisible private Integer totalArchivados = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime cutoffDatetime = Datetime.now().addDays(-DIAS_SIN_COSECHA);
        Date     cutoffDate     = Date.today().addDays(-DIAS_SIN_COSECHA);

        return Database.getQueryLocator([
            SELECT Id
            FROM Lote__c
            WHERE Archivado__c = false
            AND   Estado__c   != 'Archivado'
            AND   CreatedDate  < :cutoffDatetime
            AND   Id NOT IN (
                SELECT Lote__c
                FROM   Cosecha__c
                WHERE  Fecha_cosecha__c >= :cutoffDate
                AND    Lote__c          != null
            )
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Lote__c> toArchive = new List<Lote__c>();
        for (SObject s : scope) {
            toArchive.add(new Lote__c(
                Id           = s.Id,
                Archivado__c = true,
                Estado__c    = 'Archivado'
            ));
        }
        update toArchive;
        totalArchivados += toArchive.size();
    }

    public void finish(Database.BatchableContext bc) {}
}
