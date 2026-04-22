@IsTest
private class ActualizarTotalesLoteQueueableTest {

    private static final Date HOY = Date.today();

    private static Lote__c insertLote(String cepa) {
        Lote__c lote = new Lote__c(
            Cepa__c              = cepa,
            Fecha_Inoculacion__c = HOY
        );
        insert lote;
        return lote;
    }

    // ── execute() directo ────────────────────────────────────────────────────────

    @IsTest
    static void execute_conCosechas_actualizaTotales() {
        Lote__c lote = insertLote('Shiitake');

        TriggerHandler.bypass('CosechaHandler');
        insert new List<Cosecha__c>{
            new Cosecha__c(Lote__c = lote.Id, Peso_Kg__c = 3, Fecha_cosecha__c = HOY),
            new Cosecha__c(Lote__c = lote.Id, Peso_Kg__c = 5, Fecha_cosecha__c = HOY)
        };
        TriggerHandler.clearBypass('CosechaHandler');

        Test.startTest();
        System.enqueueJob(new ActualizarTotalesLoteQueueable(new Set<Id>{ lote.Id }));
        Test.stopTest();

        lote = [SELECT Total_Cosechado_Kg__c, Cantidad_Cosechas__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(8, lote.Total_Cosechado_Kg__c);
        System.assertEquals(2, lote.Cantidad_Cosechas__c);
    }

    @IsTest
    static void execute_sinCosechas_poneCero() {
        Lote__c lote = insertLote('Ostra');

        Test.startTest();
        System.enqueueJob(new ActualizarTotalesLoteQueueable(new Set<Id>{ lote.Id }));
        Test.stopTest();

        lote = [SELECT Total_Cosechado_Kg__c, Cantidad_Cosechas__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(0, lote.Total_Cosechado_Kg__c);
        System.assertEquals(0, lote.Cantidad_Cosechas__c);
    }

    @IsTest
    static void execute_setVacio_noLanzaExcepcion() {
        Test.startTest();
        System.enqueueJob(new ActualizarTotalesLoteQueueable(new Set<Id>()));
        Test.stopTest();

        System.assert(true, 'Empty set should not throw');
    }

    @IsTest
    static void execute_variosLotes_actualizaTodos() {
        Lote__c lote1 = insertLote('Maitake');
        Lote__c lote2 = insertLote('Reishi');

        TriggerHandler.bypass('CosechaHandler');
        insert new List<Cosecha__c>{
            new Cosecha__c(Lote__c = lote1.Id, Peso_Kg__c = 4, Fecha_cosecha__c = HOY),
            new Cosecha__c(Lote__c = lote2.Id, Peso_Kg__c = 6, Fecha_cosecha__c = HOY),
            new Cosecha__c(Lote__c = lote2.Id, Peso_Kg__c = 2, Fecha_cosecha__c = HOY)
        };
        TriggerHandler.clearBypass('CosechaHandler');

        Test.startTest();
        System.enqueueJob(new ActualizarTotalesLoteQueueable(new Set<Id>{ lote1.Id, lote2.Id }));
        Test.stopTest();

        lote1 = [SELECT Total_Cosechado_Kg__c, Cantidad_Cosechas__c FROM Lote__c WHERE Id = :lote1.Id];
        lote2 = [SELECT Total_Cosechado_Kg__c, Cantidad_Cosechas__c FROM Lote__c WHERE Id = :lote2.Id];
        System.assertEquals(4, lote1.Total_Cosechado_Kg__c);
        System.assertEquals(1, lote1.Cantidad_Cosechas__c);
        System.assertEquals(8, lote2.Total_Cosechado_Kg__c);
        System.assertEquals(2, lote2.Cantidad_Cosechas__c);
    }

    // ── Integración con trigger ───────────────────────────────────────────────────

    @IsTest
    static void afterInsert_encola_actualizaTotales() {
        Lote__c lote = insertLote('Portobello');

        Test.startTest();
        insert new Cosecha__c(Lote__c = lote.Id, Peso_Kg__c = 7, Fecha_cosecha__c = HOY);
        Test.stopTest();

        lote = [SELECT Total_Cosechado_Kg__c, Cantidad_Cosechas__c FROM Lote__c WHERE Id = :lote.Id];
        System.assertEquals(7, lote.Total_Cosechado_Kg__c);
        System.assertEquals(1, lote.Cantidad_Cosechas__c);
    }
}
