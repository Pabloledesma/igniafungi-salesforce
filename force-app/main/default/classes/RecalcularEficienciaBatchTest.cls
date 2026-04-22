@IsTest
private class RecalcularEficienciaBatchTest {

    private static final Date TEST_DATE = Date.today();

    @TestSetup
    static void setup() {
        List<Lote__c> lotes = new List<Lote__c>{
            new Lote__c(Cepa__c = 'Shiitake', Fecha_Inoculacion__c = TEST_DATE, Estado__c = 'Activo',    Peso_inicial_Kg__c = 10),
            new Lote__c(Cepa__c = 'Ostra',    Fecha_Inoculacion__c = TEST_DATE, Estado__c = 'Activo',    Peso_inicial_Kg__c = 20),
            new Lote__c(Cepa__c = 'Maitake',  Fecha_Inoculacion__c = TEST_DATE, Estado__c = 'Archivado', Peso_inicial_Kg__c = 10)
        };
        insert lotes;

        Map<String, Id> idByCepa = new Map<String, Id>();
        for (Lote__c l : [SELECT Id, Cepa__c FROM Lote__c]) {
            idByCepa.put(l.Cepa__c, l.Id);
        }

        insert new List<Cosecha__c>{
            new Cosecha__c(Lote__c = idByCepa.get('Shiitake'), Peso_Kg__c = 5, Fecha_cosecha__c = TEST_DATE),
            new Cosecha__c(Lote__c = idByCepa.get('Ostra'),    Peso_Kg__c = 8, Fecha_cosecha__c = TEST_DATE)
        };
    }

    private static Map<String, Lote__c> getLotesByCepa() {
        Map<String, Lote__c> result = new Map<String, Lote__c>();
        for (Lote__c l : [SELECT Id, Cepa__c, Eficiencia_Biologica__c FROM Lote__c]) {
            result.put(l.Cepa__c, l);
        }
        return result;
    }

    // ── Lotes activos ─────────────────────────────────────────────────────────

    @IsTest
    static void activeLots_efficiencyRecalculated() {
        Test.startTest();
        Database.executeBatch(new RecalcularEficienciaBatch(), 200);
        Test.stopTest();

        Map<String, Lote__c> lotes = getLotesByCepa();
        System.assertEquals(50.00, lotes.get('Shiitake').Eficiencia_Biologica__c); // 5/10*100
        System.assertEquals(40.00, lotes.get('Ostra').Eficiencia_Biologica__c);    // 8/20*100
    }

    // ── Lotes archivados ──────────────────────────────────────────────────────

    @IsTest
    static void archivedLots_notProcessedByBatch() {
        Lote__c archived = getLotesByCepa().get('Maitake');
        TriggerHandler.bypass('LoteHandler');
        update new Lote__c(Id = archived.Id, Eficiencia_Biologica__c = 99);
        TriggerHandler.clearBypass('LoteHandler');

        Test.startTest();
        Database.executeBatch(new RecalcularEficienciaBatch(), 200);
        Test.stopTest();

        archived = [SELECT Eficiencia_Biologica__c FROM Lote__c WHERE Id = :archived.Id];
        System.assertEquals(99, archived.Eficiencia_Biologica__c, 'Archived lot should not be touched');
    }

    // ── Contadores internos ───────────────────────────────────────────────────

    @IsTest
    static void batchCounters_reflectProcessedAndErrorTotals() {
        // Call execute() directly so the counter state is on the same instance
        RecalcularEficienciaBatch batchInstance = new RecalcularEficienciaBatch();
        List<SObject> scope = [SELECT Id FROM Lote__c WHERE Estado__c != 'Archivado'];

        Test.startTest();
        batchInstance.execute(null, scope);
        Test.stopTest();

        // 2 active lotes (Shiitake + Ostra); Maitake is Archivado and excluded from query
        System.assertEquals(2, batchInstance.totalProcesados);
        System.assertEquals(0, batchInstance.totalErrores);
    }

    // ── Bulk ──────────────────────────────────────────────────────────────────

    @IsTest
    static void bulkLots_allActiveLotsProcessed() {
        // Insert 50 extra lotes → 52 active total (fits in one chunk of 200)
        List<Lote__c> extraLotes = new List<Lote__c>();
        for (Integer i = 0; i < 50; i++) {
            extraLotes.add(new Lote__c(
                Cepa__c              = 'Lote-Bulk',
                Fecha_Inoculacion__c = TEST_DATE,
                Estado__c            = 'Activo',
                Peso_inicial_Kg__c   = 10
            ));
        }
        TriggerHandler.bypass('LoteHandler');
        insert extraLotes;
        TriggerHandler.clearBypass('LoteHandler');

        Test.startTest();
        Database.executeBatch(new RecalcularEficienciaBatch(), 200);
        Test.stopTest();

        // All 50 extra lotes have no cosechas → efficiency recalculated to 0
        Integer processedCount = [
            SELECT COUNT() FROM Lote__c
            WHERE Cepa__c = 'Lote-Bulk' AND Eficiencia_Biologica__c = 0
        ];
        System.assertEquals(50, processedCount);
    }
}
