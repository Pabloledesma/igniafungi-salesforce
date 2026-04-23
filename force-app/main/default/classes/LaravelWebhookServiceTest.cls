@IsTest
private class LaravelWebhookServiceTest {

    private static Lote__c crearLote(String cepa, Integer igniaId) {
        Lote__c lote = new Lote__c(
            Cepa__c              = cepa,
            Fecha_Inoculacion__c = Date.today().addDays(-200),
            Estado__c            = 'Archivado',
            ignia_id__c          = igniaId
        );
        insert lote;
        return lote;
    }

    // ── Callout exitoso ───────────────────────────────────────────────────────

    @IsTest
    static void notificarUnLote_callout200_sinExcepcion() {
        Lote__c lote = crearLote('Shiitake', 10);
        Test.setMock(HttpCalloutMock.class, new WebhookMock(200));

        Test.startTest();
        LaravelWebhookService.notificarLotesArchivados(new List<String>{ lote.Id });
        Test.stopTest();
    }

    @IsTest
    static void notificarVariosLotes_enviaTodosEnUnCallout() {
        Lote__c l1 = crearLote('Ostra', 11);
        Lote__c l2 = crearLote('Reishi', 12);
        Test.setMock(HttpCalloutMock.class, new WebhookMock(200));

        Test.startTest();
        LaravelWebhookService.notificarLotesArchivados(new List<String>{ l1.Id, l2.Id });
        Test.stopTest();
    }

    // ── Error del servidor — no relanza excepción ─────────────────────────────

    @IsTest
    static void respuesta500_seLogueaSinLanzarExcepcion() {
        Lote__c lote = crearLote('Maitake', 13);
        Test.setMock(HttpCalloutMock.class, new WebhookMock(500));

        Test.startTest();
        LaravelWebhookService.notificarLotesArchivados(new List<String>{ lote.Id });
        Test.stopTest();
    }

    // ── Lista vacía — no hay callout ──────────────────────────────────────────

    @IsTest
    static void listaVacia_noHaceCallout() {
        Test.setMock(HttpCalloutMock.class, new WebhookMock(200));

        Test.startTest();
        LaravelWebhookService.notificarLotesArchivados(new List<String>());
        Test.stopTest();
    }

    // ── Mock ─────────────────────────────────────────────────────────────────

    private class WebhookMock implements HttpCalloutMock {
        private final Integer statusCode;
        WebhookMock(Integer sc) { this.statusCode = sc; }

        public HttpResponse respond(HttpRequest req) {
            Assert.areEqual('callout:igniafungiwebhook/api/salesforce/webhook',
                req.getEndpoint());
            Assert.areEqual('POST', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody('{}');
            return res;
        }
    }
}
