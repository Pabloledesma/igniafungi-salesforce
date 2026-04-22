@IsTest
private class ArchivarLotesViejosTest {

    private static final Date HOY           = Date.today();
    private static final Date HACE_190_DIAS = HOY.addDays(-190);
    private static final Date HACE_10_DIAS  = HOY.addDays(-10);

    private static Lote__c crearLote(String cepa) {
        Lote__c lote = new Lote__c(
            Cepa__c              = cepa,
            Fecha_Inoculacion__c = HACE_190_DIAS,
            Estado__c            = 'En Inoculación'
        );
        insert lote;
        return lote;
    }

    // ── Archivado correcto ────────────────────────────────────────────────────

    @IsTest
    static void loteSinCosechas_masDe180Dias_esArchivado() {
        Lote__c lote = crearLote('Shiitake');
        Test.setCreatedDate(lote.Id, Datetime.now().addDays(-190));

        Test.startTest();
        Database.executeBatch(new ArchivarLotesViejos(), 200);
        Test.stopTest();

        lote = [SELECT Archivado__c, Estado__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(true,        lote.Archivado__c);
        System.assertEquals('Archivado', lote.Estado__c);
    }

    @IsTest
    static void loteConCosechaVieja_masDe180Dias_esArchivado() {
        Lote__c lote = crearLote('Ostra');
        Test.setCreatedDate(lote.Id, Datetime.now().addDays(-190));
        insert new Cosecha__c(
            Lote__c          = lote.Id,
            Peso_Kg__c       = 5,
            Fecha_cosecha__c = HACE_190_DIAS
        );

        Test.startTest();
        Database.executeBatch(new ArchivarLotesViejos(), 200);
        Test.stopTest();

        lote = [SELECT Archivado__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(true, lote.Archivado__c);
    }

    // ── No archivado ──────────────────────────────────────────────────────────

    @IsTest
    static void loteConCosechaReciente_noEsArchivado() {
        Lote__c lote = crearLote('Maitake');
        Test.setCreatedDate(lote.Id, Datetime.now().addDays(-190));
        insert new Cosecha__c(
            Lote__c          = lote.Id,
            Peso_Kg__c       = 5,
            Fecha_cosecha__c = HACE_10_DIAS
        );

        Test.startTest();
        Database.executeBatch(new ArchivarLotesViejos(), 200);
        Test.stopTest();

        lote = [SELECT Archivado__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(false, lote.Archivado__c);
    }

    @IsTest
    static void loteNuevo_sinCosechas_noEsArchivado() {
        Lote__c lote = crearLote('Enoki');
        // CreatedDate reciente (default: now)

        Test.startTest();
        Database.executeBatch(new ArchivarLotesViejos(), 200);
        Test.stopTest();

        lote = [SELECT Archivado__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(false, lote.Archivado__c);
    }

    @IsTest
    static void loteYaArchivado_noEsReprocesado() {
        Lote__c lote = crearLote('Reishi');
        Test.setCreatedDate(lote.Id, Datetime.now().addDays(-190));
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
        Lote__c lote = crearLote('Portobello');
        Test.setCreatedDate(lote.Id, Datetime.now().addDays(-190));

        ArchivarLotesViejos batchInstance = new ArchivarLotesViejos();
        List<SObject> scope = [SELECT Id FROM Lote__c WHERE Id = :lote.Id];

        Test.startTest();
        batchInstance.execute(null, scope);
        Test.stopTest();

        System.assertEquals(1, batchInstance.totalArchivados);
    }
}
