public with sharing class LaravelWebhookService implements Queueable, Database.AllowsCallouts {

    private static final String ENDPOINT =
        'callout:igniafungiwebhook/api/salesforce/webhook';

    private final List<String> loteIds;

    public LaravelWebhookService(List<String> loteIds) {
        this.loteIds = loteIds;
    }

    public static void notificarLotesArchivados(List<String> loteIds) {
        if (loteIds != null && !loteIds.isEmpty()) {
            System.enqueueJob(new LaravelWebhookService(loteIds));
        }
    }

    public void execute(QueueableContext ctx) {
        if (loteIds.isEmpty()) return;

        List<Lote__c> lotes = [
            SELECT Id, Name, Cepa__c, ignia_id__c
            FROM   Lote__c
            WHERE  Id IN :loteIds
        ];

        List<Map<String, Object>> items = new List<Map<String, Object>>();
        for (Lote__c l : lotes) {
            items.add(new Map<String, Object>{
                'loteId'  => l.Id,
                'igniaId' => l.ignia_id__c,
                'nombre'  => l.Name,
                'cepa'    => l.Cepa__c
            });
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{
            'event' => 'lotes.archivados',
            'lotes' => items
        }));

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            System.debug(LoggingLevel.ERROR,
                'LaravelWebhookService ' + res.getStatusCode() + ': ' + res.getBody());
        }
    }
}
