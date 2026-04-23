public class ArchivarLotesViejos implements Database.Batchable<SObject>, Database.Stateful {

    private static final Integer DIAS_SIN_COSECHA = 180;

    @TestVisible private Integer totalArchivados = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime cutoffDatetime = Datetime.now().addDays(-180);
        Date     hace20Dias     = Date.today().addDays(-20);

        return Database.getQueryLocator([
            SELECT Id
            FROM Lote__c
            WHERE Archivado__c = false
            AND   Estado__c   != 'Archivado'
            AND (
                Cantidad_Cosechas__c > 3
                OR (Fecha_Ultima_Cosecha__c < :hace20Dias AND Hay_Primordios__c = false)
                OR (Cantidad_Cosechas__c = 0 AND CreatedDate < :cutoffDatetime)
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

        List<String> ids = new List<String>();
        for (Lote__c lote : toArchive) {
            ids.add(lote.Id);
        }
        LaravelWebhookService.notificarLotesArchivados(ids);
    }

    public void finish(Database.BatchableContext bc) {}
}
