@IsTest
private class ArchivarLotesViejosTest {

    private static final Date HOY           = Date.today();
    private static final Date HACE_190_DIAS = HOY.addDays(-190);
    private static final Date HACE_25_DIAS  = HOY.addDays(-25);
    private static final Date HACE_10_DIAS  = HOY.addDays(-10);

    private static Lote__c crearLote(String cepa, Boolean hayPrimordios) {
        Lote__c lote = new Lote__c(
            Cepa__c              = cepa,
            Hay_Primordios__c    = hayPrimordios,
            Fecha_Inoculacion__c = HACE_190_DIAS,
            Estado__c            = 'En Inoculación'
        );
        insert lote;
        return lote;
    }

    // ── Archivado correcto ────────────────────────────────────────────────────

    @IsTest
    static void loteCon4Cosechas_esArchivado() {
        Lote__c lote = crearLote('Shiitake', false);
        lote.Cantidad_Cosechas__c = 4;
        update lote;

        Test.setMock(HttpCalloutMock.class, new WebhookMock());

        Test.startTest();
        Database.executeBatch(new ArchivarLotesViejos(), 200);
        Test.stopTest();

        lote = [SELECT Archivado__c, Estado__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(true,        lote.Archivado__c);
        System.assertEquals('Archivado', lote.Estado__c);
    }

    @IsTest
    static void loteConCosechaVieja_sinPrimordios_esArchivado() {
        Lote__c lote = crearLote('Ostra', false);
        lote.Cantidad_Cosechas__c = 1;
        lote.Fecha_Ultima_Cosecha__c = HACE_25_DIAS;
        update lote;

        Test.setMock(HttpCalloutMock.class, new WebhookMock());

        Test.startTest();
        Database.executeBatch(new ArchivarLotesViejos(), 200);
        Test.stopTest();

        lote = [SELECT Archivado__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(true, lote.Archivado__c);
    }

    @IsTest
    static void loteSinCosechas_masDe180Dias_esArchivado() {
        Lote__c lote = crearLote('Shiitake', false);
        lote.Cantidad_Cosechas__c = 0;
        update lote;
        Test.setCreatedDate(lote.Id, Datetime.now().addDays(-190));
        
        Test.setMock(HttpCalloutMock.class, new WebhookMock());

        Test.startTest();
        Database.executeBatch(new ArchivarLotesViejos(), 200);
        Test.stopTest();

        lote = [SELECT Archivado__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(true, lote.Archivado__c);
    }

    // ── No archivado ──────────────────────────────────────────────────────────

    @IsTest
    static void loteConCosechaVieja_conPrimordios_noEsArchivado() {
        Lote__c lote = crearLote('Maitake', true);
        lote.Cantidad_Cosechas__c = 1;
        lote.Fecha_Ultima_Cosecha__c = HACE_25_DIAS;
        update lote;

        Test.startTest();
        Database.executeBatch(new ArchivarLotesViejos(), 200);
        Test.stopTest();

        lote = [SELECT Archivado__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(false, lote.Archivado__c);
    }

    @IsTest
    static void loteConCosechaReciente_noEsArchivado() {
        Lote__c lote = crearLote('Maitake', false);
        lote.Cantidad_Cosechas__c = 1;
        lote.Fecha_Ultima_Cosecha__c = HACE_10_DIAS;
        update lote;

        Test.startTest();
        Database.executeBatch(new ArchivarLotesViejos(), 200);
        Test.stopTest();

        lote = [SELECT Archivado__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(false, lote.Archivado__c);
    }

    @IsTest
    static void loteNuevo_sinCosechas_noEsArchivado() {
        Lote__c lote = crearLote('Enoki', false);
        lote.Cantidad_Cosechas__c = 0;
        update lote;

        Test.startTest();
        Database.executeBatch(new ArchivarLotesViejos(), 200);
        Test.stopTest();

        lote = [SELECT Archivado__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(false, lote.Archivado__c);
    }

    @IsTest
    static void loteYaArchivado_noEsReprocesado() {
        Lote__c lote = crearLote('Reishi', false);
        lote.Cantidad_Cosechas__c = 4;
        update lote;
        
        TriggerHandler.bypass('LoteHandler');
        update new Lote__c(Id = lote.Id, Archivado__c = true, Estado__c = 'Archivado');
        TriggerHandler.clearBypass('LoteHandler');

        ArchivarLotesViejos batchInstance = new ArchivarLotesViejos();

        Test.startTest();
        Database.executeBatch(batchInstance, 200);
        Test.stopTest();

        System.assertEquals(0, batchInstance.totalArchivados, 'Already archived lot should not be reprocessed');
    }

    // ── Contadores ────────────────────────────────────────────────────────────

    @IsTest
    static void execute_actualizaTotalArchivados() {
        Lote__c lote = crearLote('Portobello', false);
        lote.Cantidad_Cosechas__c = 4;
        update lote;

        ArchivarLotesViejos batchInstance = new ArchivarLotesViejos();
        List<SObject> scope = [SELECT Id FROM Lote__c WHERE Id = :lote.Id];
        Test.setMock(HttpCalloutMock.class, new WebhookMock());

        Test.startTest();
        batchInstance.execute(null, scope);
        Test.stopTest();

        System.assertEquals(1, batchInstance.totalArchivados);
    }

    // ── Mock ─────────────────────────────────────────────────────────────────

    private class WebhookMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }
}
