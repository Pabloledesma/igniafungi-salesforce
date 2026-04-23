@IsTest
private class LoteActualizadoEventTest {

    private static final Date HOY = Date.today();

    private static Lote__c crearLote(String cepa) {
        Lote__c lote = new Lote__c(
            Cepa__c              = cepa,
            Fecha_Inoculacion__c = HOY,
            Estado__c            = 'En Inoculación',
            ignia_id__c          = 99
        );
        insert lote;
        return lote;
    }

    // ── Publicación correcta ──────────────────────────────────────────────────

    @IsTest
    static void cambioDeEstado_publicaEvento() {
        Lote__c lote = crearLote('Shiitake');

        Test.startTest();
        update new Lote__c(Id = lote.Id, Estado__c = 'En Producción');
        Test.stopTest();

        Assert.isNotNull(LoteHandler.publishResults,
            'EventBus.publish debe haberse llamado');
        Assert.areEqual(1, LoteHandler.publishResults.size());
        Assert.isTrue(LoteHandler.publishResults[0].isSuccess(),
            'El evento debe publicarse exitosamente');
    }

    @IsTest
    static void eventoContieneDatosDelLote() {
        Lote__c lote = crearLote('Ostra');

        Test.startTest();
        update new Lote__c(Id = lote.Id, Estado__c = 'Finalizado');
        Test.stopTest();

        Assert.areEqual(1, LoteHandler.publishResults.size());
        Assert.isTrue(LoteHandler.publishResults[0].isSuccess());
        Assert.isNotNull(LoteHandler.publishResults[0].getId());
    }

    // ── Bulk ─────────────────────────────────────────────────────────────────

    @IsTest
    static void variosLotesConCambioDeEstado_publicaUnEventoPorLote() {
        Lote__c l1 = crearLote('Maitake');
        Lote__c l2 = crearLote('Reishi');

        Test.startTest();
        update new List<Lote__c>{
            new Lote__c(Id = l1.Id, Estado__c = 'En Producción'),
            new Lote__c(Id = l2.Id, Estado__c = 'Finalizado')
        };
        Test.stopTest();

        Assert.areEqual(2, LoteHandler.publishResults.size());
        for (Database.SaveResult sr : LoteHandler.publishResults) {
            Assert.isTrue(sr.isSuccess());
        }
    }

    // ── Sin cambio de estado — no se publica ──────────────────────────────────

    @IsTest
    static void updateSinCambioDeEstado_noPublicaEvento() {
        Lote__c lote = crearLote('Enoki');

        Test.startTest();
        update new Lote__c(Id = lote.Id, Cepa__c = 'Enoki Premium');
        Test.stopTest();

        Assert.isNull(LoteHandler.publishResults,
            'No debe publicarse ningún evento si Estado__c no cambió');
    }

    // ── Bypass ────────────────────────────────────────────────────────────────

    @IsTest
    static void updateConBypass_noPublicaEvento() {
        Lote__c lote = crearLote('Portobello');
        TriggerHandler.bypass('LoteHandler');

        Test.startTest();
        update new Lote__c(Id = lote.Id, Estado__c = 'Archivado');
        Test.stopTest();

        TriggerHandler.clearBypass('LoteHandler');

        Assert.isNull(LoteHandler.publishResults,
            'Con handler bypassed no debe publicarse ningún evento');
    }
}
